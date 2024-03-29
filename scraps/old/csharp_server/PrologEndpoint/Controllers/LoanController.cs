﻿using PrologEndpoint.Helpers;
using PrologEndpoint.Models;
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Web.Http;
using System.Xml;
using static PrologEndpoint.Helpers.PL;

namespace PrologEndpoint.Controllers
{
    public class LoanController : ApiController
    {
        // These strings are passed into various Prolog functions. I am afraid that they will
        // be garbage collected while in use, so I copy the strings into unmanaged memory once
        // and for all.
        private unsafe readonly char *LOAN_REPAYMENT = (char *) Marshal.StringToHGlobalAnsi("loan_repayment");
        private unsafe readonly char *LOAN_AGREEMENT = (char*) Marshal.StringToHGlobalAnsi("loan_agreement");
        private unsafe readonly char *LOAN_AGR_SUMMARY = (char*) Marshal.StringToHGlobalAnsi("loan_agr_summary");
        private unsafe readonly char *LOAN_SUMMARY = (char*) Marshal.StringToHGlobalAnsi("loan_summary");

        /* Turns the LoanRepayment object into loan_repayment term. */
        private unsafe term_t *ConstructLoanRepayment(LoanRepayment loan_rep)
        {
            // Constructing the term loan_repayment(loan_rep.Day, loan_rep.Amount)
            // where absolute_day(loan_rep.Date, loan_rep.Day).
            atom_t *loan_rep_atom = PL.PL_new_atom(LOAN_REPAYMENT);
            functor_t *loan_rep_functor = PL.PL_new_functor(loan_rep_atom, 2);
            term_t *day_term = PL.PL_new_term_ref();
            PL.PL_put_integer(day_term, Utils.ComputeAbsoluteDay(loan_rep.Date));
            term_t *amount_term = PL.PL_new_term_ref();
            PL.PL_put_float(amount_term, loan_rep.Amount);
            term_t *loan_rep_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(loan_rep_term, loan_rep_functor, __arglist(day_term, amount_term));
            return loan_rep_term;
        }

        /* Turns the array of LoanRepayments into a Prolog list of loan_repayment terms. */
        private unsafe term_t *ConstructLoanRepayments(List<LoanRepayment> loan_reps)
        {
            term_t *loan_reps_term = PL.PL_new_term_ref();
            PL.PL_put_nil(loan_reps_term);
            // We go backwards through the array because Prolog lists are constructed by consing.
            for(int i = loan_reps.Count - 1; i >= 0; i--)
            {
                // Constructing term [Loan_Repayment | Loan_Repayments] where
                // Loan_Repayment is the Prolog term corresponding to loan_reps[i] and
                // Loan_Repayments is the list constructed so far.
                PL.PL_cons_list(loan_reps_term, ConstructLoanRepayment(loan_reps[i]), loan_reps_term);
            }
            return loan_reps_term;
        }

        /* Turns the LoanAgreement into a Prolog loan_agreement term. */
        private unsafe term_t *ConstructLoanAgreement(LoanAgreement loan_agr)
        {
            atom_t *loan_agr_atom = PL.PL_new_atom(LOAN_AGREEMENT);
            functor_t *loan_agr_functor = PL.PL_new_functor(loan_agr_atom, 8);
            term_t *contract_number_term = PL.PL_new_term_ref();
            PL.PL_put_integer(contract_number_term, loan_agr.ContractNumber);
            term_t *principal_amount_term = PL.PL_new_term_ref();
            PL.PL_put_float(principal_amount_term, loan_agr.PrincipalAmount);
            term_t *lodgement_day_term = PL.PL_new_term_ref();
            PL.PL_put_integer(lodgement_day_term, Utils.ComputeAbsoluteDay(loan_agr.LodgementDate));
            term_t *begin_day_term = PL.PL_new_term_ref();
            PL.PL_put_integer(begin_day_term, Utils.ComputeAbsoluteDay(new DateTime(loan_agr.CreationIncomeYear, 7, 1)));
            term_t *term_term = PL.PL_new_term_ref();
            PL.PL_put_integer(term_term, loan_agr.Term);
            term_t *computation_year_term = PL.PL_new_term_ref();
            PL.PL_put_integer(computation_year_term, loan_agr.ComputationYear - loan_agr.CreationIncomeYear - 1);
            term_t* computation_opening_balance_term = PL.PL_new_term_ref();
            if (loan_agr.ComputationOpeningBalance < 0)
                PL.PL_put_bool(computation_opening_balance_term, PL.FALSE);
            else
                PL.PL_put_float(computation_opening_balance_term, loan_agr.ComputationOpeningBalance);
            term_t *loan_agr_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(loan_agr_term, loan_agr_functor,
                __arglist(contract_number_term, principal_amount_term, lodgement_day_term, begin_day_term, term_term, computation_year_term, computation_opening_balance_term, ConstructLoanRepayments(loan_agr.Repayments)));
            return loan_agr_term;
        }

        /* Gets the LoanSummarys of a LoanAgreement. */
        private unsafe LoanSummary GetLoanSummary(LoanAgreement loan_agr)
        {
            fid_t *fid = PL.PL_open_foreign_frame();

            // The variables that will get the solutions to the summary queries.
            term_t *number_term = PL.PL_new_term_ref();
            term_t *opening_balance_term = PL.PL_new_term_ref();
            term_t *interest_rate_term = PL.PL_new_term_ref();
            term_t *min_yearly_repayment_term = PL.PL_new_term_ref();
            term_t *total_repayment_term = PL.PL_new_term_ref();
            term_t *repayment_shortfall_term = PL.PL_new_term_ref();
            term_t *total_interest_term = PL.PL_new_term_ref();
            term_t *total_principal_term = PL.PL_new_term_ref();
            term_t *closing_balance_term = PL.PL_new_term_ref();

            // Combine the variables into a loan_summary term in preparation for unification.
            atom_t *loan_summary_atom = PL.PL_new_atom(LOAN_SUMMARY);
            functor_t *loan_summary_functor = PL.PL_new_functor(loan_summary_atom, 9);
            term_t *loan_summary_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(loan_summary_term, loan_summary_functor,
                __arglist(number_term, opening_balance_term, interest_rate_term, min_yearly_repayment_term, total_repayment_term, repayment_shortfall_term, total_interest_term, total_principal_term, closing_balance_term));

            // Query for the loan_summarys.
            predicate_t *loan_agr_summary_pred = PL.PL_predicate(LOAN_AGR_SUMMARY, 2, null);
            term_t *loan_agr_summary_pred_arg0 = PL.PL_new_term_refs(2);
            PL.PL_put_term(loan_agr_summary_pred_arg0, ConstructLoanAgreement(loan_agr));
            term_t *loan_agr_summary_pred_arg1 = (term_t *) (1 + (byte *) loan_agr_summary_pred_arg0);
            PL.PL_put_term(loan_agr_summary_pred_arg1, loan_summary_term);
            qid_t *qid = PL.PL_open_query(null, PL.PL_Q_NORMAL, loan_agr_summary_pred, loan_agr_summary_pred_arg0);
            PL.PL_next_solution(qid);

            // Make a LoanSummary object from the Prolog loan_summary term.
            LoanSummary ls = new LoanSummary();
            int number_value;
            PL.PL_get_integer(number_term, &number_value);
            ls.IncomeYear = loan_agr.CreationIncomeYear + 1 + number_value;
            double opening_balance_value;
            PL.PL_get_float(opening_balance_term, &opening_balance_value);
            ls.OpeningBalance = opening_balance_value;
            double interest_rate_value;
            PL.PL_get_float(interest_rate_term, &interest_rate_value);
            ls.InterestRate = interest_rate_value;
            double min_yearly_repayment_value;
            PL.PL_get_float(min_yearly_repayment_term, &min_yearly_repayment_value);
            ls.MinYearlyRepayment = min_yearly_repayment_value;
            double total_repayment_value;
            PL.PL_get_float(total_repayment_term, &total_repayment_value);
            ls.TotalRepayment = total_repayment_value;
            double repayment_shortfall_value;
            PL.PL_get_float(repayment_shortfall_term, &repayment_shortfall_value);
            ls.RepaymentShortfall = repayment_shortfall_value;
            double total_interest_value;
            PL.PL_get_float(total_interest_term, &total_interest_value);
            ls.TotalInterest = total_interest_value;
            double total_principal_value;
            PL.PL_get_float(total_principal_term, &total_principal_value);
            ls.TotalPrincipal = total_principal_value;
            double closing_balance_value;
            PL.PL_get_float(closing_balance_term, &closing_balance_value);
            ls.ClosingBalance = closing_balance_value;

            PL.PL_close_query(qid);
            PL.PL_discard_foreign_frame(fid);
            return ls;
        }

        /* Converts Xml input adhering to Waqas' schema into a LoanAgreement. */
        private LoanAgreement ParseLoanAgreement(XmlDocument doc)
        {
            LoanAgreement la = new LoanAgreement();
            la.CreationIncomeYear = int.Parse(doc.SelectSingleNode("/reports/loanDetails/loanAgreement/field[@name='Income year of loan creation']/@value").Value);
            la.Term = int.Parse(doc.SelectSingleNode("/reports/loanDetails/loanAgreement/field[@name='Full term of loan in years']/@value").Value);
            la.PrincipalAmount = double.Parse(doc.SelectSingleNode("/reports/loanDetails/loanAgreement/field[@name='Principal amount of loan']/@value").Value);
            la.LodgementDate = DateTime.Parse(doc.SelectSingleNode("/reports/loanDetails/loanAgreement/field[@name='Lodgment day of private company']/@value").Value);
            la.ComputationYear = int.Parse(doc.SelectSingleNode("/reports/loanDetails/loanAgreement/field[@name='Income year of computation']/@value").Value);
            XmlNode computationOpeningBalanceNode = doc.SelectSingleNode("/reports/loanDetails/loanAgreement/field[@name='Opening balance of computation']/@value");
            if (computationOpeningBalanceNode != null)
                la.ComputationOpeningBalance = double.Parse(computationOpeningBalanceNode.Value);
            else
                la.ComputationOpeningBalance = -1;

            List <LoanRepayment> lrs = new List<LoanRepayment>();
            foreach (XmlNode n in doc.SelectNodes("/reports/loanDetails/repayments/repayment"))
            {
                LoanRepayment lr = new LoanRepayment();
                lr.Amount = double.Parse(n.Attributes.GetNamedItem("value").Value);
                lr.Date = DateTime.Parse(n.Attributes.GetNamedItem("date").Value);
                lrs.Add(lr);
            }
            // Prolog program needs the LoanRepayments to be in order of date.
            lrs.Sort((x, y) => x.Date.CompareTo(y.Date));
            la.Repayments = lrs;
            return la;
        }

        /* Takes a POST request whose body contains a LoanAgreement in Xml form and compute a
         * LoanSummary. Return it with an acceptable response media type. */
        // POST: api/Loan
        [HttpPost]
        public async Task<LoanSummary> Post()
        {
            var stream = await Request.Content.ReadAsStreamAsync();
            XmlDocument doc = new XmlDocument();
            doc.Load(stream);
            LoanAgreement la = ParseLoanAgreement(doc);
            WebApiApplication.ObtainEngine();
            // Now parse the LoanAgreement in Xml and obtain corresponding summaries
            LoanSummary ls = GetLoanSummary(la);
            WebApiApplication.ReleaseEngine();
            // Now return the LoanSummarys
            return ls;
        }
    }
}

using PrologEndpoint.Helpers;
using PrologEndpoint.Models;
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Web.Http;
using System.Xml;

namespace PrologEndpoint.Controllers
{
    public class LoanController : ApiController
    {
        // These strings are passed into various Prolog functions. I am afraid that they will
        // be garbage collected while in use, so I copy the strings into unmanaged memory once
        // and for all.
        private readonly IntPtr LOAN_REPAYMENT = Marshal.StringToHGlobalAnsi("loan_repayment");
        private readonly IntPtr DATE = Marshal.StringToHGlobalAnsi("date");
        private readonly IntPtr ABSOLUTE_DAY = Marshal.StringToHGlobalAnsi("absolute_day");
        private readonly IntPtr LOAN_AGREEMENT = Marshal.StringToHGlobalAnsi("loan_agreement");
        private readonly IntPtr LOAN_AGR_PREPARE = Marshal.StringToHGlobalAnsi("loan_agr_prepare");
        private readonly IntPtr LOAN_AGR_SUMMARY = Marshal.StringToHGlobalAnsi("loan_agr_summary");
        private readonly IntPtr LOAN_SUMMARY = Marshal.StringToHGlobalAnsi("loan_summary");

        /* Computes the absolute day of the given date. */
        private int ComputeAbsoluteDay(DateTime date)
        {
            // Constructing the term date(date.Year, date.Month, date.Day)
            IntPtr date_atom = PL.PL_new_atom(DATE);
            IntPtr date_functor = PL.PL_new_functor(date_atom, 3);
            IntPtr date_year_term = PL.PL_new_term_ref();
            PL.PL_put_integer(date_year_term, date.Year);
            IntPtr date_month_term = PL.PL_new_term_ref();
            PL.PL_put_integer(date_month_term, date.Month);
            IntPtr date_day_term = PL.PL_new_term_ref();
            PL.PL_put_integer(date_day_term, date.Day);
            IntPtr date_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(date_term, date_functor, __arglist(date_year_term, date_month_term, date_day_term));

            // Constructing the query absolute_day(date(date.Year, date.Month, date.Day), B)
            IntPtr absolute_day_pred = PL.PL_predicate(ABSOLUTE_DAY, 2, null);
            IntPtr absolute_day_pred_arg0 = PL.PL_new_term_refs(2);
            PL.PL_put_term(absolute_day_pred_arg0, date_term);
            IntPtr absolute_day_pred_arg1 = absolute_day_pred_arg0 + 1;
            IntPtr absolute_day_term = PL.PL_new_term_ref();
            PL.PL_put_term(absolute_day_pred_arg1, absolute_day_term);
            IntPtr qid = PL.PL_open_query(IntPtr.Zero, PL.Q_NORMAL, absolute_day_pred, absolute_day_pred_arg0);

            // Getting a solution B to the query and close query
            PL.PL_next_solution(qid);
            PL.PL_get_integer(absolute_day_term, out int absolute_day);
            PL.PL_close_query(qid);
            return absolute_day;
        }

        /* Turns the LoanRepayment object into loan_repayment term. */
        private IntPtr ConstructLoanRepayment(LoanRepayment loan_rep)
        {
            // Constructing the term loan_repayment(loan_rep.Day, loan_rep.Amount)
            // where absolute_day(loan_rep.Date, loan_rep.Day).
            IntPtr loan_rep_atom = PL.PL_new_atom(LOAN_REPAYMENT);
            IntPtr loan_rep_functor = PL.PL_new_functor(loan_rep_atom, 2);
            IntPtr day_term = PL.PL_new_term_ref();
            PL.PL_put_integer(day_term, ComputeAbsoluteDay(loan_rep.Date));
            IntPtr amount_term = PL.PL_new_term_ref();
            PL.PL_put_float(amount_term, loan_rep.Amount);
            IntPtr loan_rep_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(loan_rep_term, loan_rep_functor, __arglist(day_term, amount_term));
            return loan_rep_term;
        }

        /* Turns the array of LoanRepayments into a Prolog list of loan_repayment terms. */
        private IntPtr ConstructLoanRepayments(LoanRepayment[] loan_reps)
        {
            IntPtr loan_reps_term = PL.PL_new_term_ref();
            PL.PL_put_atom(loan_reps_term, PL.ATOM_nil());
            // We go backwards through the array because Prolog lists are constructed by consing.
            for(int i = loan_reps.Length - 1; i >= 0; i--)
            {
                // Constructing term [Loan_Repayment | Loan_Repayments] where
                // Loan_Repayment is the Prolog term corresponding to loan_reps[i] and
                // Loan_Repayments is the list constructed so far.
                IntPtr dot_atom = PL.ATOM_dot();
                IntPtr dot_functor = PL.PL_new_functor(dot_atom, 2);
                IntPtr dot_term = PL.PL_new_term_ref();
                PL.PL_cons_functor(dot_term, dot_functor, __arglist(ConstructLoanRepayment(loan_reps[i]), loan_reps_term));
                loan_reps_term = dot_term;
            }
            return loan_reps_term;
        }

        /* Turns the LoanAgreement into a Prolog loan_agreement term. */
        private IntPtr ConstructLoanAgreement(LoanAgreement loan_agr)
        {
            IntPtr loan_agr_atom = PL.PL_new_atom(LOAN_AGREEMENT);
            IntPtr loan_agr_functor = PL.PL_new_functor(loan_agr_atom, 6);
            IntPtr contract_number_term = PL.PL_new_term_ref();
            PL.PL_put_integer(contract_number_term, loan_agr.ContractNumber);
            IntPtr principal_amount_term = PL.PL_new_term_ref();
            PL.PL_put_float(principal_amount_term, loan_agr.PrincipalAmount);
            IntPtr lodgement_day_term = PL.PL_new_term_ref();
            PL.PL_put_integer(lodgement_day_term, ComputeAbsoluteDay(loan_agr.LodgementDate));
            IntPtr begin_day_term = PL.PL_new_term_ref();
            PL.PL_put_integer(begin_day_term, ComputeAbsoluteDay(new DateTime(loan_agr.CreationIncomeYear, 7, 1)));
            IntPtr term_term = PL.PL_new_term_ref();
            PL.PL_put_integer(term_term, loan_agr.Term);
            IntPtr loan_agr_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(loan_agr_term, loan_agr_functor,
                __arglist(contract_number_term, principal_amount_term, lodgement_day_term, begin_day_term, term_term, ConstructLoanRepayments(loan_agr.Repayments)));
            return loan_agr_term;
        }

        /* Turns the LoanAgreement into a prepared loan_agreement term. */
        private IntPtr ConstructPreparedLoanAgreement(LoanAgreement loan_agr)
        {
            // Constructing the term loan_agr_prepare(Loan_Agreement, Prepared_Loan_Agreement)
            // where Loan_Agreement is a term corresponding to loan_agr.
            IntPtr prepare_loan_agr_pred = PL.PL_predicate(LOAN_AGR_PREPARE, 2, null);
            IntPtr prepare_loan_agr_pred_arg0 = PL.PL_new_term_refs(2);
            PL.PL_put_term(prepare_loan_agr_pred_arg0, ConstructLoanAgreement(loan_agr));
            IntPtr prepare_loan_agr_pred_arg1 = prepare_loan_agr_pred_arg0 + 1;
            IntPtr prepared_loan_agr_term = PL.PL_new_term_ref();
            PL.PL_put_term(prepare_loan_agr_pred_arg1, prepared_loan_agr_term);
            
            // Cutting query and returning Prepared_Loan_Agreement
            IntPtr qid = PL.PL_open_query(IntPtr.Zero, PL.Q_NORMAL, prepare_loan_agr_pred, prepare_loan_agr_pred_arg0);
            PL.PL_next_solution(qid);
            PL.PL_cut_query(qid);
            return prepared_loan_agr_term;
        }

        /* Gets the LoanSummarys of a LoanAgreement. */
        private LoanSummary[] GetLoanSummaries(LoanAgreement loan_agr)
        {
            IntPtr fid = PL.PL_open_foreign_frame();

            // The variables that will get the solutions to the summary queries.
            IntPtr number_term = PL.PL_new_term_ref();
            IntPtr opening_balance_term = PL.PL_new_term_ref();
            IntPtr interest_rate_term = PL.PL_new_term_ref();
            IntPtr min_yearly_repayment_term = PL.PL_new_term_ref();
            IntPtr total_repayment_term = PL.PL_new_term_ref();
            IntPtr total_interest_term = PL.PL_new_term_ref();
            IntPtr total_principal_term = PL.PL_new_term_ref();
            IntPtr closing_balance_term = PL.PL_new_term_ref();

            // Combine the variables into a loan_summary term in preparation for unification.
            IntPtr loan_summary_atom = PL.PL_new_atom(LOAN_SUMMARY);
            IntPtr loan_summary_functor = PL.PL_new_functor(loan_summary_atom, 8);
            IntPtr loan_summary_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(loan_summary_term, loan_summary_functor,
                __arglist(number_term, opening_balance_term, interest_rate_term, min_yearly_repayment_term, total_repayment_term, total_interest_term, total_principal_term, closing_balance_term));

            // Query for the loan_summarys.
            IntPtr loan_agr_summary_pred = PL.PL_predicate(LOAN_AGR_SUMMARY, 2, null);
            IntPtr loan_agr_summary_pred_arg0 = PL.PL_new_term_refs(2);
            PL.PL_put_term(loan_agr_summary_pred_arg0, ConstructPreparedLoanAgreement(loan_agr));
            IntPtr loan_agr_summary_pred_arg1 = loan_agr_summary_pred_arg0 + 1;
            PL.PL_put_term(loan_agr_summary_pred_arg1, loan_summary_term);
            IntPtr qid = PL.PL_open_query(IntPtr.Zero, PL.Q_NORMAL, loan_agr_summary_pred, loan_agr_summary_pred_arg0);
            
            List<LoanSummary> loanSummaries = new List<LoanSummary>();
            while (PL.PL_next_solution(qid) == PL.TRUE)
            {
                // Make a LoanSummary object from the Prolog loan_summary term.
                LoanSummary ls = new LoanSummary();
                PL.PL_get_integer(number_term, out int number_value);
                ls.IncomeYear = loan_agr.CreationIncomeYear + 1 + number_value;
                PL.PL_get_float(opening_balance_term, out double opening_balance_value);
                ls.OpeningBalance = opening_balance_value;
                PL.PL_get_float(interest_rate_term, out double interest_rate_value);
                ls.InterestRate = interest_rate_value;
                PL.PL_get_float(min_yearly_repayment_term, out double min_yearly_repayment_value);
                ls.MinYearlyRepayment = min_yearly_repayment_value;
                PL.PL_get_float(total_repayment_term, out double total_repayment_value);
                ls.TotalRepayment = total_repayment_value;
                PL.PL_get_float(total_interest_term, out double total_interest_value);
                ls.TotalInterest = total_interest_value;
                PL.PL_get_float(total_principal_term, out double total_principal_value);
                ls.TotalPrincipal = total_principal_value;
                PL.PL_get_float(closing_balance_term, out double closing_balance_value);
                ls.ClosingBalance = closing_balance_value;
                loanSummaries.Add(ls);
            }
            PL.PL_close_query(qid);
            PL.PL_discard_foreign_frame(fid);
            return loanSummaries.ToArray();
        }

        /* Converts Xml input adhering to Waqas' schema into a LoanAgreement. */
        private LoanAgreement ParseLoanAgreement(XmlDocument doc)
        {
            LoanAgreement la = new LoanAgreement();
            la.CreationIncomeYear = int.Parse(doc.SelectSingleNode("/reports/loandetails/loanAgreement/field[@name='Loan Creation Year']/@value").Value);
            la.Term = int.Parse(doc.SelectSingleNode("/reports/loandetails/loanAgreement/field[@name='Full term of loan in years']/@value").Value);
            la.PrincipalAmount = double.Parse(doc.SelectSingleNode("/reports/loandetails/loanAgreement/field[@name='Principal amount of loan']/@value").Value);
            la.LodgementDate = DateTime.Parse(doc.SelectSingleNode("/reports/loandetails/loanAgreement/field[@name='Lodgment day of private company']/@value").Value);
            List<LoanRepayment> lrs = new List<LoanRepayment>();
            foreach (XmlNode n in doc.SelectNodes("/reports/loandetails/repayments/repayment"))
            {
                LoanRepayment lr = new LoanRepayment();
                lr.Amount = double.Parse(n.Attributes.GetNamedItem("value").Value);
                lr.Date = DateTime.Parse(n.Attributes.GetNamedItem("date").Value);
                lrs.Add(lr);
            }
            // Prolog needs the LoanRepayments to be in order of date.
            lrs.Sort((x, y) => x.Date.CompareTo(y.Date));
            la.Repayments = lrs.ToArray();
            return la;
        }

        /* Takes a POST request whose body contains a LoanAgreement in Xml form and compute the
         * LoanSummarys. Return an array of them in Xml form. */
        // POST: api/Loan
        [HttpPost]
        public async Task<LoanSummary[]> Post()
        {
            var stream = await Request.Content.ReadAsStreamAsync();
            XmlDocument doc = new XmlDocument();
            doc.Load(stream);

            // Circle the Prolog engine pool until one of them is available. Hence this code
            // will block execution if there are more simultaneous requests than Prolog engines
            // at a given point in time.
            for(int i = 0; ; i = (i + 1) % WebApiApplication.PrologEngines.Length)
                if (PL.PL_set_engine(WebApiApplication.PrologEngines[i], out IntPtr old_engine_a) == PL.PL_ENGINE_SET)
                    break;
            // Now parse the LoanAgreement in Xml and obtain corresponding summaries
            LoanSummary[] lss = GetLoanSummaries(ParseLoanAgreement(doc));
            // Now release the Prolog engine that we were using so that other threads can use it.
            PL.PL_set_engine(IntPtr.Zero, out IntPtr old_engine_b);
            // Now return the LoanSummarys
            return lss;
        }
    }
}

using PrologEndpoint.Helpers;
using PrologEndpoint.Models;
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Web.Http;
using System.Xml;
using System.Xml.Serialization;
using static PrologEndpoint.Helpers.PL;

namespace PrologEndpoint.Controllers
{
    public class LedgerController : ApiController
    {
        private unsafe readonly char* ENTRY = (char*)Marshal.StringToHGlobalAnsi("entry");
        private unsafe readonly char* T_TERM = (char*)Marshal.StringToHGlobalAnsi("t_term");
        private unsafe readonly char* TRANSACTION = (char*) Marshal.StringToHGlobalAnsi("transaction");
        private unsafe readonly char* ACCOUNT_LINK = (char*)Marshal.StringToHGlobalAnsi("account_link");
        private unsafe readonly char* BALANCE_SHEET_AT = (char*)Marshal.StringToHGlobalAnsi("balance_sheet_at");

        /* Turns the LoanRepayment object into loan_repayment term. */
        private unsafe term_t* ConstructCoordinate(Coordinate c)
        {
            // Constructing the term loan_repayment(loan_rep.Day, loan_rep.Amount)
            // where absolute_day(loan_rep.Date, loan_rep.Day).
            atom_t* t_term_atom = PL.PL_new_atom(T_TERM);
            functor_t* t_term_functor = PL.PL_new_functor(t_term_atom, 3);
            term_t* unit_term = PL.PL_new_term_ref();
            PL.PL_put_atom_chars(unit_term, c.Unit.ToLower());
            term_t* debit_term = PL.PL_new_term_ref();
            PL.PL_put_float(debit_term, c.Debit);
            term_t* credit_term = PL.PL_new_term_ref();
            PL.PL_put_float(credit_term, c.Credit);
            term_t* t_term_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(t_term_term, t_term_functor, __arglist(unit_term, debit_term, credit_term));
            return t_term_term;
        }

        /* Turns the array of Coordinates into a Prolog list of coordinates. */
        private unsafe term_t* ConstructVector(List<Coordinate> vector)
        {
            term_t* vector_term = PL.PL_new_term_ref();
            PL.PL_put_nil(vector_term);
            // We go backwards through the array because Prolog lists are constructed by consing.
            for (int i = vector.Count - 1; i >= 0; i--)
            {
                // Constructing term [Coordinate | Vector] where
                // Coordinate is the Prolog term corresponding to vector[i] and
                // Vector is the list constructed so far.
                PL.PL_cons_list(vector_term, ConstructCoordinate(vector[i]), vector_term);
            }
            return vector_term;
        }

        /* Turns the LoanRepayment object into loan_repayment term. */
        private unsafe term_t* ConstructTransaction(Transaction trans)
        {
            // Constructing the term loan_repayment(loan_rep.Day, loan_rep.Amount)
            // where absolute_day(loan_rep.Date, loan_rep.Day).
            atom_t* transaction_atom = PL.PL_new_atom(TRANSACTION);
            functor_t* transaction_functor = PL.PL_new_functor(transaction_atom, 4);
            term_t* day_term = PL.PL_new_term_ref();
            PL.PL_put_integer(day_term, Date.ComputeAbsoluteDay(trans.Datetime));
            term_t* t_term_term = ConstructVector(trans.Vector);
            term_t* description_term = PL.PL_new_term_ref();
            PL.PL_put_atom_chars(description_term, trans.Description);
            term_t* account_term = PL.PL_new_term_ref();
            PL.PL_put_atom_chars(account_term, trans.Account);
            term_t* transaction_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(transaction_term, transaction_functor, __arglist(day_term, description_term, account_term, t_term_term));
            return transaction_term;
        }

        /* Turns the array of Transactions into a Prolog list of transaction terms. */
        private unsafe term_t* ConstructTransactions(List<Transaction> transactions)
        {
            term_t* transactions_term = PL.PL_new_term_ref();
            PL.PL_put_nil(transactions_term);
            // We go backwards through the array because Prolog lists are constructed by consing.
            for (int i = transactions.Count - 1; i >= 0; i--)
            {
                // Constructing term [Transaction | Transactions] where
                // Transaction is the Prolog term corresponding to transactions[i] and
                // Transactions is the list constructed so far.
                PL.PL_cons_list(transactions_term, ConstructTransaction(transactions[i]), transactions_term);
            }
            return transactions_term;
        }

        /* Turns the LoanRepayment object into loan_repayment term. */
        private unsafe term_t* ConstructAccountLink(AccountLink link)
        {
            // Constructing the term loan_repayment(loan_rep.Day, loan_rep.Amount)
            // where absolute_day(loan_rep.Date, loan_rep.Day).
            atom_t* account_link_atom = PL.PL_new_atom(ACCOUNT_LINK);
            functor_t* account_link_functor = PL.PL_new_functor(account_link_atom, 2);
            term_t* child_term = PL.PL_new_term_ref();
            PL.PL_put_atom_chars(child_term, link.subaccount);
            term_t* parent_term = PL.PL_new_term_ref();
            PL.PL_put_atom_chars(parent_term, link.superaccount);
            term_t* account_link_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(account_link_term, account_link_functor, __arglist(child_term, parent_term));
            return account_link_term;
        }

        /* Turns the array of Transactions into a Prolog list of transaction terms. */
        private unsafe term_t* ConstructAccountLinks(List<AccountLink> account_links)
        {
            term_t* account_links_term = PL.PL_new_term_ref();
            PL.PL_put_nil(account_links_term);
            // We go backwards through the array because Prolog lists are constructed by consing.
            for (int i = account_links.Count - 1; i >= 0; i--)
            {
                // Constructing term [Transaction | Transactions] where
                // Transaction is the Prolog term corresponding to transactions[i] and
                // Transactions is the list constructed so far.
                PL.PL_cons_list(account_links_term, ConstructAccountLink(account_links[i]), account_links_term);
            }
            return account_links_term;
        }

        /* Turns the array of Transactions into a Prolog list of transaction terms. */
        private unsafe term_t* ConstructBases(List<String> bases)
        {
            term_t* bases_term = PL.PL_new_term_ref();
            PL.PL_put_nil(bases_term);
            // We go backwards through the array because Prolog lists are constructed by consing.
            for (int i = bases.Count - 1; i >= 0; i--)
            {
                // Constructing term [Basis | Bases] where
                // Basis is the Prolog term corresponding to bases[i] and
                // Bases is the list constructed so far.
                PL.term_t *basis_term = PL.PL_new_term_ref();
                PL.PL_put_atom_chars(basis_term, bases[i]);
                PL.PL_cons_list(bases_term, basis_term, bases_term);
            }
            return bases_term;
        }

        private List<Transaction> ParseTransactions(XmlDocument doc)
        {
            List<Transaction> transactions = new List<Transaction>();
            foreach (XmlNode n in doc.SelectNodes("/reports/bank_statement/account_details"))
            {
                String account = n.SelectSingleNode("account_name/text()").Value;
                foreach (XmlNode m in n.SelectNodes("transactions/transaction"))
                {
                    Transaction t = new Transaction();
                    t.Description = m.Attributes.GetNamedItem("transaction_description").Value;
                    t.Datetime = DateTime.Parse(m.Attributes.GetNamedItem("transaction_datetime").Value);
                    t.Account = account;
                    t.Vector = new List<Coordinate>();
                    foreach (XmlNode p in m.SelectNodes("coordinate"))
                    {
                        Coordinate c = new Coordinate();
                        c.Unit = p.Attributes.GetNamedItem("unit").Value;
                        c.Debit = Double.Parse(p.Attributes.GetNamedItem("debit").Value);
                        c.Credit = Double.Parse(p.Attributes.GetNamedItem("credit").Value);
                        t.Vector.Add(c);
                    }
                    transactions.Add(t);
                }
            }
            return transactions;
        }

        private List<AccountLink> ParseAccountLinks(XmlDocument doc)
        {
            List<AccountLink> account_links = new List<AccountLink>();
            foreach (XmlNode n in doc.SelectNodes("/reports/bank_statement/account_details"))
            {
                AccountLink al = new AccountLink();
                al.superaccount = "asset";
                al.subaccount = n.SelectSingleNode("account_name/text()").Value;
                account_links.Add(al);
            }
            return account_links;
        }

        private List<String> ParseBases(XmlDocument doc)
        {
            List<String> bases = new List<String>();
            foreach (XmlNode n in doc.SelectNodes("/reports/bank_statement/bases/basis"))
            {
                bases.Add(n.InnerText);
            }
            return bases;
        }

        private unsafe List<Coordinate> GetVector(term_t* vector_term)
        {
            List<Coordinate> vector = new List<Coordinate>();
            term_t* head_term = PL.PL_new_term_ref();
            while (PL.PL_get_list(vector_term, head_term, vector_term) == PL.TRUE)
            {
                term_t* unit_term = PL.PL_new_term_ref();
                term_t* debit_term = PL.PL_new_term_ref();
                term_t* credit_term = PL.PL_new_term_ref();

                PL.PL_get_arg(1, head_term, unit_term);
                PL.PL_get_arg(2, head_term, debit_term);
                PL.PL_get_arg(3, head_term, credit_term);

                Coordinate c = new Coordinate();
                char* unit;
                PL.PL_get_atom_chars(unit_term, &unit);
                c.Unit = Marshal.PtrToStringAnsi(new IntPtr(unit));
                double debit;
                PL.PL_get_float(debit_term, &debit);
                c.Debit = debit;
                double credit;
                PL.PL_get_float(credit_term, &credit);
                c.Credit = credit;
                vector.Add(c);
            }
            return vector;
        }

        private unsafe BalanceSheetEntry GetBalanceSheetEntry(term_t *entry_term)
        {
            term_t* account_term = PL.PL_new_term_ref();
            term_t* vector_term = PL.PL_new_term_ref();
            term_t* children_term = PL.PL_new_term_ref();

            PL.PL_get_arg(1, entry_term, account_term);
            PL.PL_get_arg(2, entry_term, vector_term);
            PL.PL_get_arg(3, entry_term, children_term);

            BalanceSheetEntry bse = new BalanceSheetEntry();
            char* account;
            PL.PL_get_atom_chars(account_term, &account);
            bse.AccountName = Marshal.PtrToStringAnsi(new IntPtr(account));
            bse.AccountVector = GetVector(vector_term);
            bse.Subentries = new List<BalanceSheetEntry>();
            term_t* head_term = PL.PL_new_term_ref();
            while (PL.PL_get_list(children_term, head_term, children_term) == PL.TRUE)
            {
                bse.Subentries.Add(GetBalanceSheetEntry(head_term));
            }
            return bse;
        }

        private unsafe List<BalanceSheetEntry> GetBalanceSheet(List<AccountLink> accountLinks, List<Transaction> transactions, List<String> bases, DateTime exchangeDate, DateTime startDate, DateTime endDate)
        {
            fid_t* fid = PL.PL_open_foreign_frame();
            
            term_t* balance_sheet_term = PL.PL_new_term_ref();

            // Query for the balance_sheet_entrys.
            predicate_t* balance_sheet_at_pred = PL.PL_predicate(BALANCE_SHEET_AT, 7, null);
            term_t* balance_sheet_at_pred_arg0 = PL.PL_new_term_refs(7);
            PL.PL_put_term(balance_sheet_at_pred_arg0, ConstructAccountLinks(accountLinks));
            term_t* balance_sheet_at_pred_arg1 = (term_t*)(1 + (byte*)balance_sheet_at_pred_arg0);
            PL.PL_put_term(balance_sheet_at_pred_arg1, ConstructTransactions(transactions));
            term_t* balance_sheet_at_pred_arg2 = (term_t*)(2 + (byte*)balance_sheet_at_pred_arg0);
            PL.PL_put_term(balance_sheet_at_pred_arg2, ConstructBases(bases));
            term_t* balance_sheet_at_pred_arg3 = (term_t*)(3 + (byte*)balance_sheet_at_pred_arg0);
            PL.PL_put_integer(balance_sheet_at_pred_arg3, Date.ComputeAbsoluteDay(exchangeDate));
            term_t* balance_sheet_at_pred_arg4 = (term_t*)(4 + (byte*)balance_sheet_at_pred_arg0);
            PL.PL_put_integer(balance_sheet_at_pred_arg4, Date.ComputeAbsoluteDay(startDate));
            term_t* balance_sheet_at_pred_arg5 = (term_t*)(5 + (byte*)balance_sheet_at_pred_arg0);
            PL.PL_put_integer(balance_sheet_at_pred_arg5, Date.ComputeAbsoluteDay(endDate));
            term_t* balance_sheet_at_pred_arg6 = (term_t*)(6 + (byte*)balance_sheet_at_pred_arg0);
            PL.PL_put_term(balance_sheet_at_pred_arg6, balance_sheet_term);
            qid_t* qid = PL.PL_open_query(null, PL.PL_Q_NORMAL, balance_sheet_at_pred, balance_sheet_at_pred_arg0);
            PL.PL_next_solution(qid);

            List<BalanceSheetEntry> entries = new List<BalanceSheetEntry>();
            term_t* head_term = PL.PL_new_term_ref();

            while (PL.PL_get_list(balance_sheet_term, head_term, balance_sheet_term) == PL.TRUE)
            {
                entries.Add(GetBalanceSheetEntry(head_term));
            }

            PL.PL_close_query(qid);
            PL.PL_discard_foreign_frame(fid);
            return entries;
        }

        // POST api/<controller>
        [HttpPost]
        public async Task<BalanceSheet> Post()
        {
            var stream = await Request.Content.ReadAsStreamAsync();
            XmlDocument doc = new XmlDocument();
            doc.Load(stream);
            List<Transaction> transactions = ParseTransactions(doc);
            List<AccountLink> accountLinks = ParseAccountLinks(doc);
            List<String> bases = ParseBases(doc);
            DateTime balanceSheetStartDate = DateTime.Parse(doc.SelectSingleNode("/reports/bank_statement/start_datetime/text()").Value);
            DateTime balanceSheetEndDate = DateTime.Parse(doc.SelectSingleNode("/reports/bank_statement/end_datetime/text()").Value);
            DateTime exchangeDate = DateTime.Parse(doc.SelectSingleNode("/reports/bank_statement/exchange_datetime/text()").Value);
            WebApiApplication.ObtainEngine();
            BalanceSheet balanceSheet = new BalanceSheet() { balanceSheet = GetBalanceSheet(accountLinks, transactions, bases, exchangeDate, balanceSheetStartDate, balanceSheetEndDate) };
            WebApiApplication.ReleaseEngine();
            return balanceSheet;
        }

        [XmlRoot("balance_sheet")]
        public class BalanceSheet
        {
            [XmlElement("balance_sheet_entry")]
            public List<BalanceSheetEntry> balanceSheet;
        }
    }
}
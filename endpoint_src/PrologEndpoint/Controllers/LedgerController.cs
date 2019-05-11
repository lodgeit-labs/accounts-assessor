using PrologEndpoint.Helpers;
using PrologEndpoint.Models;
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Web.Http;
using System.Xml;
using System.Xml.Linq;
using static PrologEndpoint.Helpers.PL;

namespace PrologEndpoint.Controllers
{
    public class LedgerController : ApiController
    {
        private unsafe readonly char* ENTRY = (char*)Marshal.StringToHGlobalAnsi("entry");
        private unsafe readonly char* BASES = (char*)Marshal.StringToHGlobalAnsi("bases");
        private unsafe readonly char* VECTOR = (char*)Marshal.StringToHGlobalAnsi("vector");
        private unsafe readonly char* COORD = (char*)Marshal.StringToHGlobalAnsi("coord");
        private unsafe readonly char* STATEMENT_TRANSACTION = (char*) Marshal.StringToHGlobalAnsi("s_transaction");
        private unsafe readonly char* ACCOUNT = (char*)Marshal.StringToHGlobalAnsi("account");
        private unsafe readonly char* BALANCE_SHEET_AT = (char*)Marshal.StringToHGlobalAnsi("balance_sheet_at");
        private unsafe readonly char* EXCHANGE_RATE = (char*)Marshal.StringToHGlobalAnsi("exchange_rate");
        private unsafe readonly char* TRANSACTION_TYPE = (char*)Marshal.StringToHGlobalAnsi("transaction_type");
        private unsafe readonly char* PREPROCESS_STATEMENT_TRANSACTIONS = (char*)Marshal.StringToHGlobalAnsi("preprocess_s_transactions");

        /* Turns the LoanRepayment object into loan_repayment term. */
        private unsafe term_t* ConstructCoordinate(Coordinate c)
        {
            // Constructing the term loan_repayment(loan_rep.Day, loan_rep.Amount)
            // where absolute_day(loan_rep.Date, loan_rep.Day).
            atom_t* coord_atom = PL.PL_new_atom(COORD);
            functor_t* coord_functor = PL.PL_new_functor(coord_atom, 3);
            term_t* unit_term = PL.PL_new_term_ref();
            PL.PL_put_atom_chars(unit_term, c.Unit);
            term_t* debit_term = PL.PL_new_term_ref();
            PL.PL_put_float(debit_term, c.Debit);
            term_t* credit_term = PL.PL_new_term_ref();
            PL.PL_put_float(credit_term, c.Credit);
            term_t* coord_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(coord_term, coord_functor, __arglist(unit_term, debit_term, credit_term));
            return coord_term;
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

        /* Turns the StatementTransaction object into stransaction term. */
        private unsafe term_t* ConstructStatementTransaction(StatementTransaction trans)
        {
            // Constructing the term loan_repayment(loan_rep.Day, loan_rep.Amount)
            // where absolute_day(loan_rep.Date, loan_rep.Day).
            atom_t* transaction_atom = PL.PL_new_atom(STATEMENT_TRANSACTION);
            functor_t* transaction_functor = PL.PL_new_functor(transaction_atom, 5);
            term_t* day_term = PL.PL_new_term_ref();
            PL.PL_put_integer(day_term, Utils.ComputeAbsoluteDay(trans.Date));
            term_t* type_id_term = PL.PL_new_term_ref();
            PL.PL_put_atom_chars(type_id_term, trans.TypeId);
            term_t* vector_term = ConstructVector(trans.Vector);
            term_t* account_term = PL.PL_new_term_ref();
            PL.PL_put_atom_chars(account_term, trans.Account);
            term_t* exchanged_amount_term = PL.PL_new_term_ref();
            if(trans.ExchangedAmountBases != null)
            {
                atom_t* bases_atom = PL.PL_new_atom(BASES);
                functor_t* bases_functor = PL.PL_new_functor(bases_atom, 1);
                PL.PL_cons_functor(exchanged_amount_term, bases_functor, __arglist(ConstructBases(trans.ExchangedAmountBases)));
            } else
            {
                atom_t* vector_atom = PL.PL_new_atom(VECTOR);
                functor_t* vector_functor = PL.PL_new_functor(vector_atom, 1);
                PL.PL_cons_functor(exchanged_amount_term, vector_functor, __arglist(ConstructVector(trans.ExchangedAmountVector)));
            }
            term_t* transaction_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(transaction_term, transaction_functor, __arglist(day_term, type_id_term, vector_term, account_term, exchanged_amount_term));
            return transaction_term;
        }

        /* Turns the array of StatementTransactions into a Prolog list of stransaction terms. */
        private unsafe term_t* ConstructStatementTransactions(List<StatementTransaction> transactions)
        {
            term_t* transactions_term = PL.PL_new_term_ref();
            PL.PL_put_nil(transactions_term);
            // We go backwards through the array because Prolog lists are constructed by consing.
            for (int i = transactions.Count - 1; i >= 0; i--)
            {
                // Constructing term [Transaction | Transactions] where
                // Transaction is the Prolog term corresponding to transactions[i] and
                // Transactions is the list constructed so far.
                PL.PL_cons_list(transactions_term, ConstructStatementTransaction(transactions[i]), transactions_term);
            }
            return transactions_term;
        }

        private unsafe term_t* PreprocessStatementTransactions(List<ExchangeRate> exchangeRates, List<TransactionType> transactionTypes, List<StatementTransaction> statementTransactions)
        {
            term_t *transactions_term = PL.PL_new_term_ref();
            term_t* preprocess_term = PL.PL_new_term_ref();

            // Query for the balance_sheet_entrys.
            predicate_t* balance_sheet_at_pred = PL.PL_predicate(PREPROCESS_STATEMENT_TRANSACTIONS, 4, null);
            term_t* balance_sheet_at_pred_arg0 = PL.PL_new_term_refs(4);
            PL.PL_put_term(balance_sheet_at_pred_arg0, ConstructExchangeRates(exchangeRates));
            term_t* balance_sheet_at_pred_arg1 = (term_t*)(1 + (byte*)balance_sheet_at_pred_arg0);
            PL.PL_put_term(balance_sheet_at_pred_arg1, ConstructTransactionTypes(transactionTypes));
            term_t* balance_sheet_at_pred_arg2 = (term_t*)(2 + (byte*)balance_sheet_at_pred_arg0);
            PL.PL_put_term(balance_sheet_at_pred_arg2, ConstructStatementTransactions(statementTransactions));
            term_t* balance_sheet_at_pred_arg3 = (term_t*)(3 + (byte*)balance_sheet_at_pred_arg0);
            PL.PL_put_term(balance_sheet_at_pred_arg3, transactions_term);
            qid_t* qid = PL.PL_open_query(null, PL.PL_Q_NORMAL, balance_sheet_at_pred, balance_sheet_at_pred_arg0);
            PL.PL_next_solution(qid);
            PL.PL_cut_query(qid);
            return transactions_term;
        }

        /* Turns the Account object into an account term. */
        private unsafe term_t* ConstructAccount(Account account)
        {
            // Constructing the term account(link.Id, link.ParentId)
            atom_t* account_atom = PL.PL_new_atom(ACCOUNT);
            functor_t* account_functor = PL.PL_new_functor(account_atom, 2);
            term_t* id_term = PL.PL_new_term_ref();
            PL.PL_put_atom_chars(id_term, account.Id);
            term_t* parent_id_term = PL.PL_new_term_ref();
            PL.PL_put_atom_chars(parent_id_term, account.ParentId);
            term_t* account_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(account_term, account_functor, __arglist(id_term, parent_id_term));
            return account_term;
        }

        /* Turns the array of Transactions into a Prolog list of transaction terms. */
        private unsafe term_t* ConstructAccounts(List<Account> accounts)
        {
            term_t* accounts_term = PL.PL_new_term_ref();
            PL.PL_put_nil(accounts_term);
            // We go backwards through the array because Prolog lists are constructed by consing.
            for (int i = accounts.Count - 1; i >= 0; i--)
            {
                // Constructing term [Transaction | Transactions] where
                // Transaction is the Prolog term corresponding to transactions[i] and
                // Transactions is the list constructed so far.
                PL.PL_cons_list(accounts_term, ConstructAccount(accounts[i]), accounts_term);
            }
            return accounts_term;
        }

        /* Turns the array of bases into a Prolog list of transaction terms. */
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

        private unsafe term_t* ConstructExchangeRate(ExchangeRate exchangeRate)
        {
            // Constructing the term exchange_rate(exchangeRate.Day, exchangeRate.SrcCurrency, exchangeRate.DestCurrency, exchangeRate.Rate)
            // where absolute_day(exchangeRate.Date, exchangeRate.Day).
            atom_t* exchange_rate_atom = PL.PL_new_atom(EXCHANGE_RATE);
            functor_t* exchange_rate_functor = PL.PL_new_functor(exchange_rate_atom, 4);
            term_t* day_term = PL.PL_new_term_ref();
            PL.PL_put_integer(day_term, Utils.ComputeAbsoluteDay(exchangeRate.Date));
            term_t* src_currency_term = PL.PL_new_term_ref();
            PL.PL_put_atom_chars(src_currency_term, exchangeRate.SrcCurrency);
            term_t* dest_currency_term = PL.PL_new_term_ref();
            PL.PL_put_atom_chars(dest_currency_term, exchangeRate.DestCurrency);
            term_t* rate_term = PL.PL_new_term_ref();
            PL.PL_put_float(rate_term, exchangeRate.Rate);
            term_t* exchange_rate_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(exchange_rate_term, exchange_rate_functor, __arglist(day_term, src_currency_term, dest_currency_term, rate_term));
            return exchange_rate_term;
        }

        /* Turns the array of ExchangeRates into a Prolog list of exchange_rate terms. */
        private unsafe term_t* ConstructExchangeRates(List<ExchangeRate> exchangeRates)
        {
            term_t* exchange_rates_term = PL.PL_new_term_ref();
            PL.PL_put_nil(exchange_rates_term);
            // We go backwards through the array because Prolog lists are constructed by consing.
            for (int i = exchangeRates.Count - 1; i >= 0; i--)
            {
                // Constructing term [Exchange_Rate | Exchange_Rates] where
                // Exchange_Rate is the Prolog term corresponding to exchangeRates[i] and
                // Exchange_Rates is the list constructed so far.
                PL.PL_cons_list(exchange_rates_term, ConstructExchangeRate(exchangeRates[i]), exchange_rates_term);
            }
            return exchange_rates_term;
        }

        private unsafe term_t* ConstructTransactionType(TransactionType transactionType)
        {
            // Constructing the term transaction_type(transactionType.Id, transactionType.Bases, transactionType.ExchangeAccount, transactionType.TradingAccount, transactionType.Description)
            atom_t* transaction_type_atom = PL.PL_new_atom(TRANSACTION_TYPE);
            functor_t* transaction_type_functor = PL.PL_new_functor(transaction_type_atom, 4);
            term_t* id_term = PL.PL_new_term_ref();
            PL.PL_put_atom_chars(id_term, transactionType.Id);
            term_t* exchanged_account_term = PL.PL_new_term_ref();
            PL.PL_put_atom_chars(exchanged_account_term, transactionType.ExchangeAccount);
            term_t* trading_account_term = PL.PL_new_term_ref();
            PL.PL_put_atom_chars(trading_account_term, transactionType.TradingAccount);
            term_t* description_term = PL.PL_new_term_ref();
            PL.PL_put_string_chars(description_term, transactionType.Description);
            term_t* transaction_type_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(transaction_type_term, transaction_type_functor, __arglist(id_term, exchanged_account_term, trading_account_term, description_term));
            return transaction_type_term;
        }

        /* Turns the array of TransactionTypes into a Prolog list of transaction_type terms. */
        private unsafe term_t* ConstructTransactionTypes(List<TransactionType> transactionTypes)
        {
            term_t* transaction_types_term = PL.PL_new_term_ref();
            PL.PL_put_nil(transaction_types_term);
            // We go backwards through the array because Prolog lists are constructed by consing.
            for (int i = transactionTypes.Count - 1; i >= 0; i--)
            {
                // Constructing term [Transaction_Type | Transaction_Types] where
                // Transaction_Type is the Prolog term corresponding to transactionTypes[i] and
                // Transaction_Types is the list constructed so far.
                PL.PL_cons_list(transaction_types_term, ConstructTransactionType(transactionTypes[i]), transaction_types_term);
            }
            return transaction_types_term;
        }

        private List<StatementTransaction> ParseStatementTransactions(XmlDocument doc)
        {
            List<String> defaultBases = ParseBases(doc);
            List<StatementTransaction> transactions = new List<StatementTransaction>();
            foreach (XmlNode n in doc.SelectNodes("/reports/balanceSheetRequest/bankStatement/accountDetails"))
            {
                String account = n.SelectSingleNode("accountName/text()").Value;
                String currency = n.SelectSingleNode("currency/text()").Value;
                foreach (XmlNode m in n.SelectNodes("transactions/transaction"))
                {
                    Coordinate c = new Coordinate();
                    c.Unit = currency;
                    c.Debit = Double.Parse(m.SelectSingleNode("debit/text()").Value);
                    c.Credit = Double.Parse(m.SelectSingleNode("credit/text()").Value);
                    XmlNode unitQuantity = m.SelectSingleNode("unit/text()");
                    XmlNode unitType = m.SelectSingleNode("unitType/text()");
                    StatementTransaction st = new StatementTransaction
                    {
                        TypeId = m.SelectSingleNode("transdesc/text()").Value,
                        Date = DateTime.Parse(m.SelectSingleNode("transdate/text()").Value),
                        Account = account,
                        Vector = new List<Coordinate>() { c }
                    };
                    if (unitQuantity != null && unitType != null)
                    {
                        // If the user has specified both the unit quantity and type, then exchange rate
                        // conversion and hence a target bases is unnecessary.
                        st.ExchangedAmountVector = new List<Coordinate>() { new Coordinate {
                            Unit = unitType.Value,
                            Debit = Double.Parse(unitQuantity.Value),
                            Credit = 0 } };
                        st.ExchangedAmountBases = null;
                    } else if(unitType != null)
                    {
                        // If the user has specified only a unit type, then automatically do a conversion
                        // to that unit.
                        st.ExchangedAmountVector = null;
                        st.ExchangedAmountBases = new List<string>() { unitType.Value };
                    } else
                    {
                        // If the user has not specified both the unit quantity and type, then automatically
                        // do a conversion to the default bases.
                        st.ExchangedAmountVector = null;
                        st.ExchangedAmountBases = defaultBases;
                    }

                    transactions.Add(st);
                }
            }
            return transactions;
        }

        private List<ExchangeRate> ParseExchangeRates(XmlDocument doc, DateTime balanceSheetEndDate)
        {
            List<ExchangeRate> exchangeRates = new List<ExchangeRate>();
            foreach (XmlNode n in doc.SelectNodes("/reports/balanceSheetRequest/unitValues/unitValue")) {
                exchangeRates.Add(new ExchangeRate()
                {
                    Date = balanceSheetEndDate,
                    SrcCurrency = n.SelectSingleNode("unitType/text()").Value,
                    DestCurrency = n.SelectSingleNode("unitValueCurrency/text()").Value,
                    Rate = Double.Parse(n.SelectSingleNode("unitValue/text()").Value)
                });
            }
            return exchangeRates;
        }

        private List<Account> ParseAccounts(XmlDocument doc)
        {
            // The account hierarchy is hard-coded into this endpoint for now
            return new List<Account>()
            {


Accounts
	Assets
		CurrentAssets
			CashAndCashEquivalents
				WellsFargo
				NationalAustraliaBank
	NoncurrentAssets
		FinancialInvestments

        Equity
		ShareCapital
	Liabilities
		NoncurrentLiabilities
			NoncurrentLoans
		CurrentLiabilities
			CurrentLoans
	Earnings
		Revenue
			InvestmentIncome

		Expenses
			BankCharges
			ForexLoss
		CurrentEarningsLosses
		RetainedEarnings


            };
        }

        private List<TransactionType> ParseTransactionTypes(XmlDocument doc)
        {
            // The transaction types are hard-coded into this endpoint for now
            return new List<TransactionType>()
            {
<action Id="Invest_In", 	Description="Shares", 		ExchangeAccount="FinancialInvestments", TradingAccount="InvestmentIncome" \>
<action Id="Dispose_Off", 	Description="Shares", 		ExchangeAccount="FinancialInvestments", TradingAccount="InvestmentIncome" \>
<action Id="Borrow", 		Description="Shares", 		ExchangeAccount="NoncurrentLoans", 	TradingAccount="InvestmentIncome" \>
<action Id="Introduce_Capital", Description="Unit_Investment", 	ExchangeAccount="ShareCapital", 	TradingAccount="InvestmentIncome" \>
<action Id="Gain", 		Description="Unit_Investment", 	ExchangeAccount="ShareCapital", 	TradingAccount="InvestmentIncome" \>
<action Id="Loss", 		Description="No Description", 	ExchangeAccount="ShareCapital", 	TradingAccount="InvestmentIncome" \>
<action Id="PayBank", 		Description="No Description", 	ExchangeAccount="BankCharges", 		TradingAccount="InvestmentIncome" \>
            };
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

        private unsafe List<BalanceSheetEntry> GetBalanceSheet(List<ExchangeRate> exchangeRates, List<TransactionType> transactionTypes, List<Account> accountLinks, List<StatementTransaction> transactions, List<String> bases, DateTime exchangeDate, DateTime startDate, DateTime endDate)
        {
            fid_t* fid = PL.PL_open_foreign_frame();
            
            term_t* balance_sheet_term = PL.PL_new_term_ref();

            // Query for the balance_sheet_entrys.
            predicate_t* balance_sheet_at_pred = PL.PL_predicate(BALANCE_SHEET_AT, 8, null);
            term_t* balance_sheet_at_pred_arg0 = PL.PL_new_term_refs(8);
            PL.PL_put_term(balance_sheet_at_pred_arg0, ConstructExchangeRates(exchangeRates));
            term_t* balance_sheet_at_pred_arg1 = (term_t*)(1 + (byte*)balance_sheet_at_pred_arg0);
            PL.PL_put_term(balance_sheet_at_pred_arg1, ConstructAccounts(accountLinks));
            term_t* balance_sheet_at_pred_arg2 = (term_t*)(2 + (byte*)balance_sheet_at_pred_arg0);
            PL.PL_put_term(balance_sheet_at_pred_arg2, PreprocessStatementTransactions(exchangeRates, transactionTypes, transactions));
            term_t* balance_sheet_at_pred_arg3 = (term_t*)(3 + (byte*)balance_sheet_at_pred_arg0);
            PL.PL_put_term(balance_sheet_at_pred_arg3, ConstructBases(bases));
            term_t* balance_sheet_at_pred_arg4 = (term_t*)(4 + (byte*)balance_sheet_at_pred_arg0);
            PL.PL_put_integer(balance_sheet_at_pred_arg4, Utils.ComputeAbsoluteDay(exchangeDate));
            term_t* balance_sheet_at_pred_arg5 = (term_t*)(5 + (byte*)balance_sheet_at_pred_arg0);
            PL.PL_put_integer(balance_sheet_at_pred_arg5, Utils.ComputeAbsoluteDay(startDate));
            term_t* balance_sheet_at_pred_arg6 = (term_t*)(6 + (byte*)balance_sheet_at_pred_arg0);
            PL.PL_put_integer(balance_sheet_at_pred_arg6, Utils.ComputeAbsoluteDay(endDate));
            term_t* balance_sheet_at_pred_arg7 = (term_t*)(7 + (byte*)balance_sheet_at_pred_arg0);
            PL.PL_put_term(balance_sheet_at_pred_arg7, balance_sheet_term);
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

        public void synthesizeBalanceSheetEntry(DateTime balanceSheetEndDate, BalanceSheetEntry balanceSheetEntry, XElement target, List<String> unitsFound)
        {
            XNamespace basic = "http://www.xbrlsite.com/basic";
            foreach(Coordinate c in balanceSheetEntry.AccountVector)
            {
                if (!unitsFound.Contains(c.Unit))
                {
                    target.Add(new XElement("unit",
                        new XAttribute("id", "U-" + c.Unit),
                        new XElement("measure", c.Unit)));
                    unitsFound.Add(c.Unit);
                }
                target.Add(new XElement(basic + balanceSheetEntry.AccountName,
                    new XAttribute("contextRef", "D-" + balanceSheetEndDate.Year),
                    new XAttribute("unitRef", "U-" + c.Unit),
                    new XAttribute("decimals", "INF"),
                    c.Debit - c.Credit));
            }
            foreach(BalanceSheetEntry bse in balanceSheetEntry.Subentries)
            {
                synthesizeBalanceSheetEntry(balanceSheetEndDate, bse, target, unitsFound);
            }
        }

        public XElement synthesizeBalanceSheet(DateTime balanceSheetStartDate, DateTime balanceSheetEndDate, List<BalanceSheetEntry> balanceSheet)
        {
            XNamespace instance = "http://www.xbrl.org/2003/instance";
            XNamespace link = "http://www.xbrl.org/2003/linkbase";
            XNamespace xlink = "http://www.w3.org/1999/xlink";
            XElement xbrl = new XElement(instance + "xbrl",
                new XAttribute(XNamespace.Xmlns + "xbrli", "http://www.xbrl.org/2003/instance"),
                new XAttribute(XNamespace.Xmlns + "link", "http://www.xbrl.org/2003/linkbase"),
                new XAttribute(XNamespace.Xmlns + "xlink", "http://www.w3.org/1999/xlink"),
                new XAttribute(XNamespace.Xmlns + "xsi", "http://www.w3.org/2001/XMLSchema-instance"),
                new XAttribute(XNamespace.Xmlns + "iso4217", "http://www.xbrl.org/2003/iso4217"),
                new XAttribute(XNamespace.Xmlns + "basic", "http://www.xbrlsite.com/basic"),
                new XElement(link + "schemaRef", new XAttribute(xlink + "type", "simple"), new XAttribute(xlink + "href", "basic.xsd"), new XAttribute(xlink + "title", "Taxonomy schema")),
                new XElement(link + "linkbaseRef", new XAttribute(xlink + "type", "simple"), new XAttribute(xlink + "href", "basic-formulas.xml"), new XAttribute(xlink + "arcrole", "http://www.w3.org/1999/xlink/properties/linkbase")),
                new XElement(link + "linkBaseRef", new XAttribute(xlink + "type", "simple"), new XAttribute(xlink + "href", "basic-formulas-cross-checks.xml"), new XAttribute(xlink + "arcrole", "http://www.w3.org/1999/xlink/properties/linkbase")),
                new XElement("context", new XAttribute("id", "D-" + balanceSheetEndDate.Year),
                    new XElement("entity", new XElement("identifier", new XAttribute("scheme", "http://standards.iso.org/iso/17442"), "30810137d58f76b84afd")),
                    new XElement("period",
                        new XElement("startDate", balanceSheetStartDate.ToString("yyyy-MM-dd")),
                        new XElement("endDate", balanceSheetEndDate.ToString("yyyy-MM-dd")))));

            List<String> unitsFound = new List<string>();
            foreach (BalanceSheetEntry bse in balanceSheet) synthesizeBalanceSheetEntry(balanceSheetEndDate, bse, xbrl, unitsFound);
            return xbrl;
        }

        // POST api/<controller>
        [HttpPost]
        public async Task<XElement> Post()
        {
            var stream = await Request.Content.ReadAsStreamAsync();
            XmlDocument doc = new XmlDocument();
            doc.Load(stream);
            List<StatementTransaction> transactions = ParseStatementTransactions(doc);
            List<Account> accountLinks = ParseAccounts(doc);
            List<String> bases = ParseBases(doc);
            DateTime balanceSheetStartDate = DateTime.Parse(doc.SelectSingleNode("/reports/balanceSheetRequest/startDate/text()").Value);
            DateTime balanceSheetEndDate = DateTime.Parse(doc.SelectSingleNode("/reports/balanceSheetRequest/endDate/text()").Value);
            List<ExchangeRate> exchangeRates = ParseExchangeRates(doc, balanceSheetEndDate);
            List<TransactionType> transactionTypes = ParseTransactionTypes(doc);
            
            WebApiApplication.ObtainEngine();
            List<BalanceSheetEntry> balanceSheet = GetBalanceSheet(exchangeRates, transactionTypes, accountLinks, transactions, bases, balanceSheetEndDate, balanceSheetStartDate, balanceSheetEndDate);
            WebApiApplication.ReleaseEngine();
            return synthesizeBalanceSheet(balanceSheetStartDate, balanceSheetEndDate, balanceSheet);
        }
    }
}
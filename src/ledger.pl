% The purpose of the following program is to derive the summary information of a ledger.
% That is, with the knowledge of all the transactions in a ledger, the following program
% will derive the balance sheets at given points in time, and the trial balance and
% movements over given periods of time.

% This program is part of a larger system for validating and correcting balance sheets.
% Hence the information derived by this program will ultimately be compared to values
% calculated by other means.

:- use_module(library(http/http_open)).
:- use_module(library(http/json)).

% Pacioli group operations. These operations operate on pairs of numbers called T-terms.
% These t-terms represent an entry in a T-table. The first element of the T-term
% represents debit and second element, credit.
% See: On Double-Entry Bookkeeping: The Mathematical Treatment

% The identity for vector addition.

pac_identity([]).

% Computes the inverse of a given vector.

pac_inverse(As, Bs) :-
	findall(C,
		(member(t_term(Unit, A_Debit, A_Credit), As),
		C = t_term(Unit, A_Credit, A_Debit)),
		Bs).

% Each coordinate of a vector can be replaced by other coordinates that equivalent for the
% purposes of the computations carried out in this program. This predicate reduces any
% coordinate into a canonical form.

pac_reduce(As, Bs) :-
	findall(B,
		(member(t_term(Unit, A_Debit, A_Credit), As),
		B_Debit is A_Debit - min(A_Debit, A_Credit),
		B_Credit is A_Credit - min(A_Debit, A_Credit),
		B = t_term(Unit, B_Debit, B_Credit)),
		Bs).

% Adds the two given vectors together.

pac_add(As, Bs, Cs_Reduced) :-
	findall(C,
		((member(t_term(Unit, A_Debit, A_Credit), As),
		\+ member(t_term(Unit, _, _), Bs),
		C = t_term(Unit, A_Debit, A_Credit));
		
		(member(t_term(Unit, B_Debit, B_Credit), Bs),
		\+ member(t_term(Unit, _, _), As),
		C = t_term(Unit, B_Debit, B_Credit));
		
		(member(t_term(Unit, A_Debit, A_Credit), As),
		member(t_term(Unit, B_Debit, B_Credit), Bs),
		Total_Debit is A_Debit + B_Debit,
		Total_Credit is A_Credit + B_Credit,
		C = t_term(Unit, Total_Debit, Total_Credit))),
		Cs),
	pac_reduce(Cs, Cs_Reduced).

% Subtracts the vector Bs from As by inverting Bs and adding it to As.

pac_sub(As, Bs, Cs) :-
	pac_inverse(Bs, Ds),
	pac_add(As, Ds, Cs).

% Checks two vectors for equality by subtracting the latter from the former and verifying
% that all the resulting coordinates are zero.

pac_equality(As, Bs) :-
	pac_sub(As, Bs, Cs),
	forall(member(C, Cs), C = t_term(_, 0, 0)).

% Obtains all available exchange rates on the day Day using Src_Currency as the base
% currency from exchangeratesapi.io. The results are memoized because this operation is
% slow and use of the web endpoint is subject to usage limits. The web endpoint used is
% https://api.exchangeratesapi.io/YYYY-MM-DD?base=Src_Currency .

:- dynamic exchange_rates/3.

exchange_rates(Day, Src_Currency, Exchange_Rates) :-
	gregorian_date(Day, Date),
	format_time(string(Date_Str), "%Y-%m-%d", Date),
	upcase_atom(Src_Currency, Src_Currency_Upcased),
	atom_string(Src_Currency_Upcased, Src_Currency_Str),
	string_concat("https://api.exchangeratesapi.io/", Date_Str, Query_Url_A),
	string_concat(Query_Url_A, "?base=", Query_Url_B),
	string_concat(Query_Url_B, Src_Currency_Str, Query_Url),
	http_open(Query_Url, Stream, []),
	json_read(Stream, json(Response), []),
	member(rates = json(Exchange_Rates), Response),
	close(Stream),
	asserta((exchange_rates(Day, Src_Currency, Exchange_Rates) :- !)).

% Obtains the exchange rate from Src_Currency to Dest_Currency on the day Day using the
% exchange_rates predicate.

exchange_rate(Day, Src_Currency, Dest_Currency, Exchange_Rate) :-
	exchange_rates(Day, Src_Currency, Exchange_Rates),
	upcase_atom(Dest_Currency, Dest_Currency_Upcased),
	member(Dest_Currency_Upcased = Exchange_Rate, Exchange_Rates).

% Exchanges the given coordinate, Amount, into the first unit from Bases for which an
% exchange on the day Day is possible. If Amount cannot be exchanged into any of the units
% from Bases, then it is left as is.

exchange_amount(_, [], Amount, Amount).

exchange_amount(Day, [Bases_Hd | _], t_term(Unit, Debit, Credit), Amount_Exchanged) :-
	exchange_rate(Day, Unit, Bases_Hd, Exchange_Rate),
	Debit_Exchanged is Debit * Exchange_Rate,
	Credit_Exchanged is Credit * Exchange_Rate,
	Amount_Exchanged = t_term(Bases_Hd, Debit_Exchanged, Credit_Exchanged).

exchange_amount(Day, [Bases_Hd | Bases_Tl], t_term(Unit, Debit, Credit), Amount_Exchanged) :-
	\+ exchange_rate(Day, Bases_Hd, Unit, _),
	exchanged_amount(Day, Bases_Tl, t_term(Unit, Debit, Credit), Amount_Exchanged).

% Consolidate the given t-terms as much as possible by exchanging each t-term into a unit
% from Bases on the day Day and combining those of the resulting t-terms that have the
% same unit together. If a t-term cannot be exchanged into a unit from Bases, then it is
% put into the result as is.

pac_consolidate(_, _, [], []).

pac_consolidate(Day, Bases, [A | As], Bs) :-
	exchange_amount(Day, Bases, A, A_Exchanged),
	pac_consolidate(Day, Bases, As, As_Exchanged),
	pac_add([A_Exchanged], As_Exchanged, Bs).

% Isomorphisms from T-Terms to signed quantities
% See: On Double-Entry Bookkeeping: The Mathematical Treatment

credit_isomorphism(t_term(A, B), C) :- C is B - A.

debit_isomorphism(t_term(A, B), C) :- C is A - B.

% Predicates for asserting that the fields of given accounts have particular values

% The child in the given account link
account_link_child(account_link(Account_Link_Child, _), Account_Link_Child).
% The parent in the given account link
account_link_parent(account_link(_, Account_Link_Parent), Account_Link_Parent).
% Relates an account to a parent account
account_parent(Account_Links, Account, Parent) :-
	account_link_parent(Account_Link, Parent),
	account_link_child(Account_Link, Account),
	member(Account_Link, Account_Links).
% Relates an account to an ancestral account
account_ancestor(Account_Links, Account, Ancestor) :-
	Account = Ancestor;
	(account_parent(Account_Links, Ancestor_Child, Ancestor),
	account_ancestor(Account_Links, Account, Ancestor_Child)).

% Predicates for asserting that the fields of given transactions have particular values

% The absolute day that the transaction happenned
transaction_day(transaction(Day, _, _, _), Day).
% A description of the transaction
transaction_description(transaction(_, Description, _, _), Description).
% The account that the transaction modifies
transaction_account(transaction(_, _, Account, _), Account).
% The amounts by which the account is being debited and credited
transaction_t_term(transaction(_, _, _, T_Term), T_Term).

transaction_account_ancestor(Account_Links, Transaction, Ancestor_Account) :-
	transaction_account(Transaction, Transaction_Account),
	account_ancestor(Account_Links, Transaction_Account, Ancestor_Account).

transaction_between(Transaction, From_Day, To_Day) :-
	transaction_day(Transaction, Day),
	From_Day =< Day,
	Day =< To_Day.

transaction_before(Transaction, End_Day) :-
	transaction_day(Transaction, Day),
	Day =< End_Day.

% Account isomorphisms. They are standard conventions in accounting.

account_isomorphism(asset, debit_isomorphism).
account_isomorphism(equity, credit_isomorphism).
account_isomorphism(liability, credit_isomorphism).
account_isomorphism(revenue, credit_isomorphism).
account_isomorphism(expense, debit_isomorphism).

% Adds all the T-Terms of the transactions.

transaction_t_term_total([], []).

transaction_t_term_total([Hd_Transaction | Tl_Transaction], Reduced_Net_Activity) :-
	transaction_t_term(Hd_Transaction, Curr),
	transaction_t_term_total(Tl_Transaction, Acc),
	pac_add(Curr, Acc, Net_Activity),
	pac_reduce(Net_Activity, Reduced_Net_Activity).

% Relates Day to the balance at that time of the given account.

balance_by_account(Accounts, Transactions, Bases, Exchange_Day, Account, Day, Balance_Consolidated) :-
	findall(Transaction,
		(member(Transaction, Transactions),
		transaction_before(Transaction, Day),
		transaction_account_ancestor(Accounts, Transaction, Account)), Transactions_A),
	transaction_t_term_total(Transactions_A, Balance),
	pac_consolidate(Exchange_Day, Bases, Balance, Balance_Consolidated).

% Relates the period from From_Day to To_Day to the net activity during that period of
% the given account.

net_activity_by_account(Accounts, Transactions, Bases, Exchange_Day, Account, From_Day, To_Day, Net_Activity_Consolidated) :-
	findall(Transaction,
		(member(Transaction, Transactions),
		transaction_between(Transaction, From_Day, To_Day),
		transaction_account_ancestor(Accounts, Transaction, Account)), Transactions_A),
	transaction_t_term_total(Transactions_A, Net_Activity),
	pac_consolidate(Exchange_Day, Bases, Net_Activity, Net_Activity_Consolidated).

% Now for balance sheet predicates.

balance_sheet_entry(Account_Links, Transactions, Bases, Exchange_Day, Account, To_Day, Sheet_Entry) :-
	findall(Child_Sheet_Entry, (account_parent(Account_Links, Child_Account, Account),
		balance_sheet_entry(Account_Links, Transactions, Bases, Exchange_Day, Child_Account, To_Day, Child_Sheet_Entry)),
		Child_Sheet_Entries),
	balance_by_account(Account_Links, Transactions, Bases, Exchange_Day, Account, To_Day, Balance),
	Sheet_Entry = entry(Account, Balance, Child_Sheet_Entries).

balance_sheet_at(Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, Balance_Sheet) :-
	balance_sheet_entry(Accounts, Transactions, Bases, Exchange_Day, asset, To_Day, Asset_Section),
	balance_sheet_entry(Accounts, Transactions, Bases, Exchange_Day, equity, To_Day, Equity_Section),
	balance_sheet_entry(Accounts, Transactions, Bases, Exchange_Day, liability, To_Day, Liability_Section),
	balance_by_account(Accounts, Transactions, Bases, Exchange_Day, earnings, From_Day, Retained_Earnings),
	net_activity_by_account(Accounts, Transactions, Bases, Exchange_Day, earnings, From_Day, To_Day, Current_Earnings),
	pac_add(Retained_Earnings, Current_Earnings, Earnings),
	pac_reduce(Earnings, Earnings_Reduced),
	Balance_Sheet = [Asset_Section, Liability_Section, entry(earnings, Earnings_Reduced,
		[entry(retained_earnings, Retained_Earnings, []), entry(current_earnings, Current_Earnings, [])]),
		Equity_Section].

% Now for trial balance predicates.

trial_balance_entry(Account_Links, Transactions, Bases, Exchange_Day, Account, From_Day, To_Day, Trial_Balance_Entry) :-
	findall(Child_Sheet_Entry, (account_parent(Account_Links, Child_Account, Account),
		trial_balance_entry(Account_Links, Transactions, Bases, Exchange_Day, Child_Account, From_Day, To_Day, Child_Sheet_Entry)),
		Child_Sheet_Entries),
	net_activity_by_account(Account_Links, Transactions, Bases, Exchange_Day, Account, From_Day, To_Day, Net_Activity),
	Trial_Balance_Entry = entry(Account, Net_Activity, Child_Sheet_Entries).

trial_balance_between(Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, Trial_Balance) :-
	balance_sheet_entry(Accounts, Transactions, Bases, Exchange_Day, asset, To_Day, Asset_Section),
	balance_sheet_entry(Accounts, Transactions, Bases, Exchange_Day, equity, To_Day, Equity_Section),
	balance_sheet_entry(Accounts, Transactions, Bases, Exchange_Day, liability, To_Day, Liability_Section),
	trial_balance_entry(Accounts, Transactions, Bases, Exchange_Day, revenue, From_Day, To_Day, Revenue_Section),
	trial_balance_entry(Accounts, Transactions, Bases, Exchange_Day, expense, From_Day, To_Day, Expense_Section),
	balance_by_account(Accounts, Transactions, Bases, Exchange_Day, earnings, From_Day, Retained_Earnings),
	Trial_Balance = [Asset_Section, Liability_Section, entry(retained_earnings, Retained_Earnings, []),
		Equity_Section, Revenue_Section, Expense_Section].

% Now for movement predicates.

movement_between(Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, Movement) :-
	trial_balance_entry(Accounts, Transactions, Bases, Exchange_Day, asset, From_Day, To_Day, Asset_Section),
	trial_balance_entry(Accounts, Transactions, Bases, Exchange_Day, equity, From_Day, To_Day, Equity_Section),
	trial_balance_entry(Accounts, Transactions, Bases, Exchange_Day, liability, From_Day, To_Day, Liability_Section),
	trial_balance_entry(Accounts, Transactions, Bases, Exchange_Day, revenue, From_Day, To_Day, Revenue_Section),
	trial_balance_entry(Accounts, Transactions, Bases, Exchange_Day, expense, From_Day, To_Day, Expense_Section),
	Movement = [Asset_Section, Liability_Section, Equity_Section, Revenue_Section,
		Expense_Section].


% The purpose of the following program is to derive the summary information of a ledger.
% That is, with the knowledge of all the transactions in a ledger, the following program
% will derive the balance sheets at given points in time, and the trial balance and
% movements over given periods of time.

% This program is part of a larger system for validating and correcting balance sheets.
% Hence the information derived by this program will ultimately be compared to values
% calculated by other means.

:- use_module(library(http/http_open)).
:- use_module(library(http/json)).

% Obtains all available exchange rates on the day Day using an arbitrary base currency
% from exchangeratesapi.io. The results are memoized because this operation is slow and
% use of the web endpoint is subject to usage limits. The web endpoint used is
% https://openexchangerates.org/api/historical/YYYY-MM-DD.json?app_id=677e4a964d1b44c99f2053e21307d31a .

:- dynamic exchange_rates/2.

exchange_rates(Day, Exchange_Rates) :-
	gregorian_date(Day, Date),
	format_time(string(Date_Str), "%Y-%m-%d", Date),
	string_concat("http://openexchangerates.org/api/historical/", Date_Str, Query_Url_A),
	string_concat(Query_Url_A, ".json?app_id=677e4a964d1b44c99f2053e21307d31a", Query_Url),
	http_open(Query_Url, Stream, []),
	json_read(Stream, json(Response), []),
	member(rates = json(Exchange_Rates), Response),
	close(Stream),
	asserta((exchange_rates(Day, Exchange_Rates) :- !)).

% % Predicates for asserting that the fields of given exchange rates have particular values

% The day to which the exchange rate applies
exchange_rate_day(exchange_rate(Day, _, _, _), Day).
% The source currency of this exchange rate
exchange_rate_src_currency(exchange_rate(_, Src_Currency, _, _), Src_Currency).
% The destination currency of this exchange rate
exchange_rate_dest_currency(exchange_rate(_, _, Dest_Currency, _), Dest_Currency).
% The actual rate of this exchange rate
exchange_rate_rate(exchange_rate(_, _, _, Rate), Rate).

% Obtains the exchange rate from Src_Currency to Dest_Currency on the day Day using the
% given lookup table.

symmetric_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate) :-
  member(exchange_rate(Day, Src_Currency, Dest_Currency, Exchange_Rate), Table).

symmetric_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate) :-
  member(exchange_rate(Day, Dest_Currency, Src_Currency, Inverted_Exchange_Rate), Table),
  Exchange_Rate is 1 / Inverted_Exchange_Rate.

% Obtains the exchange rate from Src_Currency to Dest_Currency on the day Day using the
% exchange_rates predicate.

symmetric_exchange_rate(_, Day, Src_Currency_Upcased, Dest_Currency_Upcased, Exchange_Rate) :-
	exchange_rates(Day, Exchange_Rates),
	member(Src_Currency = Src_Exchange_Rate, Exchange_Rates),
	member(Dest_Currency = Dest_Exchange_Rate, Exchange_Rates),
	Exchange_Rate is Dest_Exchange_Rate / Src_Exchange_Rate,
	upcase_atom(Src_Currency, Src_Currency_Upcased),
	upcase_atom(Dest_Currency, Dest_Currency_Upcased).

% Derive an exchange rate from the source to the destination currency by chaining together
% =< Length exchange rates.

equivalence_exchange_rate(_, _, Currency, Currency, 1, Length) :- Length >= 0.

equivalence_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate, Length) :-
  Length > 0,
  symmetric_exchange_rate(Table, Day, Src_Currency, Int_Currency, Head_Exchange_Rate),
  New_Length is Length - 1,
  equivalence_exchange_rate(Table, Day, Int_Currency, Dest_Currency, Tail_Exchange_Rate, New_Length),
  Exchange_Rate is Head_Exchange_Rate * Tail_Exchange_Rate, !.

% Derive an exchange rate from the source to the destination currency by chaining together
% =< 2 exchange rates.

exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate) :-
  equivalence_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate, 2), !.

% Pacioli group operations. These operations operate on vectors. A vector is a list of
% coordinates. A coordinate is a triple comprising a unit, a debit amount, and a credit
% amount. See: On Double-Entry Bookkeeping: The Mathematical Treatment Also see: Tutorial
% on multiple currency accounting

% The identity for vector addition.

vec_identity([]).

% Computes the (additive) inverse of a given vector.

vec_inverse(As, Bs) :-
	findall(C,
		(member(coord(Unit, A_Debit, A_Credit), As),
		C = coord(Unit, A_Credit, A_Debit)),
		Bs).

% Each coordinate of a vector can be replaced by other coordinates that equivalent for the
% purposes of the computations carried out in this program. This predicate reduces the
% coordinates of a vector into a canonical form.

vec_reduce(As, Bs) :-
	findall(B,
		(member(coord(Unit, A_Debit, A_Credit), As),
		B_Debit is A_Debit - min(A_Debit, A_Credit),
		B_Credit is A_Credit - min(A_Debit, A_Credit),
		B = coord(Unit, B_Debit, B_Credit)),
		Bs).

% Adds the two given vectors together.

vec_add(As, Bs, Cs_Reduced) :-
	findall(C,
		((member(coord(Unit, A_Debit, A_Credit), As),
		\+ member(coord(Unit, _, _), Bs),
		C = coord(Unit, A_Debit, A_Credit));
		
		(member(coord(Unit, B_Debit, B_Credit), Bs),
		\+ member(coord(Unit, _, _), As),
		C = coord(Unit, B_Debit, B_Credit));
		
		(member(coord(Unit, A_Debit, A_Credit), As),
		member(coord(Unit, B_Debit, B_Credit), Bs),
		Total_Debit is A_Debit + B_Debit,
		Total_Credit is A_Credit + B_Credit,
		C = coord(Unit, Total_Debit, Total_Credit))),
		Cs),
	vec_reduce(Cs, Cs_Reduced).

% Subtracts the vector Bs from As by inverting Bs and adding it to As.

vec_sub(As, Bs, Cs) :-
	vec_inverse(Bs, Ds),
	vec_add(As, Ds, Cs).

% Checks two vectors for equality by subtracting the latter from the former and verifying
% that all the resulting coordinates are zero.

vec_equality(As, Bs) :-
	vec_sub(As, Bs, Cs),
	forall(member(C, Cs), C = coord(_, 0, 0)).

% Exchanges the given coordinate, Amount, into the first unit from Bases for which an
% exchange on the day Day is possible. If Amount cannot be exchanged into any of the units
% from Bases, then it is left as is.

exchange_amount(_, _, [], Amount, Amount).

exchange_amount(Exchange_Rates, Day, [Bases_Hd | _], coord(Unit, Debit, Credit), Amount_Exchanged) :-
	exchange_rate(Exchange_Rates, Day, Unit, Bases_Hd, Exchange_Rate),
	Debit_Exchanged is Debit * Exchange_Rate,
	Credit_Exchanged is Credit * Exchange_Rate,
	Amount_Exchanged = coord(Bases_Hd, Debit_Exchanged, Credit_Exchanged).

exchange_amount(Exchange_Rates, Day, [Bases_Hd | Bases_Tl], coord(Unit, Debit, Credit), Amount_Exchanged) :-
	\+ exchange_rate(Exchange_Rates, Day, Bases_Hd, Unit, _),
	exchange_amount(Exchange_Rates, Day, Bases_Tl, coord(Unit, Debit, Credit), Amount_Exchanged).

% Using the exchange rates from the day Day, change the bases of the given vector into
% those from Bases. Where two different coordinates have been mapped to the same basis,
% combine them. If a coordinate cannot be exchanged into a unit from Bases, then it is
% put into the result as is.

vec_change_bases(_, _, _, [], []).

vec_change_bases(Exchange_Rates, Day, Bases, [A | As], Bs) :-
	exchange_amount(Exchange_Rates, Day, Bases, A, A_Exchanged),
	vec_change_bases(Exchange_Rates, Day, Bases, As, As_Exchanged),
	vec_add([A_Exchanged], As_Exchanged, Bs).

% Predicates for asserting that the fields of given accounts have particular values

% The ID of the given account
account_id(account(Account_Id, _), Account_Id).
% The ID of the parent of the given account
account_parent_id(account(_, Account_Parent_Id), Account_Parent_Id).
% Relates an account id to a parent account id
account_parent_id(Accounts, Account_Id, Parent_Id) :-
	account_parent_id(Account, Parent_Id),
	account_id(Account, Account_Id),
	member(Account, Accounts).
% Relates an account to an ancestral account
account_ancestor_id(Accounts, Account_Id, Ancestor_Id) :-
	Account_Id = Ancestor_Id;
	(account_parent_id(Accounts, Ancestor_Child_Id, Ancestor_Id),
	account_ancestor_id(Accounts, Account_Id, Ancestor_Child_Id)).

% Gets the ids for the assets, equity, liabilities, earnings, retained earnings, current
% earnings, revenue, and expenses accounts. These are the first eight accounts in any
% accounts list.
account_ids([Account0|[Account1|[Account2|[Account3|[Account4|[Account5|[Account6|[Account7|_]]]]]]]],
    Assets, Equity, Liabilities, Earnings, Retained_Earnings, Current_Earnings, Revenue, Expenses) :-
  account_id(Account0, Assets), % Assets account always comes first
  account_id(Account1, Equity), % Equity account always comes second
  account_id(Account2, Liabilities), % Liabilities account always comes third
  account_id(Account3, Earnings), % Earnings account always comes fourth
  account_id(Account4, Retained_Earnings), % Retained earnings account always comes fifth
  account_id(Account5, Current_Earnings), % Current earnings account always comes sixth
  account_id(Account6, Revenue), % Revenue account always comes seventh
  account_id(Account7, Expenses). % Expenses account always comes eighth

% Predicates for asserting that the fields of given transactions have particular values

% The absolute day that the transaction happenned
transaction_day(transaction(Day, _, _, _), Day).
% A description of the transaction
transaction_description(transaction(_, Description, _, _), Description).
% The account that the transaction modifies
transaction_account_id(transaction(_, _, Account_Id, _), Account_Id).
% The amounts by which the account is being debited and credited
transaction_vector(transaction(_, _, _, Vector), Vector).

transaction_account_ancestor_id(Accounts, Transaction, Ancestor_Account_Id) :-
	transaction_account_id(Transaction, Transaction_Account_Id),
	account_ancestor_id(Accounts, Transaction_Account_Id, Ancestor_Account_Id).

transaction_between(Transaction, From_Day, To_Day) :-
	transaction_day(Transaction, Day),
	From_Day =< Day,
	Day =< To_Day.

transaction_before(Transaction, End_Day) :-
	transaction_day(Transaction, Day),
	Day =< End_Day.

% Adds all the T-Terms of the transactions.

transaction_vector_total([], []).

transaction_vector_total([Hd_Transaction | Tl_Transaction], Reduced_Net_Activity) :-
	transaction_vector(Hd_Transaction, Curr),
	transaction_vector_total(Tl_Transaction, Acc),
	vec_add(Curr, Acc, Net_Activity),
	vec_reduce(Net_Activity, Reduced_Net_Activity).

% Relates Day to the balance at that time of the given account.

balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, Day, Balance_Transformed) :-
	findall(Transaction,
		(member(Transaction, Transactions),
		transaction_before(Transaction, Day),
		transaction_account_ancestor_id(Accounts, Transaction, Account_Id)), Transactions_A),
	transaction_vector_total(Transactions_A, Balance),
	vec_change_bases(Exchange_Rates, Exchange_Day, Bases, Balance, Balance_Transformed).

% Relates the period from From_Day to To_Day to the net activity during that period of
% the given account.

net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, From_Day, To_Day, Net_Activity_Transformed) :-
	findall(Transaction,
		(member(Transaction, Transactions),
		transaction_between(Transaction, From_Day, To_Day),
		transaction_account_ancestor_id(Accounts, Transaction, Account_Id)), Transactions_A),
	transaction_vector_total(Transactions_A, Net_Activity),
	vec_change_bases(Exchange_Rates, Exchange_Day, Bases, Net_Activity, Net_Activity_Transformed).

% Now for balance sheet predicates.

balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, To_Day, Sheet_Entry) :-
	findall(Child_Sheet_Entry, (account_parent_id(Accounts, Child_Account, Account_Id),
		balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Child_Account, To_Day, Child_Sheet_Entry)),
		Child_Sheet_Entries),
	balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, To_Day, Balance),
	Sheet_Entry = entry(Account_Id, Balance, Child_Sheet_Entries).

balance_sheet_at(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, Balance_Sheet) :-
  account_ids(Accounts, Assets_AID, Equity_AID, Liabilities_AID, Earnings_AID, Retained_Earnings_AID, Current_Earnings_AID, _, _),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Assets_AID, To_Day, Asset_Section),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Equity_AID, To_Day, Equity_Section),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Liabilities_AID, To_Day, Liability_Section),
	balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Earnings_AID, From_Day, Retained_Earnings),
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Earnings_AID, From_Day, To_Day, Current_Earnings),
	vec_add(Retained_Earnings, Current_Earnings, Earnings),
	vec_reduce(Earnings, Earnings_Reduced),
	Balance_Sheet = [Asset_Section, Liability_Section, entry(Earnings_AID, Earnings_Reduced,
		[entry(Retained_Earnings_AID, Retained_Earnings, []), entry(Current_Earnings_AID, Current_Earnings, [])]),
		Equity_Section].

% Now for trial balance predicates.

trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, From_Day, To_Day, Trial_Balance_Entry) :-
	findall(Child_Sheet_Entry, (account_parent_id(Accounts, Child_Account_Id, Account_Id),
		trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day,
		  Child_Account_Id, From_Day, To_Day, Child_Sheet_Entry)),
		Child_Sheet_Entries),
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, From_Day, To_Day, Net_Activity),
	Trial_Balance_Entry = entry(Account_Id, Net_Activity, Child_Sheet_Entries).

trial_balance_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, Trial_Balance) :-
  account_ids(Accounts, Assets_AID, Equity_AID, Liabilities_AID, Earnings_AID, Retained_Earnings_AID, _, Revenue_AID, Expenses_AID),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Assets_AID, To_Day, Asset_Section),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Equity_AID, To_Day, Equity_Section),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Liabilities_AID, To_Day, Liability_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Revenue_AID, From_Day, To_Day, Revenue_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Expenses_AID, From_Day, To_Day, Expense_Section),
	balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Earnings_AID, From_Day, Retained_Earnings),
	Trial_Balance = [Asset_Section, Liability_Section, entry(Retained_Earnings_AID, Retained_Earnings, []),
		Equity_Section, Revenue_Section, Expense_Section].

% Now for movement predicates.

movement_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, Movement) :-
  account_ids(Accounts, Assets_AID, Equity_AID, Liabilities_AID, _, _, _, Revenue_AID, Expenses_AID),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Assets_AID, From_Day, To_Day, Asset_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Equity_AID, From_Day, To_Day, Equity_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Liabilities_AID, From_Day, To_Day, Liability_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Revenue_AID, From_Day, To_Day, Revenue_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Expenses_AID, From_Day, To_Day, Expense_Section),
	Movement = [Asset_Section, Liability_Section, Equity_Section, Revenue_Section, Expense_Section].


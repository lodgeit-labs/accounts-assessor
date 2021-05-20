
% -------------------------------------------------------------------
% The purpose of the following program is to derive the summary information of a ledger.
% That is, with the knowledge of all the transactions in a ledger, the following program
% will derive the balance sheets at given points in time, and the trial balance and
% movements over given periods of time.

% This program is part of a larger system for validating and correcting balance sheets.
% Hence the information derived by this program will ultimately be compared to values
% calculated by other means.

/*
data types we use here:

Exchange_Rates: list of exchange_rate terms

Accounts: list of account terms

Transactions: list of transaction terms, output of preprocess_s_transactions

Report_Currency: This is a list such as ['AUD']. When no report currency is specified, this list is empty. A report can only be requested for one currency, so multiple items are not possible. A report request without a currency means no conversions will take place, which is useful for debugging.

Exchange_Date: the day for which to find exchange_rate's to use. Always report end date?

Account_Id: the id/name of the account that the balance is computed for. Sub-accounts are found by lookup into Accounts.

Balance: a list of coord's
*/

% Relates Date to the balance at that time of the given account.
%:- table balance_until_day/9.
% leave these in place until we've got everything updated w/ balance/5
balance_until_day(Exchange_Rates, Transactions_By_Account, Report_Currency, Exchange_Date, Account_Id, Date, Balance_Transformed, Transactions_Count) :-
	assertion(account_name(Account_Id, _)),
	transactions_before_day_on_account_and_subaccounts(Transactions_By_Account, Account_Id, Date, Filtered_Transactions),
	length(Filtered_Transactions, Transactions_Count),
	transaction_vectors_total(Filtered_Transactions, Balance),
	vec_change_bases(Exchange_Rates, Exchange_Date, Report_Currency, Balance, Balance_Transformed).

/* balance on account up to and including Date*/
balance_by_account(Exchange_Rates, Transactions_By_Account, Report_Currency, Exchange_Date, Account_Id, Date, Balance_Transformed, Transactions_Count) :-
	add_days(Date, 1, Date2),
	balance_until_day(Exchange_Rates, Transactions_By_Account, Report_Currency, Exchange_Date, Account_Id, Date2, Balance_Transformed, Transactions_Count).


account_own_transactions_sum(Exchange_Rates, Exchange_Date, Report_Currency, Account, Date, Transactions_By_Account, Sum, Transactions_Count) :-
	add_days(Date,1,Date2),
	transactions_by_account(Transactions_By_Account, Account, Account_Transactions),
	findall(
		Transaction,
		(
			member(Transaction, Account_Transactions),
			transaction_before(Transaction, Date2)
		),
		Filtered_Transactions
	),
	length(Filtered_Transactions, Transactions_Count),
	transaction_vectors_total(Filtered_Transactions, Totals),
	vec_change_bases(Exchange_Rates, Exchange_Date, Report_Currency, Totals, Sum)
	%,format(user_error, 'account_own_transactions_sum: ~q :~n~q ~n ~q ~n', [Account, Sum, Filtered_Transactions])
	.

 transactions_before(Account_Transactions,Date2,Filtered_Transactions) :-
	findall(
		Transaction,
		(
			member(Transaction, Account_Transactions),
			transaction_before(Transaction, Date2)
		),
		Filtered_Transactions
	).


 child_account_balances(Static_Data, Account_Id, Date, Child_Balances) :-
	findall(
		Child_Balance,
		(
			account_parent(Child_Account, Account_Id),
			balance(Static_Data, Child_Account, Date, Child_Balance, _)
		),
		Child_Balances
	).



:- table balance/5.
/*
balance(
	Static_Data,			% Static Data
	Account_Id,				% atom:Account ID
	Date,					% date(Year, Month, Day)
	Balance,				% List record:coord
	Transactions_Count		% Nat
).
*/
% TODO: do "Transactions_Count" elsewhere
% TODO: get rid of the add_days(...) and use generic period selector(s)

/*fixme/finishme: uses exchange_date from static_data!*/
balance(Static_Data, Account_Id, Date, Balance, Transactions_Count) :-
	dict_vars(Static_Data,
		[Exchange_Date, Exchange_Rates, Transactions_By_Account, Report_Currency]
	),
	assertion(account_name(Account_Id,_)),
	add_days(Date,1,Date2),

	/* TODO use transactions_in_account_set here */

	/* compute own balance */
	transactions_by_account(Transactions_By_Account, Account_Id, Account_Transactions),
	%format('~w transactions ~p~n:',[Account_Id, Account_Transactions]),
	transactions_before(Account_Transactions,Date2,Filtered_Transactions),
	/* TODO should take total count including sub-accounts, probably */
	length(Filtered_Transactions, Transactions_Count),
	transaction_vectors_total(Filtered_Transactions, Totals),
	/* recursively compute balance for subaccounts and add them to this total */
	child_account_balances(Static_Data, Account_Id, Date, Child_Balances),
	append([Totals], Child_Balances, Balance_Components),
	vec_sum(Balance_Components, Totals2),
	vec_change_bases(Exchange_Rates, Exchange_Date, Report_Currency, Totals2, Balance).


transactions_in_period( Transactions_In_Account_Set, Start_Date, End_Date,Transactions_A) :-
	findall(
		Transaction,
		(
			member(Transaction, Transactions_In_Account_Set),
			transaction_in_period(Transaction, Start_Date, End_Date)
		),
		Transactions_A
	).


% Relates the period from Start_Date to End_Date to the net activity during that period of the given account.
 net_activity_by_account(Static_Data, Account_Id, Net_Activity_Transformed, Transactions_Count) :-
	Static_Data.start_date = Start_Date,
	Static_Data.end_date = End_Date,
	Static_Data.exchange_date = Exchange_Date,
	Static_Data.exchange_rates = Exchange_Rates,
	Static_Data.transactions_by_account = Transactions_By_Account,
	Static_Data.report_currency = Report_Currency,

	transactions_in_account_set(Transactions_By_Account, Account_Id, Transactions_In_Account_Set),
	transactions_in_period( Transactions_In_Account_Set, Start_Date, End_Date,Transactions_A),
	length(Transactions_A, Transactions_Count),
	transaction_vectors_total(Transactions_A, Net_Activity),
	vec_change_bases(Exchange_Rates, Exchange_Date, Report_Currency, Net_Activity, Net_Activity_Transformed).



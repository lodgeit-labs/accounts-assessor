
%:- record entry(account_id, balance, child_sheet_entries, transactions_count, misc).

 make_report_entry(Name, Children, Uri) :-
	doc_new_uri(report_entry, Uri),
	doc_add(Uri, rdf:type, l:report_entry),
	doc_add(Uri, report_entries:name, Name),
	doc_add(Uri, report_entries:children, Children).

set_report_entry_total_vec(Uri, Balance) :-
	!doc_add(Uri, report_entries:total_vec, Balance).

set_report_entry_transaction_count(Uri, Transaction_Count) :-
	!doc_add(Uri, report_entries:transaction_count, Transaction_Count).

set_report_entry_normal_side(Uri, X) :-
	!doc_add(Uri, report_entries:normal_side, X).

set_report_entry_gl_account(Uri, X) :-
	!doc_add(Uri, report_entries:gl_account, X).

add_report_entry_misc(Entry, Column, Desc, Type) :-
	doc_new_uri(report_entry_misc_data, D1),
	doc_add(Entry, report_entries:misc, D1),
	doc_add(D1, report_entries:column, Column),
	doc_add(D1, report_entries:value, Desc),
	doc_add(D1, report_entries:misc_type, $>rdf_global_id(report_entries:Type)).

report_entry_gl_account(Uri, X) :-
	doc(Uri, report_entries:gl_account, X).

report_entry_name(Entry, Name) :-
	doc(Entry, report_entries:name, Name).

report_entry_total_vec(Entry, X) :-
	doc(Entry, report_entries:total_vec, X).

report_entry_children(Entry, X) :-
	doc(Entry, report_entries:children, X).

report_entry_normal_side(Entry, X) :-
	(	doc(Entry, report_entries:normal_side, X)
	->	true
	;	X = kb:debit).

report_entry_transaction_count(Entry, X) :-
	doc(Entry, report_entries:transaction_count, X).

report_entry_vec_by_role(Bs, Role, Vec) :-
	!abrlt(Role, Account),
	!accounts_report_entry_by_account_id(Bs, Account, Entry),
	!report_entry_total_vec(Entry, Vec).




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
	assertion(account_name(Account_Id, _)),
	add_days(Date, 1, Date2),
	balance_until_day(Exchange_Rates, Transactions_By_Account, Report_Currency, Exchange_Date, Account_Id, Date2, Balance_Transformed, Transactions_Count).


account_own_transactions_sum(Exchange_Rates, Exchange_Date, Report_Currency, Account, Date, Transactions_By_Account, Sum, Transactions_Count) :-
	add_days(Date,1,Date2),
	(
		Account_Transactions = Transactions_By_Account.get(Account)
	->
		true
	;
		Account_Transactions = []
	),
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
	
	/* TODO use transactions_in_account_set here */
	
	assertion(account_name(Account_Id,_)),
	add_days(Date,1,Date2),
	(
		Account_Transactions = Transactions_By_Account.get(Account_Id)
	->
		true
	;
		Account_Transactions = []
	),
	%format('~w transactions ~p~n:',[Account_Id, Account_Transactions]),

	findall(
		Transaction,
		(
			member(Transaction, Account_Transactions),
			transaction_before(Transaction, Date2)
		),
		Filtered_Transactions
	),
	
	/* TODO should take total including sub-accounts, probably */
	length(Filtered_Transactions, Transactions_Count),
	transaction_vectors_total(Filtered_Transactions, Totals),
	/*
	recursively compute balance for subaccounts and add them to this total
	*/
	findall(
		Child_Balance,
		(
			account_parent(Child_Account, Account_Id),
			balance(Static_Data, Child_Account, Date, Child_Balance, _)
		),
		Child_Balances
	),
	append([Totals], Child_Balances, Balance_Components),
	vec_sum(Balance_Components, Totals2),	
	vec_change_bases(Exchange_Rates, Exchange_Date, Report_Currency, Totals2, Balance).

% Relates the period from Start_Date to End_Date to the net activity during that period of
% the given account.
net_activity_by_account(Static_Data, Account_Id, Net_Activity_Transformed, Transactions_Count) :-
	Static_Data.start_date = Start_Date,
	Static_Data.end_date = End_Date,
	Static_Data.exchange_date = Exchange_Date,
	Static_Data.exchange_rates = Exchange_Rates,
	Static_Data.transactions_by_account = Transactions_By_Account,
	Static_Data.report_currency = Report_Currency,

	transactions_in_account_set(Transactions_By_Account, Account_Id, Transactions_In_Account_Set),
	
	findall(
		Transaction,
		(	
			member(Transaction, Transactions_In_Account_Set),
			transaction_in_period(Transaction, Start_Date, End_Date)
		), 
		Transactions_A
	),

	length(Transactions_A, Transactions_Count),
	transaction_vectors_total(Transactions_A, Net_Activity),
	vec_change_bases(Exchange_Rates, Exchange_Date, Report_Currency, Net_Activity, Net_Activity_Transformed).

% Now for balance sheet predicates. These build up a tree structure that corresponds to the account hierarchy, with balances for each account.



balance_sheet_entry(Static_Data, Account_Id, Entry) :-
	
	/*this doesnt seem to help with tabling performance at all*/
	dict_vars(Static_Data, [End_Date, Exchange_Date, Exchange_Rates, Transactions_By_Account, Report_Currency]),
	dict_from_vars(Static_Data_Simplified, [End_Date, Exchange_Date, Exchange_Rates, Transactions_By_Account, Report_Currency]),
	
	balance_sheet_entry2(Static_Data_Simplified, Account_Id, Entry).

%:- table balance_sheet_entry2/3.

balance_sheet_entry2(Static_Data, Account_Id, Entry) :-
	% find all direct children sheet entries
	% fixme:  If Key is unbound, all associations in Dict are returned on backtracking. The order in which the associations are returned is undefined. (in doc.pl). This leads to random order of entries in the report.
	account_direct_children(Account_Id, Child_Accounts),
	%(account_name(Account_Id, 'Members') -> gtrace ; true),
	maplist(!balance_sheet_entry2(Static_Data), Child_Accounts, Child_Entries),
	% find child balances
	maplist(!report_entry_total_vec,Child_Entries,Child_Balances),
	maplist(!report_entry_transaction_count,Child_Entries,Child_Counts),
	% balance for this account including subaccounts (sum all transactions from beginning of time)

	account_own_transactions_sum(Static_Data.exchange_rates, Static_Data.exchange_date, Static_Data.report_currency, Account_Id, Static_Data.end_date, Static_Data.transactions_by_account, Own_Sum, Own_Transactions_Count),
	
	vec_sum([Own_Sum | Child_Balances], Balance),
	%format(user_error, 'balance_sheet_entry2: ~q :~n~q~n', [Account_Id, Balance]),
	sum_list(Child_Counts, Children_Transaction_Count),
	Transactions_Count is Children_Transaction_Count + Own_Transactions_Count,

	!account_name(Account_Id, Account_Name),
	!account_normal_side(Account_Id, Normal_side),
	make_report_entry(Account_Name, Child_Entries, Entry),
	set_report_entry_total_vec(Entry, Balance),
	set_report_entry_normal_side(Entry, Normal_side),
	set_report_entry_transaction_count(Entry, Transactions_Count),
	set_report_entry_gl_account(Entry, Account_Id).


/*accounts_report(Static_Data, Accounts_Report) :-
	balance_sheet_entry(Static_Data, $>account_by_role_throw(rl('Accounts')), Entry),
	Entry = entry(_,_,Accounts_Report,_,[]).*/

balance_sheet_at(Static_Data, [Net_Assets_Entry, Equity_Entry]) :-
	balance_sheet_entry(Static_Data, $>abrlt('NetAssets'), Net_Assets_Entry),
	balance_sheet_entry(Static_Data, $>abrlt('Equity'), Equity_Entry).

balance_sheet_delta(Static_Data, [Net_Assets_Entry, Equity_Entry]) :-
	!activity_entry(Static_Data, $>abrlt('NetAssets'), Net_Assets_Entry),
	!activity_entry(Static_Data, $>abrlt('Equity'), Equity_Entry).

trial_balance_between(Exchange_Rates, Transactions_By_Account, Report_Currency, Exchange_Date, _Start_Date, End_Date, [Trial_Balance_Section]) :-
	balance_by_account(Exchange_Rates, Transactions_By_Account, Report_Currency, Exchange_Date, $>abrlt('NetAssets'), End_Date, Net_Assets_Balance, Net_Assets_Count),
	balance_by_account(Exchange_Rates, Transactions_By_Account, Report_Currency, Exchange_Date, $>abrlt('Equity'), End_Date, Equity_Balance, Equity_Count),

	vec_sum([Net_Assets_Balance, Equity_Balance], Trial_Balance),
	Transactions_Count is Net_Assets_Count + Equity_Count,

	% too bad there isnt a trial balance concept in the taxonomy yet, but not a problem
	make_report_entry('Trial_Balance', [], Trial_Balance_Section),
	set_report_entry_total_vec(Trial_Balance_Section, Trial_Balance),
	set_report_entry_transaction_count(Trial_Balance_Section, Transactions_Count).


profitandloss_between(Static_Data, [ProftAndLoss]) :-
	!activity_entry(Static_Data, $>abrlt('ComprehensiveIncome'), ProftAndLoss).

activity_entry(Static_Data, Account_Id, Entry) :-
	account_direct_children(Account_Id, Child_accounts),
	maplist(!activity_entry(Static_Data), Child_accounts,Child_Sheet_Entries),
	net_activity_by_account(Static_Data, Account_Id, Net_Activity, Transactions_Count),
	account_name(Account_Id, Account_Name),
	account_normal_side(Account_Id, Normal_side),
	make_report_entry(Account_Name, Child_Sheet_Entries, Entry),
	set_report_entry_total_vec(Entry, Net_Activity),
	set_report_entry_normal_side(Entry, Normal_side),
	set_report_entry_transaction_count(Entry, Transactions_Count),
	set_report_entry_gl_account(Entry, Account_Id).


balance_until_day2(Sd, Report_Currency, Date, Account, balance(Balance, Tx_Count)) :-
	!balance_until_day(Sd.exchange_rates, Sd.transactions_by_account, Report_Currency, Date, Account, Date, Balance, Tx_Count).

balance_by_account2(Sd, Report_Currency, Date, Account, balance(Balance, Tx_Count)) :-
	!balance_by_account(Sd.exchange_rates, Sd.transactions_by_account, Report_Currency, Date, Account, Date, Balance, Tx_Count).

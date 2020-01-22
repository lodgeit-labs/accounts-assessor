
:- record entry(account_id, balance, child_sheet_entries, transactions_count).

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
balance_until_day(Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency, Exchange_Date, Account_Id, Date, Balance_Transformed, Transactions_Count) :-
	assertion(account_exists(Accounts, Account_Id)),
	transactions_before_day_on_account_and_subaccounts(Accounts, Transactions_By_Account, Account_Id, Date, Filtered_Transactions),
	length(Filtered_Transactions, Transactions_Count),
	transaction_vectors_total(Filtered_Transactions, Balance),
	vec_change_bases(Exchange_Rates, Exchange_Date, Report_Currency, Balance, Balance_Transformed).

/* balance on account up to and including Date*/
balance_by_account(Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency, Exchange_Date, Account_Id, Date, Balance_Transformed, Transactions_Count) :-
	assertion(account_exists(Accounts, Account_Id)),
	add_days(Date, 1, Date2),
	balance_until_day(Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency, Exchange_Date, Account_Id, Date2, Balance_Transformed, Transactions_Count).


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
% TODO: do "Transactions_Count" elsewhere
% TODO: get rid of the add_days(...) and use generic period selector(s)
balance(Static_Data, Account_Id, Date, Balance, Transactions_Count) :-
	dict_vars(Static_Data, 
		[Exchange_Date, Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency]
	),
	
	/* TODO use transactions_in_account_set here */
	
	nonvar(Accounts),
	assertion(account_exists(Accounts, Account_Id)),
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
			account_child_parent(Static_Data.accounts, Child_Account, Account_Id),
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
	Static_Data.accounts = Accounts,
	Static_Data.transactions_by_account = Transactions_By_Account,
	Static_Data.report_currency = Report_Currency,

	transactions_in_account_set(Accounts, Transactions_By_Account, Account_Id, Transactions_In_Account_Set),
	
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
	dict_vars(Static_Data, [End_Date, Exchange_Date, Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency]),
	dict_from_vars(Static_Data_Simplified, [End_Date, Exchange_Date, Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency]),
	
	balance_sheet_entry2(Static_Data_Simplified, Account_Id, Entry).

:- table balance_sheet_entry2/3.

balance_sheet_entry2(Static_Data, Account_Id, Entry) :-
	% find all direct children sheet entries
	findall(
		Child_Sheet_Entry, 
		(
			account_child_parent(Static_Data.accounts, Child_Account, Account_Id),
			balance_sheet_entry2(Static_Data, Child_Account, Child_Sheet_Entry)
		),
		Child_Sheet_Entries
	),
	% find balance for this account including subaccounts (sum all transactions from beginning of time)
	findall(
		Child_Balance,
		member(entry(_,Child_Balance,_,_),Child_Sheet_Entries),
		Child_Balances
	),
	findall(
		Child_Count,
		member(entry(_,_,_,Child_Count),Child_Sheet_Entries),
		Child_Counts
	       ),
	account_own_transactions_sum(Static_Data.exchange_rates, Static_Data.exchange_date, Static_Data.report_currency, Account_Id, Static_Data.end_date, Static_Data.transactions_by_account, Own_Sum, Own_Transactions_Count),
	
	vec_sum([Own_Sum | Child_Balances], Balance),
	%format(user_error, 'balance_sheet_entry2: ~q :~n~q~n', [Account_Id, Balance]),
	sum_list(Child_Counts, Children_Transaction_Count),
	Transactions_Count is Children_Transaction_Count + Own_Transactions_Count,
	Entry = entry(Account_Id, Balance, Child_Sheet_Entries, Transactions_Count).

accounts_report(Static_Data, Accounts_Report) :-
	balance_sheet_entry(Static_Data, 'Accounts', Entry),
	Entry = entry(_,_,Accounts_Report,_).

balance_sheet_at(Static_Data, [Net_Assets_Entry, Equity_Entry]) :-
	balance_sheet_entry(Static_Data, 'NetAssets', Net_Assets_Entry),
	balance_sheet_entry(Static_Data, 'Equity', Equity_Entry).

trial_balance_between(Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency, Exchange_Date, _Start_Date, End_Date, [Trial_Balance_Section]) :-
	balance_by_account(Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency, Exchange_Date, 'NetAssets', End_Date, Net_Assets_Balance, Net_Assets_Count),
	balance_by_account(Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency, Exchange_Date, 'Equity', End_Date, Equity_Balance, Equity_Count),

	vec_sum([Net_Assets_Balance, Equity_Balance], Trial_Balance),
	Transactions_Count is Net_Assets_Count + Equity_Count,

	% too bad there isnt a trial balance concept in the taxonomy yet, but not a problem
	Trial_Balance_Section = entry('Trial_Balance', Trial_Balance, [], Transactions_Count).

profitandloss_between(Static_Data, [ProftAndLoss]) :-
	activity_entry(Static_Data, 'NetIncomeLoss', ProftAndLoss).

% Now for trial balance predicates.

activity_entry(Static_Data, Account_Id, Entry) :-
	/*fixme, use maplist, or https://github.com/rla/rdet/ ? */
	findall(
		Child_Sheet_Entry, 
		(
			account_child_parent(Static_Data.accounts, Child_Account_Id, Account_Id),
			activity_entry(Static_Data, Child_Account_Id, Child_Sheet_Entry)
		),
		Child_Sheet_Entries
	),
	net_activity_by_account(Static_Data, Account_Id, Net_Activity, Transactions_Count),
	Entry = entry(Account_Id, Net_Activity, Child_Sheet_Entries, Transactions_Count).


/* balance sheet and profit&loss entries*//*
bs_and_pl_entries(Accounts, Report_Currency, Context, Balance_Sheet_Entries, ProftAndLoss_Entries, [Lines2, Lines3]) :-
	format_report_entries(xbrl, 0, Accounts, 0, Report_Currency, Context, Balance_Sheet_Entries, Lines3),
	format_report_entries(xbrl, 0, Accounts, 0, Report_Currency, Context, ProftAndLoss_Entries, Lines2).
*/




/*
	vec_add(Historical_Earnings, Current_Earnings, Retained_Earnings),
	Retained_Earnings_Section = entry('RetainedEarnings', Retained_Earnings,
		[
			entry('HistoricalEarnings', Historical_Earnings, []), 
			entry('CurrentEarnings', Current_Earnings, [])
		]
	),*/

	
	
	
	
	
/*we'll throw this thing away
%balance_sheet_at(Static_Data, Balance_Sheet) :-
	%Static_Data.start_date = Start_Date,
	%Static_Data.end_date = End_Date,
	%Static_Data.exchange_date = Exchange_Date,
	%Static_Data.exchange_rates = Exchange_Rates,
	%Static_Data.accounts = Accounts,
	%Static_Data.transactions = Transactions,
	%Static_Data.report_currency = Report_Currency,

	%assertion(ground(Accounts)),
	%assertion(ground(Transactions)),
	%assertion(ground(Exchange_Rates)),
	%assertion(ground(Report_Currency)),
	%assertion(ground(Exchange_Date)),
	%assertion(ground(Start_Date)),
	%assertion(ground(End_Date)),
	
	%account_by_role(Accounts, ('Accounts'/'Assets'), Assets_AID),
	%account_by_role(Accounts, ('Accounts'/'Equity'), Equity_AID),
	%account_by_role(Accounts, ('Accounts'/'Liabilities'), Liabilities_AID),
	%account_by_role(Accounts, ('Accounts'/'Earnings'), Earnings_AID),
	%account_by_role(Accounts, ('Accounts'/'Assets'), Assets_AID),
	%account_by_role(Accounts, ('Accounts'/'Equity'), Equity_AID),
	%account_by_role(Accounts, ('Accounts'/'Assets'), Assets_AID),
	%account_by_role(Accounts, ('Accounts'/'Equity'), Equity_AID),

	%writeln("<!-- Balance sheet entries -->"),
	%balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Assets_AID, End_Date, Asset_Section),
	%balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Liabilities_AID, End_Date, Liability_Section),
	%balance_by_account(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, 'NetAssets', End_Date, Net_Assets, Transactions_Count),
	%Net_Assets_Section = entry('NetAssets', Net_Assets, [], Transactions_Count),

	%% then account_value can just be a simple total and can be directly equated with account_balance

	%% get earnings before the report period
	%balance_until_day(Exchange_Rates, Accounts, Transactions, Report_Currency, 
	%/*exchange day = */Start_Date, 
	%Earnings_AID, 
	%/*until day = */ Start_Date, 
	%Historical_Earnings, _),
	
	%% get earnings change over the period
	%writeln("<!-- Net activity by account -->"),
	%net_activity_by_account(Static_Data, Earnings_AID, Current_Earnings, _),
		
	%writeln("<!-- Get transactions with retained earnings -->"),
	%/* build a fake transaction that sets the balance of historical and current earnings.
	%there is no need to make up transactions here, but it makes things more uniform */

	%make_transaction(Start_Date, '', 'HistoricalEarnings', Historical_Earnings, Historical_Earnings_Transaction),
	%make_transaction(Start_Date, '', 'CurrentEarnings', Current_Earnings, Current_Earnings_Transaction),

	%Retained_Earnings_Transactions = [Current_Earnings_Transaction, Historical_Earnings_Transaction],
	%append(Transactions, Retained_Earnings_Transactions, Transactions_With_Retained_Earnings),
	
	%balance_sheet_entry(Exchange_Rates, Accounts, Transactions_With_Retained_Earnings, Report_Currency, Exchange_Date, 'Equity', End_Date, Equity_Section),
	%Balance_Sheet = [Asset_Section, Liability_Section, Equity_Section, Net_Assets_Section],
	%writeln("<!-- balance_sheet_at: done. -->").
*/

	%format('balance_sheet_entry; done: ~p~n',[Entry]).


% account_value becomes equivalent to account_balance when we regard Historical and Current Earnings as just
% containing the transactions of the Historical vs. Current periods, respectively
/*
account_value(Static_Data, Account_Id, Date, Value) :-
	% this one because we're either adding the empty lists just once in transactions.pl or we're adding them every
	% time we use the transactions dict
	Account_Transactions = Static_Data.transactions.get(Account_Id),

	% vectors_total(some_vector_list)
	transaction_vectors_total(Account_Transactions,Value).
*/



/*
+accounts_report2(Static_Data, Account, Entry) :-
+       dict_vars(Static_Data, [Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, End_Date]),
+       Entry = entry(Account, Balance, Child_Sheet_Entries, Transactions_Count),
+       (
+               account_role(Account, ('Accounts'/'NetIncomeLoss'))
+       ->
+               accounts_report2_income(Static_Data, Account, Entry)
+       ;
+               accounts_report2_balance(Static_Data, Account, Entry)
+       ).





*/





/*
TODO: could/should the concept of what a balance of some account is be specified declaratively somewhere so that we could
abstract out of simply assoticating the specific earnings logic to the NetIncomeLoss role?
yes
*/
/*
do balance by account on the whole tree,
except handle the NetIncomeLoss role'd account specially, like we do below, 
that is, take balance until start date, take net activity between start and end date, 
stick the results into historical and current earnings, report only the current period
	* let's put that behavior in the balance calculation, not the reporting

TODO: should probably take an argument which gives a list of accounts to include and it
includes just those accounts and their ancestors

how does the concept of "accounts_report" differ from the concept of "balance_sheet" ?

*/
/*
trial_balance_between(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Start_Date, End_Date, Trial_Balance) :-
	account_ids(Accounts, Assets_AID, Equity_AID, Liabilities_AID, Earnings_AID, _Earnings_AID, _, Revenue_AID, Expenses_AID),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Assets_AID, End_Date, Asset_Section),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Equity_AID, End_Date, Equity_Section),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Liabilities_AID, End_Date, Liability_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Revenue_AID, Start_Date, End_Date, Revenue_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Expenses_AID, Start_Date, End_Date, Expense_Section),
	balance_by_account(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Earnings_AID, Start_Date, Earnings),
	% current earnings, not retained?
	Trial_Balance = [Asset_Section, Liability_Section, entry(Earnings_AID, Earnings, []),
		Equity_Section, Revenue_Section, Expense_Section].
*/
% Now for movement predicates.
% - this isn't made available anywhere yet
/*
movement_between(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Start_Date, End_Date, Movement) :-
  account_ids(Accounts, Assets_AID, Equity_AID, Liabilities_AID, _, _, _, Revenue_AID, Expenses_AID),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Assets_AID, Start_Date, End_Date, Asset_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Equity_AID, Start_Date, End_Date, Equity_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Liabilities_AID, Start_Date, End_Date, Liability_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Revenue_AID, Start_Date, End_Date, Revenue_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Expenses_AID, Start_Date, End_Date, Expense_Section),
	Movement = [Asset_Section, Liability_Section, Equity_Section, Revenue_Section, Expense_Section].

*/
/*
profitandloss_between(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Start_Date, End_Date, ProftAndLoss) :-
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, 'Earnings', Start_Date, End_Date, ProftAndLoss).
*/

/*
profitandloss_between(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Start_Date, End_Date, ProftAndLoss) :-
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, 'Earnings', Start_Date, End_Date, Activity),
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, 'Revenue', Start_Date, End_Date, Revenue),
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, 'Expenses', Start_Date, End_Date, Expenses),
	ProftAndLoss = [entry('ProftAndLoss', Activity, [
		entry('Revenue', Revenue, []),
		entry('Expenses', Expenses, [])
	])].
*/
%trial_balance_between(Static_Data,[Trial_Balance_Section]) :-

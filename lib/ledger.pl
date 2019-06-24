% ===================================================================
% Project:   LodgeiT
% Module:    ledger.pl
% Date:      2019-06-02
% ===================================================================

:- module(ledger, [balance_sheet_at/8, balance_by_account/8, trial_balance_between/8, profitandloss_between/8]).

:- use_module(accounts,     [account_parent_id/3, account_ids/9]).
:- use_module(pacioli,      [vec_add/3, vec_inverse/2, vec_reduce/2, vec_sub/3]).
:- use_module(exchange,     [vec_change_bases/5]).
:- use_module(transactions, [transaction_account_ancestor_id/3,
			     transaction_in_period/3,
		     	     transaction_vectors_total/2,
		  	     transactions_before_day_on_account_and_subaccounts/5
		            ]).

% -------------------------------------------------------------------
% The purpose of the following program is to derive the summary information of a ledger.
% That is, with the knowledge of all the transactions in a ledger, the following program
% will derive the balance sheets at given points in time, and the trial balance and
% movements over given periods of time.

% This program is part of a larger system for validating and correcting balance sheets.
% Hence the information derived by this program will ultimately be compared to values
% calculated by other means.


% Relates Day to the balance at that time of the given account.
% exchanged
balance_until_day(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, Day, Balance_Transformed) :-
	transactions_before_day_on_account_and_subaccounts(Accounts, Transactions, Account_Id, Day, Filtered_Transactions),
	transaction_vectors_total(Filtered_Transactions, Balance),
	vec_change_bases(Exchange_Rates, Exchange_Day, Bases, Balance, Balance_Transformed).

% up to day
balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, Day, Balance_Transformed) :-
	Day_Plus_1 is Day + 1,
	balance_until_day(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, Day_Plus_1, Balance_Transformed).
	
% Relates the period from From_Day to To_Day to the net activity during that period of
% the given account.
net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, From_Day, To_Day, Net_Activity_Transformed) :-
	findall(Transaction,
		(member(Transaction, Transactions),
		transaction_in_period(Transaction, From_Day, To_Day),
		transaction_account_ancestor_id(Accounts, Transaction, Account_Id)), Transactions_A),
	transaction_vectors_total(Transactions_A, Net_Activity),
	vec_change_bases(Exchange_Rates, Exchange_Day, Bases, Net_Activity, Net_Activity_Transformed).

	
	
	

% Now for balance sheet predicates.

balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, To_Day, Sheet_Entry) :-
	% find all direct children sheet entries
	findall(Child_Sheet_Entry, (account_parent_id(Accounts, Child_Account, Account_Id),
		balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Child_Account, To_Day, Child_Sheet_Entry)),
		Child_Sheet_Entries),
	% find balance for this account including subaccounts (sum all transactions from beginning of time)
	balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, To_Day, Balance),
	Sheet_Entry = entry(Account_Id, Balance, Child_Sheet_Entries).


balance_sheet_at(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, Balance_Sheet) :-
	account_ids(Accounts, Assets_AID, _Equity_AID, Liabilities_AID, Earnings_AID, _Retained_Earnings_AID, _Current_Earnings_AID, _, _),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Assets_AID, To_Day, Asset_Section),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Liabilities_AID, To_Day, Liability_Section),
	% get earnings before the report period
	balance_until_day(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Earnings_AID, From_Day, Historical_Earnings),
	% get earnings change over the period
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Earnings_AID, From_Day, To_Day, Current_Earnings),
	% total them
	/*
	vec_add(Historical_Earnings, Current_Earnings, Earnings),
	vec_reduce(Earnings, Earnings_Reduced),
	Retained_Earnings_Section = entry('RetainedEarnings', Earnings_Reduced,
		[
		entry('HistoricalEarnings', Historical_Earnings, []), 
		entry('CurrentEarnings', Current_Earnings, [])
		]),	*/
	get_transactions_with_retained_earnings(Current_Earnings, Historical_Earnings, Transactions, From_Day, To_Day, Transactions_With_Retained_Earnings),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions_With_Retained_Earnings, Bases, Exchange_Day, 'Equity', To_Day, Equity_Section),
	balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 'NetAssets', To_Day, NetAssets),
	NetAssets_Section = entry('NetAssets', NetAssets, []),
	Balance_Sheet = [Asset_Section, Liability_Section, Equity_Section, NetAssets_Section].

get_transactions_with_retained_earnings(Current_Earnings, Historical_Earnings, Transactions, From_Day, To_Day, [Historical_Earnings_Transaction, Current_Earnings_Transaction | Transactions]) :-
	From_Day_Minus_1 is From_Day - 1,
	Historical_Earnings_Transaction = transaction(From_Day_Minus_1,'','HistoricalEarnings',Historical_Earnings),
	Current_Earnings_Transaction = transaction(To_Day,'','CurrentEarnings',Current_Earnings).

trial_balance_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, [Trial_Balance_Section]) :-
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 'Accounts', From_Day, To_Day, Trial_Balance),
	Trial_Balance_Section = entry('Trial_Balance', Trial_Balance, []).
/*
profitandloss_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, ProftAndLoss) :-
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 'Earnings', From_Day, To_Day, ProftAndLoss).
*/

/*
profitandloss_between(Exchange_Rates, Account_Hierarchy, Transactions, Bases, Exchange_Day, Start_Day, End_Day, ProftAndLoss) :-
	net_activity_by_account(Exchange_Rates, Account_Hierarchy, Transactions, Bases, Exchange_Day, 'Earnings', Start_Day, End_Day, Activity),
	net_activity_by_account(Exchange_Rates, Account_Hierarchy, Transactions, Bases, Exchange_Day, 'Revenue', Start_Day, End_Day, Revenue),
	net_activity_by_account(Exchange_Rates, Account_Hierarchy, Transactions, Bases, Exchange_Day, 'Expenses', Start_Day, End_Day, Expenses),
	ProftAndLoss = [entry('ProftAndLoss', Activity, [
		entry('Revenue', Revenue, []),
		entry('Expenses', Expenses, [])
	])].
*/

profitandloss_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, [ProftAndLoss]) :-
	activity_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 'Earnings', From_Day, To_Day, ProftAndLoss).

% Now for trial balance predicates.

activity_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, From_Day, To_Day, Trial_Balance_Entry) :-
	findall(Child_Sheet_Entry, (account_parent_id(Accounts, Child_Account_Id, Account_Id),
		activity_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day,
		  Child_Account_Id, From_Day, To_Day, Child_Sheet_Entry)),
		Child_Sheet_Entries),
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, From_Day, To_Day, Net_Activity),
	Trial_Balance_Entry = entry(Account_Id, Net_Activity, Child_Sheet_Entries).
/*
trial_balance_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, Trial_Balance) :-
	account_ids(Accounts, Assets_AID, Equity_AID, Liabilities_AID, Earnings_AID, _Earnings_AID, _, Revenue_AID, Expenses_AID),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Assets_AID, To_Day, Asset_Section),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Equity_AID, To_Day, Equity_Section),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Liabilities_AID, To_Day, Liability_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Revenue_AID, From_Day, To_Day, Revenue_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Expenses_AID, From_Day, To_Day, Expense_Section),
	balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Earnings_AID, From_Day, Earnings),
	% current earnings, not retained?
	Trial_Balance = [Asset_Section, Liability_Section, entry(Earnings_AID, Earnings, []),
		Equity_Section, Revenue_Section, Expense_Section].
*/
% Now for movement predicates.
% - this isn't made available anywhere yet

movement_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, Movement) :-
  account_ids(Accounts, Assets_AID, Equity_AID, Liabilities_AID, _, _, _, Revenue_AID, Expenses_AID),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Assets_AID, From_Day, To_Day, Asset_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Equity_AID, From_Day, To_Day, Equity_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Liabilities_AID, From_Day, To_Day, Liability_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Revenue_AID, From_Day, To_Day, Revenue_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Expenses_AID, From_Day, To_Day, Expense_Section),
	Movement = [Asset_Section, Liability_Section, Equity_Section, Revenue_Section, Expense_Section].


% The purpose of the following program is to derive the summary information of a ledger.
% That is, with the knowledge of all the transactions in a ledger, the following program
% will derive the balance sheets at given points in time, and the trial balance and
% movements over given periods of time.

% This program is part of a larger system for validating and correcting balance sheets.
% Hence the information derived by this program will ultimately be compared to values
% calculated by other means.

:- ['exchange_rates', 'pacioli', 'exchange', 'accounts', 'transactions'].



% Relates Day to the balance at that time of the given account.
% exchanged
balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, Day, Balance_Transformed) :-
	transactions_up_to_day_on_account_and_subaccounts(Accounts, Transactions, Account_Id, Day, Filtered_Transactions),
	transaction_vectors_total(Filtered_Transactions, Balance),
	vec_change_bases(Exchange_Rates, Exchange_Day, Bases, Balance, Balance_Transformed).

% Relates the period from From_Day to To_Day to the net activity during that period of
% the given account.
% - same as balance_by_account but with a start limit on date
net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, From_Day, To_Day, Net_Activity_Transformed) :-
	findall(Transaction,
		(member(Transaction, Transactions),
		transaction_between(Transaction, From_Day, To_Day),
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

% this is the entry point for the ledger endpoint
balance_sheet_at(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, Balance_Sheet) :-
	account_ids(Accounts, Assets_AID, Equity_AID, Liabilities_AID, Earnings_AID, Retained_Earnings_AID, Current_Earnings_AID, _, _),
	
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Assets_AID, To_Day, Asset_Section),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Liabilities_AID, To_Day, Liability_Section),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Equity_AID, To_Day, Equity_Section),
	
	% earnings up to the beginning of the report period
	balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Earnings_AID, From_Day, Retained_Earnings),
	% earnings in the report period
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Earnings_AID, From_Day, To_Day, Current_Earnings),
	vec_add(Retained_Earnings, Current_Earnings, Earnings),
	vec_reduce(Earnings, Earnings_Reduced),
	
	Earnings_Section = 
		entry(Earnings_AID, Earnings_Reduced,
		[
			entry(Retained_Earnings_AID, Retained_Earnings, []), 
			entry(Current_Earnings_AID, Current_Earnings, [])
		]),
	%gtrace,
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 'Livestock', To_Day, Livestock_Section),
	
	
	Balance_Sheet = [Asset_Section, Liability_Section, Earnings_Section, Equity_Section, Livestock_Section].

		
		

% Now for trial balance predicates.
% - this isn't made available anywhere yet

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
% - this isn't made available anywhere yet

movement_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, Movement) :-
  account_ids(Accounts, Assets_AID, Equity_AID, Liabilities_AID, _, _, _, Revenue_AID, Expenses_AID),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Assets_AID, From_Day, To_Day, Asset_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Equity_AID, From_Day, To_Day, Equity_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Liabilities_AID, From_Day, To_Day, Liability_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Revenue_AID, From_Day, To_Day, Revenue_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Expenses_AID, From_Day, To_Day, Expense_Section),
	Movement = [Asset_Section, Liability_Section, Equity_Section, Revenue_Section, Expense_Section].


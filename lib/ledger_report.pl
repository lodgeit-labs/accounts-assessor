% ===================================================================
% Project:   LodgeiT
% Module:    ledger.pl
% Date:      2019-06-02
% ===================================================================

:- module(ledger_report, [
		balance_sheet_at/8, 
		balance_by_account/9, 
		trial_balance_between/8, 
		profitandloss_between/8, 
		format_report_entries/9, 
		bs_and_pl_entries/8,
		format_balances/10]).

:- use_module('accounts', [
		account_child_parent/3,
		account_in_set/3,
		account_by_role/3,
		account_role_by_id/3,
		account_exists/2,
		account_normal_side/3]).
:- use_module('pacioli', [
		vec_add/3, 
		vec_inverse/2, 
		vec_reduce/2, 
		vec_sub/3]).
:- use_module('exchange', [
		vec_change_bases/5]).
:- use_module('transactions', [
		transaction_account_in_set/3,
		transaction_in_period/3,
		transaction_vectors_total/2,
		transactions_before_day_on_account_and_subaccounts/5]).
:- use_module('days', [
		add_days/3]).
:- use_module('utils', [
		get_indentation/2,
		pretty_term_string/2]).

% -------------------------------------------------------------------
% The purpose of the following program is to derive the summary information of a ledger.
% That is, with the knowledge of all the transactions in a ledger, the following program
% will derive the balance sheets at given points in time, and the trial balance and
% movements over given periods of time.

% This program is part of a larger system for validating and correcting balance sheets.
% Hence the information derived by this program will ultimately be compared to values
% calculated by other means.


% Relates Day to the balance at that time of the given account. 
balance_until_day(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, Day, Balance_Transformed, Transactions_Count) :-
	transactions_before_day_on_account_and_subaccounts(Accounts, Transactions, Account_Id, Day, Filtered_Transactions),
	length(Filtered_Transactions, Transactions_Count),
	transaction_vectors_total(Filtered_Transactions, Balance),
	vec_change_bases(Exchange_Rates, Exchange_Day, Bases, Balance, Balance_Transformed).

/* balance on account up to and including Date*/
balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, Date, Balance_Transformed, Transactions_Count) :-
	assertion(account_exists(Accounts, Account_Id)),
	add_days(Date, 1, Date2),
	balance_until_day(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, Date2, Balance_Transformed, Transactions_Count).
	
% Relates the period from From_Day to To_Day to the net activity during that period of
% the given account.
net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, From_Day, To_Day, Net_Activity_Transformed, Transactions_Count) :-
	findall(Transaction,
		(member(Transaction, Transactions),
		transaction_in_period(Transaction, From_Day, To_Day),
		transaction_account_in_set(Accounts, Transaction, Account_Id)), Transactions_A),
	length(Transactions_A, Transactions_Count),
	transaction_vectors_total(Transactions_A, Net_Activity),
	vec_change_bases(Exchange_Rates, Exchange_Day, Bases, Net_Activity, Net_Activity_Transformed).

	

% Now for balance sheet predicates. These build up a tree structure that corresponds to the account hierarchy, with balances for each account.

balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, To_Day, Sheet_Entry) :-
	% find all direct children sheet entries
	findall(Child_Sheet_Entry, (account_child_parent(Accounts, Child_Account, Account_Id),
		balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Child_Account, To_Day, Child_Sheet_Entry)),
		Child_Sheet_Entries),
	% find balance for this account including subaccounts (sum all transactions from beginning of time)
	balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, To_Day, Balance, Transactions_Count),
	Sheet_Entry = entry(Account_Id, Balance, Child_Sheet_Entries, Transactions_Count).


balance_sheet_at(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, Balance_Sheet) :-
	account_by_role(Accounts, ('Accounts'/'Assets'), Assets_AID),
	account_by_role(Accounts, ('Accounts'/'Equity'), Equity_AID),
	account_by_role(Accounts, ('Accounts'/'Liabilities'), Liabilities_AID),
	account_by_role(Accounts, ('Accounts'/'Earnings'), Earnings_AID),
	account_by_role(Accounts, ('Accounts'/'Assets'), Assets_AID),
	account_by_role(Accounts, ('Accounts'/'Equity'), Equity_AID),
	account_by_role(Accounts, ('Accounts'/'Assets'), Assets_AID),
	account_by_role(Accounts, ('Accounts'/'Equity'), Equity_AID),

	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Assets_AID, To_Day, Asset_Section),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Liabilities_AID, To_Day, Liability_Section),
	% get earnings before the report period
	add_days(From_Day, -1, From_Day_Minus_1),
	balance_until_day(Exchange_Rates, Accounts, Transactions, Bases, From_Day_Minus_1, Earnings_AID, From_Day, Historical_Earnings, _),
	% get earnings change over the period
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Earnings_AID, From_Day, To_Day, Current_Earnings, _),
	% total them
	/*
	vec_add(Historical_Earnings, Current_Earnings, Earnings),
	vec_reduce(Earnings, Earnings_Reduced),
	Retained_Earnings_Section = entry('RetainedEarnings', Earnings_Reduced,
		[
		entry('HistoricalEarnings', Historical_Earnings, []), 
		entry('CurrentEarnings', Current_Earnings, [])
		]),	*/
		
	/* there is no need to make up transactions here, but it makes things more uniform */
	get_transactions_with_retained_earnings(Current_Earnings, Historical_Earnings, Transactions, From_Day, To_Day, Transactions_With_Retained_Earnings),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions_With_Retained_Earnings, Bases, Exchange_Day, 'Equity', To_Day, Equity_Section),
	balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 'Net_Assets', To_Day, Net_Assets, Transactions_Count),
	Net_Assets_Section = entry('Net_Assets', Net_Assets, [], Transactions_Count),
	Balance_Sheet = [Asset_Section, Liability_Section, Equity_Section, Net_Assets_Section].

/* build a fake transaction that sets the balance of historical and current earnings */
get_transactions_with_retained_earnings(Current_Earnings, Historical_Earnings, Transactions, From_Day, To_Day, [Historical_Earnings_Transaction, Current_Earnings_Transaction | Transactions]) :-
	add_days(From_Day, -1, From_Day_Minus_1),
	Historical_Earnings_Transaction = transaction(From_Day_Minus_1,'','Historical_Earnings',Historical_Earnings),
	Current_Earnings_Transaction = transaction(To_Day,'','Current_Earnings',Current_Earnings).

trial_balance_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, [Trial_Balance_Section]) :-
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 'Accounts', From_Day, To_Day, Trial_Balance, Transactions_Count),
	Trial_Balance_Section = entry('Trial_Balance', Trial_Balance, [], Transactions_Count).
/*
profitandloss_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, ProftAndLoss) :-
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 'Earnings', From_Day, To_Day, ProftAndLoss).
*/

/*
profitandloss_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Start_Day, End_Day, ProftAndLoss) :-
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 'Earnings', Start_Day, End_Day, Activity),
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 'Revenue', Start_Day, End_Day, Revenue),
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 'Expenses', Start_Day, End_Day, Expenses),
	ProftAndLoss = [entry('ProftAndLoss', Activity, [
		entry('Revenue', Revenue, []),
		entry('Expenses', Expenses, [])
	])].
*/

profitandloss_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, [ProftAndLoss]) :-
	activity_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 'Earnings', From_Day, To_Day, ProftAndLoss).

% Now for trial balance predicates.

activity_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, From_Day, To_Day, Trial_Balance_Entry) :-
	findall(
		Child_Sheet_Entry, 
		(
			account_child_parent(Accounts, Child_Account_Id, Account_Id),
			activity_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 		  Child_Account_Id, From_Day, To_Day, Child_Sheet_Entry)
		),
		Child_Sheet_Entries
	),
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, From_Day, To_Day, Net_Activity, Transactions_Count),
	Trial_Balance_Entry = entry(Account_Id, Net_Activity, Child_Sheet_Entries, Transactions_Count).
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
/*
movement_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, From_Day, To_Day, Movement) :-
  account_ids(Accounts, Assets_AID, Equity_AID, Liabilities_AID, _, _, _, Revenue_AID, Expenses_AID),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Assets_AID, From_Day, To_Day, Asset_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Equity_AID, From_Day, To_Day, Equity_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Liabilities_AID, From_Day, To_Day, Liability_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Revenue_AID, From_Day, To_Day, Revenue_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Expenses_AID, From_Day, To_Day, Expense_Section),
	Movement = [Asset_Section, Liability_Section, Equity_Section, Revenue_Section, Expense_Section].

*/





/* balance sheet and profit&loss entries*/
bs_and_pl_entries(Accounts, Report_Currency, Context, Balance_Sheet_Entries, ProftAndLoss_Entries, Used_Units_Out, Lines2, Lines3) :-
	format_report_entries(Accounts, 0, Report_Currency, Context, Balance_Sheet_Entries, [], Used_Units, [], Lines3),
	format_report_entries(Accounts, 0, Report_Currency, Context, ProftAndLoss_Entries, Used_Units, Used_Units_Out, [], Lines2).

format_report_entries(_, _, _, _, [], Used_Units, Used_Units, Lines, Lines).

format_report_entries(Accounts, Level, Report_Currency, Context, Entries, Used_Units_In, Used_Units_Out, Lines_In, LinesOut) :-
	[entry(Name, Balances, Children, Transactions_Count)|EntriesTail] = Entries,
	account_normal_side(Accounts, Name, Normal_Side),
	(
		(Balances = [],(Transactions_Count \= 0; Level = 0))
	->
		format_balance(Level, Report_Currency, Context, Name, Normal_Side, [],
			Used_Units_In, UsedUnitsIntermediate, Lines_In, LinesIntermediate)
	;
		format_balances(Level, Report_Currency, Context, Name, Normal_Side, Balances, 
			Used_Units_In, UsedUnitsIntermediate, Lines_In, LinesIntermediate)
	),
	Level_New is Level + 1,
	format_report_entries(Accounts, Level_New, Report_Currency, Context, Children, UsedUnitsIntermediate, UsedUnitsIntermediate2, LinesIntermediate, LinesIntermediate2),
	format_report_entries(Accounts, Level, Report_Currency, Context, EntriesTail, UsedUnitsIntermediate2, Used_Units_Out, LinesIntermediate2, LinesOut),
	!.

format_balances(_, _, _, _, _, [], Used_Units, Used_Units, Lines, Lines).

format_balances(Level, Report_Currency, Context, Name, Normal_Side, [Balance|Balances], Used_Units_In, Used_Units_Out, Lines_In, LinesOut) :-
   format_balance(Level, Report_Currency, Context, Name, Normal_Side, [Balance], Used_Units_In, UsedUnitsIntermediate, Lines_In, LinesIntermediate),
   format_balances(Level, Report_Currency, Context, Name, Normal_Side, Balances, UsedUnitsIntermediate, Used_Units_Out, LinesIntermediate, LinesOut).

format_balance(Level, Report_Currency_List, Context, Name, Normal_Side, [], Used_Units_In, Used_Units_Out, Lines_In, Lines_Out) :-
	(
		[Report_Currency] = Report_Currency_List
	->
		true
	;
		Report_Currency = 'AUD' % just for displaying zero balance
	),
	format_balance(Level, _, Context, Name, Normal_Side, [coord(Report_Currency, 0, 0)], Used_Units_In, Used_Units_Out, Lines_In, Lines_Out).
   
format_balance(Level, _, Context, Name, Normal_Side, [coord(Unit, Debit, Credit)], Used_Units_In, Used_Units_Out, Lines_In, LinesOut) :-
	union([Unit], Used_Units_In, Used_Units_Out),
	(
		Normal_Side = credit
	->
		Balance is (Credit - Debit)
	;
		Balance is (Debit - Credit)
	),
	get_indentation(Level, Indentation),
	format(string(BalanceSheetLine), '~w<basic:~w contextRef="~w" unitRef="U-~w" decimals="INF">~2:f</basic:~w>\n', [Indentation, Name, Context, Unit, Balance, Name]),
	append(Lines_In, [BalanceSheetLine], LinesOut).

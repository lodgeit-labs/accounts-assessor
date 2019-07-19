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
		balance_sheet_entries/8,
		investment_report/3]).

:- use_module('accounts', [
		account_child_parent/3,
		account_in_set/3,
		account_by_role/3,
		account_role/2,
		account_role_by_id/3]).
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
:- use_module('system_accounts', [
		trading_account_ids/2]).

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






balance_sheet_entries(Account_Hierarchy, Report_Currency, End_Year, Balance_Sheet_Entries, ProftAndLoss_Entries, Used_Units_Out, Lines2, Lines3) :-
	format_report_entries(Account_Hierarchy, 0, Report_Currency, End_Year, Balance_Sheet_Entries, [], Used_Units, [], Lines3),
	format_report_entries(Account_Hierarchy, 0, Report_Currency, End_Year, ProftAndLoss_Entries, Used_Units, Used_Units_Out, [], Lines2).

format_report_entries(_, _, _, _, [], Used_Units, Used_Units, Lines, Lines).

format_report_entries(Account_Hierarchy, Level, Report_Currency, End_Year, Entries, Used_Units_In, UsedUnitsOut, LinesIn, LinesOut) :-
	[entry(Name, Balances, Children, Transactions_Count)|EntriesTail] = Entries,
	account_normal_side(Account_Hierarchy, Name, Normal_Side),
	(
		(Balances = [],(Transactions_Count \= 0; Level = 0))
	->
		format_balance(Account_Hierarchy, Level, Report_Currency, End_Year, Name, Normal_Side, [],
			Used_Units_In, UsedUnitsIntermediate, LinesIn, LinesIntermediate)
	;
		format_balances(Account_Hierarchy, Level, Report_Currency, End_Year, Name, Normal_Side, Balances, 
			Used_Units_In, UsedUnitsIntermediate, LinesIn, LinesIntermediate)
	),
	Level_New is Level + 1,
	format_report_entries(Account_Hierarchy, Level_New, Report_Currency, End_Year, Children, UsedUnitsIntermediate, UsedUnitsIntermediate2, LinesIntermediate, LinesIntermediate2),
	format_report_entries(Account_Hierarchy, Level, Report_Currency, End_Year, EntriesTail, UsedUnitsIntermediate2, UsedUnitsOut, LinesIntermediate2, LinesOut),
	!.

format_balances(_, _, _, _, _, _, [], Used_Units, Used_Units, Lines, Lines).

format_balances(Account_Hierarchy, Level, Report_Currency, End_Year, Name, Normal_Side, [Balance|Balances], Used_Units_In, UsedUnitsOut, LinesIn, LinesOut) :-
   format_balance(Account_Hierarchy, Level, Report_Currency, End_Year, Name, Normal_Side, [Balance], Used_Units_In, UsedUnitsIntermediate, LinesIn, LinesIntermediate),
   format_balances(Account_Hierarchy, Level, Report_Currency, End_Year, Name, Normal_Side, Balances, UsedUnitsIntermediate, UsedUnitsOut, LinesIntermediate, LinesOut).

format_balance(Account_Hierarchy, Level, Report_Currency_List, End_Year, Name, Normal_Side, [], Used_Units_In, UsedUnitsOut, LinesIn, LinesOut) :-
	(
		[Report_Currency] = Report_Currency_List
	->
		true
	;
		Report_Currency = 'AUD' % just for displaying zero balance
	),
	format_balance(Account_Hierarchy, Level, _, End_Year, Name, Normal_Side, [coord(Report_Currency, 0, 0)], Used_Units_In, UsedUnitsOut, LinesIn, LinesOut).
   
format_balance(_Account_Hierarchy, Level, _, End_Year, Name, Normal_Side, [coord(Unit, Debit, Credit)], Used_Units_In, UsedUnitsOut, LinesIn, LinesOut) :-
	union([Unit], Used_Units_In, UsedUnitsOut),
	(
		Normal_Side = credit
	->
		Balance is (Credit - Debit)
	;
		Balance is (Debit - Credit)
	),
	get_indentation(Level, Indentation),
	format(string(BalanceSheetLine), '~w<basic:~w contextRef="D-~w" unitRef="U-~w" decimals="INF">~2:f</basic:~w>\n', [Indentation, Name, End_Year, Unit, Balance, Name]),
	append(LinesIn, [BalanceSheetLine], LinesOut).


account_normal_side(Account_Hierarchy, Name, credit) :-
	member(Credit_Side_Account_Id, ['Liabilities', 'Equity', 'Expenses', 'Earnings']),
	once(account_in_set(Account_Hierarchy, Name, Credit_Side_Account_Id)),
	!.
account_normal_side(_, _, debit).
	
	
/*
generate realized and unrealized investment report sections for each trading account
*/
investment_report((Exchange_Rates, Accounts, Transactions, Report_Currency, Report_Date), Transaction_Types, Lines) :-
	trading_account_ids(Transaction_Types, Trading_Account_Ids),
	maplist(
		investment_report2((Exchange_Rates, Accounts, Transactions, Report_Currency, Report_Date)),
		Trading_Account_Ids, 
		Lines_Nested),
	flatten(Lines_Nested, Lines).

units_traded_on_trading_account(Accounts, Trading_Account, All_Units_Roles) :-
	findall(
		Unit_Account_Role,
		(
			member(Gains_Role, [realized, unrealized]),
			account_by_role(Accounts, (Trading_Account/Gains_Role), Gains_Account),
			member(Forex_Role, [without_currency_movement, only_currency_movement]),
			account_by_role(Accounts, (Gains_Account/Forex_Role), Forex_Account),
			account_child_parent(Accounts, Unit_Account_Id, Forex_Account),
			account_role_by_id(Accounts, Unit_Account_Id, (_Parent_Id/Unit_Account_Role))
		),
		All_Units_Roles0
	),
	sort(All_Units_Roles0, All_Units_Roles).

/*
generate realized and unrealized investment report sections for one trading account
*/
investment_report2((Exchange_Rates, Accounts, Transactions, Report_Currency, Report_Date), Trading_Account, [Lines, Warnings]) :-
	units_traded_on_trading_account(Accounts, Trading_Account, All_Units_Roles),
	maplist(
		investment_report3(
			(Exchange_Rates, Accounts, Transactions, Report_Currency, Report_Date, Trading_Account)),
		All_Units_Roles,
		Lines,
		Check_Realized_Totals_List,
		Check_Unrealized_Totals_List),
	Static_Data = (Exchange_Rates, Accounts, Transactions, Report_Currency, Report_Date),
	maplist(
		check_totals(Static_Data, Trading_Account),
		[Check_Realized_Totals_List,Check_Unrealized_Totals_List],
		[realized, unrealized],
		Warnings).
	
	
check_totals((Exchange_Rates, Accounts, Transactions, Report_Currency, Report_Date), Trading_Account, Check_Totals_List, Gains_Role, Warning) :- 
	% these totals should be more or less equal to the account balances
	gtrace,
	vec_reduce(Check_Totals_List, Total),
	account_by_role(Accounts, (Trading_Account/Gains_Role), Account),
	balance_by_account(Exchange_Rates, Accounts, Transactions, Report_Currency, Report_Date, Account, Report_Date, Total_Balance, _),
	(
		(
			Total_Balance = Total
		)
	->
			Warning = []
	;
		(
			term_string(Total_Balance, Total_Balance_Str),
			term_string(Total, Total_Str),
			Warning = [
				'\n', Gains_Role, ' total balance check failed: account balance: ',
				Total_Balance_Str, 'investment report total:', Total_Str, '.\n']
		)
	).
	
	
investment_report3(Static_Data, Unit, [Unit, ':', '\n', Lines1, Lines2, '\n'], Realized_Total, Unrealized_Total) :-
	investment_report3_lines(Static_Data, Unit, realized, Lines1, Realized_Total),
	investment_report3_lines(Static_Data, Unit, unrealized, Lines2, Unrealized_Total).
	
investment_report3_lines(Static_Data, Unit, Gains_Role, Lines, Total) :-
	investment_report3_balance(Static_Data, Gains_Role, without_currency_movement, Unit, Gains_Market_Balance, Gains_Market_Lines),
	investment_report3_balance(Static_Data, Gains_Role, only_currency_movement, Unit, Gains_Forex_Balance, Gains_Forex_Lines),
	vec_add(Gains_Market_Balance, Gains_Forex_Balance, Total),
	pretty_term_string(Total, Total_Str),
	Msg = [
		' ', Gains_Role, ' total: ', Total_Str,  '\n',
		'  market gain:\n',
		Gains_Market_Lines,
		'  forex gain:\n',
		Gains_Forex_Lines
	],
	flatten(Msg, Msg2),
	atomic_list_concat(Msg2, Lines).

investment_report3_balance((Exchange_Rates, Accounts, Transactions, Report_Currency, Report_Date, Trading_Account), Gains_Role, Forex_Role, Unit, Balance, Lines) :-
	Report_Date = date(End_Year,_,_),
	account_by_role(Accounts, (Trading_Account/Gains_Role), Gains_Account),
	account_by_role(Accounts, (Gains_Account/Forex_Role), Gains_Forex_Account),
	account_by_role(Accounts, (Gains_Forex_Account/Unit), Unit_Account),
	balance_by_account(Exchange_Rates, Accounts, Transactions, Report_Currency, Report_Date, Unit_Account, Report_Date, Balance, _),
	format_balances(Accounts, 4, Report_Currency, End_Year, Unit, credit, Balance, [], _, [], Lines).

% ===================================================================
% Project:   LodgeiT
% Module:    ledger.pl
% Date:      2019-06-02
% ===================================================================

:- module(ledger_report, [
		balance_sheet_at/8, 
		balance_by_account/9, 
		balance_until_day/9,
		trial_balance_between/8, 
		profitandloss_between/8, 
		format_report_entries/11, 
		format_report_entries/10, 
		bs_and_pl_entries/8,
		format_balances/11,
		net_activity_by_account/10,
		pesseract_style_table_rows/4]).

:- use_module('accounts', [
		account_child_parent/3,
		account_in_set/3,
		account_by_role/3,
		account_role_by_id/3,
		account_exists/2,
		account_detail_level/3,
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
		transaction_type/2,
		transaction_vectors_total/2,
		transactions_before_day_on_account_and_subaccounts/5,
		make_transaction/5
]).
:- use_module('days', [
		add_days/3]).
:- use_module('utils', [
		get_indentation/2,
		filter_out_chars_from_atom/3,
		pretty_term_string/2]).

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

Bases, interchangeably also called Report_Currency. This is a list such as ['AUD']. When no report currency is specified, this list is empty. A report can only be requested for one currency, so multiple items are not possible. A report request without a currency means no conversions will take place, which is useful for debugging.

Exchange_Day: the day for which to find exchange_rate's to use. Always report end date?

Account_Id: the id/name of the account that the balance is computed for. Sub-accounts are found by lookup into Accounts.

Balance: a list of coord's
*/

% Relates Date to the balance at that time of the given account. 
balance_until_day(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, Date, Balance_Transformed, Transactions_Count) :-
	writeln("<!-- calling: balance_until_day -->"),
	assertion(account_exists(Accounts, Account_Id)),
	writeln("<!-- transactions_before_day_on_account_and_subaccounts -->"),
	transactions_before_day_on_account_and_subaccounts(Accounts, Transactions, Account_Id, Date, Filtered_Transactions),
	length(Filtered_Transactions, Transactions_Count),
	writeln("<!-- transaction_vectors_total -->"),
	transaction_vectors_total(Filtered_Transactions, Balance),
	writeln("<!-- vec_change_bases -->"),
	vec_change_bases(Exchange_Rates, Exchange_Day, Bases, Balance, Balance_Transformed),
	writeln("<!-- done: balance_until_day -->").

/* balance on account up to and including Date*/
balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, Date, Balance_Transformed, Transactions_Count) :-
	writeln("<!-- calling: balance_by_account -->"),
	writeln("<!-- checking account exists: "),
	writeln(Account_Id),
	writeln("-->"),
	assertion(account_exists(Accounts, Account_Id)),
	add_days(Date, 1, Date2),
	balance_until_day(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, Date2, Balance_Transformed, Transactions_Count),
	writeln("<!-- done: balance_by_account -->").
	
% Relates the period from Start_Date to End_Date to the net activity during that period of
% the given account.
net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, Start_Date, End_Date, Net_Activity_Transformed, Transactions_Count) :-
	findall(
		Transaction,
		(	
			member(Transaction, Transactions),
			transaction_in_period(Transaction, Start_Date, End_Date),
			transaction_account_in_set(Accounts, Transaction, Account_Id)
		), 
		Transactions_A),
	length(Transactions_A, Transactions_Count),
	transaction_vectors_total(Transactions_A, Net_Activity),
	vec_change_bases(Exchange_Rates, Exchange_Day, Bases, Net_Activity, Net_Activity_Transformed).

	

% Now for balance sheet predicates. These build up a tree structure that corresponds to the account hierarchy, with balances for each account.

balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, End_Date, Sheet_Entry) :-
	writeln("<!-- calling: balance_sheet_entry -->"),
	% find all direct children sheet entries
	findall(Child_Sheet_Entry, 
		(
			account_child_parent(Accounts, Child_Account, Account_Id),
			balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Child_Account, End_Date, Child_Sheet_Entry)
		),
		Child_Sheet_Entries
	),
	% find balance for this account including subaccounts (sum all transactions from beginning of time)
	balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, End_Date, Balance, Transactions_Count),
	Sheet_Entry = entry(Account_Id, Balance, Child_Sheet_Entries, Transactions_Count),
	writeln("<!-- done: balance_sheet_entry -->").


balance_sheet_at(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Start_Date, End_Date, Balance_Sheet) :-
	assertion(ground(Exchange_Rates)),
	assertion(ground(Accounts)),
	assertion(ground(Transactions)),
	assertion(ground(Bases)),
	assertion(ground(Exchange_Day)),
	assertion(ground(Start_Date)),
	assertion(ground(End_Date)),
	
	account_by_role(Accounts, ('Accounts'/'Assets'), Assets_AID),
	account_by_role(Accounts, ('Accounts'/'Equity'), Equity_AID),
	account_by_role(Accounts, ('Accounts'/'Liabilities'), Liabilities_AID),
	account_by_role(Accounts, ('Accounts'/'Earnings'), Earnings_AID),
	account_by_role(Accounts, ('Accounts'/'Assets'), Assets_AID),
	account_by_role(Accounts, ('Accounts'/'Equity'), Equity_AID),
	account_by_role(Accounts, ('Accounts'/'Assets'), Assets_AID),
	account_by_role(Accounts, ('Accounts'/'Equity'), Equity_AID),

	writeln("<!-- Balance sheet entries -->"),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Assets_AID, End_Date, Asset_Section),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Liabilities_AID, End_Date, Liability_Section),
	balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 'NetAssets', End_Date, Net_Assets, Transactions_Count),
	Net_Assets_Section = entry('NetAssets', Net_Assets, [], Transactions_Count),

	% get earnings before the report period
	balance_until_day(Exchange_Rates, Accounts, Transactions, Bases, 
	/*exchange day*/
	Start_Date, 
	Earnings_AID, 
	/*transactions until day*/
	Start_Date, 
	Historical_Earnings, _),
	
	% get earnings change over the period
	writeln("<!-- Net activity by account -->"),
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Earnings_AID, Start_Date, End_Date, Current_Earnings, _),
		
	writeln("<!-- Get transactions with retained earnings -->"),
	/* build a fake transaction that sets the balance of historical and current earnings.
	there is no need to make up transactions here, but it makes things more uniform */
	make_transaction(Start_Date, '', 'HistoricalEarnings', Historical_Earnings, Historical_Earnings_Transaction),
	make_transaction(Start_Date, '', 'CurrentEarnings', Current_Earnings, Current_Earnings_Transaction),
	Retained_Earnings_Transactions = [Current_Earnings_Transaction, Historical_Earnings_Transaction],
	append(Transactions, Retained_Earnings_Transactions, Transactions_With_Retained_Earnings),
	
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions_With_Retained_Earnings, Bases, Exchange_Day, 'Equity', End_Date, Equity_Section),
	
	Balance_Sheet = [Asset_Section, Liability_Section, Equity_Section, Net_Assets_Section],
	writeln("<!-- balance_sheet_at: done. -->").

trial_balance_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, _Start_Date, End_Date, [Trial_Balance_Section]) :-
	/*net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 'Accounts', Start_Date, End_Date, Trial_Balance, Transactions_Count),*/
	balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 'Accounts', End_Date, Trial_Balance, Transactions_Count),
	Trial_Balance_Section = entry('Trial_Balance', Trial_Balance, [], Transactions_Count).
/*
profitandloss_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Start_Date, End_Date, ProftAndLoss) :-
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 'Earnings', Start_Date, End_Date, ProftAndLoss).
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

profitandloss_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Start_Date, End_Date, [ProftAndLoss]) :-
	activity_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, 'Earnings', Start_Date, End_Date, ProftAndLoss).

% Now for trial balance predicates.

activity_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, Start_Date, End_Date, Trial_Balance_Entry) :-
	findall(
		Child_Sheet_Entry, 
		(
			account_child_parent(Accounts, Child_Account_Id, Account_Id),
			activity_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Child_Account_Id, Start_Date, End_Date, Child_Sheet_Entry)
		),
		Child_Sheet_Entries
	),
	net_activity_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Account_Id, Start_Date, End_Date, Net_Activity, Transactions_Count),
	Trial_Balance_Entry = entry(Account_Id, Net_Activity, Child_Sheet_Entries, Transactions_Count).
/*
trial_balance_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Start_Date, End_Date, Trial_Balance) :-
	account_ids(Accounts, Assets_AID, Equity_AID, Liabilities_AID, Earnings_AID, _Earnings_AID, _, Revenue_AID, Expenses_AID),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Assets_AID, End_Date, Asset_Section),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Equity_AID, End_Date, Equity_Section),
	balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Liabilities_AID, End_Date, Liability_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Revenue_AID, Start_Date, End_Date, Revenue_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Expenses_AID, Start_Date, End_Date, Expense_Section),
	balance_by_account(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Earnings_AID, Start_Date, Earnings),
	% current earnings, not retained?
	Trial_Balance = [Asset_Section, Liability_Section, entry(Earnings_AID, Earnings, []),
		Equity_Section, Revenue_Section, Expense_Section].
*/
% Now for movement predicates.
% - this isn't made available anywhere yet
/*
movement_between(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Start_Date, End_Date, Movement) :-
  account_ids(Accounts, Assets_AID, Equity_AID, Liabilities_AID, _, _, _, Revenue_AID, Expenses_AID),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Assets_AID, Start_Date, End_Date, Asset_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Equity_AID, Start_Date, End_Date, Equity_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Liabilities_AID, Start_Date, End_Date, Liability_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Revenue_AID, Start_Date, End_Date, Revenue_Section),
	trial_balance_entry(Exchange_Rates, Accounts, Transactions, Bases, Exchange_Day, Expenses_AID, Start_Date, End_Date, Expense_Section),
	Movement = [Asset_Section, Liability_Section, Equity_Section, Revenue_Section, Expense_Section].

*/





/* balance sheet and profit&loss entries*/
bs_and_pl_entries(Accounts, Report_Currency, Context, Balance_Sheet_Entries, ProftAndLoss_Entries, Used_Units_Out, Lines2, Lines3) :-
	format_report_entries(xbrl, Accounts, 0, Report_Currency, Context, Balance_Sheet_Entries, [], Used_Units, [], Lines3),
	format_report_entries(xbrl, Accounts, 0, Report_Currency, Context, ProftAndLoss_Entries, Used_Units, Used_Units_Out, [], Lines2).

	
	

/* omitting Max_Detail_Level defaults it to 0 */
format_report_entries(Format, Accounts, Indent_Level, Report_Currency, Context, Entries, Used_Units_In, Used_Units_Out, Lines_In, Lines_Out) :-
	format_report_entries(Format, 0, Accounts, Indent_Level, Report_Currency, Context, Entries, Used_Units_In, Used_Units_Out, Lines_In, Lines_Out).
	
format_report_entries(_, _, _, _, _, _, [], Used_Units, Used_Units, Lines, Lines).

format_report_entries(Format, Max_Detail_Level, Accounts, Indent_Level, Report_Currency, Context, Entries, Used_Units_In, Used_Units_Out, Lines_In, Lines_Out) :-
	[entry(Name, Balances, Children, Transactions_Count)|Entries_Tail] = Entries,
	(
		/* does the account have a detail level and is it greater than Max_Detail_Level? */
		(account_detail_level(Accounts, Name, Detail_Level), Detail_Level > Max_Detail_Level)
	->
		/* nothing to do */
		(
			Used_Units_In = Used_Units_Out, 
			Lines_In = Lines_Out
		)
	;
		(
			account_normal_side(Accounts, Name, Normal_Side),
			(
				/* should we display an account with zero transactions? */
				(Balances = [],(Indent_Level = 0; Transactions_Count \= 0))
			->
				/* force-display it */
				format_balance(Format, Indent_Level, Report_Currency, Context, Name, Normal_Side, [],
					Used_Units_In, UsedUnitsIntermediate, Lines_In, LinesIntermediate)
			;
				/* if not, let the logic omit it entirely */
				format_balances(Format, Indent_Level, Report_Currency, Context, Name, Normal_Side, Balances, 
					Used_Units_In, UsedUnitsIntermediate, Lines_In, LinesIntermediate)
			),
			Level_New is Indent_Level + 1,
			/*display child entries*/
			format_report_entries(Format, Max_Detail_Level, Accounts, Level_New, Report_Currency, Context, Children, UsedUnitsIntermediate, UsedUnitsIntermediate2, LinesIntermediate, LinesIntermediate2),
			/*recurse on Entries_Tail*/
			format_report_entries(Format, Max_Detail_Level, Accounts, Indent_Level, Report_Currency, Context, Entries_Tail, UsedUnitsIntermediate2, Used_Units_Out, LinesIntermediate2, Lines_Out)
		)
	),
	!.
			
pesseract_style_table_rows(_, _, [], []).

pesseract_style_table_rows(Accounts, Report_Currency, Entries, [Lines|Lines_Tail]) :-
	[entry(Name, Balances, Children, _)|Entries_Tail] = Entries,
	/*render child entries*/
	pesseract_style_table_rows(Accounts, Report_Currency, Children, Children_Lines),
	/*render balance*/
	maybe_balance_lines(Accounts, Name, Report_Currency, Balances, Balance_Lines),
	(
		Children_Lines = []
	->
		
		(
			Lines = [tr([td(Name), td(Balance_Lines)])]
			
		)
	;
		(
			flatten([tr([td([b(Name)])]), Children_Lines, [tr([td([align="right"],[Name]), td(Balance_Lines)])]], Lines)

		)		
	),
	/*recurse on Entries_Tail*/
	pesseract_style_table_rows(Accounts, Report_Currency, Entries_Tail, Lines_Tail).
			
maybe_balance_lines(Accounts, Name, Report_Currency, Balances, Balance_Lines) :-
	account_normal_side(Accounts, Name, Normal_Side),
	(
		Balances = []
	->
		/* force-display it */
		format_balance(html, 0, Report_Currency, '', Name, Normal_Side, Balances,
			[], _, [], Balance_Lines)
	;
		/* if not, let the logic omit it entirely */
		format_balances(html, 0, Report_Currency, '', Name, Normal_Side, Balances, 
			[], _, [], Balance_Lines)
	).
			
			
			
format_balances(_, _, _, _, _, _, [], Used_Units, Used_Units, Lines, Lines).

format_balances(Format, Indent_Level, Report_Currency, Context, Name, Normal_Side, [Balance|Balances], Used_Units_In, Used_Units_Out, Lines_In, Lines_Out) :-
   format_balance(Format, Indent_Level, Report_Currency, Context, Name, Normal_Side, [Balance], Used_Units_In, UsedUnitsIntermediate, Lines_In, LinesIntermediate),
   format_balances(Format, Indent_Level, Report_Currency, Context, Name, Normal_Side, Balances, UsedUnitsIntermediate, Used_Units_Out, LinesIntermediate, Lines_Out).

format_balance(Format, Indent_Level, Report_Currency_List, Context, Name, Normal_Side, [], Used_Units_In, Used_Units_Out, Lines_In, Lines_Out) :-
	(
		[Report_Currency] = Report_Currency_List
	->
		true
	;
		Report_Currency = 'AUD' % just for displaying zero balance
	),
	format_balance(Format, Indent_Level, _, Context, Name, Normal_Side, [coord(Report_Currency, 0, 0)], Used_Units_In, Used_Units_Out, Lines_In, Lines_Out).
   
format_balance(Format, Indent_Level, Report_Currency_List, Context, Name, Normal_Side, [coord(Unit, Debit, Credit)], Used_Units_In, Used_Units_Out, Lines_In, Lines_Out) :-
	union([Unit], Used_Units_In, Used_Units_Out),
	(
		Normal_Side = credit
	->
		Balance is (Credit - Debit)
	;
		Balance is (Debit - Credit)
	),
	get_indentation(Indent_Level, Indentation),
	%filter_out_chars_from_atom(is_underscore, Name, Name2),
	Name2 = Name,
	(
		Format = xbrl
	->
		format(string(Line), '~w<basic:~w contextRef="~w" unitRef="U-~w" decimals="INF">~2:f</basic:~w>\n', [Indentation, Name2, Context, Unit, Balance, Name2])
	;
		(
			(
				Report_Currency_List = [Unit]
			->
				Printed_Unit = ''
			;
				Printed_Unit = Unit
			),
			format(string(Line), '~2:f~w\n', [Balance, Printed_Unit])
		)
	),
	append(Lines_In, [Line], Lines_Out).

is_underscore('_').


	/*
	vec_add(Historical_Earnings, Current_Earnings, Retained_Earnings),
	Retained_Earnings_Section = entry('RetainedEarnings', Retained_Earnings,
		[
			entry('HistoricalEarnings', Historical_Earnings, []), 
			entry('CurrentEarnings', Current_Earnings, [])
		]
	),*/

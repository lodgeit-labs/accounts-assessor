% ===================================================================
% Project:   LodgeiT
% Module:    ledger.pl
% Date:      2019-06-02
% ===================================================================

:- module(ledger_report, [
		accounts_report/2,
		balance_sheet_at/2,
		balance_by_account/9, 
		balance_until_day/9,
		balance/5,
		trial_balance_between/8, 
		profitandloss_between/2, 
		format_report_entries/11, 
		format_report_entries/10, 
		bs_and_pl_entries/8,
		format_balances/11,
		net_activity_by_account/4,
			  pesseract_style_table_rows/4,
			  entry_balance/2,
			  entry_account_id/2,
			  entry_child_sheet_entries/2]).

:- use_module(library(rdet)).
:- use_module(library(record)).

:- rdet(profitandloss_between/2).
:- rdet(bs_and_pl_entries/8).
:- rdet(maybe_balance_lines/5).
:- rdet(format_balance/11).
:- rdet(format_balances/11).
:- rdet(pesseract_style_table_rows/4).
:- rdet(format_report_entries/10).
:- rdet(format_report_entries/11).
:- rdet(activity_entry/3).
:- rdet(trial_balance_between/8).
:- rdet(balance_sheet_entry/8).
:- rdet(balance_until_day/9).	
:- rdet(balance_by_account/9).	
:- rdet(net_activity_by_account/4).	

:- use_module('accounts', [
		account_child_parent/3,
		account_in_set/3,
		account_by_role/3,
		account_role_by_id/3,
		account_exists/2,
		account_detail_level/3,
		account_normal_side/3,
		account_parent/2]).
:- use_module('pacioli', [
		vec_add/3, 
		vec_sum/2,
		vec_inverse/2, 
		vec_reduce/2, 
		vec_sub/3]).
:- use_module('exchange', [
		vec_change_bases/5]).
:- use_module('transactions', [
		transaction_account_in_set/3,
		transaction_in_period/3,
		transaction_before/2,
		transaction_type/2,
		transaction_vectors_total/2,
		transactions_before_day_on_account_and_subaccounts/5,
		make_transaction/5,
		transactions_in_account_set/4
]).
:- use_module('days', [
		add_days/3]).
:- use_module('utils', [
		get_indentation/2,
		filter_out_chars_from_atom/3,
		pretty_term_string/2]).

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

% TODO: do "Transactions_Count" elsewhere
% TODO: get rid of the add_days(...) and use generic period selector(s)
balance(Static_Data, Account_Id, Date, Balance, Transactions_Count) :-
	dict_vars(Static_Data, 
		[Exchange_Date, Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency]
	),
	
	/* todo use transactions_in_account_set here */
	
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
	
	/* todo should take total including sub-accounts, probably */
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
	%format('balance_sheet_entry: ~w~n',[Account_Id]),
%balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Account_Id, End_Date, Sheet_Entry) :-
	/*
	dict_vars(Static_Data, 
		[End_Date, Exchange_Date, Exchange_Rates, Accounts, Transactions, Report_Currency]
	),
	*/
	% find all direct children sheet entries
	findall(
		Child_Sheet_Entry, 
		(
			account_child_parent(Static_Data.accounts, Child_Account, Account_Id),
			balance_sheet_entry(Static_Data, Child_Account, Child_Sheet_Entry)
			%balance_sheet_entry(Exchange_Rates, Accounts, Transactions, Report_Currency, Exchange_Date, Child_Account, End_Date, Child_Sheet_Entry)
		),
		Child_Sheet_Entries
	),
	% find balance for this account including subaccounts (sum all transactions from beginning of time)
	balance(Static_Data, Account_Id, Static_Data.end_date, Balance, Transactions_Count),
	Entry = entry(Account_Id, Balance, Child_Sheet_Entries, Transactions_Count).

accounts_report(Static_Data, Accounts_Report) :-
	/*
	dict_vars(Static_Data, 
		[End_Date, Exchange_Date, Exchange_Rates, Accounts, Transactions, Report_Currency]
	),
	*/
	balance_sheet_entry(Static_Data, 'Accounts', Entry),
	% print_term(Entry,[]),
	Entry = entry(_,_,Accounts_Report,_).

balance_sheet_at(Static_Data, [Net_Assets_Entry, Equity_Entry]) :-
	balance_sheet_entry(Static_Data, 'NetAssets', Net_Assets_Entry),
	balance_sheet_entry(Static_Data, 'Equity', Equity_Entry).

trial_balance_between(Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency, Exchange_Date, _Start_Date, End_Date, [Trial_Balance_Section]) :-

	balance_by_account(Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency, Exchange_Date, 'Accounts', End_Date, Accounts_Balance, Transactions_Count),
	balance_by_account(Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency, Exchange_Date, 'CurrentEarnings', End_Date, Current_Earnings_Balance, _),
	balance_by_account(Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency, Exchange_Date, 'HistoricalEarnings', End_Date, Historical_Earnings_Balance, _),
	vec_sum([Current_Earnings_Balance, Historical_Earnings_Balance], Earnings_Balance),	
	vec_sub(Accounts_Balance, Earnings_Balance, Trial_Balance),
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


/* balance sheet and profit&loss entries*/
bs_and_pl_entries(Accounts, Report_Currency, Context, Balance_Sheet_Entries, ProftAndLoss_Entries, Used_Units_Out, Lines2, Lines3) :-
	format_report_entries(xbrl, Accounts, 0, Report_Currency, Context, Balance_Sheet_Entries, [], Used_Units, [], Lines3),
	format_report_entries(xbrl, Accounts, 0, Report_Currency, Context, ProftAndLoss_Entries, Used_Units, Used_Units_Out, [], Lines2).


/* omitting Max_Detail_Level defaults it to 0 */
format_report_entries(Format, Accounts, Indent_Level, Report_Currency, Context, Entries, Used_Units_In, Used_Units_Out, Lines_In, Lines_Out) :-
	format_report_entries(Format, 0, Accounts, Indent_Level, Report_Currency, Context, Entries, Used_Units_In, Used_Units_Out, Lines_In, Lines_Out).
	
format_report_entries(_, _, _, _, _, _, [], Used_Units_In, Used_Units_Out, Lines_In, Lines_Out) :-
	(Used_Units_In = Used_Units_Out, Lines_In = Lines_Out -> true ; throw('internal error')).

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
todo: could/should the concept of what a balance of some account is be specified declaratively somewhere so that we could
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

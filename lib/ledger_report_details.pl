:- module(ledger_report_details, [
		investment_report/3]).

:- use_module('system_accounts', [
		trading_account_ids/2]).

:- use_module('accounts', [
		account_child_parent/3,
		account_in_set/3,
		account_by_role/3,
		account_role_by_id/3,
		account_exists/2]).

:- use_module('ledger_report', [
		balance_by_account/9,
		format_report_entries/10]).

:- use_module('pacioli', [
		vec_add/3]).
		
:- use_module('utils', [
		get_indentation/2,
		pretty_term_string/2]).

/*
generate realized and unrealized investment report sections for each trading account
*/
investment_report((Exchange_Rates, Accounts, Transactions, Report_Currency, Report_Date), Transaction_Types, Lines) :-
	trading_account_ids(Transaction_Types, Trading_Account_Ids),
	maplist(
		investment_report2((Exchange_Rates, Accounts, Transactions, Report_Currency, Report_Date)),
		Trading_Account_Ids, 
		Lines).

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
		check_investment_totals(Static_Data, Trading_Account),
		[Check_Realized_Totals_List, Check_Unrealized_Totals_List],
		[realized, unrealized],
		Warnings).
	
	
check_investment_totals((Exchange_Rates, Accounts, Transactions, Report_Currency, Report_Date), Trading_Account, Check_Totals_List_Nested, Gains_Role, Warning) :- 
	flatten(Check_Totals_List_Nested, Check_Totals_List),
	% the totals in investment report should be more or less equal to the account balances
	vec_add(Check_Totals_List, [/*coord('AUD', 1, 0)*/], Total),
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
	account_by_role(Accounts, (Trading_Account/Gains_Role), Gains_Account),
	account_by_role(Accounts, (Gains_Account/Forex_Role), Gains_Forex_Account),
	account_by_role(Accounts, (Gains_Forex_Account/Unit), Unit_Account),
	balance_by_account(Exchange_Rates, Accounts, Transactions, Report_Currency, Report_Date, Unit_Account, Report_Date, Balance, Transactions_Count),
	format_report_entries(1, Accounts, 4, Report_Currency, '', [entry(Unit_Account, Balance, [], Transactions_Count)], [], _, [], Lines).

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

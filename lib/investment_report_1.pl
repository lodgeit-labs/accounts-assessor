:- module(investment_report_1, [investment_report_1/2]).

:-use_module(library(rdet)).

:- rdet(check_investment_totals/4).
:- rdet(units_traded_on_trading_account/3).
:- rdet(investment_report3_balance/7).
:- rdet(investment_report3_lines/6).
:- rdet(strip_unit_costs/2).
:- rdet(investment_report3/6).
:- rdet(investment_report2/3).
:- rdet(investment_report1/2).
:- rdet(investment_report_to_html/2).
:- rdet(investment_report_1/2).


investment_report_1(Static_Data, Lines) :-

	investment_report1(Static_Data, Report0),
	flatten(Report0, Report),
	investment_report_to_html(Report, Report_Table_Data),

	dict_vars(Static_Data, [Start_Date, End_Date, Report_Currency]),
	format_date(Start_Date, Start_Date_Atom),
	format_date(End_Date, End_Date_Atom),
	report_currency_atom(Report_Currency, Report_Currency_Atom),
	atomic_list_concat(['investment report from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ', Report_Currency_Atom], Title_Text),
	
	Header = tr([th('Investment'), th('Opening Unit #'), th('Opening Cost'), th('Closing Unit #'), th('Closing Cost'), th('Realized Market'), th('Realized Forex'), th('Unrealized Market'), th('Unrealized Forex')]),
	
	append([Header], Report_Table_Data, Tbl),
	/*report_page(Title_Text, Tbl, 'investment_report1.html', Lines)*/
	nonvar(Title_Text), nonvar(Tbl), Lines = ''.


investment_report_to_html([], '').
investment_report_to_html([Item|Items], [tr(Columns)|Rows]) :-
	Item = row(Unit, Opening, Closing, Realized, Unrealized),
	assets_html(Opening, Opening_Html),
	assets_html(Closing, Closing_Html),
	gains_html(Realized, Rea_Html),
	gains_html(Unrealized, Unr_Html),
	flatten([td(Unit), Opening_Html, Closing_Html, Rea_Html, Unr_Html], Columns),
	investment_report_to_html(Items, Rows).

gains_html((_, Market, Forex), [td(Market), td(Forex)]).
assets_html((Count, Cost), [td(Count), td(Cost)]).


/*
	generate realized and unrealized investment report sections for each trading account
*/
investment_report1(Static_Data, Lines) :-
	dict_vars(Static_Data, [Transaction_Types]),
	trading_account_ids(Transaction_Types, Trading_Account_Ids),
	maplist(
		investment_report2(Static_Data),
		Trading_Account_Ids, 
		Lines).
		
/*
	generate realized and unrealized investment report sections for one trading account
*/
investment_report2(Static_Data, Trading_Account, Lines) :-
	dict_vars(Static_Data, [Accounts]),
	units_traded_on_trading_account(Accounts, Trading_Account, All_Units_Roles),
	maplist(
		investment_report3(Static_Data, Trading_Account),
		All_Units_Roles,
		Lines,
		Realized_Totals_Crosscheck_List,
		Unrealized_Totals_Crosscheck_List),
	maplist(
		check_investment_totals(Static_Data, Trading_Account),
		[Realized_Totals_Crosscheck_List, Unrealized_Totals_Crosscheck_List],
		[realized, unrealized]).
	
investment_report3(Static_Data, Trading_Account, Unit, Row, Realized_Total, Unrealized_Total) :-
	Row = row(Unit, Lines0o, Lines0c, Lines1, Lines2),
	dict_vars(Static_Data, [Start_Date, End_Date, Exchange_Rates, Accounts, Transactions, Report_Currency]),
	account_by_role(Accounts, ('FinancialInvestments'/Unit), Assets_Account),
	balance_until_day(Exchange_Rates, Accounts, Transactions, Report_Currency, Start_Date, Assets_Account, Start_Date, Opening_Value, _),
	balance_until_day(Exchange_Rates, Accounts, Transactions, Report_Currency, End_Date, Assets_Account, End_Date, Closing_Value, _),
	balance_until_day([], Accounts, Transactions, [], Start_Date, Assets_Account, Start_Date, Opening_Count, _),
	balance_until_day([], Accounts, Transactions, [], End_Date, Assets_Account, End_Date, Closing_Count, _),
	/*fixme check the units here:*/
	/*
	not very systematic, but there are gonna be multiple units with different with_cost_per_unit here
	*/
	strip_unit_costs(Opening_Count, Opening_Count_Stripped),
	strip_unit_costs(Closing_Count, Closing_Count_Stripped),

	number_vec(_, Opening_Count2, Opening_Count_Stripped),
	number_vec(_, Opening_Value2, Opening_Value),
	number_vec(_, Closing_Count2, Closing_Count_Stripped),
	number_vec(_, Closing_Value2, Closing_Value),
	Lines0o = (Opening_Count2, Opening_Value2),
	Lines0c = (Closing_Count2, Closing_Value2),
	investment_report3_lines(Static_Data, Trading_Account, Unit, realized, Lines1, Realized_Total),
	investment_report3_lines(Static_Data, Trading_Account, Unit, unrealized, Lines2, Unrealized_Total).
	
strip_unit_costs(V1, V3) :-
	findall(
		coord(True_Unit, D, C),
		(
			member(coord(Unit, D, C), V1),
			(
				Unit = with_cost_per_unit(True_Unit, _)
				;
				(
					Unit \= with_cost_per_unit(_, _),
					True_Unit = Unit
				)
			)
		),
		V2
	),
	vec_add(V2, [], V3).
				
	
	
investment_report3_lines(Static_Data, Trading_Account, Unit, Gains_Role, Lines, Total) :-
	investment_report3_balance(Static_Data, Trading_Account, Gains_Role, withoutCurrencyMovement, Unit, Gains_Market_Balance, Gains_Market_Lines),
	investment_report3_balance(Static_Data, Trading_Account, Gains_Role, onlyCurrencyMovement, Unit, Gains_Forex_Balance, Gains_Forex_Lines),
	vec_add(Gains_Market_Balance, Gains_Forex_Balance, Total),
	Lines = (Gains_Role, Gains_Market_Lines, Gains_Forex_Lines).

investment_report3_balance(Static_Data, Trading_Account, Gains_Role, Forex_Role, Unit, Balance, Lines) :-
	dict_vars(Static_Data, [Exchange_Rates, Accounts, Transactions, Report_Currency, End_Date]),
	account_by_role(Accounts, (Trading_Account/Gains_Role), Gains_Account),
	account_by_role(Accounts, (Gains_Account/Forex_Role), Gains_Forex_Account),
	account_by_role(Accounts, (Gains_Forex_Account/Unit), Unit_Account),
	balance_by_account(Exchange_Rates, Accounts, Transactions, Report_Currency, End_Date, Unit_Account, End_Date, Balance, Transactions_Count),
	format_report_entries(simple, 1, Accounts, 0, Report_Currency, '', [entry(Unit_Account, Balance, [], Transactions_Count)], [], _, [], Lines).

units_traded_on_trading_account(Accounts, Trading_Account, All_Units_Roles) :-
	findall(
		Unit_Account_Role,
		(
			member(Gains_Role, [realized, unrealized]),
			account_by_role(Accounts, (Trading_Account/Gains_Role), Gains_Account),
			member(Forex_Role, [withoutCurrencyMovement, onlyCurrencyMovement]),
			account_by_role(Accounts, (Gains_Account/Forex_Role), Forex_Account),
			account_child_parent(Accounts, Unit_Account_Id, Forex_Account),
			account_role_by_id(Accounts, Unit_Account_Id, (_Parent_Id/Unit_Account_Role))
		),
		All_Units_Roles0
	),
	sort(All_Units_Roles0, All_Units_Roles).
	
check_investment_totals(Static_Data, Trading_Account, Check_Totals_List_Nested, Gains_Role) :- 
	dict_vars(Static_Data, [Exchange_Rates, Accounts, Transactions, Report_Currency, End_Date]),
	flatten(Check_Totals_List_Nested, Check_Totals_List),
	% the totals in investment report should be more or less equal to the account balances
	vec_add(Check_Totals_List, [/*coord('AUD', 1, 0)*/], Total),
	account_by_role(Accounts, (Trading_Account/Gains_Role), Account),
	balance_by_account(Exchange_Rates, Accounts, Transactions, Report_Currency, End_Date, Account, End_Date, Total_Balance, _),
	(
		vecs_are_almost_equal(Total_Balance, Total)
	->
		true
	;
		(
			term_string(Total_Balance, Total_Balance_Str),
			term_string(Total, Total_Str),
			throw_string([Gains_Role, ' total balance check failed: account balance: ',
				Total_Balance_Str, 'investment report total:', Total_Str, '.\n'])
		)
	).

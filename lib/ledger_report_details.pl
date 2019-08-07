:- module(ledger_report_details, [
		investment_report/2,
		bs_report/5,
		pl_report/6	
		]).

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
		balance_until_day/9,
		format_report_entries/11,
		pesseract_style_table_rows/4]).

:- use_module('pacioli', [
		vec_add/3,
	    number_vec/3,
		vecs_are_almost_equal/2]).
		
:- use_module('utils', [
		get_indentation/2,
		pretty_term_string/2]).

:- use_module('days', [
		format_date/2]).

:- use_module('files', [
		my_tmp_file_name/2,
		request_tmp_dir/1,
		server_public_url/1]).
		
:- use_module(library(http/html_write)).


report_file_path(FN, Url, Path) :-
	request_tmp_dir(Tmp_Dir),
	server_public_url(Server_Public_Url),
	atomic_list_concat([Server_Public_Url, '/tmp/', Tmp_Dir, '/', FN], Url),
	my_tmp_file_name(FN, Path).

html_tokenlist_string(Tokenlist, String) :-
	new_memory_file(X),
	open_memory_file(X, write, Mem_Stream),
	print_html(Mem_Stream, Tokenlist),
	close(Mem_Stream),
	memory_file_to_string(X, String).

write_file_from_string(File_Path, Html_String) :-
	open(File_Path, write, File_Stream),
	write(File_Stream, Html_String),
	close(File_Stream).

report_section(File_Name, Html_Tokenlist, Lines) :-
	report_file_path(File_Name, Url, File_Path),
	html_tokenlist_string(Html_Tokenlist, Html_String),
	write_file_from_string(File_Path, Html_String),
	Lines = ['url: ', Url, '\n', '\n', Html_String].

report_currency_atom(Report_Currency_List, Report_Currency_Atom) :-
	(
		Report_Currency_List = [Report_Currency]
	->
		atomic_list_concat(['(', Report_Currency, ')'], Report_Currency_Atom)
	;
		Report_Currency_Atom = ''
	).

report_page(Title_Text, Tbl, File_Name, Lines) :-
	Body_Tags = [Title_Text, ':', br([]), table([border="1"], Tbl)],
	Page = page(
		title([Title_Text]),
		Body_Tags),
	phrase(Page, Page_Tokenlist),
	report_section(File_Name, Page_Tokenlist, Lines).

pl_report(Accounts, Report_Currency, ProftAndLoss2, Start_Date, End_Date, Lines) :-

	format_date(Start_Date, Start_Date_Atom),
	format_date(End_Date, End_Date_Atom),
	report_currency_atom(Report_Currency, Report_Currency_Atom),
	atomic_list_concat(['profit&loss from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ', Report_Currency_Atom], Title_Text),
	
	pesseract_style_table_rows(Accounts, Report_Currency, ProftAndLoss2, Report_Table_Data),
	Header = tr([th('Account'), th(['Value', Report_Currency_Atom])]),
	flatten([Header, Report_Table_Data], Tbl),
	report_page(Title_Text, Tbl, 'profit_and_loss.html', Lines).
		
bs_report(Accounts, Report_Currency, Balance_Sheet, End_Date, Lines) :-

	format_date(End_Date, End_Date_Atom),
	report_currency_atom(Report_Currency, Report_Currency_Atom),
	atomic_list_concat(['balance sheet for ', End_Date_Atom, ' ', Report_Currency_Atom], Title_Text),
	
	pesseract_style_table_rows(Accounts, Report_Currency, Balance_Sheet, Report_Table_Data),
	Header = tr([th('Account'), th(['Balance', Report_Currency_Atom])]),
	flatten([Header, Report_Table_Data], Tbl),
	report_page(Title_Text, Tbl, 'balance_sheet.html', Lines).
	
	
investment_report(Static_Data, Lines) :-

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
	report_page(Title_Text, Tbl, 'investment_report.html', Lines).


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
	account_by_role(Accounts, ('Financial_Investments'/Unit), Assets_Account),
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
	investment_report3_balance(Static_Data, Trading_Account, Gains_Role, without_currency_movement, Unit, Gains_Market_Balance, Gains_Market_Lines),
	investment_report3_balance(Static_Data, Trading_Account, Gains_Role, only_currency_movement, Unit, Gains_Forex_Balance, Gains_Forex_Lines),
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
			member(Forex_Role, [without_currency_movement, only_currency_movement]),
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


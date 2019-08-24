:- module(ledger_report_details, [
		investment_report_1/2,
		bs_report/3,
		pl_report/4,
		investment_report_2/4
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
	    value_subtract/3,
	    value_multiply/3,
		value_convert/3,
		vecs_are_almost_equal/2]).
		
:- use_module('utils', [
		get_indentation/2,
		pretty_term_string/2,
		throw_string/1]).

:- use_module('days', [
		format_date/2]).

:- use_module('files', [
		my_tmp_file_name/2,
		request_tmp_dir/1,
		server_public_url/1]).

:- use_module('exchange_rates', [
		exchange_rate/5,
		exchange_rate_throw/5]).

:- use_module('pricing', [
		outstanding_goods_count/2]).

:- use_module('exchange', [
		vec_change_bases/5]).
		
:- use_module(library(http/html_write)).
:- use_module(library(rdet)).


:- rdet(ir2_forex_gain/8).
:- rdet(ir2_market_gain/10).
:- rdet(clip_investments/4).
:- rdet(filter_investment_sales/3).
:- rdet(clip_investment/3).
:- rdet(optional_converted_value/3).
:- rdet(format_conversion/3).
:- rdet(optional_currency_conversion/5).
:- rdet(format_money_precise/3).
:- rdet(format_money/3).
:- rdet(format_money2/4).
:- rdet(ir2_row_to_html/3).
:- rdet(investment_report_2_unrealized/3).
:- rdet(investment_report_2_sale_lines/4).
:- rdet(investment_report_2_sales/3).
:- rdet(investment_report_2/4).
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
:- rdet(bs_report/3).
:- rdet(pl_report/4).
:- rdet(report_page/4).
:- rdet(report_currency_atom/2).
:- rdet(report_section/3).
:- rdet(html_tokenlist_string/2).
:- rdet(report_file_path/3).



:- [investment_report_1].



html_tokenlist_string(Tokenlist, String) :-
	new_memory_file(X),
	open_memory_file(X, write, Mem_Stream),
	print_html(Mem_Stream, Tokenlist),
	close(Mem_Stream),
	memory_file_to_string(X, String).

report_section(File_Name, Html_Tokenlist, Url) :-
	report_file_path(File_Name, Url, File_Path),
	html_tokenlist_string(Html_Tokenlist, Html_String),
	write_file(File_Path, Html_String).

report_currency_atom(Report_Currency_List, Report_Currency_Atom) :-
	(
		Report_Currency_List = [Report_Currency]
	->
		atomic_list_concat(['(', Report_Currency, ')'], Report_Currency_Atom)
	;
		Report_Currency_Atom = ''
	).

report_page(Title_Text, Tbl, File_Name, Info) :-
	Body_Tags = [Title_Text, ':', br([]), table([border="1"], Tbl)],
	Page = page(
		title([Title_Text]),
		Body_Tags),
	phrase(Page, Page_Tokenlist),
	report_section(File_Name, Page_Tokenlist, Url),
	Info = Title_Text-Url.
	

pl_html(Static_Data, ProftAndLoss2, Filename_Suffix, Report) :-
	dict_vars(Static_Data, [Accounts, Start_Date, End_Date, Report_Currency]),
	format_date(Start_Date, Start_Date_Atom),
	format_date(End_Date, End_Date_Atom),
	report_currency_atom(Report_Currency, Report_Currency_Atom),
	atomic_list_concat(['profit&loss from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ', Report_Currency_Atom], Title_Text),
	pesseract_style_table_rows(Accounts, Report_Currency, ProftAndLoss2, Report_Table_Data),
	Header = tr([th('Account'), th(['Value', Report_Currency_Atom])]),
	flatten([Header, Report_Table_Data], Tbl),
	atomic_list_concat(['profit_and_loss', Filename_Suffix, '.html'], Filename),
	report_page(Title_Text, Tbl, Filename, Report).
		
bs_html(Static_Data, Balance_Sheet, Report) :-
	dict_vars(Static_Data, [Accounts, Start_Date, End_Date, Report_Currency]),
	format_date(Start_Date, Start_Date_Atom),
	format_date(End_Date, End_Date_Atom),
	report_currency_atom(Report_Currency, Report_Currency_Atom),
	atomic_list_concat(['balance sheet from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ', Report_Currency_Atom], Title_Text),
	pesseract_style_table_rows(Accounts, Report_Currency, Balance_Sheet, Report_Table_Data),
	Header = tr([th('Account'), th(['Balance', Report_Currency_Atom])]),
	flatten([Header, Report_Table_Data], Tbl),
	report_page(Title_Text, Tbl, 'balance_sheet.html', Report).
	
crosschecks_report(Pl, Bs, Ir, Report) :-
	Report = [
		equality(account_balance(Pl, 'Accounts'/'InvestmentIncome'), sum(Ir.totals.gains)),
		equality(account_balance(Bs, 'Accounts'/'FinancialInvestments'), sum(Ir.totals.closing.total_converted)),

		
crosschecks_evaluation :-


crosschecks_html :-
	

:- record investment_report_item(type, info, outstanding_count, sales, clipped).

event(Event, Date, Unit_Cost_Foreign, Currency_Conversion, Unit_Cost_Converted, Total_Cost_Foreign, Total_Cost_Converted) :-
	Event = _{
		date: Date, 
		unit_cost_foreign: Unit_Cost_Foreign, 
		currency_conversion: Currency_Conversion, 
		unit_cost_converted: Unit_Cost_Converted, 
		total_cost_foreign: Total_Cost_Foreign, 
		total_cost_converted: Total_Cost_Converted
	}.


investment_report_2(Static_Data, Outstanding_In, Filename_Suffix, Report_Data, Report_File_Info) :-
	Report_Data = _{
		rows: Rows,
		totals: Totals,
	},
	investment_report_2_rows(Static_Data, Outstanding_In, Rows),
	investment_totals(Rows, Totals),

	atomic_list_concat(['investment_report', Filename_Suffix, '.html'], Filename),
	report_page(Title_Text, Tbl, Filename, Report_File_Info).
	
	



investment_report_2_rows(Static_Data, Outstanding_In, Filename_Suffix, Report_Output) :-
	Start_Date = Static_Data.start_date,
	End_Date = Static_Data.end_date,
	Report_Currency = Static_Data.report_currency,
	clip_investments(Static_Data, Outstanding_In, Realized_Investments, Unrealized_Investments),

	format_date(Start_Date, Start_Date_Atom),
	format_date(End_Date, End_Date_Atom),
	report_currency_atom(Report_Currency, Report_Currency_Atom),
	atomic_list_concat(['investment report from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ', Report_Currency_Atom], Title_Text),

	/* each item of Investments is a purchase with some info and list of sales */
	maplist(investment_report_2_sales(Static_Data), Realized_Investments, Sale_Lines),
	maplist(investment_report_2_unrealized(Static_Data), Unrealized_Investments, Non_Sale_Lines),
	flatten([Sale_Lines, Non_Sale_Lines], Rows0),

	/* lets sort by unit, sale date, purchase date */
	sort(7, @=<, Rows0, Rows1),
	sort(2, @=<, Rows1, Rows2),
	sort(1, @=<, Rows2, Rows),

	maplist(ir2_row_to_html(Report_Currency), Rows, Rows_Html),

	Header = tr([
		th('Unit'), th('Count'), th('Currency'),
		th('Opening Date'), th('Opening Unit Cost Foreign'), th('Currency Conversion'), th('Opening Unit Cost Converted'), th('Opening Total Cost Foreign'), th('Opening Total Cost Converted'), 
		
		th('Sale Date'), th('Sale Unit Price Foreign'), th('Currency Conversion'), th('Sale Unit Price Converted'),
		
		th('Rea Market Gain'), th('Rea Forex Gain'), th('Unr Market Gain'), th('Unr Forex Gain'), 
		
		th('Closing Unit Price Foreign'), th('Currency Conversion'), th('Closing Unit Price Converted'),
		th('Closing Total Value Foreign'), th('Closing Total Value Converted')]),
	flatten([Header, Rows_Html], Tbl),


investment_report_2_sales(Static_Data, I, Lines) :-
	I = investment_report_item(rea, Info, 0, Sales, Clipped),
	maplist(investment_report_2_sale_lines(Static_Data, Info, Clipped), Sales, Lines).


investment_report_2_sale_lines(Static_Data, Info, Clipped, Sale, Row) :-
	dict_vars(Static_Data, [Exchange_Rates, Report_Currency]),
	Sale = sale(Sale_Date, Sale_Unit_Price_Foreign, Count),
	Sale_Unit_Price_Foreign = value(End_Unit_Price_Unit, End_Unit_Price_Amount),
	Info = info(Investment_Currency, Unit, Opening_Unit_Cost_Converted, Opening_Unit_Cost_Foreign, Opening_Date),

	ir2_forex_gain(Exchange_Rates, Opening_Date, Sale_Unit_Price_Foreign, Sale_Date, Investment_Currency, Report_Currency, Count, Forex_Gain),
	ir2_market_gain(Exchange_Rates, Opening_Date, Sale_Date, Investment_Currency, Report_Currency, Count, Opening_Unit_Cost_Converted, End_Unit_Price_Unit, End_Unit_Price_Amount, Market_Gain),

	optional_currency_conversion(Exchange_Rates, Opening_Date, Investment_Currency, Report_Currency, Opening_Currency_Conversion),
	optional_currency_conversion(Exchange_Rates, Sale_Date, Investment_Currency, Report_Currency,
	Sale_Currency_Conversion),
	optional_converted_value(Sale_Unit_Price_Foreign, Sale_Currency_Conversion, Sale_Unit_Price_Converted),

	value_multiply(Opening_Unit_Cost_Foreign, Count, Opening_Total_Cost_Foreign),
	value_multiply(Opening_Unit_Cost_Converted, Count, Opening_Total_Cost_Converted),

	event(Opening0, Opening_Date, Opening_Unit_Cost_Foreign, Opening_Currency_Conversion, Opening_Unit_Cost_Converted, Opening_Total_Cost_Foreign, Opening_Total_Cost_Converted),
	(Clipped = clipped	->
		(Opening = Opening0, Purchase = _{})
	;	(Opening = _{},	Purchase = Opening0)),		
	event(Sale, Sale_Date, Sale_Unit_Price_Foreign, Sale_Currency_Conversion, Sale_Unit_Price_Converted, '', ''),
	Row = _{
		unit: Unit, count: Count, investment_currency: Investment_Currency,
		opening: Opening, purchase: Purchase, sale: Sale,
		gains: _{unr: _{}, rea: _{market: Market_Gain, forex: Forex_Gain}},
		closing: _{}
	).

		
investment_report_2_unrealized(Static_Data, Investment, Row) :-
	
	End_Date = Static_Data.end_date,
	Exchange_Rates = Static_Data.exchange_rates,
	Report_Currency = Static_Data.report_currency,
	Cost_Or_Market = Static_Data.cost_or_market,
	Investment = investment_report_item(unr, Info, Count, [], Clipped),
	Info = info(Investment_Currency, Unit, Opening_Unit_Cost_Converted, Opening_Unit_Cost_Foreign, Opening_Date),


	exchange_rate_throw(Exchange_Rates, End_Date, Unit, Investment_Currency, _),
	(
		Cost_Or_Market = cost
	->
		vec_change_bases(Exchange_Rates, End_Date, [Investment_Currency], 
			[coord(with_cost_per_unit(Unit, Opening_Unit_Cost_Converted), 1, 0)],
			End_Unit_Price_Coord
		)
	;
		vec_change_bases(Exchange_Rates, End_Date, [Investment_Currency], 
			[coord(Unit, 1, 0)],
			End_Unit_Price_Coord
		)		
	),
	End_Unit_Price_Unit = Investment_Currency,
	number_vec(End_Unit_Price_Unit, End_Unit_Price_Amount, End_Unit_Price_Coord),
	
	ir2_forex_gain(Exchange_Rates, Opening_Date, value(End_Unit_Price_Unit, End_Unit_Price_Amount), End_Date, Investment_Currency, Report_Currency, Count, Forex_Gain),
	ir2_market_gain(Exchange_Rates, Opening_Date, End_Date, Investment_Currency, Report_Currency, Count, Opening_Unit_Cost_Converted, End_Unit_Price_Unit, End_Unit_Price_Amount, Market_Gain),

	optional_currency_conversion(Exchange_Rates, Opening_Date, Investment_Currency, Report_Currency, Opening_Currency_Conversion),
	optional_currency_conversion(Exchange_Rates, End_Date, Investment_Currency, Report_Currency, Closing_Currency_Conversion),
	exchange_rate_throw(Exchange_Rates, End_Date, Unit, Investment_Currency, Closing_Unit_Price_Foreign_Amount),
	Closing_Unit_Price_Foreign = value(Investment_Currency, Closing_Unit_Price_Foreign_Amount),
	Investment_Currency_Current_Market_Value_Amount is Count * Closing_Unit_Price_Foreign_Amount,
	Investment_Currency_Current_Market_Value = value(Investment_Currency, Investment_Currency_Current_Market_Value_Amount),
	[Report_Currency_Unit] = Report_Currency,
	exchange_rate_throw(Exchange_Rates, End_Date, Unit, Report_Currency_Unit, Closing_Unit_Price_Converted_Amount),
	Current_Market_Value_Amount is Count * Closing_Unit_Price_Converted_Amount,
	Current_Market_Value = value(Report_Currency_Unit, Current_Market_Value_Amount),
	optional_converted_value(Closing_Unit_Price_Foreign, Closing_Currency_Conversion, Closing_Unit_Price_Converted),

	value_multiply(Opening_Unit_Cost_Foreign, Count, Opening_Total_Cost_Foreign),
	value_multiply(Opening_Unit_Cost_Converted, Count, Opening_Total_Cost_Converted),
	Unr_Market_Explanation = 




	event(Opening0, Opening_Date, Opening_Unit_Cost_Foreign, Opening_Currency_Conversion, Opening_Unit_Cost_Converted, Opening_Total_Cost_Foreign, Opening_Total_Cost_Converted),
	(Clipped = clipped	->
		(Opening = Opening0, Purchase = _{})
	;	(Opening = _{},	Purchase = Opening0)),		
	event(Closing, Closing_Unit_Price_Foreign, Closing_Currency_Conversion, Closing_Unit_Price_Converted, Investment_Currency_Current_Market_Value, Current_Market_Value),
	Row = _{
		unit: Unit, count: Count, investment_currency: Investment_Currency,
		opening: Opening, purchase: Purchase, sale: _{},
		gains: _{rea: _{}, unr: _{market: Market_Gain, forex: Forex_Gain}},
		closing: Closing
	).

		
table_to_html(
	Table, 
	[
		Table.title, ':',
		br([]),
		HTML_Table
	]
) :-
	format_table(Table, Formatted_Table),
	table_contents_to_html(Formatted_Table, HTML_Table).

table_contents_to_html(
	table{title:_, columns: Columns, rows: Rows},
	table([border="1"],[HTML_Header | HTML_Rows])
) :-
	% make HTML Header
	maplist(
		[Column,Header_Cell]>>(Header_Cell is td(Column.title)), 
		Columns, 
		Header_Cells
	),
	/*
	findall(
		td(Header_Value),
		(
			member(Column, Columns),
			Header_Value = Column.title
		),
		Header_Cells
	),
	*/

	HTML_Header = tr(Header_Cells),

	% make HTML Rows 
	% maplist ?
	findall(
		tr(HTML_Row),
		(
			member(Row,Rows),
			findall(
				td(Cell),
				(
					member(Column, Columns),
					Cell = Row.(Column.id)
				),
				HTML_Row
			)
		),
		HTML_Rows
	).

format_table(
	table{title:Title, columns:Columns, rows:Rows}, 
	table{title:Title, columns:Columns, rows:Formatted_Rows}
) :-
	maplist(format_row(Columns),Rows,Formatted_Rows).

format_row(Columns, Row, Formatted_Row) :-
	findall(
		Column_Id:Formatted_Cell,
		(
			member(Column, Columns),
			Column_Id = Column.id
			format_cell(Row.Column_Id, Column.options, Formatted_Cell)
		),
		Formatted_Row_KVs
	),
	dict_create(Formatted_Row,row,Formatted_Row_KVs).




investment_report_2_columns :-
	Unit_Columns = [
		column{id:unit, title:"Unit", options:_{}},
		column{id:count, title:"Count", options:_{}},
		column{id:currency, title:"Investment Currency", options:_{}}
	]

	Event_Details = [
		column{id:date, title:"Date", options:_{}},
		column{id:unit_cost_foreign, title:"Unit Cost Foreign", options:_{}},
		column{id:conversion, title:"Conversion", options:_{}},
		column{id:unit_cost_converted, title:"Unit Cost Converted", options:_{}},
		column{id:total_cost_foreign, title:"Total Cost Foreign", options:_{}},
		column{id:total_cost_converted, title:"Total Cost Converted", options:_{}}
	],

	Event_Groups = [ 
		group{id:purchase, title:"Purchase", members:Event_Details},
		group{id:opening, title:"Opening", members:Event_Details},
		group{id:sale, title:"Sale", members:Event_Details},
		group{id:closing, title:"Closing", members:Event_Details}
	],

	flatten_columns(Event_Groups, Event_Columns),

	Gains_Details = [
		column{id:market, title:"Market Gain", options:_{}},
		column{id:forex, title:"Forex Gain", options:_{}}
	],

	Gains_Groups = [
		group{id:realized, title:"Realized", members:Gains_Details},
		group{id:unrealized, title:"Unrealized", members:Gains_Details}
	],

	flatten_columns(Gains_Groups, Gains_Columns),

	flatten([Unit_Columns, Event_Columns, Gains_Columns], Report_Columns).


flatten_groups(Groups, Columns) :-
	findall(
		Group_Columns,
		(
			member(Group, Groups),
			group_columns(Group, Group_Columns)
		),
		Columns_Nested
	),
	flatten(Columns_Nested, Columns).

group_columns(
	group{id:Group_ID, title:Group_Title, members:Group_Members},
	Group_Columns
) :-
	findall(
		column{
			id:Group_ID/Member_ID,
			title:Column_Title,
			options:Options
		},
		(
			member(column{id:Member_ID, title:Member_Title, options:Options}, Group_Members),
			atomics_to_string([Group_Title, Member_Title], " ", Column_Title),
		),
		Group_Columns
	).

	
ir2_row_to_html(Report_Currency, Row, Html) :-
	/*
		Rea_Market_Gain, Rea_Forex_Gain, Unr_Market_Gain, Unr_Forex_Gain, 
	*/

	Row = row(
		Unit, Count, Investment_Currency, 

 		Purchase_Data, Opening_Data,
		Sale_Data
		
		Gains_Data

		Closing_Data
		),
	
	/*
	date(...)
	value(...)
	exchange_rate(...)
	or plain atom -> pass through
	*/
	format_date(Opening_Date, Opening_Date2),
	format_money_precise(Report_Currency, Opening_Unit_Cost_Foreign, Opening_Unit_Cost_Foreign2),
	format_conversion(Report_Currency, Opening_Conversion, Opening_Conversion2),
	format_money_precise(Report_Currency, Opening_Unit_Cost_Converted, Opening_Unit_Cost_Converted2),
	format_money(Report_Currency, Opening_Total_Cost_Foreign, Opening_Total_Cost_Foreign2),
	format_money(Report_Currency, Opening_Total_Cost_Converted, Opening_Total_Cost_Converted2),

	(Sale_Date = '' -> Sale_Date2 = '' ; format_date(Sale_Date, Sale_Date2)),
	format_money_precise(Report_Currency, Sale_Unit_Price_Foreign, Sale_Unit_Price_Foreign2),
	format_conversion(Report_Currency, Sale_Conversion, Sale_Conversion2),
	format_money_precise(Report_Currency, Sale_Unit_Price_Converted, Sale_Unit_Price_Converted2),
		
	format_money(Report_Currency, Rea_Market_Gain, Rea_Market_Gain2),
	format_money(Report_Currency, Rea_Forex_Gain, Rea_Forex_Gain2),
	format_money(Report_Currency, Unr_Market_Gain, Unr_Market_Gain2),
	format_money(Report_Currency, Unr_Forex_Gain, Unr_Forex_Gain2),

	format_money_precise(Report_Currency, Closing_Unit_Price_Foreign, Closing_Unit_Price_Foreign2),
	format_conversion(Report_Currency, Closing_Currency_Conversion, Closing_Currency_Conversion2),
	format_money_precise(Report_Currency, Closing_Unit_Price_Converted, Closing_Unit_Price_Converted2),

	format_money(Report_Currency, Closing_Market_Value_Foreign, Closing_Market_Value_Foreign2),
	format_money(Report_Currency, Closing_Market_Value_Converted, Closing_Market_Value_Converted2),
	
	% maplist td onto row data
	Html = tr([
		td(Unit), td(Count), td(Investment_Currency), 
		
		td(Opening_Date2), td(Opening_Unit_Cost_Foreign2), td(Opening_Conversion2), td(Opening_Unit_Cost_Converted2), td(Opening_Total_Cost_Foreign2), td(Opening_Total_Cost_Converted2),
		% todo purchase td(Opening_Date2), td(Opening_Unit_Cost_Foreign2), td(Opening_Conversion2), td(Opening_Unit_Cost_Converted2), td(Opening_Total_Cost_Foreign2), td(Opening_Total_Cost_Converted2),
		
		% probably use the same 6-items group:
		td(Sale_Date2), td(Sale_Unit_Price_Foreign2), td(Sale_Conversion2), td(Sale_Unit_Price_Converted2),
		
		td(Rea_Market_Gain2), td(Rea_Forex_Gain2), td(Unr_Market_Gain2), td(Unr_Forex_Gain2),		
		
		% could use the 6-item group here too
		td(Closing_Unit_Price_Foreign2), td(Closing_Currency_Conversion2), td(Closing_Unit_Price_Converted2),
		td(Closing_Market_Value_Foreign2), td(Closing_Market_Value_Converted2)]).
*/

format_cell(date(Date), Options, Output) :-
	!,
	format_date(Date, Output).

format_cell(value(Unit, Value), Options, Output) :-
	!,
	(
		Precision = Options.get(precision)
	->
		true
	;
		Precision = 2
	),
	format_money2(_, Precision, value(Unit, Value), Output).

format_cell(exchange_rate(Date, Src, Dst, Rate), Options, Output) :-
	!,
	format_conversion(_, exchange_rate(Date, Src, Dst, Rate), Output).

format_cell(Other, Options, Other).


format_money_precise(Optional_Implicit_Unit, In, Out) :-
	format_money2(Optional_Implicit_Unit, 6, In, Out).
	
format_money(Optional_Implicit_Unit, In, Out) :-
	format_money2(Optional_Implicit_Unit, 2, In, Out).

format_money2(_Optional_Implicit_Unit, Precision, In, Out) :-
	(
		In = ''
	->
		Out = ''
	;
		(
			In = value(Unit1,X)
		->
			true
		;
			(
				X = In,
				Unit1 = '?'
			)
		),
		(
			false%member(Unit1, Optional_Implicit_Unit)
		->
			Unit2 = ''
		;
			Unit2 = Unit1
		),
		atomic_list_concat(['~',Precision,':f~w'], Format_String),
		format(string(Out), Format_String, [X, Unit2])
	).
	
optional_currency_conversion(Exchange_Rates, Date, Src, Optional_Dst, Conversion) :-
	(
		(
			[Dst] = Optional_Dst,
			exchange_rate(Exchange_Rates, Date, Src, Dst, Rate)
		)
	->
		Conversion = exchange_rate(Date, Src, Dst, Rate)
	;
		Conversion = ''
	).

format_conversion(_Report_Currency, '', '').
	
format_conversion(_Report_Currency, Conversion, String) :-
	Conversion = exchange_rate(_, Src, Dst, Rate),
	Inverse is 1 / Rate,
	format(string(String), '1~w=~6:f~w', [Dst, Inverse, Src]). 
	%pretty_term_string(Conversion, String).

optional_converted_value(V1, C, V2) :-
	(
		C = ''
	->
		V2 = ''
	;
		value_convert(V1, C, V2)
	).


ir2_forex_gain(Exchange_Rates, Opening_Date, End_Price, End_Date, Investment_Currency, Report_Currency, Count, Gain) :-
	End_Price = value(End_Unit_Price_Unit, End_Unit_Price_Amount),
	%(End_Unit_Price_Unit == Investment_Currency ->true;(gtrace,true)),
	(
		End_Unit_Price_Unit = Investment_Currency
	->
		true
	;
		throw_string("exchange rate missing")
	),
	% old investment currency rate to report currency
	Market_Price_Unit = without_currency_movement_against_since(
		End_Unit_Price_Unit, Investment_Currency, Report_Currency, Opening_Date
	),
	
	(
		Report_Currency = [Report_Currency_Unit]
	->
		(
			/*
			the vec_change_bases here silently fails now. when we also add "at cost" logic, it might be even less clean to obtain the exchange rate manually..
			vec_add([coord(End_Unit_Price_Unit, End_Unit_Price_Amount, 0)], 
			*/
			exchange_rate_throw(Exchange_Rates, End_Date, Market_Price_Unit, Report_Currency_Unit, _),
			vec_change_bases(Exchange_Rates, End_Date, Report_Currency, 
				[
					% unit price in investment currency
					coord(End_Unit_Price_Unit, End_Unit_Price_Amount, 0),
					% unit price in investment currency with old exchange rate
					coord(Market_Price_Unit, 0, End_Unit_Price_Amount)
				],
				% forex gain, in report currency, on one investment unit between start and end dates
				Forex_Gain_Vec
			),
			number_vec(Report_Currency_Unit, Forex_Gain_Amount, Forex_Gain_Vec),
			Forex_Gain_Amount_Total is Forex_Gain_Amount * Count,
			Gain = value(Report_Currency_Unit, Forex_Gain_Amount_Total)
		)
	;
		Gain = ''
	).

ir2_market_gain(Exchange_Rates, Opening_Date, End_Date, Investment_Currency, Report_Currency, Count, Opening_Unit_Cost_Converted, End_Unit_Price_Unit, End_Unit_Price_Amount, Gain) :-
	Market_Price_Unit = without_currency_movement_against_since(
		End_Unit_Price_Unit, Investment_Currency, Report_Currency, Opening_Date
	),
	Report_Currency = [Report_Currency_Unit],
	exchange_rate_throw(Exchange_Rates, End_Date, Market_Price_Unit, Report_Currency_Unit, End_Market_Price_Rate),
	End_Market_Price_Amount_Converted is End_Unit_Price_Amount * End_Market_Price_Rate,
	End_Market_Unit_Price_Converted = value(Report_Currency_Unit, End_Market_Price_Amount_Converted),
	value_multiply(End_Market_Unit_Price_Converted, Count, End_Total_Price_Converted),
	value_multiply(Opening_Unit_Cost_Converted, Count, Opening_Total_Cost_Converted),
	value_subtract(End_Total_Price_Converted, Opening_Total_Cost_Converted, Gain).

	
clip_investments(Static_Data, (Outstanding_In, Investments_In), Realized_Investments, Unrealized_Investments) :-
	findall(
		I,
		(
			(
				member((O, Investment_Id), Outstanding_In),
				outstanding_goods_count(O, Count),
				Count =\= 0,
				nth0(Investment_Id, Investments_In, investment(Info1, _Sales)),
				Info1 = outstanding(Investment_Currency, Unit, _, Purchase_Unit_Cost_Converted, Purchase_Unit_Cost_Foreign, Purchase_Date),
				Info2 = info(Investment_Currency, Unit, Purchase_Unit_Cost_Converted, Purchase_Unit_Cost_Foreign, Purchase_Date),
				I = (unr, Info2, Count, [])
			)
			;
			(
				member(investment(Info1, Sales), Investments_In),
				Info1 = outstanding(Investment_Currency, Unit, _, Purchase_Unit_Cost_Converted, Purchase_Unit_Cost_Foreign, Purchase_Date),
				Info2 = info(Investment_Currency, Unit, Purchase_Unit_Cost_Converted, Purchase_Unit_Cost_Foreign, Purchase_Date),
				I = (rea, Info2, 0, Sales)
				
			)
		),
		Investments1
	),
	maplist(filter_investment_sales(Static_Data), Investments1, Investments2),
	exclude(irrelevant_investment(Static_Data), Investments2, Investments3),

	maplist(clip_investment(Static_Data), Investments3, Investments4),
	findall(I, (member(I, Investments4), investment_report_item_type(I,unr)), Unrealized_Investments),
	findall(I, (member(I, Investments4), investment_report_item_type(I,rea)), Realized_Investments)
	%,print_term(clip_investments(Outstanding_In, Investments_In, Realized_Investments, Unrealized_Investments),[])
	.

/*
	
*/	
filter_investment_sales(Static_Data, I1, I2) :-
	dict_vars(Static_Data, [Start_Date]),
	I1 = (Tag, Info, Outstanding_Count, Sales1),
	I2 = (Tag, Info, Outstanding_Count, Sales2),
	/*	everything's already clipped from the report end date side.
	filter out sales before report period. */
	exclude(sale_before(Start_Date), Sales1, Sales2).

irrelevant_investment(_Static_Data, I1) :-
	I1 = (Tag, _Info1, _Outstanding_Count, Sales),
	/*an unrealized investment has 0 sales. but a realized investment that we just filtered away all sales from does not belong in the report*/
	(
		Tag = unr
	->
		false
	;
		Sales = []
	).
	
clip_investment(Static_Data, I1, I2) :-
	Start_Date = Static_Data.start_date,
	Exchange_Rates = Static_Data.exchange_rates,
	Report_Currency = Static_Data.report_currency,
	%dict_vars(Static_Data, [Start_Date, Exchange_Rates, Report_Currency]),
	[Report_Currency_Unit] = Report_Currency,
	I1 = (Tag, Info1, Outstanding_Count, Sales),
	I2 = (Tag, Info2, Outstanding_Count, Sales, Clipped),
	Info1 = info(Investment_Currency, Unit, Purchase_Unit_Cost_Converted, Purchase_Unit_Cost_Foreign, Purchase_Date),
	Info2 = info(Investment_Currency, Unit, Opening_Unit_Cost_Converted, Opening_Unit_Cost_Foreign, Opening_Date),
	(
		Purchase_Date @>= Start_Date
	->
		(
			Opening_Unit_Cost_Foreign = Purchase_Unit_Cost_Foreign,
			Opening_Unit_Cost_Converted = Purchase_Unit_Cost_Converted,
			Opening_Date = Purchase_Date,
			Clipped = unclipped
		)
	;
		(
		/*	
			clip start date, adjust purchase price.
			the simplest case is when the price in purchase currency at report start date is specified by user.
		*/
			Opening_Date = Start_Date,
			exchange_rate_throw(Exchange_Rates, Opening_Date, Unit, Investment_Currency, Before_Opening_Exchange_Rate_Foreign),
			Opening_Unit_Cost_Foreign = value(Investment_Currency, Before_Opening_Exchange_Rate_Foreign),
			exchange_rate_throw(Exchange_Rates, Opening_Date, Unit, Report_Currency_Unit, Before_Opening_Exchange_Rate_Converted),			
			Opening_Unit_Cost_Converted = value(Report_Currency_Unit, Before_Opening_Exchange_Rate_Converted),
			Clipped = clipped
		)
	).

sale_before(Start_Date, sale(Date,_,_)) :- 
	Date @< Start_Date.

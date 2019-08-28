:- module(investment_report_2, [investment_report_2/5]).

:- use_module('tables').
:- use_module('utils').
:- use_module('days').
:- use_module('pricing').
:- use_module('report_page').
:- use_module('pacioli').
:- use_module('exchange').
:- use_module('exchange_rates').

:- use_module(library(record)).
:- use_module(library(rdet)).

:- rdet(investment_report_2_unrealized/3).
:- rdet(investment_report_2_sale_lines/4).
:- rdet(investment_report_2_sales/3).
:- rdet(investment_report_2/4).
:- rdet(ir2_forex_gain/8).
:- rdet(ir2_market_gain/10).
:- rdet(clip_investments/4).
:- rdet(filter_investment_sales/3).
:- rdet(clip_investment/3).
	

:- record ir_item(type, info, outstanding_count, sales, clipped).


event(Event, Date, Unit_Cost_Foreign, Currency_Conversion, Unit_Cost_Converted, Total_Cost_Foreign, Total_Cost_Converted) :-
	Event = _{
		date: Date, 
		unit_cost_foreign: Unit_Cost_Foreign, 
		conversion: Currency_Conversion, 
		unit_cost_converted: Unit_Cost_Converted, 
		total_cost_foreign: Total_Cost_Foreign, 
		total_cost_converted: Total_Cost_Converted
	}.



investment_report_2(Static_Data, Outstanding_In, Filename_Suffix, Report_Data, [Report_File_Info, Json_Filename:Json_Url]) :-
	
	Start_Date = Static_Data.start_date,
	End_Date = Static_Data.end_date,
	Report_Currency = Static_Data.report_currency,
	
	format_date(Start_Date, Start_Date_Atom),
	format_date(End_Date, End_Date_Atom),
	report_currency_atom(Report_Currency, Report_Currency_Atom),
	atomic_list_concat(['investment report from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ', Report_Currency_Atom], Title_Text),

	columns(Columns),
	rows(Static_Data, Outstanding_In, Rows),
	totals(Rows, Totals),
	flatten([Rows, Totals], Rows2),

	Table = _{title: Title_Text, rows: Rows2, columns: Columns},
	tables:table_html(Table, Html),

	atomic_list_concat(['investment_report', Filename_Suffix, '.html'], Filename),
	report_page(Title_Text, Html, Filename, Report_File_Info),
	
	atomic_list_concat(['investment_report', Filename_Suffix, '.json'], Json_Filename),
	dict_json_text(Table, Json_Text),
	report_item(Json_Filename, Json_Text, Json_Url),
	
	Report_Data = _{
		rows: Rows,
		totals: Totals
	}.

totals(Rows, Totals) :-
 	tables:table_totals(Rows, [gains/rea/market, gains/rea/forex, gains/unr/market, gains/unr/forex, closing/total_converted], Totals).
  	
columns(Columns) :-
	Unit_Columns = [
		column{id:unit, title:"Unit", options:_{}},
		column{id:count, title:"Count", options:_{}},
		column{id:currency, title:"Investment Currency", options:_{}}
	],

	Event_Details = [
		column{id:date, title:"Date", options:_{}},
		column{id:unit_cost_foreign, title:"Unit Cost Foreign", options:_{}},
		column{id:conversion, title:"Conversion", options:_{}},
		column{id:unit_cost_converted, title:"Unit Cost Converted", options:_{}},
		column{id:total_cost_foreign, title:"Total Cost Foreign", options:_{}},
		column{id:total_cost_converted, title:"Total Cost Converted", options:_{}}
	],

	Events = [ 
		group{id:purchase, title:"Purchase", members:Event_Details},
		group{id:opening, title:"Opening", members:Event_Details},
		group{id:sale, title:"Sale", members:Event_Details},
		group{id:closing, title:"Closing", members:Event_Details}
	],

	Gains_Details = [
		column{id:market, title:"Market Gain", options:_{}},
		column{id:forex, title:"Forex Gain", options:_{}}
	],

	Gains_Groups = [
		group{id:rea, title:"Realized", members:Gains_Details},
		group{id:unr, title:"Unrealized", members:Gains_Details}
	],

		
	Gains = [
		group{id:gains, title:"", members: Gains_Groups}],

	flatten([Unit_Columns, Events, Gains], Columns).



rows(Static_Data, Outstanding_In, Rows) :-
	clip_investments(Static_Data, Outstanding_In, Realized_Investments, Unrealized_Investments),
	maplist(investment_report_2_sales(Static_Data), Realized_Investments, Sale_Lines),
	maplist(investment_report_2_unrealized(Static_Data), Unrealized_Investments, Non_Sale_Lines),
	flatten([Sale_Lines, Non_Sale_Lines], Rows0),

	/* lets sort by unit, sale date, purchase date */

/*how to sort with nested dicts with optional keys?*/

	sort(unit, @=<, Rows0, Rows).

/*,
	sort([sale,date], @=<, Rows1, Rows2),
	sort([purchase,date], @=<, Rows2, Rows).*/


investment_report_2_sales(Static_Data, I, Lines) :-
	%print_term(I,[]),
	I = ir_item(rea, Info, 0, Sales, Clipped),
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

	value_multiply(Sale_Unit_Price_Foreign, Count, Sale_Total_Price_Foreign),
	value_multiply(Sale_Unit_Price_Converted, Count, Sale_Total_Price_Converted),

	event(Sale_Event, Sale_Date, Sale_Unit_Price_Foreign, Sale_Currency_Conversion, Sale_Unit_Price_Converted, Sale_Total_Price_Foreign, Sale_Total_Price_Converted),
	gensym(iri, Id),

	Row = _{
		id: Id,
		unit: Unit,
		count: Count,
		currency: Investment_Currency,
		opening: Opening,
		purchase: Purchase,
		sale: Sale_Event,
		gains: _{
			unr: _{},
			rea: _{
				market: Market_Gain,
				forex: Forex_Gain
			}
		},
		closing: _{}
	}.

		
investment_report_2_unrealized(Static_Data, Investment, Row) :-
	
	End_Date = Static_Data.end_date,
	Exchange_Rates = Static_Data.exchange_rates,
	Report_Currency = Static_Data.report_currency,
	Cost_Or_Market = Static_Data.cost_or_market,
	Investment = ir_item(unr, Info, Count, [], Clipped),
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

	/*Unr_Market_Explanation = */

	event(Opening0, Opening_Date, Opening_Unit_Cost_Foreign, Opening_Currency_Conversion, Opening_Unit_Cost_Converted, Opening_Total_Cost_Foreign, Opening_Total_Cost_Converted),

	(
		Clipped = clipped
	->
		(
			Opening = Opening0,
			Purchase = _{}
		)
	;	
		(
			Opening = _{},
			Purchase = Opening0
		)
	),		

	event(Closing, End_Date, Closing_Unit_Price_Foreign, Closing_Currency_Conversion, Closing_Unit_Price_Converted, Investment_Currency_Current_Market_Value, Current_Market_Value),
	gensym(iri, Id),

	Row = _{
		id: Id,
		unit: Unit,
		count: Count,
		currency: Investment_Currency,
		opening: Opening,
		purchase: Purchase,
		sale: _{},
		gains: _{
			rea: _{},
			unr: _{
				market: Market_Gain,
				forex: Forex_Gain
			}
		},
		closing: Closing
	}.

	
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


/*
ir2_row_to_html(Report_Currency, Row, Html) :-
	
	Row = row(Unit, Count, Investment_Currency, Purchase_Data, Opening_Data, Sale_Data, Gains_Data, Closing_Data),
	
	
	date(...)
	value(...)
	exchange_rate(...)
	or plain atom -> pass through
	
	  
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

ir2_market_gain(Exchange_Rates, Opening_Date, End_Date, Investment_Currency, Report_Currency, Count, Opening_Unit_Cost_Converted, Investment_Currency, End_Unit_Price_Amount, Gain) :-
	Report_Currency = [Report_Currency_Unit],
	Market_Price_Without_Movement_Unit = without_currency_movement_against_since(
		Investment_Currency, Investment_Currency, Report_Currency, Opening_Date),
	exchange_rate_throw(Exchange_Rates, End_Date, Market_Price_Without_Movement_Unit, Report_Currency_Unit, End_Market_Price_Rate),
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
	findall(I, (member(I, Investments4), ir_item_type(I,unr)), Unrealized_Investments),
	findall(I, (member(I, Investments4), ir_item_type(I,rea)), Realized_Investments)
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
	I2 = ir_item(Tag, Info2, Outstanding_Count, Sales, Clipped),
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



optional_converted_value(V1, C, V2) :-
	(
		C = ''
	->
		V2 = ''
	;
		value_convert(V1, C, V2)
	).

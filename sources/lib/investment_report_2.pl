

:- record ir_item(type, info, outstanding_count, sales, clipped).


 event_with_date(Event, Date, Unit_Cost_Foreign, Currency_Conversion, Unit_Cost_Converted, Total_Cost_Foreign, Total_Cost_Converted) :-
	Event = _{
		date: Date, 
		unit_cost_foreign: Unit_Cost_Foreign, 
		conversion: Currency_Conversion, 
		unit_cost_converted: Unit_Cost_Converted, 
		total_cost_foreign: Total_Cost_Foreign, 
		total_cost_converted: Total_Cost_Converted
	}.

 ir2_event(Event, Unit_Cost_Foreign, Currency_Conversion, Unit_Cost_Converted, Total_Cost_Foreign, Total_Cost_Converted, Date) :-
	Event = _{
		unit_cost_foreign: Unit_Cost_Foreign, 
		conversion: Currency_Conversion, 
		unit_cost_converted: Unit_Cost_Converted, 
		total_cost_foreign: Total_Cost_Foreign, 
		total_cost_converted: Total_Cost_Converted,
		date: Date

	}.


 investment_report_2_0(Static_Data, Filename_Suffix, Semantic_Json) :-
	format_date(Static_Data.start_date, Start_Date_Atom),
	format_date(Static_Data.end_date, End_Date_Atom),
	report_currency_atom(Static_Data.report_currency, Report_Currency_Atom),
	atomic_list_concat($>flatten(['investment report from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ',Report_Currency_Atom, $>report_details_text]), Title_Text),
	atomic_list_concat(['investment_report', Filename_Suffix, '.html'], Filename),
	atomic_list_concat(['investment_report', Filename_Suffix, '_html'], Key),
	atomic_list_concat(['investment_report', Filename_Suffix], Json_Filename),

	(	current_prolog_flag(die_on_error, true)
	->	investment_report_2_1(Static_Data, Semantic_Json, Html, Title_Text, Json_Filename)
	;	catch_with_backtrace(
			investment_report_2_1(Static_Data, Semantic_Json, Html, Title_Text, Json_Filename),
			E,
			(
				term_string(E, Msg),
				error_page_html(Msg, Html),
				handle_processing_exception2(E),
				%assert_alert('error', E),
				Semantic_Json = _{}
			)
		)
	),
	add_report_page(0, Title_Text, Html, loc(file_name,Filename), Key).

 investment_report_2_1(Static_Data, Semantic_Json, Html, Title_Text, Json_Filename) :-
	(Static_Data.report_currency = [_] -> true ;throw_string('investment report: report currency expected')),
	!investment_report_2(Static_Data, Semantic_Json, Table_Json, Html, Title_Text),
	make_json_report(Table_Json, Json_Filename).


 investment_report_2(Static_Data, Semantic_Json, Table_Json, Html, Title_Text) :-
	reset_gensym(iri),

	columns(Columns),
	rows(Static_Data, Static_Data.outstanding, Rows),
	totals(Rows, Totals),
	flatten([Rows, Totals], Rows2),

	Table_Json = _{title: Title_Text, rows: Rows2, columns: Columns},
	!table_html([highlight_totals - true], Table_Json, Table_Html),
	!page_with_table_html(Title_Text, Table_Html, Html),

	'table sheet'(Table_Json),

	Semantic_Json = _{
		rows: Rows,
		totals: Totals
	}.



 totals(Rows, Totals) :-
	/*these are computed automatically*/
 	table_totals(Rows,
	[
		gains/rea/market_foreign, gains/rea/market_converted, gains/rea/forex,
		gains/unr/market_foreign, gains/unr/market_converted, gains/unr/forex,
		opening/total_cost_foreign, opening/total_cost_converted,
		closing/total_cost_foreign, closing/total_cost_converted,
		on_hand_at_cost/total_converted_at_purchase,
		on_hand_at_cost/total_converted_at_balance,
		on_hand_at_cost/total_forex_gain
	], Totals0),
	/*these are not computed automatically*/
	Totals = Totals0.put(
		gains/realized_total, Realized_Total).put(
		gains/unrealized_total, Unrealized_Total).put(
		gains/total, Total),
	vec_add(Totals0.gains.rea.market_converted, Totals0.gains.rea.forex, Realized_Total),
	vec_add(Totals0.gains.unr.market_converted, Totals0.gains.unr.forex, Unrealized_Total),
	vec_add(Realized_Total, Unrealized_Total, Total).
  	


 columns(Columns) :-
	Unit_Columns = [
		column{id:unit, title:"Unit", options:_{}},
		column{id:count, title:"Count", options:_{}},
		column{id:currency, title:"Investment Currency", options:_{}}
	],

	Sale_Event_Details = [
		column{id:date, 						title:"Date", options:_{}},
		column{id:unit_cost_foreign, 			title:"Unit Cost Foreign", options:_{}},
		column{id:conversion, 					title:"Conversion", options:_{}},
		column{id:unit_cost_converted, 			title:"Unit Cost Converted", options:_{}},
		column{id:total_cost_foreign, 			title:"Total Cost Foreign", options:_{}},
		column{id:total_cost_converted, 		title:"Total Cost Converted", options:_{}}
	],

	/*fixme, these column names shouldn't be _cost_ but _value_ */
	(	at_cost
	->	(
			Market_Event_Details = [
				column{id:date, 					title:"Date", options:_{}},
				column{id:unit_cost_foreign, 		title:"Unit Value Foreign", options:_{}},
				column{id:conversion, 				title:"Conversion", options:_{}},
				column{id:unit_cost_converted, 		title:"Unit Value Converted", options:_{}},
				column{id:total_cost_foreign, 		title:"Total Value Foreign", options:_{}},
				column{id:total_cost_converted, 	title:"Total Value Converted", options:_{}}
			]
		)
	;	(
			Market_Event_Details = [
				column{id:date, 					title:"Date", options:_{}},
				column{id:unit_cost_foreign, 		title:"Unit Market Value Foreign", options:_{}},
				column{id:conversion, 				title:"Conversion", options:_{}},
				column{id:unit_cost_converted, 		title:"Unit Market Value Converted", options:_{}},
				column{id:total_cost_foreign, 		title:"Total Market Value Foreign", options:_{}},
				column{id:total_cost_converted, 	title:"Total Market Value Converted", options:_{}}
			]
		)
	),

	On_Hand_At_Cost_Details = [
		column{id:unit_cost_foreign, 			title:"Foreign Per Unit", options:_{}},
		column{id:count, 						title:"Count", options:_{}},
		column{id:total_foreign, 				title:"Foreign Total", options:_{}},
		column{id:total_converted_at_purchase, 	title:"Converted at Purchase Date Total", options:_{}},
		column{id:total_converted_at_balance, 	title:"Converted at Balance Date Total", options:_{}},
		column{id:total_forex_gain, 			title:"Currency Gain/(loss) Total", options:_{}}
	],

/*options:_{hide_group_prefix:true}*/
/*On Hand at Cost ((converted at balance date), Unrealised Currency Gain/Loss between Cost at Purchase Date and Cost at Report Date*/
/*group{id:on_hand_at_cost, title:"On Hand At Cost Per Unit", members:On_Hand_At_Cost_Per_Unit_Details},
column{id:count, title:"Count", options:_{}},
group{id:on_hand_at_cost, title:"On Hand At Cost Total", members:On_Hand_At_Cost_Total_Details},*/

	Events = [
		/*trade?*/
		group{id:purchase, title:"Purchase", members:Sale_Event_Details},
		/*checkpoint?*/
		group{id:opening, title:"Opening", members:Market_Event_Details},
		group{id:sale, title:"Sale", members:Sale_Event_Details},
		group{id:closing, title:"Closing", members:Market_Event_Details},
		group{id:on_hand_at_cost, title:"On Hand At Cost", members:On_Hand_At_Cost_Details}
	],

	Gains_Details = [
		column{id:market_foreign, title:"Market Gain Foreign", options:_{}},
		column{id:market_converted, title:"Market Gain Converted", options:_{}},
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
	/*,todo? see also: https://github.com/lodgeit-labs/accounts-assessor/issues/50
	sort([sale,date], @=<, Rows1, Rows2),
	sort([purchase,date], @=<, Rows2, Rows).*/


 investment_report_2_sales(Static_Data, I, Lines) :-
	%print_term(I,[]),
	I = ir_item(rea, Info, 0, Sales, Clipped),
	maplist(investment_report_2_sale_lines(Static_Data, Info, Clipped), Sales, Lines).


 investment_report_2_sale_lines(Static_Data, Info, Clipped, Sale, Row) :-
	push_format('process sale: investment(~q), sale(~q)', [Info, Sale]),
	dict_vars(Static_Data, [Exchange_Rates, Report_Currency]),
	Sale = sale(Sale_Date, Sale_Unit_Price_Foreign, Count),
	Info = info2(Investment_Currency, Unit, Opening_Unit_Cost_Converted, Opening_Unit_Cost_Foreign, Opening_Date, _),
	
	value(End_Unit_Price_Unit, End_Unit_Price_Amount) = Sale_Unit_Price_Foreign,
	
	ir2_forex_gain(Exchange_Rates, Opening_Date, Sale_Unit_Price_Foreign, Sale_Date, Investment_Currency, Report_Currency, Count, Forex_Gain),
	ir2_market_gain(Exchange_Rates, Opening_Date, Sale_Date, Investment_Currency, Report_Currency, Count, Opening_Unit_Cost_Converted, End_Unit_Price_Unit, End_Unit_Price_Amount, Market_Gain),

	optional_currency_conversion(Exchange_Rates, Opening_Date, Investment_Currency, Report_Currency, Opening_Currency_Conversion),
	optional_currency_conversion(Exchange_Rates, Sale_Date, Investment_Currency, Report_Currency,
	Sale_Currency_Conversion),
	optional_converted_value(Sale_Unit_Price_Foreign, Sale_Currency_Conversion, Sale_Unit_Price_Converted),

	value_multiply(Opening_Unit_Cost_Foreign, Count, Opening_Total_Cost_Foreign),
	value_multiply(Opening_Unit_Cost_Converted, Count, Opening_Total_Cost_Converted),

	!ir2_event(
		Opening0,
		Opening_Unit_Cost_Foreign,
		Opening_Currency_Conversion,
		Opening_Unit_Cost_Converted,
		Opening_Total_Cost_Foreign,
		Opening_Total_Cost_Converted,
		Opening_Date),

	clippage(Clipped,Opening0,Opening,Purchase),

	value_multiply(Sale_Unit_Price_Foreign, Count, Sale_Total_Price_Foreign),
	value_multiply(Sale_Unit_Price_Converted, Count, Sale_Total_Price_Converted),

	event_with_date(Sale_Event, Sale_Date, Sale_Unit_Price_Foreign, Sale_Currency_Conversion, Sale_Unit_Price_Converted, Sale_Total_Price_Foreign, Sale_Total_Price_Converted),

	value_subtract(Sale_Total_Price_Foreign, Opening_Total_Cost_Foreign, Market_Gain_Foreign),

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
				market_foreign: Market_Gain_Foreign,
				market_converted: Market_Gain,
				forex: Forex_Gain
			}
		},
		closing: _{}
	},

	pop_format.


		
 investment_report_2_unrealized(Static_Data, Investment, Row) :-
	push_format('process unrealized investment: ~q', [Investment]),

	End_Date = Static_Data.end_date,
	Exchange_Rates = Static_Data.exchange_rates,
	Report_Currency = Static_Data.report_currency,
	[Report_Currency_Unit] = Report_Currency,

	Investment = ir_item(unr, Info, Count, [], Clipped),
	Info = info2(Investment_Currency, Unit_Name, Opening_Unit_Cost_Converted, Opening_Unit_Cost_Foreign, Opening_Date, Original_Purchase_Info),

	(	at_cost
	->	Unit = with_cost_per_unit(Unit_Name, Opening_Unit_Cost_Foreign)
	;	Unit = Unit_Name),

	exchange_rate_throw(Exchange_Rates, End_Date, Unit, Investment_Currency, _),
	vec_change_bases(Exchange_Rates, End_Date, [Investment_Currency],
		[coord(Unit, 1)],
		End_Unit_Price_Coord
	),

	exchange_rate_throw(Exchange_Rates, End_Date, Unit, Report_Currency_Unit, Closing_Unit_Price_Converted_Amount),

	End_Unit_Price_Unit = Investment_Currency,
	number_vec(End_Unit_Price_Unit, End_Unit_Price_Amount, End_Unit_Price_Coord),

	ir2_forex_gain(Exchange_Rates, Opening_Date, value(End_Unit_Price_Unit, End_Unit_Price_Amount), End_Date, Investment_Currency, Report_Currency, Count, Forex_Gain),
	ir2_market_gain(Exchange_Rates, Opening_Date, End_Date, Investment_Currency, Report_Currency, Count, Opening_Unit_Cost_Converted, End_Unit_Price_Unit, End_Unit_Price_Amount, Market_Gain),
	optional_currency_conversion(Exchange_Rates, Opening_Date, Investment_Currency, Report_Currency, Opening_Currency_Conversion),
	optional_currency_conversion(Exchange_Rates, End_Date, Investment_Currency, Report_Currency, Closing_Currency_Conversion),

	Closing_Unit_Price_Foreign_Amount = End_Unit_Price_Amount,

	Closing_Unit_Price_Foreign = value(Investment_Currency, Closing_Unit_Price_Foreign_Amount),
	{Investment_Currency_Current_Market_Value_Amount = Count * Closing_Unit_Price_Foreign_Amount},
	Investment_Currency_Current_Market_Value = value(Investment_Currency, Investment_Currency_Current_Market_Value_Amount),
	[Report_Currency_Unit] = Report_Currency,

	{Current_Market_Value_Amount = Count * Closing_Unit_Price_Converted_Amount},
	Current_Market_Value = value(Report_Currency_Unit, Current_Market_Value_Amount),

	optional_converted_value(Closing_Unit_Price_Foreign, Closing_Currency_Conversion, Closing_Unit_Price_Converted),

	value_multiply(Opening_Unit_Cost_Foreign, Count, Opening_Total_Cost_Foreign),
	value_multiply(Opening_Unit_Cost_Converted, Count, Opening_Total_Cost_Converted),

	!ir2_event(Opening0, Opening_Unit_Cost_Foreign, Opening_Currency_Conversion, Opening_Unit_Cost_Converted, Opening_Total_Cost_Foreign, Opening_Total_Cost_Converted, Opening_Date),

	clippage(Clipped,Opening0,Opening,Purchase),

	!ir2_event(Closing, Closing_Unit_Price_Foreign, Closing_Currency_Conversion, Closing_Unit_Price_Converted, Investment_Currency_Current_Market_Value, Current_Market_Value, End_Date),

	value_subtract(Investment_Currency_Current_Market_Value, Opening_Total_Cost_Foreign, Market_Gain_Foreign),

	gensym(iri, Id),

	Row = _{
		id: Id,
		unit: Unit_Name,
		count: Count,
		currency: Investment_Currency,
		opening: Opening,
		purchase: Purchase,
		sale: _{},
		gains: _{
			rea: _{},
			 unr: _{
				market_foreign: Market_Gain_Foreign,
				market_converted: Market_Gain,
				forex: Forex_Gain
			}
		},
		closing: Closing,
		on_hand_at_cost: On_Hand_At_Cost
	},

	Original_Purchase_Info = original_purchase_info(Original_Purchase_Unit_Cost_Converted, Original_Purchase_Unit_Cost_Foreign, _Original_Purchase_Date),
	value_multiply(Original_Purchase_Unit_Cost_Foreign, Count, Original_Purchase_Total_Cost_Foreign),
	value_multiply(Original_Purchase_Unit_Cost_Converted, Count, Original_Purchase_Total_Cost_Converted),
	On_Hand_At_Cost = _{
		unit_cost_foreign: Original_Purchase_Unit_Cost_Foreign,
		count: Count,
		total_foreign: Original_Purchase_Total_Cost_Foreign,
		total_converted_at_purchase: Original_Purchase_Total_Cost_Converted,
		total_converted_at_balance: Original_Purchase_Total_Cost_Converted_At_Balance,
		total_forex_gain: Total_At_Cost_Forex_Gain
	},

	optional_converted_value(Original_Purchase_Total_Cost_Foreign, Closing_Currency_Conversion, Original_Purchase_Total_Cost_Converted_At_Balance),
	
	value_subtract(Original_Purchase_Total_Cost_Converted_At_Balance, Original_Purchase_Total_Cost_Converted, Total_At_Cost_Forex_Gain),

	pop_format.



 clippage(Clipped,Opening0,Opening,Purchase) :-
	(	Clipped = clipped
	->	(
			Opening = Opening0,
			Purchase = _{}
		)
	;
		(
			Opening = _{},
			Purchase = Opening0
		)
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



 ir2_forex_gain(Exchange_Rates, Opening_Date, End_Price, End_Date, Investment_Currency, Report_Currency, Count, Gain) :-
	End_Price = value(End_Unit_Price_Unit, End_Unit_Price_Amount),
	%(End_Unit_Price_Unit == Investment_Currency ->true;(g trace,true)),
	(
		End_Unit_Price_Unit = Investment_Currency
	->
		true
	;
		throw_format("investment is traded against different currency (~w) than specified (~w).",[End_Unit_Price_Unit, Investment_Currency])
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
			credit_coord(Market_Price_Unit, End_Unit_Price_Amount, Coord_X1),
			vec_change_bases(Exchange_Rates, End_Date, Report_Currency, 
				[
					% unit price in investment currency
					coord(End_Unit_Price_Unit, End_Unit_Price_Amount),
					% unit price in investment currency with old exchange rate
					Coord_X1
				],
				% forex gain, in report currency, on one investment unit between start and end dates
				Forex_Gain_Vec
			),
			number_vec(Report_Currency_Unit, Forex_Gain_Amount, Forex_Gain_Vec),
			{Forex_Gain_Amount_Total = Forex_Gain_Amount * Count},
			Gain = value(Report_Currency_Unit, Forex_Gain_Amount_Total)
		)
	;
		Gain = ''
	).



 ir2_market_gain(Exchange_Rates, Opening_Date, End_Date, Investment_Currency, Report_Currency, Count, Opening_Unit_Cost_Converted, Investment_Currency, End_Unit_Price_Amount, Gain
) :-
	Report_Currency = [Report_Currency_Unit],
	Market_Price_Without_Movement_Unit = without_currency_movement_against_since(
		Investment_Currency, Investment_Currency, Report_Currency, Opening_Date),
	exchange_rate_throw(Exchange_Rates, End_Date, Market_Price_Without_Movement_Unit, Report_Currency_Unit, End_Market_Price_Rate),
	{End_Market_Price_Amount_Converted = End_Unit_Price_Amount * End_Market_Price_Rate},
	End_Market_Unit_Price_Converted = value(Report_Currency_Unit, End_Market_Price_Amount_Converted),

	value_multiply(End_Market_Unit_Price_Converted, Count, End_Total_Price_Converted),
	value_multiply(Opening_Unit_Cost_Converted, Count, Opening_Total_Cost_Converted),
	value_subtract(End_Total_Price_Converted, Opening_Total_Cost_Converted, Gain).

	
 clip_investments(Static_Data, Oust, Realized_Investments, Unrealized_Investments) :-
 	Oust = (Outstanding_In, Investments_In),

	findall(
		I,
		(
			all_unrealized(Outstanding_In, Investments_In, I)
		;
			all_realized(Investments_In, I)
		),
		Investments1
	),

	maplist(filter_investment_sales(Static_Data), Investments1, Investments2),
	exclude(irrelevant_investment(Static_Data), Investments2, Investments3),

	maplist(clip_investment(Static_Data), Investments3, Investments4),
	findall(I, (member(I, Investments4), ir_item_type(I,unr)), Unrealized_Investments),
	findall(I, (member(I, Investments4), ir_item_type(I,rea)), Realized_Investments).



 all_unrealized(Outstanding_In, Investments_In, I) :-
	member((O, Investment_Id), Outstanding_In),
	outstanding_goods_count(O, Count),
	Count =\= 0,
	nth0(Investment_Id, Investments_In, investment(Info1, _Sales)),

	/*just re-pack outstanding() into info(), omitting Goods_Count */
	Info1 = outstanding(Investment_Currency, Unit, _, Purchase_Unit_Cost_Converted, Purchase_Unit_Cost_Foreign, Purchase_Date),
	Info2 = info(Investment_Currency, Unit, Purchase_Unit_Cost_Converted, Purchase_Unit_Cost_Foreign, Purchase_Date),

	I = (unr, Info2, Count, []).



 all_realized(Investments_In, I) :-
	member(investment(Info1, Sales), Investments_In),
	Info1 = outstanding(Investment_Currency, Unit, _, Purchase_Unit_Cost_Converted, Purchase_Unit_Cost_Foreign, Purchase_Date),
	Info2 = info(Investment_Currency, Unit, Purchase_Unit_Cost_Converted, Purchase_Unit_Cost_Foreign, Purchase_Date),
	I = (rea, Info2, 0, Sales).



/*filter out sales that happened before report period start. */
 filter_investment_sales(Static_Data, I1, I2) :-
	dict_vars(Static_Data, [Start_Date]),
	I1 = (Tag, Info, Outstanding_Count, Sales1),
	I2 = (Tag, Info, Outstanding_Count, Sales2),
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



/*
dimensional analysis notes:

		* Closing_Unit_Price_Foreign : Foreign/Unit
			* Foreign^1 * Unit^-1
			* {
				"foreign": 1,
				"unit": -1
			  }
			* semantic_thing(..)
		* Closing_Currency_Conversion : Report/Foreign
			* exchange_rate(Report/Foreign)
		* Closing_Unit_Price_Converted : Report/Unit
			
		m/s
		m^2

		5m + 10m
		m + m  <-- pure dimensional arithmetic
		5m * 10m <-- vs. quantity arithmetic
		m*m = m^2 = Area
		5m * 2s 
		5m / 2s 
		5m + 2s <-- nope
		5minutes + 2seconds ? <-- yep, because they're both just units of time dimension
		5apples + 4 oranges ? <-- maybe?
			* if there's a common conversion into some dimension?
			* ex. you have 9 fruits..

		dimensions: ex time, mass, length				
		units: ex. minutes, kilograms, feet				<--
		quantities: 5 minutes, 10 kilograms, 8 feet		<-- these two levels well worked out in the Python

		Given:
		60 seconds / minute
		60 minutes / hour
		24 hours / day

		How many seconds in a day...
		
		There are also explicitly dimensionless quantities...
		* haven't had to actually deal w/ this yet
		
		(Count : Unit) * (Price : Currency/Unit) = (Price * Count) : Currency

		Can read the units directly out of the quantity for reporting purposes and potentially for automatically figuring out calculations
			like w/ the seconds -> days conversion, etc...
	

		r1: market value today
		r2: contract rate
		r3: market value at contract maturity

		r1 USD/AUD today


		in the future:
		contract rate: r2 USD/AUD

		but the market value in the future might be r3

		r2 vs r3 is "the spread" <-- definitely a factor in gains
		but i'm not sure about r1

		r4 : virtual rate computed from the price gotten at selling the contract(?)


*/


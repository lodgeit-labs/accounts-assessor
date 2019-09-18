




gains_formulas(X.unrealized),



market_gain_formulas([
		start_currency_conversion = conversion_rate(investment_currency, report_currency, opening_date),
		end_currency_conversion = conversion_rate(investment_currency, report_currency, closing_date),
		opening_total_cost_converted = opening_unit_cost_converted * count,
		end_total_market_price_converted = end_market_price / end_currency_conversion * start_currency_conversion
		market_gain = end_total_market_price_converted - opening_total_cost_converted
	]).

	
	
	
	
forex_gain_formulas :-
	% old investment currency rate to report currency
	Hypothetical_Market_Price_Unit = rate_at(Investment_Currency, Opening_Date)
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














/*Unrealized Forex Gain total = sum(Unrealized Forex Gains)
iow



*/




/*
Start_Currency_Conversion = conversion(Investment_Currency, Report_Currency, Opening_Date)
End_Currency_Conversion = conversion(Investment_Currency, Report_Currency, Opening_Date)
End_Total_Market_Price_Converted == {date:closing, scope:total, aspect:market, role:value, currency:report}

Opening_Total_Cost_Converted = Opening_Unit_Cost_Converted * Count
End_Total_Market_Price_Converted = End_Market_Price / End_Currency_Conversion * Start_Currency_Conversion
Market_Gain = End_Total_Market_Price_Converted - Opening_Total_Cost_Converted
*/
/*
End_Total_Market_Price_Converted == {date:closing, scope:total, aspect:market, role:value, currency:report, rea_or_unr: Rea_Or_Unr}



	
	
	
	
	
	
	
	
/*label(Purchase_Or_Opening, {
	unrealized_gains/start_total_cost_converted: [Purchase_Or_Opening, 'total', Cost_Or_Value

}) :-
	(
		Purchase_Or_Opening = purchase
	->
		(
			Cost_Or_Value = cost

		)
	;
		(
			Cost_Or_Value = value
		
		)
	).*/	
	
	
investment_formulas(Rea_Or_Unr, Input, ..) :-
	gains_formulas(Rea_Or_Unr, Formulas1),
	...
	
evaluate(Conversion, value(Conversion, Rate, _{})) :-
	Conversion = conversion(Src, Dst, Date),
	exchange_rate(Sd, Src, Dst, Date, Rate).

%evaluate(Value * Value
*/

/*
	trying from bottom up here..
	Formulas = [
		closing_total_market = mul(closing_unitvalue_market, outstanding_count),
		closing_unitvalue_market = {type: value, amount: 1. {type: exchange_rate, date:end_date, src: unit, dst: investment_currency},
		opening_currency_conversion = 
	

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


	how about top-down instead?
*/









investment_report_2_unrealized(Static_Data, Investment, Row) :-
        
        End_Date = Static_Data.end_date,
        Exchange_Rates = Static_Data.exchange_rates,
        Report_Currency = Static_Data.report_currency,
        Cost_Or_Market = Static_Data.cost_or_market,
        
        Investment = ir_item(unr, Info, Count, [], Clipped),
        Info = info(Investment_Currency, Unit, Opening_Unit_Cost_Converted, Opening_Unit_Cost_Foreign, Opening_Date),


        
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

        event(Opening0, Opening_Unit_Cost_Foreign, Opening_Currency_Conversion, Opening_Unit_Cost_Converted, Opening_Total_Cost_Foreign, Opening_Total_Cost_Converted),

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
                        Purchase0 = Opening0,
                        Purchase = Purchase0.put(date, Opening_Date)
                )
        ),              

        event(Closing, Closing_Unit_Price_Foreign, Closing_Currency_Conversion, Closing_Unit_Price_Converted, Investment_Currency_Current_Market_Value, Current_Market_Value),

        value_subtract(Investment_Currency_Current_Market_Value, Opening_Total_Cost_Foreign, Market_Gain_Foreign),

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
                                market_foreign: Market_Gain_Foreign,
                                market_converted: Market_Gain,
                                forex: Forex_Gain
                        }
                },
                closing: Closing
        }.

        
        
        
        
        
        
        
        
        
        
        
market_gain_formulas :-
	Market_Price_Without_Movement_Unit = without_currency_movement_against_since(
		Investment_Currency, Investment_Currency, Report_Currency, Opening_Date),
	
	exchange_rate_throw(Exchange_Rates, End_Date, Market_Price_Without_Movement_Unit, Report_Currency_Unit, End_Market_Price_Rate),
	
	
	End_Market_Price_Amount_Converted is End_Unit_Price_Amount * End_Market_Price_Rate,
	End_Market_Unit_Price_Converted = value(Report_Currency_Unit, End_Market_Price_Amount_Converted),

	value_multiply(End_Market_Unit_Price_Converted, Count, End_Total_Price_Converted),
	value_multiply(Opening_Unit_Cost_Converted, Count, Opening_Total_Cost_Converted),
	value_subtract(End_Total_Price_Converted, Opening_Total_Cost_Converted, Gain).

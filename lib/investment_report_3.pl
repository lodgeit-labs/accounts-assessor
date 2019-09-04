/*
Start_Currency_Conversion = conversion(Investment_Currency, Report_Currency, Opening_Date)
End_Currency_Conversion = conversion(Investment_Currency, Report_Currency, Opening_Date)
End_Total_Market_Price_Converted == {date:closing, scope:total, aspect:market, role:value, currency:report}

Opening_Total_Cost_Converted = Opening_Unit_Cost_Converted * Count
End_Total_Market_Price_Converted = End_Market_Price / End_Currency_Conversion * Start_Currency_Conversion
Market_Gain = End_Total_Market_Price_Converted - Opening_Total_Cost_Converted
*/
/*

gains_formulas(Rea_Or_Unr, Formulas) :-
	formulas([
		Start_Currency_Conversion = conversion(Investment_Currency, Report_Currency, Opening_Date)
		End_Currency_Conversion = conversion(Investment_Currency, Report_Currency, Closing_Date)
		End_Total_Market_Price_Converted == {date:closing, scope:total, aspect:market, role:value, currency:report, rea_or_unr: Rea_Or_Unr}

		Opening_Total_Cost_Converted = Opening_Unit_Cost_Converted * Count
		End_Total_Market_Price_Converted = End_Market_Price / End_Currency_Conversion * Start_Currency_Conversion
		Market_Gain = End_Total_Market_Price_Converted - Opening_Total_Cost_Converted
	], Formulas).

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

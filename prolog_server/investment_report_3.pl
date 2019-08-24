

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


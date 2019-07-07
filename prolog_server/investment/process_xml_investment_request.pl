% simple investment calculator

:- module(process_xml_investment_request, [process_xml_investment_request/2]).
:- use_module(library(xpath)).
:- use_module(library(record)).
:- use_module('../../lib/utils', [
	inner_xml/3, write_tag/2, fields/2, numeric_fields/2, 
	pretty_term_string/2]).

:- record investment(
	name, purchase_date, unit_cost, count, currency, 
	% purchase date rate of purchase currency to report currency
	purchase_date_rate, 
	report_date, 
	% report date cost in purchase currency
	report_date_cost,
	% report date rate of purchase currency to report currency
	report_date_rate).	
% for example: Google Shares	7/1/2015	10	100	USD	0.7	6/30/2016	20	0.65

extract(Dom, Investment) :-
	fields(Dom, [
		name, Name, 
		currency, Currency
	]),
	numeric_fields(Dom, [
		purchase_date, Purchase_Date,
		unit_cost, PDPC_Unit_Cost,
		count, Count,
		purchase_date_rate, PD_Rate,
		report_date, Report_Date,
		report_date_value, RDPC_Unit_Value,
		report_date_rate, RD_Rate
	]),
	Investment = investment(
		Name, 
		Purchase_Date, 
		Count,
		Currency, 
		Report_Date,
		PDPC_Unit_Cost, 
		RDPC_Unit_Value,
		PD_Rate,
		RD_Rate
	),
	/*
		% at purchase date in purchase currency
		PDPC_Total_Cost, 
		% at purchase date in report currency
		PDRC_Total_Cost, 
		% at report date in purchase currency
		RDPC_Total_Value,
		RDPC_Unrealized_Gain,
		% at report date in report currency
		RDRC_Old_Rate_Total_Value,
		RDRC_New_Rate_Total_Value,
		RDRC_Total_Gain, 
		RDRC_Market_Gain, 
		RDRC_Currency_Gain),
	*/
	true.

:- initialization(test0(
	investment(
		'Google', 
		date(2015,7,1), 
		100, 
		'USD', 
		date(2016,6,30), 
		10, 
		20,
		0.7,
		0.65)
	)).
	
test0(Investment) :-
	compile_with_variable_names_preserved4(
		(
			Investment = investment(
				Name, 
				Purchase_Date, 
				Count,
				Currency, 
				Report_Date,
				PDPC_Unit_Cost, 
				RDPC_Unit_Value,
				PD_Rate,
				RD_Rate
			)
		),
		(
			PDPC_Total_Cost = Count * PDPC_Unit_Cost,
			PDRC_Total_Cost = PDPC_Total_Cost / PD_Rate,
			RDPC_Total_Value = Count * RDPC_Unit_Value,
			RDPC_Unrealized_Gain = RDPC_Total_Value - PDPC_Total_Cost,
			RDRC_Old_Rate_Total_Value = RDPC_Total_Value / PD_Rate,
			RDRC_New_Rate_Total_Value = RDPC_Total_Value / RD_Rate,
			RDRC_Total_Gain = RDRC_New_Rate_Total_Value - PDRC_Total_Cost,
			RDRC_Market_Gain = RDRC_Old_Rate_Total_Value - PDRC_Total_Cost,
			RDRC_Currency_Gain = RDRC_Total_Gain - RDRC_Market_Gain
		),	
		Names, _Expansions
	),
	/*writeln('------'),
	writeln(Expansions),
	writeln('------'),*//*
	PDPC_Total_Cost_v is PDPC_Total_Cost,
	PDRC_Total_Cost_v is PDRC_Total_Cost,
	RDPC_Total_Value_v is RDPC_Total_Value,
	RDPC_Unrealized_Gain_v is RDPC_Unrealized_Gain,
	RDRC_Old_Rate_Total_Value_v is RDRC_Old_Rate_Total_Value,
	RDRC_New_Rate_Total_Value_v is RDRC_New_Rate_Total_Value,
	RDRC_Total_Gain_v is RDRC_Total_Gain,
	RDRC_Market_Gain_v is RDRC_Market_Gain,
	RDRC_Currency_Gain_v is RDRC_Currency_Gain,
*/
	
    
	true.
		

		
		
		
		
	/*term_string(PDPC_Total_Cost, Formula_String1, [Names1]),*/	

process_xml_investment_request(_, DOM) :-
	xpath(DOM, //reports/investments, _),
	findall(Investment, xpath(DOM, //reports/investments/investment, Investment), Investments),
	writeln('<?xml version="1.0"?>'),
	writeln('<response>'),
	maplist(extract, Investments),
	maplist(compute, Investments, _Results),
	writeln('</response>'),
	nl, nl.
/*
process(Investment, Result) :-
	result = result(
		% on purchase date in purchase currency
		Total_Cost, 
		% on purchase date
		Report_Currency_Cost, 
		% at report date in purchase currency
		Total_Market_Value,
		Unrealized_Gain,
		% at report date
		Report_Currency_Market_Value,
		% at report date in report currency
		Total_Gain, Market_Gain, Currency_Gain),
	
	Unrealized_Gain = Total_Market_Value - Report_Currency_Cost,
	Total_Market_Value = Report_Date_Unit_Value 
	
	

	
process(Investment) :-
	writeln('<investment>'),
	
	
	inner_xml(DOM, //name, [Name]),
	inner_xml(DOM, //currency, [Currency]),
	write_tag('name', Name),
	write_tag('currency', Currency),

	numeric_fields(DOM, [

		'unitsBorn',						Natural_increase_count,
		'naturalIncreaseValuePerUnit',		Natural_increase_value_per_head,
		'unitsSales',						Sales_count,
		% salesValue?
		'saleValue', 						Sales_value,
		'unitsRations', 					Killed_for_rations_or_exchanged_for_goods_count,
		'unitsOpening', 					Stock_on_hand_at_beginning_of_year_count,
		'openingValue',				 		Stock_on_hand_at_beginning_of_year_value,
		'unitsClosing', 					(Stock_on_hand_at_end_of_year_count_input, _),
		'unitsPurchases',		 			Purchases_count,
		% purchasesValue?
		'purchaseValue',					Purchases_value,
		'unitsDeceased',					Losses_count]),

	compute_livestock_by_simple_calculation(	Natural_increase_count,Natural_increase_value_per_head,Sales_count,Sales_value,Killed_for_rations_or_exchanged_for_goods_count,Stock_on_hand_at_beginning_of_year_count,Stock_on_hand_at_beginning_of_year_value,Stock_on_hand_at_end_of_year_count_input,Purchases_count,Purchases_value,Losses_count,Killed_for_rations_or_exchanged_for_goods_value,Stock_on_hand_at_end_of_year_value,Closing_and_killed_and_sales_minus_losses_count,Closing_and_killed_and_sales_value,Opening_and_purchases_and_increase_count,Opening_and_purchases_value,Natural_Increase_value,Average_cost,Revenue,Livestock_COGS,Gross_Profit_on_Livestock_Trading, Explanation),

    write_tag('Killed_for_rations_or_exchanged_for_goods_value',	Killed_for_rations_or_exchanged_for_goods_value),
    write_tag('Stock_on_hand_at_end_of_year_value',					Stock_on_hand_at_end_of_year_value),
    write_tag('Closing_and_killed_and_sales_minus_losses_count',		Closing_and_killed_and_sales_minus_losses_count),
    write_tag('Closing_and_killed_and_sales_value',		Closing_and_killed_and_sales_value),
    write_tag('Opening_and_purchases_and_increase_count',			Opening_and_purchases_and_increase_count),
    write_tag('Opening_and_purchases_value',			Opening_and_purchases_value),
    write_tag('Natural_Increase_value',								Natural_Increase_value),
    write_tag('Average_cost',										Average_cost),
    write_tag('Revenue',											Revenue),
    write_tag('Livestock_COGS',										Livestock_COGS),
    write_tag('Gross_Profit_on_Livestock_Trading', 					Gross_Profit_on_Livestock_Trading),
	writeln(Explanation),
	writeln('</livestock>').
*/
/*

Optimally we should preload the Excel sheet with test data that when pressed, provides a controlled natural language response describing the set of processes the data underwent as a result of the computational rules along with a solution to the problem.
*/

%test0 :-
	

	/*Investment = investment(
		Name, Purchase_Currency, Purchase_Date, Count, 
		on_purchase_date{unit_cost: Unit_Cost, rate:Rate}, 
		on_report_date{unit_value:Unit_Value, rate:Rate}),*/
/*
	Investment = investment(
		'Google', 'USD', date(2015,7,1), 10, 
		on_purchase_date{unit_cost: 10, rate:0.7}, 
		on_report_date{unit_value:20, rate:0.65}),
		
	compile_with_variable_names_preserved((
		on_report_date{
		Unrealized_Gain = Total_Market_Value - Report_Currency_Cost,
	Total_Market_Value = Report_Date_Unit_Value 
	
		
		),	Names1),
    term_string(Gross_Profit_on_Livestock_Trading, Gross_Profit_on_Livestock_Trading_Formula_String, [Names1]),

	
		
*/

/* simple investment calculator
see doc/investment and dropbox Develop/videos/ledger
*/


:- module(process_xml_investment_request, [process_xml_investment_request/2]).
:- use_module(library(xpath)).
:- use_module(library(record)).
:- use_module('../../lib/utils', [
	inner_xml/3, write_tag/2, fields/2, numeric_fields/2, 
	pretty_term_string/2 /*, magic_formula */]).
:- use_module('../../lib/days', [format_date/2, parse_date/2, gregorian_date/2]).
:- use_module('../../lib/statements', [
		process_ledger/13]).

	
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


process(Dom) :-

	/*
		PDPC = purchase date, purchase currency
		RDRC = report date, report currency, etc
	*/

	fields(Dom, [
		'Name', Name, 
		'Currency', Currency,
		'Purchase_Date', Purchase_Date_Atom,
		'Report_Date', Report_Date_Atom
	]),
	/*parse_date(Purchase_Date_Atom, Purchase_Date),
	parse_date(Report_Date_Atom, Report_Date),*/
	numeric_fields(Dom, [
		'Unit_Cost', PDPC_Unit_Cost,
		'Unit_Value', RDPC_Unit_Value,
		'Count', Count,
		'Purchase_Date_Rate', PD_Rate,
		'Report_Date_Rate', RD_Rate
	]),
	writeln('<investment>'),
	write_tag('Name', Name),
	write_tag('Purchase_Date', Purchase_Date_Atom),
	write_tag('Count', Count),
	write_tag('Currency', Currency),
	write_tag('Report_Date', Report_Date_Atom),

	magic_formula(
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
		)
	),
	nonvar(RDPC_Unrealized_Gain),nonvar(RDRC_Currency_Gain),
	writeln('</investment>'),nl,nl,
	
	
	/*
	now for the cross check..
process_ledger(S_Transactions, Start_Days, End_Days, Exchange_Rates, Action_Taxonomy, Report_Currency, Livestock_Types, Livestock_Opening_Costs_And_Counts, Debug_Message, Account_Hierarchy_In, Account_Hierarchy, Transactions_With_Livestock, Used_Units, Balance_Sheet, ProftAndLoss) :-

	Purchase_Date,
	Report_Date,
	report_currency,
	[s_transaction(Purchase_Date, 'Invest_In', vector([coord(Currency, PDPC_Total_Cost, 0)]), 'Bank', coord(Name, Count, 0))],	
	*/
	
    
	true.
		

process_xml_investment_request(_, DOM) :-
	xpath(DOM, //reports/investments, _),
	findall(Investment, xpath(DOM, //reports/investments/investment, Investment), Investments),
	writeln('<?xml version="1.0"?>'),
	writeln('<response>'),
	%maplist(extract, Investments),
	maplist(process, Investments),
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
*/	

/*Investment = investment(
		Name, Purchase_Currency, Purchase_Date, Count, 
		on_purchase_date{unit_cost: Unit_Cost, rate:Rate}, 
		on_report_date{unit_value:Unit_Value, rate:Rate}),
	Investment = investment(
		'Google', 'USD', date(2015,7,1), 10, 
		on_purchase_date{unit_cost: 10, rate:0.7}, 
		on_report_date{unit_value:20, rate:0.65}),
*/


/*
Optimally we should preload the Excel sheet with test data that when pressed, provides a controlled natural language response describing the set of processes the data underwent as a result of the computational rules along with a solution to the problem.
*/



/*
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
	).

	
:- initialization(test0).

test0 :-
	process(investment(
		'Google', 
		date(2015,7,1), 
		100, 
		'USD', 
		date(2016,6,30), 
		10, 
		20,
		0.7,
		0.65)
	))).
	
	
process(Investment) :-
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
*/

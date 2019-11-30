% standalone livestock calculator

:- module(process_xml_livestock_request, []).
:- use_module(library(xpath)).
:- use_module('utils', [
	inner_xml/3, write_tag/2, fields/2, numeric_fields/2, 
	pretty_term_string/2]).
:- use_module('report_page').
:- use_module('tables').
:- use_module('files', [
	absolute_tmp_path/2
]).
:- use_module('xml', [
	validate_xml/3
]).


:- ['livestock_calculator'].

process_xml_livestock_request(File_Name, DOM, Reports) :-

	findall(Livestock, xpath(DOM, //reports/livestockaccount/livestocks/livestock, Livestock), Livestocks),
	Livestocks \= [],

	Reports = _{
		files: File_Infos,
		errors: [Schema_Errors, Alerts],
		warnings: []
	},

	absolute_tmp_path(File_Name, Instance_File),
	absolute_file_name(my_schemas('bases/Reports.xsd'), Schema_File, []),
	validate_xml(Instance_File, Schema_File, Schema_Errors),
	(
		Schema_Errors = []
	->
		(

			writeln('<response>'),
			writeln('<livestocks>'),
			maplist(process, Livestocks, Alerts, File_Infos),
			writeln('</livestocks>'),
			writeln('</response>'),
			nl, nl
		)
	).
	
process(DOM, [], Report_File_Info) :-
	writeln('<livestock>'),
	inner_xml(DOM, //name, [Name]),
	inner_xml(DOM, //currency, [Currency]),
	write_tag('name', Name),
	write_tag('currency', Currency),

	Inputs = 
	[
		'unitsBorn',						Natural_increase_count,
		'naturalIncreaseValuePerUnit',		Natural_increase_value_per_head,
		'unitsSales',						Sales_count,
		% todo maybe rename to salesValue
		'saleValue', 						Sales_value,
		'unitsRations', 					Killed_for_rations_count,
		'unitsOpening', 					Stock_on_hand_at_beginning_of_year_count,
		'openingValue',				 		Stock_on_hand_at_beginning_of_year_value,
		'unitsClosing', 					(Stock_on_hand_at_end_of_year_count_input, _),
		'unitsPurchases',		 			Purchases_count,
		% todo maybe rename to purchasesValue
		'purchaseValue',					Purchases_value,
		'unitsDeceased',					Losses_count
	],

	numeric_fields(DOM, Inputs),

	compute_livestock_by_simple_calculation(Natural_increase_count,Natural_increase_value_per_head,Sales_count,Sales_value,Killed_for_rations_count,Stock_on_hand_at_beginning_of_year_count,Stock_on_hand_at_beginning_of_year_value,Stock_on_hand_at_end_of_year_count_input,Purchases_count,Purchases_value,Losses_count,Killed_for_rations_value,Stock_on_hand_at_end_of_year_value,Closing_and_killed_and_sales_minus_losses_count,Closing_and_killed_and_sales_value,Opening_and_purchases_and_increase_count,Opening_and_purchases_value,Natural_Increase_value,Average_cost,Revenue,Livestock_COGS,Gross_Profit_on_Livestock_Trading, Explanation),
	
	findall(Line, (member(L, Explanation), atomic_list_concat(L, Line)),  Explanation_Lines),
	atomic_list_concat(Explanation_Lines, '\n', Explanation_Str),
	
	% simplify the Inputs array, where there is a pair (Var, Default), leave just Var
	findall(
		Item,
		(
			member(X, Inputs),
			(
				X = (Item, _Default)
				;
				(
					atomic(X),
					Item = X
				)
			)
		),
		Inputs_Without_Defaults
	),
	
	utils:unzip(Inputs_Without_Defaults, Input_Tags, Input_Vars),
	maplist(write_tag, Input_Tags, Input_Vars),

    write_tag('Killed_for_rations_value',	Killed_for_rations_value),
    write_tag('Stock_on_hand_at_end_of_year_value',					Stock_on_hand_at_end_of_year_value),
    write_tag('Closing_and_killed_and_sales_minus_losses_count',	Closing_and_killed_and_sales_minus_losses_count),
    write_tag('Closing_and_killed_and_sales_value',					Closing_and_killed_and_sales_value),
    write_tag('Opening_and_purchases_and_increase_count',			Opening_and_purchases_and_increase_count),
    write_tag('Opening_and_purchases_value',						Opening_and_purchases_value),
    write_tag('Natural_Increase_value',								Natural_Increase_value),
    write_tag('Average_cost',										Average_cost),
    write_tag('Revenue',											Revenue),
    write_tag('Livestock_COGS',										Livestock_COGS),
    write_tag('Gross_Profit_on_Livestock_Trading', 					Gross_Profit_on_Livestock_Trading),
    write_tag('Explanation', 										Explanation_Str),
	writeln('</livestock>'),

	Columns = [
		column{id:name, title:"Livestock", options:_{}},
		column{id:currency, title:"Currency", options:_{}},
		column{id:average_cost, title:"Average Cost", options:_{}},
		column{id:cogs, title:"Cost Of Goods Sold", options:_{}},
		column{id:gross_profit, title:"Gross Profit", options:_{}}
	],

	Row0 = _{
		name: Name,
		currency: Currency, 
		average_cost: value(Currency, Average_cost), 
		cogs: value(Currency, Livestock_COGS),
		gross_profit: value(Currency, Gross_Profit_on_Livestock_Trading)
	},

	tables:format_row(Columns, Row0, Formatted_Row),
	tables:row_to_html(Columns, Formatted_Row, Row_Html),

	findall(tr(td([colspan="5"],R)), member(R, Explanation), Explanations),
	tables:header_html(Columns, Html_Header),
	flatten([Html_Header, Row_Html, Explanations], Table_Contents_Html),
	
	utils:replace_nonalphanum_chars_with_underscore(Name, Fn_Suffix),
	atomic_list_concat(['livestock_report_', Fn_Suffix, '.html'], Fn),
	atomic_list_concat(['livestock_report_', Fn_Suffix, '_html'], Id),
	report_page:report_page_with_table(Name, Table_Contents_Html, Fn, Id, Report_File_Info).

/*
Optimally we should preload the Excel sheet with test data that when pressed, provides a controlled natural language response describing the set of processes the data underwent as a result of the computational rules along with a solution to the problem.
*/

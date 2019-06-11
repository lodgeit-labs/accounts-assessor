% simple livestock calculator

:- module(process_xml_livestock_request, [process_xml_livestock_request/2]).
:- use_module(library(xpath)).
:- use_module('../../lib/utils', [
	inner_xml/3, write_tag/2, fields/2, numeric_fields/2, 
	pretty_term_string/2]).





process_xml_livestock_request(_, DOM) :-

	findall(Livestock, xpath(DOM, //reports/livestockaccount/livestocks/livestock, Livestock), Livestocks),
	Livestocks \= [],

	format('Content-type: text/xml~n~n'), 
	writeln('<?xml version="1.0"?>'),
	writeln('<response>'),

	maplist(process, Livestocks),

	writeln('</response>'),
	nl, nl.



process(DOM) :-
	writeln('<livestock>'),
	inner_xml(DOM, //name, [Name]),
	inner_xml(DOM, //currency, [Currency]),
	write_tag('name', Name),
	write_tag('currency', Currency),

	numeric_fields(DOM, [

		'unitsBorn',						Natural_increase_count,
		% missing:
		'naturalIncreaseValuePerUnit',		Natural_increase_value_per_head,
		'unitsSales',						Sales_count,
		% salesValue?
		'saleValue', 						Sales_value,
		'unitsRations', 					Killed_for_rations_or_exchanged_for_goods_count,
		'unitsOpening', 					Stock_on_hand_at_beginning_of_year_count,
		'openingValue',				 		Stock_on_hand_at_beginning_of_year_value,
		% should be checked by doing a total
		'unitsClosing', 					Stock_on_hand_at_end_of_year_count,
		'unitsPurchases',		 			Purchases_count,
		% purchasesValue?
		'purchaseValue',					Purchases_value,
		'unitsDeceased',					Losses_count]),
	
	Natural_Increase_value is Natural_increase_count * Natural_increase_value_per_head,
	Opening_and_purchases_and_increase_count is Stock_on_hand_at_beginning_of_year_count + Purchases_count + Natural_increase_count,
	Opening_and_purchases_value is Stock_on_hand_at_beginning_of_year_value + Purchases_value,
	
	Average_cost is (Opening_and_purchases_value + Natural_Increase_value) /  Opening_and_purchases_and_increase_count,
	
	Stock_on_hand_at_end_of_year_value is Average_cost * Stock_on_hand_at_end_of_year_count,
	Killed_for_rations_or_exchanged_for_goods_value is Killed_for_rations_or_exchanged_for_goods_count * Average_cost,
	
	Closing_and_killed_and_sales_minus_losses_count is Sales_count + Killed_for_rations_or_exchanged_for_goods_count + Stock_on_hand_at_end_of_year_count - Losses_count,
	Closing_and_killed_and_sales_value is Sales_value + Killed_for_rations_or_exchanged_for_goods_value + Stock_on_hand_at_end_of_year_value,
	
	Revenue is Sales_value + Killed_for_rations_or_exchanged_for_goods_value,
	Livestock_COGS is Opening_and_purchases_value - Stock_on_hand_at_end_of_year_value,
	Gross_Profit_on_Livestock_Trading is Revenue - Livestock_COGS,

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

	writeln('</livestock>').


/*

Optimally we should preload the Excel sheet with test data that when pressed, provides a controlled natural language response describing the set of processes the data underwent as a result of the computational rules along with a solution to the problem.
*/

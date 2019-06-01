% simple livestock calculator


:- debug.
:- use_module(library(xpath)).

:- ['../../src/utils'].




process_xml_livestock_request(_, DOM) :-

	findall(Livestock, xpath(DOM, //reports/livestockaccount/livestocks/livestock, Livestock), Livestocks),

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
		% is just a check?
		'unitsClosing', 					Stock_on_hand_at_end_of_year_count,
		'unitsPurchases',		 			Purchases_count,
		% purchasesValue?
		'purchaseValue',					Purchases_value,
		'unitsDeceased',					Losses_count]),
	
	Natural_Increase_value is Natural_increase_count * Natural_increase_value_per_head,
	Opening_and_purchases_and_increase_count is Stock_on_hand_at_beginning_of_year_count + Purchases_count + Natural_increase_count,
	Opening_and_purchases_and_increase_value is Stock_on_hand_at_beginning_of_year_value + Purchases_value + Natural_Increase_value,
	Average_cost is Opening_and_purchases_and_increase_value / Opening_and_purchases_and_increase_count,
	Stock_on_hand_at_end_of_year_value is Average_cost * Stock_on_hand_at_end_of_year_count,
	Killed_for_rations_or_exchanged_for_goods_value is Killed_for_rations_or_exchanged_for_goods_count * Average_cost,
	Losses_and_closing_and_killed_and_sales_count is Sales_count + Killed_for_rations_or_exchanged_for_goods_count + Stock_on_hand_at_end_of_year_count - Losses_count,
	Losses_and_closing_and_killed_and_sales_value	is Sales_value + Killed_for_rations_or_exchanged_for_goods_value + Stock_on_hand_at_end_of_year_value,
	Revenue	is Sales_value + Killed_for_rations_or_exchanged_for_goods_value,
	Livestock_COGS is Opening_and_purchases_and_increase_value - Stock_on_hand_at_end_of_year_value,
	Gross_Profit_on_Livestock_Trading is Revenue - Livestock_COGS,

    write_tag('Killed_for_rations_or_exchanged_for_goods_value',	Killed_for_rations_or_exchanged_for_goods_value),
    write_tag('Stock_on_hand_at_end_of_year_value',					Stock_on_hand_at_end_of_year_value),
    write_tag('Losses_and_closing_and_killed_and_sales_count',		Losses_and_closing_and_killed_and_sales_count),
    write_tag('Losses_and_closing_and_killed_and_sales_value',		Losses_and_closing_and_killed_and_sales_value),
    write_tag('Opening_and_purchases_and_increase_count',			Opening_and_purchases_and_increase_count),
    write_tag('Opening_and_purchases_and_increase_value',			Opening_and_purchases_and_increase_value),
    write_tag('Natural_Increase_value',								Natural_Increase_value),
    write_tag('Average_cost',										Average_cost),
    write_tag('Revenue',											Revenue),
    write_tag('Livestock_COGS',										Livestock_COGS),
    write_tag('Gross_Profit_on_Livestock_Trading', 					Gross_Profit_on_Livestock_Trading),

	writeln('</livestock>').



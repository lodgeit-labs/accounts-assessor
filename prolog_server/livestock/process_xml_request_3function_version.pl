:- debug.
:- use_module(library(xpath)).


% this gets the children of an element with ElementXPath
% this should be imported from somewhere
inner_xml(DOM, ElementXPath, Children) :-
   xpath(DOM, ElementXPath, element(_,_,Children)).

write_tag(TagName,TagValue) :-
	string_concat("<",TagName,OpenTagTmp),
	string_concat(OpenTagTmp,">",OpenTag),
	string_concat("</",TagName,ClosingTagTmp),
	string_concat(ClosingTagTmp,">",ClosingTag),
	writeln(OpenTag),
	writeln(TagValue),
	writeln(ClosingTag).


% simple livestock calculator
process_xml_request(FileNameIn) :-
	read_livestock_xml_request(
		FileNameIn,
		Natural_increase,
		Natural_increase_value_per_head_AUD,
		% Gross_Sales,
		Gross_Sales_AUD,
		Killed_for_rations_or_exchanged_for_goods,
		Stock_on_hand_at_beginning_of_year,
		Stock_on_hand_at_end_of_year,
		Purchases_count,
		Purchases_at_cost_AUD,
		Opening_and_purchases_AUD
		% Losses_by_death
	),

	livestock_calculations(
		Natural_increase,
		Natural_increase_value_per_head_AUD,
		% Gross_Sales,
		Gross_Sales_AUD,
		Killed_for_rations_or_exchanged_for_goods,
		Stock_on_hand_at_beginning_of_year,
		Stock_on_hand_at_end_of_year,
		Purchases_count,
		Purchases_at_cost_AUD,
		Opening_and_purchases_AUD,
		% Losses_by_death,
		Killed_for_rations_or_exchanged_for_goods_AUD,
		Stock_on_hand_at_end_of_year_AUD,
		% Losses_and_closing_and_killed_and_sales_count,
		% Losses_and_closing_and_killed_and_sales_AUD,
		Opening_and_purchases_and_increase_count,
		Natural_Increase_AUD,
		Opening_and_purchases_and_increase_AUD,
		Opening_and_purchases_and_increase_AUD2,
		Average_cost,
		Revenue,
		Livestock_COGS,
		Gross_Profit_on_Livestock_Trading
	),

	write_livestock_xml_response(
		Killed_for_rations_or_exchanged_for_goods_AUD,
		Stock_on_hand_at_end_of_year_AUD,
		% Losses_and_closing_and_killed_and_sales_count,
		% Losses_and_closing_and_killed_and_sales_AUD,
		Opening_and_purchases_and_increase_count,
		Natural_Increase_AUD,
		Opening_and_purchases_and_increase_AUD,
		Opening_and_purchases_and_increase_AUD2,
		Average_cost,
		Revenue,
		Livestock_COGS,
		Gross_Profit_on_Livestock_Trading
	).

read_livestock_xml_request(
	FileNameIn,
	Natural_increase,
	Natural_increase_value_per_head_AUD,
	% Gross_Sales,
	Gross_Sales_AUD,
	Killed_for_rations_or_exchanged_for_goods,
	Stock_on_hand_at_beginning_of_year,
	Stock_on_hand_at_end_of_year,
	Purchases_count,
	Purchases_at_cost_AUD,
	Opening_and_purchases_AUD
	% Losses_by_death
) :-
	load_xml(FileNameIn, DOM, []),
	xpath(DOM, //reports/livestockdetails/livestockaccount, LIVESTOCKACCOUNT),
	xpath(LIVESTOCKACCOUNT, field(@name='natural increase stock count', @value(number)=Natural_increase),E1),
	xpath(LIVESTOCKACCOUNT, field(@name='natural increase AUD per head', @value(number)=Natural_increase_value_per_head_AUD),E2),
	% xpath(LIVESTOCKACCOUNT, field(@name='gross sales stock count', @value=Gross_Sales_atom),E3),
	xpath(LIVESTOCKACCOUNT, field(@name='gross sales AUD total', @value(number)=Gross_Sales_AUD),E4),
	xpath(LIVESTOCKACCOUNT, field(@name='rations or exchanged stock count', @value(number)=Killed_for_rations_or_exchanged_for_goods),E5),
	xpath(LIVESTOCKACCOUNT, field(@name='beginning stock count', @value(number)=Stock_on_hand_at_beginning_of_year),E6),
	xpath(LIVESTOCKACCOUNT, field(@name='ending stock count', @value(number)=Stock_on_hand_at_end_of_year),E7),
	xpath(LIVESTOCKACCOUNT, field(@name='purchases stock count', @value(number)=Purchases_count),E8),
	xpath(LIVESTOCKACCOUNT, field(@name='purchases AUD total', @value(number)=Purchases_at_cost_AUD),E9),
	xpath(LIVESTOCKACCOUNT, field(@name='opening and purchases AUD', @value(number)=Opening_and_purchases_AUD),E10).


livestock_calculations(
	% abstract on this:
	% Inputs:
	Natural_increase,
	Natural_increase_value_per_head_AUD,
	% Gross_Sales,
	Gross_sales_AUD,
	Killed_for_rations_or_exchanged_for_goods,
	Stock_on_hand_at_beginning_of_year,
	Stock_on_hand_at_end_of_year,
	Purchases_count,
	Purchases_at_cost_AUD,
	Opening_and_purchases_AUD,
	% Losses_by_death,
	% Outputs:
	Killed_for_rations_or_exchanged_for_goods_AUD,
	Stock_on_hand_at_end_of_year_AUD,
	% Losses_and_closing_and_killed_and_sales_count,
	% Losses_and_closing_and_killed_and_sales_AUD,
	Opening_and_purchases_and_increase_count,
	Natural_Increase_AUD,
	Opening_and_purchases_and_increase_AUD,
	Opening_and_purchases_and_increase_AUD2,
	Average_cost,
	Revenue,
	Livestock_COGS,
	Gross_Profit_on_Livestock_Trading
) :-
	% abstract on this:
	% will be more difficult, due to:
	%	needing to capture the structure of expressions
	%	Output values depending on intermediate values as opposed to just input values
	Natural_Increase_AUD is Natural_increase * Natural_increase_value_per_head_AUD,
	Opening_and_purchases_and_increase_AUD is Opening_and_purchases_AUD + Natural_Increase_AUD,
	Opening_and_purchases_and_increase_count is Stock_on_hand_at_beginning_of_year + Purchases_count + Natural_increase,
	Average_cost is Opening_and_purchases_and_increase_AUD / Opening_and_purchases_and_increase_count,
	Stock_on_hand_at_beginning_of_year_AUD is Average_cost * Stock_on_hand_at_beginning_of_year,
	Stock_on_hand_at_end_of_year_AUD is Average_cost * Stock_on_hand_at_end_of_year,
	Opening_and_purchases_and_increase_AUD2 is Stock_on_hand_at_beginning_of_year_AUD + Purchases_at_cost_AUD,
	Killed_for_rations_or_exchanged_for_goods_AUD is Killed_for_rations_or_exchanged_for_goods * Average_cost,
	% Losses_and_closing_and_killed_and_sales_count is Gross_Sales + Killed_for_rations_or_exchanged_for_goods + Stock_on_hand_at_end_of_year - Losses_by_death,
	% Losses_and_closing_and_killed_and_sales_AUD	is Gross_sales_AUD + Killed_for_rations_or_exchanged_for_goods_AUD + Stock_on_hand_at_end_of_year_AUD,
	Revenue	is Gross_sales_AUD + Killed_for_rations_or_exchanged_for_goods_AUD,
	Livestock_COGS is Opening_and_purchases_and_increase_AUD - Stock_on_hand_at_end_of_year_AUD,
	Gross_Profit_on_Livestock_Trading is Revenue - Livestock_COGS.

write_livestock_xml_response(
	% abstract on this:
	Killed_for_rations_or_exchanged_for_goods_AUD,
	Stock_on_hand_at_end_of_year_AUD,
	% Losses_and_closing_and_killed_and_sales_count,
	% Losses_and_closing_and_killed_and_sales_AUD,
	Opening_and_purchases_and_increase_count,
	Natural_Increase_AUD,
	Opening_and_purchases_and_increase_AUD,
	Opening_and_purchases_and_increase_AUD2,
	Average_cost,
	Revenue,
	Livestock_COGS,
	Gross_Profit_on_Livestock_Trading
) :-
	format('Content-type: text/xml~n~n'), 
	writeln('<?xml version="1.0"?>'),
	writeln('<response>'),
	% abstract on this:
	% needs to have list of (XML location , value) pairs.
	% for location, value in Outputs:
	%	make_node_at_location(location,value)
	write_tag('Killed_for_rations_or_exchanged_for_goods_AUD',Killed_for_rations_or_exchanged_for_goods_AUD),
	write_tag('Stock_on_hand_at_end_of_year_AUD',Stock_on_hand_at_end_of_year_AUD),
	% write_tag('Losses_and_closing_and_killed_and_sales_count',Losses_and_closing_and_killed_and_sales_count),
	% write_tag('Losses_and_closing_and_killed_and_sales_AUD',Losses_and_closing_and_killed_and_sales_AUD),
	write_tag('Opening_and_purchases_and_increase_count',Opening_and_purchases_and_increase_count),
	write_tag('Natural_Increase_AUD',Natural_Increase_AUD),
	write_tag('Opening_and_purchases_and_increase_AUD',Opening_and_purchases_and_increase_AUD),
	write_tag('Opening_and_purchases_and_increase_AUD2',Opening_and_purchases_and_increase_AUD2),
	write_tag('Average_cost',Average_cost),
	write_tag('Revenue',Revenue),
	write_tag('Livestock_COGS',Livestock_COGS),
	write_tag('Gross_Profit_on_Livestock_Trading', Gross_Profit_on_Livestock_Trading),
	writeln('</response>'),
	nl, nl.

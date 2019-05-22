% simple livestock calculator
/*
inputs:
Natural_increase
natural_increase_value_per_head_AUD
Gross_Sales
Gross_sales_AUD
Killed_for_rations_or_exchanged_for_goods
Stock_on_hand_at_beginning_of_year
Stock_on_hand_at_end_of_year
Purchases_count
purchases_at_cost_AUD
Losses_by_death


average_cost ?

*/

/*
* XML extractions are something we should be able to handle generically.

* Calculator logic and XML extraction logic should be independent of each other, something should extract
  XML in a generic fashion like below, into a form that Prolog processes natively, and the calculator logic
  should just make use of that. Similarly writing the XML output should be an independent thing. We're not
  doing anything memory-intensive enough yet to necessitate interleaving these activities, and when we do get
  to that point it should be handled generically so that we can still write each of the Read, Calculate, and Write
  components independently. This separation of concerns will become critical the moment we need to support any
  second input/output format, and even prior to that point, the lack of separation will foil any attempts at
  properly abstracting on this logic.

[
	(Natural_increase, //request/Natural_increase),
	(Natural_increase_value_per_head_AUD, //request/natural_increase_value_per_head_AUD),
	(Gross_Sales, //request/Gross_Sales),
	(Gross_Sales_AUD, //request/Gross_Sales_AUD),
	...
]

or just..

[
	//request/Natural_increase,
	//request/Natural_increase_value_per_head_AUD
]

or...
.. generalize this with XMLSchema

or...
.. generalize this with a simpler in-house analog of XMLSchema


or...
.. plenty of options here...

*/

[
	["Natural_increase",//request/Natural_increase],
	["natural_increase_value_per_head_AUD",//request/natural_increase_value_per_head_AUD],
	["Gross_Sales",//request/Gross_Sales],
	["Gross_sales_AUD",//request/Gross_Sales_AUD],
	["Killed_for_rations_or_exchanged_for_goods",//request/Killed_for_rations_or_exchanged_for_goods],
	["Stock_on_hand_at_beginning_of_year",//request/Stock_on_hand_at_beginning_of_year],
	["Stock_on_hand_at_end_of_year",//request/Stock_on_hand_at_end_of_year],
	["Purchases_count",//request/Purchases_count],
	["purchases_at_cost_AUD",//request/purchases_at_cost_AUD],
	["Losses_by_death",//Losses_by_death]
]

% so this probably be more like a dict of name/path pairs
% the query should take one of these dicts and an XML DOM and return something like a dict of name/value pairs
% the query should actually take a dict of the keys you want to include, and find those keys in the dict

/*
This is the way we write it, so this is a rough draft of how it *should* be written.

formulas:
Killed_for_rations_or_exchanged_for_goods_AUD	=Killed_for_rations_or_exchanged_for_goods*average_cost

Stock_on_hand_at_end_of_year_AUD	=average_cost*Stock_on_hand_at_end_of_year
Stock_on_hand_at_beginning_of_year_AUD = average_cost*Stock_on_hand_at_beginning_of_year
losses_and_closing_and_killed_and_sales_count	= Gross_Sales + Killed_for_rations_or_exchanged_for_goods+Stock_on_hand_at_end_of_year-Losses_by_death
losses_and_closing_and_killed_and_sales_AUD	=Gross_sales_AUD+Killed_for_rations_or_exchanged_for_goods_AUD+Stock_on_hand_at_end_of_year_AUD
opening_and_purchases_and_increase_count	=Stock_on_hand_at_beginning_of_year+Purchases_count+Natural_increase
Natural_Increase_AUD	=Natural_increase*natural_increase_value_per_head_AUD
opening_and_purchases_and_increase_AUD	=Stock_on_hand_at_beginning_of_year_AUD+purchases_at_cost_AUD
average_cost	=opening_and_purchases_and_increase_AUD/opening_and_purchases_and_increase_count
Revenue	=Gross_sales_AUD + Killed_for_rations_or_exchanged_for_goods_AUD
Livestock_COGS	=opening_and_purchases_and_increase_AUD - Stock_on_hand_at_end_of_year_AUD
Gross_Profit_on_Livestock_Trading	= Revenue - Livestock_COGS ?


opening_and_purchases_and_increase_AUD
	Stock_on_hand_at_beginning_of_year_AUD
		average_cost
			opening_and_purchases_and_increase_AUD <-- circular dependency
			opening_and_purchases_and_increase_count
		Stock_on_hand_at_beginning_of_year
	purchases_at_cost_AUD

*/

% any independent formulas here could be expressed as a dict of name/path pairs.


% Every input value has a:
%	* location in the XML request
%	* Variable to carry the value

% Every output value has a:
%	* location in the XML response
%	* formula determining its value in terms of the input values
%	* Variable to carry the value
%	** note: creation of output values is complicated by the fact that they may depend on intermediate values,
%	** i.e., it won't necessarily suffice to have them expressed as simple arithmetic formulas in terms of the
%	** input values. Ex. Killed_for_rations_or_exchanged_for_goods_AUD is dependent on the intermediate value Average_cost

% why do we need the _FileNameIn if we already have the DOM for that file?
process_xml_request(_FileNameIn, DOM) :-
	read_livestock_xml_request(DOM, Natural_increase, Natural_increase_value_per_head_AUD, Gross_Sales, Gross_Sales_AUD, Killed_for_rations_or_exchanged_for_goods, Stock_on_hand_at_beginning_of_year, Stock_on_hand_at_end_of_year, Purchases_count, Purchases_at_cost_AUD, Losses_by_death),

	livestock_calculations(Natural_increase, Natural_increase_value_per_head_AUD, Gross_Sales, Gross_Sales_AUD, Killed_for_rations_or_exchanged_for_goods, Stock_on_hand_at_beginning_of_year, Stock_on_hand_at_end_of_year, Purchases_count, Purchases_at_cost_AUD, Losses_by_death, Killed_for_rations_or_exchanged_for_goods_AUD, Stock_on_hand_at_end_of_year_AUD, Losses_and_closing_and_killed_and_sales_count, Losses_and_closing_and_killed_and_sales_AUD, Opening_and_purchases_and_increase_count, Natural_Increase_AUD, Opening_and_purchases_and_increase_AUD, Opening_and_purchases_and_increase_AUD2, Average_cost, Revenue, Livestock_COGS, Gross_Profit_on_Livestock_Trading),

	write_livestock_xml_response(Killed_for_rations_or_exchanged_for_goods_AUD, Stock_on_hand_at_end_of_year_AUD, Losses_and_closing_and_killed_and_sales_count, Losses_and_closing_and_killed_and_sales_AUD, Opening_and_purchases_and_increase_count, Natural_Increase_AUD, Opening_and_purchases_and_increase_AUD, Opening_and_purchases_and_increase_AUD2, Average_cost, Revenue, Livestock_COGS, Gross_Profit_on_Livestock_Trading).

% note: duplication of these variables in specification of XML paths, hence why it should be returning a list/dict
read_livestock_xml_request(
	DOM,
	% abstract on this
	Natural_increase,
	Natural_increase_value_per_head_AUD,
	Gross_Sales,
	Gross_Sales_AUD,
	Killed_for_rations_or_exchanged_for_goods,
	Stock_on_hand_at_beginning_of_year,
	Stock_on_hand_at_end_of_year,
	Purchases_count,
	Purchases_at_cost_AUD,
	Losses_by_death
) :-
	% abstract on this:
	inner_xml(DOM, //request/Natural_increase, Natural_increase),
	inner_xml(DOM, //request/Natural_increase_value_per_head_AUD, Natural_increase_value_per_head_AUD),
	inner_xml(DOM, //request/Gross_Sales, Gross_Sales),
	inner_xml(DOM, //request/Gross_Sales_AUD, Gross_Sales_AUD),
	inner_xml(DOM, //request/Killed_for_rations_or_exchanged_for_goods, Killed_for_rations_or_exchanged_for_goods),
	inner_xml(DOM, //request/Stock_on_hand_at_beginning_of_year, Stock_on_hand_at_beginning_of_year),
	inner_xml(DOM, //request/Stock_on_hand_at_end_of_year, Stock_on_hand_at_end_of_year),
	inner_xml(DOM, //request/Purchases_count, Purchases_count),
	inner_xml(DOM, //request/Purchases_at_cost_AUD, Purchases_at_cost_AUD),
	inner_xml(DOM, //request/Losses_by_death, Losses_by_death).

livestock_calculations(
	% abstract on this:
	% Inputs:
	Natural_increase,
	Natural_increase_value_per_head_AUD,
	Gross_Sales,
	Gross_sales_AUD,
	Killed_for_rations_or_exchanged_for_goods,
	Stock_on_hand_at_beginning_of_year,
	Stock_on_hand_at_end_of_year,
	Purchases_count,
	Purchases_at_cost_AUD,
	Losses_by_death,
	% Outputs:
	Killed_for_rations_or_exchanged_for_goods_AUD,
	Stock_on_hand_at_end_of_year_AUD,
	Losses_and_closing_and_killed_and_sales_count,
	Losses_and_closing_and_killed_and_sales_AUD,
	Opening_and_purchases_and_increase_count,
	Natural_Increase_AUD,
	Opening_and_purchases_and_increse_AUD,
	Opening_and_purchases_and_increase_AUD,
	Average_cost,
	Revenue,
	Livestock_COGS,
	Gross_Profit_on_Livestock_Trading
) :-
	% abstract on this:
	Killed_for_rations_or_exchanged_for_goods_AUD is Killed_for_rations_or_exchanged_for_goods * Average_cost,
	Stock_on_hand_at_end_of_year_AUD is Average_cost * Stock_on_hand_at_end_of_year,
	Losses_and_closing_and_killed_and_sales_count is Gross_Sales + Killed_for_rations_or_exchanged_for_goods + Stock_on_hand_at_end_of_year - Losses_by_death,
	Losses_and_closing_and_killed_and_sales_AUD	is Gross_sales_AUD + Killed_for_rations_or_exchanged_for_goods_AUD + Stock_on_hand_at_end_of_year_AUD,
	Opening_and_purchases_and_increase_count is Stock_on_hand_at_beginning_of_year + Purchases_count + Natural_increase,
	Natural_Increase_AUD is Natural_increase * Natural_increase_value_per_head_AUD,
	Opening_and_purchases_and_increase_AUD is Opening_and_purchases_AUD + Natural_Increase_AUD,
	Opening_and_purchases_and_increase_AUD2 is Stock_on_hand_at_beginning_of_year_AUD + Purchases_at_cost_AUD,
	Average_cost is Opening_and_purchases_and_increase_AUD / Opening_and_purchases_and_increase_count,
	Revenue	is Gross_sales_AUD + Killed_for_rations_or_exchanged_for_goods_AUD,
	Livestock_COGS is Opening_and_purchases_and_increase_AUD - Stock_on_hand_at_end_of_year_AUD,
	Gross_Profit_on_Livestock_Trading is Revenue - Livestock_COGS.
		


write_livestock_xml_response(
	% abstract on this:
	Killed_for_rations_or_exchanged_for_goods_AUD,
	Stock_on_hand_at_end_of_year_AUD,
	Losses_and_closing_and_killed_and_sales_count,
	Losses_and_closing_and_killed_and_sales_AUD,
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
	write_tag('Killed_for_rations_or_exchanged_for_goods_AUD',Killed_for_rations_or_exchanged_for_goods_AUD),
	write_tag('Stock_on_hand_at_end_of_year_AUD',Stock_on_hand_at_end_of_year_AUD),
	write_tag('Losses_and_closing_and_killed_and_sales_count',Losses_and_closing_and_killed_sales_count),
	write_tag('Losses_and_closing_and_killed_and_sales_AUD',Losses_and_closing_and_killed_sales_AUD),
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

		
% read XML into input vars
% run calculations on input vars to get output vars
% write output vars to XML

/*
- idk if there will be any atom-to-number conversions needed
- i'd just output all the intermediate calculations along with the results
- need to capitalize the uncapitalized ones, to be treated as variables


*/

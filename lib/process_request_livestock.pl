:- module(_, []).
/*
standalone livestock calculator
*/
:- use_module(library(xpath)).
:- use_module(library(xbrl/utils), [
	inner_xml/3, write_tag/2, fields/2, numeric_fields/2, 
	pretty_term_string/2]).
:- use_module('report_page').
:- use_module('tables').
:- use_module(library(xbrl/files), [
	absolute_tmp_path/2
]).
:- use_module(library(xbrl/files), [
	validate_xml/3
]).
:- use_module(library(xbrl/doc), []).

:- ['livestock_calculator'].

process(File_Name, DOM, Reports) :-

	findall(Livestock, xpath(DOM, //reports/livestockaccount/livestocks/livestock, Livestock), Livestocks),
	Livestocks \= [],

	absolute_tmp_path(File_Name, Instance_File),
	absolute_file_name(my_schemas('bases/Reports.xsd'), Schema_File, []),
	validate_xml(Instance_File, Schema_File, Schema_Errors),
	(	Schema_Errors = []
	->	(
			writeln('<response>'),
			writeln('<livestocks>'),
			maplist(process, Livestocks, Alerts, File_Infos),
			Reports = _{
				 File_Infos,
				errors: [Schema_Errors, Alerts],
				warnings: []
			},
			writeln('</livestocks>'),
			writeln('</response>'),
			nl, nl
		)
	;	Reports = _{
			 [],
			errors: [Schema_Errors],
			warnings: []
		}
	).
	
process(DOM, [], Report_File_Info) :-
	extract_livestock_data(DOM, T),
	writeln('<livestock>'),

	doc(T, livestock:name, Name),
	doc(T, livestock:currency, Currency),
	doc(T, livestock:natural_increase_value_per_unit, exchange_rate(xxx, Name, Currency, NaturalIncreaseValuePerUnit)),
	doc(T, livestock:opening_cost,   value(Currency, Opening_Cost  )),
	doc(T, livestock:opening_count,  value(Name,    Opening_Count )),
	doc(T, livestock:purchase_cost,  value(Currency, Purchase_Cost )),
	doc(T, livestock:purchase_count, value(Name,    Purchase_Count)),
	%doc(T, livestock:rations_value,  value(Currency, Rations_Value )),
	doc(T, livestock:rations_count,  value(Name,    Rations_Count )),
	doc(T, livestock:sale_cost,      value(Currency, Sale_Cost     )),
	doc(T, livestock:sale_count,     value(Name,    Sale_Count    )),
	%doc(T, livestock:closing_value,  value(Currency, Closing_Value )),
	doc(T, livestock:closing_count,  value(Name,    Closing_Count )),
	doc(T, livestock:losses_count,   value(Name,    Losses_Count  )),
	doc(T, livestock:born_count,     value(Name,    Born_Count    )),
	doc(T, livestock:average_cost,   exchange_rate(xxx, Name, Currency, _)),


	compute_livestock_by_simple_calculation(Born_Count,NaturalIncreaseValuePerUnit,Sale_Count,Sale_Cost,Rations_Count,Opening_Count,Opening_Cost,Closing_Count,Purchase_Count,Purchase_Cost,Losses_Count,Killed_for_rations_value,Stock_on_hand_at_end_of_year_value,Closing_and_killed_and_sales_minus_losses_count,Closing_and_killed_and_sales_value,Opening_and_purchases_and_increase_count,Opening_and_purchases_value,Natural_Increase_value,Average_cost,Revenue,Livestock_COGS,Gross_Profit_on_Livestock_Trading, Explanation),
	
	findall(Line, (member(L, Explanation), atomic_list_concat(L, Line)),  Explanation_Lines),
	atomic_list_concat(Explanation_Lines, '\n', Explanation_Str),
	
	write_tag('name', Name),
	write_tag('currency', Currency),
	write_tag('unitsBorn',Born_Count),
	write_tag('naturalIncreaseValuePerUnit',NaturalIncreaseValuePerUnit),
	write_tag('unitsSales',Sale_Count),
	write_tag('saleValue',Sale_Cost),
	write_tag('unitsRations',Rations_Count),
	write_tag('unitsOpening',Opening_Count),
	write_tag('openingValue',Opening_Cost),
	write_tag('unitsClosing',Closing_Count),
	write_tag('unitsPurchases',Purchase_Count),
	write_tag('purchaseValue',Purchase_Cost),
	write_tag('unitsDeceased',Losses_Count),
	%write_tag('rationsValue',Rations_Value),
	%write_tag('closingValue',Closing_Value),
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

	format_row(Columns, Row0, Formatted_Row),
	row_to_html(Columns, Formatted_Row, Row_Html),

	findall(tr(td([colspan="5"],R)), member(R, Explanation), Explanations),
	header_html(Columns, Html_Header),
	flatten([Html_Header, Row_Html, Explanations], Table_Contents_Html),
	
	replace_nonalphanum_chars_with_underscore(Name, Fn_Suffix),
	atomic_list_concat(['livestock_report_', Fn_Suffix, '.html'], Fn),
	atomic_list_concat(['livestock_report_', Fn_Suffix, '_html'], Id),
	report_page_with_table(Name, Table_Contents_Html, Fn, Id, Report_File_Info).

/*
Optimally we should preload the Excel sheet with test data that when pressed, provides a controlled natural language response describing the set of processes the data underwent as a result of the computational rules along with a solution to the problem.
*/

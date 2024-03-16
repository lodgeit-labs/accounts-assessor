process_request_livestock(File_Name, DOM) :-
	findall(Livestock, xpath(DOM, //reports/livestockaccount/livestocks/livestock, Livestock), Livestocks),
	Livestocks \= [],
	resolve_specifier(loc(specifier, my_schemas('bases/Reports.xsd')), XSD),
	catch(
		(
			validate_xml2(File_Name, XSD),
			maplist(process_request_livestock2, Livestocks, Results),
			add_xml_result(element(response, [], [element(livestocks, [], Results)]))
		),
		E,
		(
			stringize(E,E_str),
			add_xml_result(element(response, [], [element(livestocks, [], element(livestock, [], element('Error', [], E_str)))]))
		)
	).

process_request_livestock2(DOM, element(livestock, [], Xml)) :-
	extract_livestock_data(DOM, T),

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

	maplist(({Xml}/[(Tag_Name, Value)]>>(add(Xml, element(Tag_Name, [], [Value])))), [
		('name', Name),
		('currency', Currency),
		('unitsBorn',Born_Count),
		('naturalIncreaseValuePerUnit',NaturalIncreaseValuePerUnit),
		('unitsSales',Sale_Count),
		('saleValue',Sale_Cost),
		('unitsRations',Rations_Count),
		('unitsOpening',Opening_Count),
		('openingValue',Opening_Cost),
		('unitsClosing',Closing_Count),
		('unitsPurchases',Purchase_Count),
		('purchaseValue',Purchase_Cost),
		('unitsDeceased',Losses_Count),
		%('rationsValue',Rations_Value),
		%('closingValue',Closing_Value),
		('Killed_for_rations_value',	Killed_for_rations_value),
		('Stock_on_hand_at_end_of_year_value',					Stock_on_hand_at_end_of_year_value),
		('Closing_and_killed_and_sales_minus_losses_count',	Closing_and_killed_and_sales_minus_losses_count),
		('Closing_and_killed_and_sales_value',					Closing_and_killed_and_sales_value),
		('Opening_and_purchases_and_increase_count',			Opening_and_purchases_and_increase_count),
		('Opening_and_purchases_value',						Opening_and_purchases_value),
		('Natural_Increase_value',								Natural_Increase_value),
		('Average_cost',										Average_cost),
		('Revenue',											Revenue),
		('Livestock_COGS',										Livestock_COGS),
		('Gross_Profit_on_Livestock_Trading', 					Gross_Profit_on_Livestock_Trading),
		('Explanation', 										Explanation_Str)
	]).



/*
Optimally we should preload the Excel sheet with test data that when pressed, provides a controlled natural language response describing the set of processes the data underwent as a result of the computational rules along with a solution to the problem.
*/


/*
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
	add_report_page_with_table(Name, Table_Contents_Html, loc(file_name,Fn), Id, Report_File_Info)
*/

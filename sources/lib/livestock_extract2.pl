unused.

extract_livestock_data_from_ledger_request(Request_Dom) :-
	findall(Livestock_Dom, xpath(Request_Dom, //reports/balanceSheetRequest/livestockData, Livestock_Dom), Livestock_Doms),
	maplist(extract_livestock_data, Livestock_Doms, _).

extract_livestock_data(Livestock_Dom, B) :-
	doc_new_theory(B),
	/* optimally, we'd also create a 'user_input' graph and link it to the theory */
	/*doc_assert(G, g:is_extracted_from_request_xml, true), goes into request graph */
	fields(Livestock_Dom, [
		'name', Name_Atom,
		'currency', Currency_Atom]),
	numeric_fields(Livestock_Dom, [
		'naturalIncreaseValuePerUnit', NaturalIncreaseValuePerUnit,
		'openingValue'  ,Opening_Cost,
		'unitsOpening'  ,Opening_Count,
		'closingValue'  ,(Closing_Value,_),
		'unitsClosing'  ,(Closing_Count,_),
		'rationsValue'  ,(Rations_Value,_),
		'unitsRations'  ,Rations_Count,
		'unitsDeceased' ,Losses_Count,
		'unitsBorn'     ,Born_Count,
		'saleValue'     ,(Sale_Cost,_),
		'unitsSales'    ,(Sale_Count,_),
		'purchaseValue' ,(Purchase_Cost,_),
		'unitsPurchases',(Purchase_Count,_)
	]),
	doc_add(B, rdf:type, l:livestock_data),

	$>doc_add_rdf(B, livestock:currency, value(currency, Currency_Atom)) = Currency,
	$>doc_add_rdf(B, livestock:name,     value(unit,     Name_Atom)) =     Name,

	doc_add_rdf(B, livestock:nivpu,          value(ratio(Name,Currency), NaturalIncreaseValuePerUnit)),
	doc_add_rdf(B, livestock:opening_cost,   value(Currency,  Opening_Cost  )),
	doc_add_rdf(B, livestock:opening_count,  value(Name,      Opening_Count )),
	doc_add_rdf(B, livestock:purchase_cost,  value(Currency,  Purchase_Cost )),
	doc_add_rdf(B, livestock:purchase_count, value(Name,      Purchase_Count)),
	doc_add_rdf(B, livestock:rations_value,  value(Currency,  Rations_Value )),
	doc_add_rdf(B, livestock:rations_count,  value(Name,      Rations_Count )),
	doc_add_rdf(B, livestock:sale_cost,      value(Currency,  Sale_Cost     )),
	doc_add_rdf(B, livestock:sale_count,     value(Name,      Sale_Count    )),
	doc_add_rdf(B, livestock:closing_value,  value(Currency,  Closing_Value )),
	doc_add_rdf(B, livestock:closing_count,  value(Name,      Closing_Count )),
	doc_add_rdf(B, livestock:losses_count,   value(Name,      Losses_Count  )),
	doc_add_rdf(B, livestock:born_count,     value(Name,      Born_Count    )),
	doc_add_rdf(B, livestock:average_cost,   value(ratio(Name,Currency, _)),
    true.

:- module(_, []).
:- use_module(library(xbrl/utils), []).
:- use_module(library(xpath)).
:- use_module('doc', []).

extract(Request_Dom) :-
	findall(Livestock_Dom, xpath(Request_Dom, //reports/balanceSheetRequest/livestockData, Livestock_Dom), Livestock_Doms),
	maplist(extract_livestock_data, Livestock_Doms, _).

extract_livestock_data(Livestock_Dom, B) :-
	doc:doc_new_theory(B),
	/* optimally, we'd also create a 'user_input' graph and link it to the theory */
	/*doc_assert(G, g:is_extracted_from_request_xml, true), goes into request graph */
	utils:fields(Livestock_Dom, [
		'name', Name,
		'currency', Currency]),
	utils:numeric_fields(Livestock_Dom, [
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
	doc:doc_add(B, rdf:type, l:livestock_data),
	doc:doc_add(B, livestock:name, Name),
	doc:doc_add(B, livestock:currency, Currency),
	doc:doc_add(B, livestock:natural_increase_value_per_unit, exchange_rate(xxx, Name, Currency, NaturalIncreaseValuePerUnit)),
	doc:doc_add(B, livestock:opening_cost,   value(Currency, Opening_Cost  )),
	doc:doc_add(B, livestock:opening_count,  value(Name,    Opening_Count )),
	doc:doc_add(B, livestock:purchase_cost,  value(Currency, Purchase_Cost )),
	doc:doc_add(B, livestock:purchase_count, value(Name,    Purchase_Count)),
	doc:doc_add(B, livestock:rations_value,  value(Currency, Rations_Value )),
	doc:doc_add(B, livestock:rations_count,  value(Name,    Rations_Count )),
	doc:doc_add(B, livestock:sale_cost,      value(Currency, Sale_Cost     )),
	doc:doc_add(B, livestock:sale_count,     value(Name,    Sale_Count    )),
	doc:doc_add(B, livestock:closing_value,  value(Currency, Closing_Value )),
	doc:doc_add(B, livestock:closing_count,  value(Name,    Closing_Count )),
	doc:doc_add(B, livestock:losses_count,   value(Name,    Losses_Count  )),
	doc:doc_add(B, livestock:born_count,     value(Name,    Born_Count    )),
	doc:doc_add(B, livestock:average_cost,   exchange_rate(xxx, Name, Currency, _)),
    true.

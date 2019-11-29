:- module(_, []).
:- use_module('utils', []).

extract(Doms) :-
	maplist(extract_livestock_data, Doms).

extract_livestock_data(Livestock_Dom) :-
	doc_new_theory(B),
	/* optimally, we'd also create a 'user_input' graph and link it to the theory */
	/*doc_assert(G, g:is_extracted_from_request_xml, true), goes into request graph */
	utils:fields(Livestock_Dom, [
		'name', Name
		'currency', Currency]),
	utils:numeric_fields(Livestock_Dom, [
	    'naturalIncreaseValuePerUnit', NaturalIncreaseValuePerUnit,
		'openingValue'  ,Opening_Cost,
		'unitsOpening'  ,Opening_Count,
		'unitsClosing'  ,Closing_Count,
		'closingValue'  ,Closing_Value,
		'unitsRations'  ,Rations_Count,
		'rationsValue'  ,Rations_Value,
		'unitsDeceased' ,Losses_Count,
		'unitsBorn'     ,Born_Count,
		'saleValue'     ,(Sale_Cost,_),
		'unitsSales'    ,(Sale_Count,_),
		'purchaseValue' ,(Purchase_Cost,_),
        'unitsPurchases',(Purchase_Count,_)
    ]),
	doc_add(B, rdf:a, l:livestock_data),
	doc_add(B, livestock:name, Name),
	doc_add(B, livestock:currency, Currency),
	doc_add(B, livestock:natural_increase_value_per_unit, exchange_rate(xxx, Name, Currency, NaturalIncreaseValuePerUnit)),
	doc_add(B, livestock:opening_cost,   value(Currency, Opening_Cost  )),
	doc_add(B, livestock:opening_count,  value(count,    Opening_Count )),
	doc_add(B, livestock:purchase_cost,  value(Currency, Purchase_Cost )),
	doc_add(B, livestock:purchase_count, value(count,    Purchase_Count)),
    doc_add(B, livestock:rations_value,  value(Currency, Rations_Value )),
	doc_add(B, livestock:rations_count,  value(count,    Rations_Count )),
	doc_add(B, livestock:sale_cost,      value(Currency, Sale_Cost     )),
	doc_add(B, livestock:sale_count,     value(count,    Sale_Count    )),
    doc_add(B, livestock:closing_value,  value(Currency, Closing_Value )),
	doc_add(B, livestock:closing_count,  value(count,    Closing_Count )),
    doc_add(B, livestock:losses_count,   value(count,    Losses_Count  )),
    doc_add(B, livestock:born_count,     value(count,    Born_Count    )),
    doc_add(B, livestock:average_cost,   value(Currency, _             )),

    true.


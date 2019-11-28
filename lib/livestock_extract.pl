:- module(_, []).
:- use_module('utils', []).

extract(Doms) :-
	maplist(extract_livestock_data, Doms).

extract_livestock_data(Livestock_Dom) :-
	new_graph(G),
	rdf_assert(G, g:is_extracted_from_request_xml, true), /* goes into request graph */
	rdf_create_bnode(B),

	utils:fields(Livestock_Dom, [
		'name', Type
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

	my_rdf:add          (B, rdf:a, l:livestock_data, G),
	my_rdf:add          (B, livestock:type, Type, G),
	my_rdf:add          (B, livestock:currency, Currency, G),
	my_rdf:add          (B, livestock:natural_increase_value_per_unit, value(Currency, NaturalIncreaseValuePerUnit), G),

	my_rdf:add          (B, livestock:opening_cost,   value(Currency, Opening_Cost  ), G),
	my_rdf:add          (B, livestock:opening_count,  value(count,    Opening_Count ), G),
	my_rdf:add_if_ground(B, livestock:purchase_cost,  value(Currency, Purchase_Cost ), G),
	my_rdf:add_if_ground(B, livestock:purchase_count, value(count,    Purchase_Count), G),
    my_rdf:add_if_ground(B, livestock:rations_value,  value(Currency, Rations_Value ), G),
	my_rdf:add          (B, livestock:rations_count,  value(count,    Rations_Count ), G),
	my_rdf:add_if_ground(B, livestock:sale_cost,      value(Currency, Sale_Cost     ), G),
	my_rdf:add_if_ground(B, livestock:sale_count,     value(count,    Sale_Count    ), G),
    my_rdf:add_if_ground(B, livestock:closing_value,  value(Currency, Closing_Value ), G),
	my_rdf:add_if_ground(B, livestock:closing_count,  value(count,    Closing_Count ), G),
    my_rdf:add          (B, livestock:losses_count,   value(count,    Losses_Count  ), G),
    my_rdf:add          (B, livestock:born_count,     value(count,    Born_Count    ), G).




process_request_depreciation_new :-
	docm(l:request, l:has, Queries_List),
	doc_list_items(Queries_List, Queries),
	gtrace,
	maplist(process_depreciation_query, Queries).

process_depreciation_query(Query) :-
	doc_value(Query, l:depreciation_query_has_type, Type),
	process_depreciation_query2(Type, Query).

process_depreciation_query2(
	'https://lodgeit.net.au/#depreciation_query_type_depreciation_pool_from_start', Query) :-
	depreciation_pool_from_start(Pool,To_date,Method,Total_depreciation)

	gtrace.













	/*,
	doc(Q, rdf:type, l:depreciation_query),
	doc(Q, l:scenario_label, Scenario_Label),
	doc(Q, l:start_date, Query_Start_Date),
	doc(Q, l:end_date, Query_Start_Date),
	doc(S, rdf:type, l:depreciation_scenario),
	doc(S, rdfs:label, Scenario_Label),
	doc(S, l:method, _Method),
	findall(
		_,
		(	(	doc(Q, l:contains, Asset),
				doc(Q, rdf:type, l:depreciation_asset))
		->	(	doc(Asset, l:asset_type_label, Asset_Type_Label),
				doc(Asset, l:cost, Cost),
				doc(Asset, l:start_date, Invest_In_Date),
				_Transaction = transaction(Invest_In_Date, unused_field, Asset_Type_Label, t_term(Cost, unused_field)),
				depreciation_computation_new:depreciation_between_two_dates(Transaction, Invest_In_Date, Query_Start_Date, Method, Depreciation_Value),
				doc_add(Asset, l:depreciation_between_two_dates, Depreciation_Value)
				)
		;	throw(xxx)),
		_
	).*/


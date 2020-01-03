:- use_module(depreciation_computation, []).
:- use_module(library(fnotation)).

process_request_depreciation_new :-
	maplist(process_depreciation_asset, $> doc_list_items($> doc(l:request, l:depreciation_assets))),
	maplist(process_depreciation_event, $> doc_list_items($> doc(l:request, l:depreciation_events))),
	maplist(process_depreciation_query, $> doc_list_items($> doc(l:request, l:depreciation_queries))).

process_depreciation_asset(I) :-
	event_calculus:assert_asset(
		$> doc_value(I, l:id),
		$> doc_value(I, l:cost),
		$> doc_value(I, l:start_date),
		$> doc_value(I, l:effective_life_years)).

process_depreciation_event(I) :-
	doc_value(I, l:depreciation_event_has_type, Type),
	doc_value(I, l:depreciation_event_asset, Asset),
	absolute_day($> doc_value(I, l:depreciation_event_date), Days),
	(	Type == l:transfer_asset_to_pool
	->	(
			atom_string($> doc_value(I, l:depreciation_event_pool), Pool),
			event_calculus:assert_event(transfer_asset_to_pool(Asset,Pool),Days)
		)
		;
			event_calculus:assert_event(asset_disposal(Asset),Days)
	).

process_depreciation_query(Query) :-
	doc_value(Query, l:depreciation_query_has_type, Type),
	process_depreciation_query2(Type, Query).

process_depreciation_query2(
	'https://lodgeit.net.au/#depreciation_pool_from_start', Q) :-
	depreciation_computation:depreciation_pool_from_start(
		$>doc_value(Q,
			l:depreciation_query_pool),
		$>absolute_day($> doc_value(Q,
			l:depreciation_query_to_date)),
		$>atom_string($<, $>doc_value(Q,
			l:depreciation_query_method)),
		$>doc_add_value(Q,
			l:depreciation_query_total_depreciation)
	).

process_depreciation_query2(
	'https://lodgeit.net.au/#depreciation_between_two_dates', Q) :-
	depreciation_computation:depreciation_between_two_dates(
		$>doc_value(Q, l:depreciation_query_asset_id),
		$>doc_value(Q, l:depreciation_query_from_date),
		$>doc_value(Q, l:depreciation_query_to_date),
		$>atom_string($<, $>doc_value(Q, l:depreciation_query_method)),
		$>doc_add_value(Q, l:depreciation_query_depreciation_value)
	).

process_depreciation_query2(
	'https://lodgeit.net.au/#written_down_value', Q) :-
	depreciation_computation:written_down_value(
		$>doc_value(Q, l:depreciation_query_asset_id),
		$>doc_value(Q, l:depreciation_query_written_down_date),
		$>atom_string($<, $>doc_value(Q, l:depreciation_query_method)),
		_,
		$>doc_add_value(Q, l:depreciation_query_written_down_value)
	).

process_depreciation_query2(
	'https://lodgeit.net.au/#profit_and_loss', Q) :-
	depreciation_computation:profit_and_loss(
		$>doc_value(Q, l:depreciation_query_asset_id),
		$>doc_value(Q, l:depreciation_query_termination_value),
		$>doc_value(Q, l:depreciation_query_termination_date),
	   _,
		$>doc_add_value(Q, l:depreciation_query_profit_and_loss)
	).




















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


:- use_module(depreciation_computation, []).
%:- use_module(library(fnotation)).

process_request_depreciation_new :-
	request_data(D),
	doc_value(D, depr_ui:depreciation_queries, _),

	(	maplist(process_depreciation_asset, $> doc_list_items($> doc_value(D, depr_ui:depreciation_assets)))
	->	true
	;	throw_string('depreciation: assets processing failed')),

	% events sheet is optional
	(	doc_value(D, depr_ui:depreciation_events, Events)
	->	(	maplist(process_depreciation_event, $> doc_list_items(Events))
		->	true
		;	throw_string('depreciation: events processing failed'))
	;	true
	),

	(	maplist(process_depreciation_query, $> doc_list_items($> doc_value(D, depr_ui:depreciation_queries)))
	->	true
	;	throw_string('depreciation: queries processing failed')).

process_depreciation_asset(I) :-
	event_calculus:assert_asset(
		$> doc_value(I, depr:id),
		$> doc_value(I, depr:cost),
		$> doc_value(I, depr:start_date),
		$> doc_value(I, depr:effective_life_years)).

process_depreciation_event(I) :-
	doc_value(I, depr:depreciation_event_has_type, Type),
	doc_value(I, depr:depreciation_event_asset, Asset),
	doc_value(I, depr:depreciation_event_date, Date),
	days_from_begin_accounting(Date, Days),
	(	rdf_equal2(Type, depr:transfer_asset_to_pool)
	->	atom_string(Pool, $>doc_value(I, depr:depreciation_event_pool)),
		(	begin_income_year(Date)
		->	true
		;	throw_string('can only transfer asset to pool on beginning of income year')),
		!event_calculus:assert_event(transfer_asset_to_pool(Asset,Pool),Days)
	;	assertion(rdf_equal2(Type, depr:asset_disposal)),
		!event_calculus:assert_event(asset_disposal(Asset),Days)).



process_depreciation_query(Query) :-
	doc_value(Query, depr:depreciation_query_has_type, Type),
	process_depreciation_query2(Type, Query).

depreciation_query_method(Q, Method_atom) :-
	doc_value(Q, depr:depreciation_query_method, Uri),
	(	rdf_equal2(depr:diminishing_value, Uri)
	->	Method_atom = diminishing_value
	;	Method_atom = prime_cost).

process_depreciation_query2(
	'https://rdf.lodgeit.net.au/v1/calcs/depr#depreciation_pool_from_start', Q) :-
	format(user_error, '~nquery:~n', []),
	depreciation_computation:depreciation_pool_from_start(
		$>atom_string(<$, $>doc_value(Q,
			depr:depreciation_query_pool)),
		$>doc_value(Q,	depr:depreciation_query_to_date),
		$>depreciation_query_method(Q),
		$>doc_add_value(Q,
			depr:depreciation_query_total_depreciation)
	).

process_depreciation_query2(
	'https://rdf.lodgeit.net.au/v1/calcs/depr#depreciation_between_two_dates', Q) :-
	format(user_error, '~nquery:~n', []),
	depreciation_computation:depreciation_between_two_dates(
		$>doc_value(Q, depr:depreciation_query_asset_id),
		$>doc_value(Q, depr:depreciation_query_from_date),
		$>doc_value(Q, depr:depreciation_query_to_date),
		$>depreciation_query_method(Q),
		$>doc_add_value(Q, depr:depreciation_query_depreciation_value)
	).

process_depreciation_query2(
	'https://rdf.lodgeit.net.au/v1/calcs/depr#written_down_value', Q) :-
	format(user_error, '~nquery:~n', []),
	depreciation_computation:written_down_value(
		$>doc_value(Q, depr:depreciation_query_asset_id),
		$>doc_value(Q, depr:depreciation_query_written_down_date),
		$>depreciation_query_method(Q),
		_,
		$>doc_add_value(Q, depr:depreciation_query_written_down_value)
	).

process_depreciation_query2(
	'https://rdf.lodgeit.net.au/v1/calcs/depr#profit_and_loss', Q) :-
	format(user_error, '~nquery:~n', []),
	depreciation_computation:profit_and_loss(
		$>doc_value(Q, depr:depreciation_query_asset_id),
		$>doc_value(Q, depr:depreciation_query_termination_value),
		$>doc_value(Q, depr:depreciation_query_termination_date),
		$>depreciation_query_method(Q),
		$>doc_add_value(Q, depr:depreciation_query_profit_and_loss)
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


/*

asset_rate(Q, Asset_Type_Label, R) :-
	doc(Q, l:contains, R),
	doc(R, rdf:type, l:depreciation_rate),
	doc(R, l:asset_type_label, Asset_Type_Label),
	!.

asset_rate(_Q, Asset_Type_Label, R) :-
	asset_type_hierarchy_ancestor(Asset_Type_Label, Ancestor_Label),
	doc(R, rdf:type, l:depreciation_rate),
	doc(R, l:asset_type_label, Ancestor_Label),
	!.


asset_type_hierarchy_ancestor(Label, Ancestor_Label) :-
	doc(I, rdf:type, l:depreciation_asset_type_hierarchy_item),
	doc(I, l:child_label, Label),
	doc(I, l:parent_label, Ancestor_Label).

asset_type_hierarchy_ancestor(Label, Ancestor_Label) :-
	doc(I, rdf:type, l:depreciation_asset_type_hierarchy_item),
	doc(I, l:child_label, Label),
	doc(I, l:parent_label, Parent_Label),
	asset_type_hierarchy_ancestor(Parent_Label, Ancestor_Label).


*/

:- use_module(depreciation_computation, []).
:- use_module(library(fnotation)).

process_request_depreciation_new :-
	docm(l:request, l:has, Queries_List),
	doc_list_items(Queries_List, Queries),
	gtrace,
	maplist(process_depreciation_query, Queries).

process_depreciation_query(Query) :-
	doc_value(Query, l:depreciation_query_has_type, Type),
	process_depreciation_query2(Type, Query).

process_depreciation_query2(
	'https://lodgeit.net.au/#depreciation_pool_from_start', Q) :-
	doc_value(Q, l:depreciation_query_pool, Pool),
	doc_value(Q, l:depreciation_query_to_date, To_Date),
	doc_value(Q, l:depreciation_query_method, Method),
	doc_add_value(Q, l:depreciation_query_total_depreciation, Total_Depreciation),
	depreciation_computation:depreciation_pool_from_start(Pool,To_Date,Method,Total_Depreciation)/*,
	gtrace*/.

process_depreciation_query2(
	'https://lodgeit.net.au/#depreciation_between_two_dates', Q) :-
	doc_value(Q, l:depreciation_query_asset_id, Asset_id),
	doc_value(Q, l:depreciation_query_from_date, From_date),
	doc_value(Q, l:depreciation_query_to_date, To_date),
	doc_value(Q, l:depreciation_query_method, Method),
	doc_add_value(Q, l:depreciation_query_depreciation_value, Depreciation_value),
	depreciation_between_two_dates(Asset_id, From_date, To_date, Method, Depreciation_value).

process_depreciation_query2(
	'https://lodgeit.net.au/#depreciation_written_down_value', Q) :-
	doc_value(Q, l:depreciation_query_asset_id, Asset_id),
	doc_value(Q, l:depreciation_query_written_down_date, Written_down_date),
	doc_value(Q, l:depreciation_query_method, Method),
	doc_add_value(Q, l:depreciation_query_written_down_value, Written_down_value),
	written_down_value(Asset_id, Written_down_date, Method, _, Written_down_value).

process_depreciation_query2(
	'https://lodgeit.net.au/#depreciation_profit_and_loss', Q) :-
	doc_value(Q, l:depreciation_query_asset_id, Asset_id),
	doc_value(Q, l:depreciation_query_termination_value, Termination_value),
	doc_value(Q, l:depreciation_query_termination_date, Termination_date),
	doc_add_value(Q, l:depreciation_query_profit_and_loss, ProfitAndLoss),
	profit_and_loss(Asset_id, Termination_value, Termination_date, _, ProfitAndLoss).















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


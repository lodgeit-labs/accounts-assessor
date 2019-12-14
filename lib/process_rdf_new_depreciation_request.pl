:- module(_, []).

:- use_module(library(xbrl/utils)).
:- use_module('doc', []).
:- use_module('depreciation_computation_new', []).




process_rdf_depreciation_new_request(Reports) :-
	doc(Q, rdf:a, l:depreciation_query),
	doc(Q, l:scenario_label, Scenario_Label),
	doc(Q, l:start_date, Query_Start_Date),
	doc(Q, l:end_date, Query_Start_Date),
	doc(S, rdf:a, l:depreciation_scenario),
	doc(S, rdfs:label, Scenario_Label),
	doc(S, l:method, Method),

	findall(_,(
		(	(	doc(Q, l:contains, Asset),
				doc(Q, rdf:a, l:depreciation_asset))
		->	(	doc(Asset, l:asset_type_label, Asset_Type_Label),
				doc(Asset, l:cost, Cost),
				doc(Asset, l:start_date, Invest_In_Date),
				Transaction = transaction(Date, unused_field, Asset_Type_Label, t_term(Cost, unused_field)),
				depreciation_between_two_dates(Transaction, Invest_In_Date, Query_Start_Date, Method, Depreciation_Value),
				doc_add(Asset, l:depreciation_between_two_dates, Depreciation_Value)
				)
		;	throw(xxx))),
	report_file_path('response.n3', Report_Url, Report_File_Path),
	doc_to_rdf(Rdf_Graph),
	rdf_save(Report_File_Path, [graph(Rdf_Graph), sorted(true)]).
	Reports = _{files:[Report_File_Path], alerts:[]}.

doc_to_rdf(Rdf_Graph) :-
	rdf_create_bnode(Rdf_Graph),
	findall(_
		(
			doc(X,Y,Z),
			rdf_assert(X,Y,Z,Rdf_Graph)
		),_).



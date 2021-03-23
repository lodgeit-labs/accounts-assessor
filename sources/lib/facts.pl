/*
mock_request :-
	doc_init.
*/
 make_fact(Vec, Aspects, Uri) :-
 	push_format('~q = ~q', [Aspects, $>round_term(Vec)]),
	!doc_new_uri(fact, Uri),
	!doc_add(Uri, rdf:type, l:fact),
	!doc_add(Uri, l:vec, $>flatten([Vec])),
	!doc_add(Uri, l:aspects, Aspects),
	pop_context.

 make_fact(Vec, Aspects) :-
	make_fact(Vec, Aspects, _).

 fact_vec(Uri, X) :-
	doc(Uri, l:vec, X).



/*
find all facts with matching aspects
for a fact to match, it has to have all the aspects present in Aspects, and they have to unify.
rest of aspects of the fact are ignored. All matching facts are returned. Unifications
are not preserved.
*/
 facts_by_aspects(aspects(Aspects), Facts) :-
	findall(
		Uri,
		(
			doc(Uri, rdf:type, l:fact),
			doc(Uri, l:aspects, aspects(Aspects2)),
			maplist(rebmem(Aspects2), Aspects)
		),
		Facts
	).



/*
given account role, get balance from corresponding report_entry, and assert a fact (with given aspects)
*/

 add_fact_by_account_role(Json_reports, aspects(Aspects)) :-
	!member(report - Report_path, Aspects),
	path_get_dict(Report_path, Json_reports, Report),
	!member(account_role - Role, Aspects),
	!report_entry_vec_by_role(Report, Role, Vec),
	!account_normal_side($>abrlt(Role), Side),
	maplist(!coord_normal_side_value2(Side), Vec, Values),
	!make_fact(Values, aspects(Aspects), _).

%add_sum_fact_from_report_entries_by_roles(Bs, Roles, New_fact_aspects) :-
%	!maplist(report_entry_vec_by_role(Bs), Roles, Vecs),
%	!vec_sum(Vecs, Sum),
%	!make_fact(Sum, New_fact_aspects, _).



/*
input: 2d matrix of aspect terms and other stuff.
extend aspect terms with additional aspect
*/

add_aspect_to_table(Aspect, In, Out) :-
	!maplist(add_aspect_to_row(Aspect), In, Out).
add_aspect_to_row(Aspect, In, Out) :-
	!maplist(tbl_add_aspect(Aspect), In, Out).
/* add aspect if this is an aspects([..]) term, otherwise return it as it is */
tbl_add_aspect(_, X, X) :-
	X \= aspects(_).
tbl_add_aspect(Aspect, aspects(Aspects), aspects(Aspects2)) :-
	append(Aspects, [Aspect], Aspects2).



/*
input: 2d matrix of aspect terms and other stuff.
replace aspect(..) terms with values
*/

 evaluate_fact_table(Pres, Tbl) :-
	maplist(evaluate_fact_table3, Pres, Tbl).

 evaluate_fact_table3(Row_in, Row_out) :-
	maplist(evaluate_fact, Row_in, Row_out).

 evaluate_fact(X, X) :-
	X \= aspects(_).

 evaluate_fact(In, with_metadata(Values,In)) :-
	evaluate_fact2(In, Values).

 evaluate_fact2(In,Sum) :-
	In = aspects(_),
	!facts_by_aspects(In, Facts),
	!facts_vec_sum(Facts, Sum).

 facts_vec_sum(Facts, Sum) :-
	!maplist(fact_vec, Facts, Vecs),
	!vec_sum(Vecs, Sum).





add_summation_fact(Summed_aspectses, Sum_aspectses) :-
	maplist(!facts_by_aspects, Summed_aspectses, Factses),
	flatten(Factses, Facts),
	!facts_vec_sum(Facts, Vec),
	!make_fact(Vec, Sum_aspectses).






 optionally_assert_doc_value_as_unit_fact(Default_currency, Unit, Item, Prop) :-
	(	assert_doc_value_as_unit_fact(Default_currency, Unit, Item, Prop)
	->	true
	;	true).

 assert_doc_value_as_unit_fact(Default_currency, Unit, Item, Prop) :-
	assert_doc_value_as_unit_fact_with_concept(Default_currency, Unit, Item, Prop, Prop).

 assert_doc_value_as_unit_fact_with_concept(Default_currency, Unit, Item, Prop, Concept) :-
	assert_doc_value_as_fact(Item, Prop, Default_currency,
		aspects([
			concept - ($>rdf_global_id(Concept)),
			unit - Unit
	])).

 assert_doc_value_as_fact(Item, Prop, Default_currency, Aspects) :-
	read_value_from_doc_string(Item, Prop, Default_currency, Value),
	!make_fact(Value, Aspects, Uri),
	!doc_add(Uri, l:source, $>doc(Item, Prop)).


computed_unit_fact(Unit, Exp) :-
	exp_concept_to_aspects(Exp, Aspects_exp),
	exp_add_aspect(Aspects_exp, unit - Unit, Aspects_exp_with_aspect_added),
	exp_compute(Aspects_exp_with_aspect_added).

concept_to_aspects(Concept, Aspects) :-
	(	atom(Concept)
	;	Concept = _:_),
	Aspects = aspects([concept - ($>rdf_global_id(Concept))]).

concept_to_aspects(X, X) :-
	(number(X),!);(rational(X),!).

walk_exp(Func, Exp, Exp2) :-
	call(Func, Exp, Exp2),
	!.

walk_exp(Func, Exp, Exp2) :-
	Exp =.. [Functor | Args],
	maplist(walk_exp(Func), Args, Args2),
	Exp2 =.. [Functor | Args2],
	!.

exp_concept_to_aspects(Exp, Aspects) :-
	walk_exp(concept_to_aspects, Exp, Aspects).

exp_add_aspect(Aspects_exp, Added, Aspects_exp_with_aspect_added) :-
	walk_exp(add_aspect(Added), Aspects_exp, Aspects_exp_with_aspect_added).

exp_compute(A = B) :-
	assertion(A = aspects(_)),
	!exp_eval(B, B2),
	!facts_by_aspects(A, Already_asserted),
	(	Already_asserted = []
	->	true
	;	throw_string('exp_compute internal error')),
	!make_fact(B2, A).

exp_eval(X, X) :-
	is_list(X). % a vector

exp_eval(X, X2) :-
	X = aspects(_),
	!evaluate_fact2(X,X2).

exp_eval(A + B, C) :-
	exp_eval(A, A2),
	exp_eval(B, B2),
	vec_add(A2, B2, C).

exp_eval(A - B, C) :-
	exp_eval(A, A2),
	exp_eval(B, B2),
	vec_sub(A2, B2, C).

exp_eval(A * B, C) :-
	exp_eval(A, A2),
	((rational(B),!);(number(B),!)),
	{B2 = B * 100},
	split_vector_by_percent(A2, B2, C, _).

add_aspect(Added, aspects(X), aspects(Y)) :-
	append(X, [Added], Y).









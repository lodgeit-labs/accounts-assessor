
livestock_doc_calculator :-
	findall(L, doc(L, rdf:type, l:livestock_data), Ls),
	maplist(livestock_doc_calculator2, Ls).

livestock_doc_calculator2(L) :-
	Rules = [
(
	(L, rdf:type, l:livestock_data),
	(L, P, _),
=>
	(P, doc:cardinality, 1)
),
(
	(P, doc:cardinality, 1),
	(X, P, Y),
	(X, P, Z)
=>
	(Y = Z)
),
(
	(L, rdf:type, livestock:doc)
=>
	$>expand_uris(
		$>with_subj(L,
			$>with_base('livestock', [
					closing_count =:= opening_count + born_count + purchase_count - rations_count - losses_count - sale_count,
					born_value =:= born_count * nivpu,
					opening_and_purchases_and_increase_count =:= opening_count + purchases_count + born_count,
					opening_and_purchases_value =:= stock_on_hand_at_beginning_of_year_value + purchases_value,
					vverage_cost =:= (opening_and_purchases_value + born_value) /  opening_and_purchases_and_increase_count,
					closing_value =:= average_cost * stock_on_hand_at_end_of_year_count,
					rations_value =:= rations_count * average_cost,
					closing_and_killed_and_sales_minus_losses_count =:= sales_count + rations_count + closing_count - losses_count,
					closing_and_killed_and_sales_value = sales_value + rations_value + closing_value,
					revenue =:= sales_value,
					cogs =:= opening_and_purchases_value - closing_value - rations_value,
					profit =:= revenue - cogs
				]
			)
		)
	])
)],
	solve_doc_with_rules(Rules).



/*
	result from expanders (except ignoring expansion into full urls):

	L, rdf:type, livestock:doc
=>
	... ,
	L livestock:profit V1, L livestock:revenue V2, L livestock:cogs V3, V1 =:= V2 - V3
*/


solve_doc_with_rules(Rules) :-
	/*
	rules must be expressed in terms of values only, even constants must be wrapped.
	solver with deal with values under the hood. P = Q will be handled as P value PV, Q value QV, PV = QV.
	if P or Q has unit, those are unified too. Units of values figuring in constraints would be handled with your dimensional stuff. Everything should initially work just fine ignoring units.
	the solver has to iterate over doc triples in addition to iterating over inferred facts.
	doc triples should have the same treatment as inferred facts, wrt binding variables.
	when solving is done, final set of inferred facts will be doc_add'ed.
	*/



/*
	syntax sugar expanders
*/


with_subj(X, Triples_Out, Term, Term_Out) :-
	Term =.. [Term],
	!,
	Triples_Out = (X, Term, Term_Out).

with_subj(X, Arg_Triples_Out, Term, Term_Out) :-
	Term =.. [F|Args],
	Term_Out =.. [F|Args],
	maplist(with_subj(X), Arg_Triples_Out, Args, Args_Out).




with_base(Base, X, Base:X) :-
	atom(X), !.

with_base(Base, Prefix:X, Prefix:X),!.

with_base(Base, X, Y) :-
	X =.. [F|Args],
	Y =.. [F|Args2],
	maplist(with_base, Args, Args2).




expand_uris(Prefix:X, Y) :-
	rdf_global_term(Prefix:X, Y),!.

expand_uris(X, Y) :-
	atom(X), !.

expand_uris(X, Y) :-
	X =.. [F|Args],
	Y =.. [F|Args2],
	maplist(expand_uris, Args, Args2).




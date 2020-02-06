:- rdf_register_prefix(l,
'https://rdf.lodgeit.net.au/v1/request#').
:- rdf_register_prefix(livestock,
'https://rdf.lodgeit.net.au/v1/livestock#').
:- rdf_register_prefix(excel,
'https://rdf.lodgeit.net.au/v1/excel#').
:- rdf_register_prefix(depr,
'https://rdf.lodgeit.net.au/v1/calcs/depr#').
:- rdf_register_prefix(ic,
'https://rdf.lodgeit.net.au/v1/calcs/ic#').
:- rdf_register_prefix(hp,
'https://rdf.lodgeit.net.au/v1/calcs/hp#').
:- rdf_register_prefix(depr_ui,
'https://rdf.lodgeit.net.au/v1/calcs/depr/ui#').
:- rdf_register_prefix(ic_ui,
'https://rdf.lodgeit.net.au/v1/calcs/ic/ui#').
:- rdf_register_prefix(hp_ui,
'https://rdf.lodgeit.net.au/v1/calcs/hp/ui#').
:- rdf_register_prefix(transactions,
'https://rdf.lodgeit.net.au/v1/transactions#').
:- rdf_register_prefix(s_transactions,
'https://rdf.lodgeit.net.au/v1/s_transactions#').

/*@prefix depr_ui: <https://rdf.lodgeit.net.au/v1/calcs/depr/ui#> .
@prefix ic_ui: <https://rdf.lodgeit.net.au/v1/calcs/ic/ui#> .
@prefix hp_ui: <https://rdf.lodgeit.net.au/v1/calcs/hp/ui#> .*/



/*
a quad-store implemented with an open list stored in a global thread-local variable
*/

%:- debug(doc).

dump :-
	findall(_,
		(
			docm(S,P,O),
			debug(doc, 'dump:~q~n', [(S,P,O)])
		),
	_).

doc_clear :-
	b_setval(the_theory,_X),
	doc_set_default_graph(default).

doc_set_default_graph(G) :-
	b_setval(default_graph, G).

doc_add((S,P,O)) :-
	doc_add(S,P,O).

:- rdf_meta doc_add(r,r,r,r).

doc_add(S,P,O,G) :-
	debug(doc, 'add:~q~n', [(S,P,O)]),
	b_getval(the_theory,X),
	rol_add(X,(S,P,O,G)).

:- rdf_meta doc_add(r,r,r).

doc_add(S,P,O) :-
	b_getval(default_graph, G),
	doc_add(S,P,O,G).

doc_assert(S,P,O,G) :-
	b_getval(the_theory,X),
	rol_assert(X, (S,P,O,G)).

:- rdf_meta doc(r,r,r).
/*
must have at most one match
*/
doc(S,P,O) :-
	b_getval(default_graph, G),
	doc(S,P,O,G).

:- rdf_meta doc(r,r,r,r).
/*
must have at most one match
*/
doc(S,P,O,G) :-
	b_getval(the_theory,X),
	debug(doc, 'doc?:~q~n', [(S,P,O,G)]),
	rol_single_match(X,(S,P,O,G)).

:- rdf_meta docm(r,r,r).
/*
can have multiple matches
*/
docm(S,P,O) :-
	b_getval(default_graph, G),
	docm(S,P,O,G).

:- rdf_meta docm(r,r,r,r).
docm(S,P,O,G) :-
	b_getval(the_theory,X),
	debug(doc, 'docm:~q~n', [(S,P,O,G)]),
	rol_member(X,(S,P,O,G)).
/*
member
*/

exists(I) :-
	docm(I, exists, now);
	once((gensym(bn, I),doc_add(I, exists, now))).


has(S,P,O) :-
	(	doc(S,P,O2)
	->	O = O2
	;	doc_add(S,P,O)).

/*
?- make,doc_clear, doc_core:exists(First), has(First, num, 1), has(First, field, F1), doc_core:exists(Last), has(Last, num, N2), call_with_depth_limit(has(Last, field, "foo"), 15, Depth).
First = Last, Last = bn11,
F1 = "foo",
N2 = 1,
Depth = 14 ;
First = bn11,
Last = bn12,
Depth = 16.

?-
*/


/*
a thin layer above ROL
*/

rol_single_match(T,SpogA) :-
	/* only allow one match */
	findall(x,rol_member(T,SpogA),Matches),
	length(Matches, Length),
	(	Length > 1
	->	(
			format(string(Msg), 'multiple_matches, use docm: ~q', [SpogA]),
			%gtrace,
			throw_string(Msg)
		)
	;	rol_member(T,SpogA)).


/*
Reasonably Open List.
T is an open list. Unifying with the tail variable is only possible through rol_add.
*/

rol_add(T,Spog) :-
	/* ensure Spog is added as a last element of T, while memberchk would otherwise possibly just unify an existing member with it */
		rol_member(T,Spog)
	->	throw(added_quad_matches_existing_quad)
	;	memberchk(Spog,T).

rol_assert(T,Spog) :-
	rol_member(T,Spog)
	->	true
	;	memberchk(Spog,T).


rol_add_quiet(T, Spog) :-
		rol_member(T,Spog)
	->	true
	; 	memberchk(Spog,T).

/* nondet */
rol_member(T,SpogA) :-
	/* avoid unifying SpogA with the open tail of T */
	member(SpogB, T),
	(
		var(SpogB)
	->	(!,fail)
	;	SpogA = SpogB).

	/*match(SpogA, SpogB)).
match((S1,P1,O1,G1),(S2,P2,O2,G2))
	(	S1 = S2
	->	true
	;	rdf_equal(?Resource1, ?Resource2)
*/

/*
helper predicates
*/

doc_new_theory(T) :-
	doc_new_uri(T),
	doc_add(T, rdf:type, l:theory).

doc_new_uri(Uri) :-
	doc_new_uri(Uri, '').

doc_new_(Type, Uri) :-
	doc_new_uri(Uri),
	doc_add(Uri, rdf:type, Type).

doc_new_uri(Uri, Postfix) :-
	%tmp_file_url(loc(file_name, 'response.n3'), D),
	gensym('#bnx', Uri0),
	atomic_list_concat([Uri0, '_', Postfix], Uri).
	/*,
	atomic_list_concat([D, '#', Uid], Uri)*/
	/*,
	% this is maybe too strong because it can bind with variable nodes
	assertion(\+doc(Uri,_,_)),
	assertion(\+doc(_,_,Uri))
	*/

doc_init :-
	/*	i'm storing some data in the 'doc' rdf-like database, only as an experiment for now.
	livestock and action verbs exclusively, some other data in parallel with passing them around in variables..	*/
	doc_clear,
	doc_new_uri(R),
	/* fixme: we create a bnode of type l:request for storing and processing stuff, and excel sends an actual l:request. not sure what we want to do here. Im hesitant to turn the two objects into one. Possibly this should be l:processing or something. */
	doc_add(R, rdf:type, l:request).

doc_from_rdf(Rdf_Graph) :-
	findall((X,Y,Z),
		rdf(X,Y,Z,Rdf_Graph),
		Triples),
	maplist(triple_rdf_vs_doc, Triples, Triples2),
	maplist(doc_add, Triples2).

triple_rdf_vs_doc((S,P,O), (S,P,O2)) :-
	node_rdf_vs_doc(O,O2).

node_rdf_vs_doc(
	date_time(Y,M,D,0,0,0.0) ^^ 'http://www.w3.org/2001/XMLSchema#dateTime',
	date(Y,M,D)) :- !.

node_rdf_vs_doc(
	String ^^ 'http://www.w3.org/2001/XMLSchema#string',
	String):- string(String), !.

node_rdf_vs_doc(
	Int ^^ 'http://www.w3.org/2001/XMLSchema#integer',
	Int) :- integer(Int),!.

node_rdf_vs_doc(
	Float ^^ 'http://www.w3.org/2001/XMLSchema#decimal',
	Rat) :-
		freeze(Float, float(Float)),
		freeze(Rat, rational(Rat)),
		(	nonvar(Rat)
		->	Float is float(Rat)
		;	Rat is rationalize(Float)),!.

node_rdf_vs_doc(Atom, Atom)/* :- gtrace, writeq(Atom)*/.


doc_to_rdf(Rdf_Graph) :-
	rdf_create_bnode(Rdf_Graph),
	findall(_,
		(
			docm(X,Y,Z),
			triple_rdf_vs_doc((X2,Y2,Z2),(X,Y,Z)),
			debug(doc, 'to_rdf:~q~n', [(X2,Y2,Z2)]),
			rdf_assert(X2,Y2,Z2,Rdf_Graph)
		),_).


:- rdf_meta request_has_property(r,r).

request_has_property(P, O) :-
	request(R),
	doc(R, P, O).

:- rdf_meta request_add_property(r,r).

request_add_property(P, O) :-
	request(R),
	doc_add(R, P, O).

:- rdf_meta request_assert_property(r,r,r).

request_assert_property(P, O, G) :-
	request(R),
	doc_assert(R, P, O, G).

request(R) :-
	doc(R, rdf:type, l:request).

add_alert(Type, Msg) :-
	request(R),
	doc_new_uri(Uri),
	doc_add(R, l:alert, Uri),
	doc_add(Uri, l:type, Type),
	doc_add(Uri, l:message, Msg).

assert_alert(Type, Msg) :-
	/*todo*/
	request(R),
	doc_new_uri(Uri),
	doc_add(R, l:alert, Uri),
	doc_add(Uri, l:type, Type),
	doc_add(Uri, l:message, Msg).

get_alert(Type, Msg) :-
	request(R),
	docm(R, l:alert, Uri),
	doc(Uri, l:type, Type),
	doc(Uri, l:message, Msg).

add_comment_stringize(Title, Term) :-
	pretty_term_string(Term, String),
	add_comment_string(Title, String).

add_comment_string(Title, String) :-
	doc_new_uri(Uri),
	doc_add(Uri, title, Title, comments),
	doc_add(Uri, body, String, comments).

doc_list_member(M, L) :-
	doc(L, rdf:first, M).

doc_list_member(M, L) :-
	doc(L, rdf:rest, R),
	doc_list_member(M, R).

doc_list_items(L, Items) :-
	findall(Item, doc_list_member(Item, L), Items).

:- rdf_meta doc_value(r,r,r).

doc_value(S, P, V) :-
	doc(S, P, O),
	doc(O, rdf:value, V).

:- rdf_meta doc_add_value(r,r,r).

doc_add_value(S, P, V) :-
	doc_new_uri(Uri),
	doc_add(S, P, Uri),
	doc_add(Uri, rdf:value, V).

/*
user:goal_expansion(
	vague_props(X, variable_names(Names))
, X) :-
	term_variables(X, Vars),
	maplist(my_variable_naming, Vars, Names).
vague_doc(S,
	compile_with_variable_names_preserved(X, variable_names(Names))),
*/












/*

pondering a syntax for triples..

	R l:ledger_account_opening_balance_total [
		l:coord Opening_Balance;
		l:ledger_account_name Bank_Account_Name];
	  l:ledger_account_opening_balance_part [
	  	l:coord Opening_Balance_Inverted;
		l:ledger_account_name Equity];
	*/
	/*
	R l:ledger_account_opening_balance_total [
		l:coord Opening_Balance;
		l:ledger_account_name Bank_Account_Name];
	  l:ledger_account_opening_balance_part [
	  	l:coord $>coord_inverse(<$, Opening_Balance),
		l:ledger_account_name $>account_by_role('Accounts'/'Equity')];
	*/



dg :-
	dump,gtrace.


gu(Prefixed, Full) :-
	rdf_global_id(Prefixed, Full).

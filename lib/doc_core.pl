:- module(_,[doc_clear/0,doc_add/3, doc/3, docm/3]).
:- use_module(library(semweb/rdf11)).
:- use_module(library(debug)).


/*
a quad-store implemented with an open list stored in a global thread-local variable
*/

%:- debug(doc).

doc_clear :-
	b_setval(the_theory,_X),
	doc_set_default_graph(default).

doc_set_default_graph(G) :-
	b_setval(default_graph, G).

:- rdf_meta doc_add(r,r,r).

doc_add(S,P,O) :-
	b_getval(default_graph, G),
	debug(doc, 'add:~q~n', [(S,P,O)]),
	b_getval(the_theory,X),
	rol_add(X,(S,P,O,G)).

:- rdf_meta doc(r,r,r).
/*
must have single match
*/
doc(S,P,O) :-
	b_getval(default_graph, G),
	b_getval(the_theory,X),
	debug(doc, 'doc:~q~n', [(S,P,O,G)]),
	rol_single_match(X,(S,P,O,G)).

:- rdf_meta docm(r,r,r).
/*
can have multiple matches
*/
docm(S,P,O) :-
	b_getval(default_graph, G),
	b_getval(the_theory,X),
	debug(doc, 'docm:~q~n', [(S,P,O,G)]),
	rol_member(X,(S,P,O,G)).


/*
a thin layer above ROL
*/

rol_single_match(T,SpogA) :-
	/* only allow one match */
	findall(x,rol_member(T,SpogA),Matches),
	length(Matches, Length),
	(	Length > 1
	->	throw(multiple_matches)
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
:- use_module(library(debug)).

:- begin_tests(theory).

test(0) :-
	rol_add(T, a),
	assertion((T = [a|Tail],var(Tail))).

test(1) :-
	rol_add(T, a),rol_add(T,b),
	assertion((T = [a, b|Tail],var(Tail))).

test(2, throws(added_quad_matches_existing_quad)) :-
	rol_add(T, a),rol_add(T,_).

test(3) :-
	rol_add(T,a),rol_add(T,b).
/*
test(4, throws(multiple_matches)) :-
	rol_add(T,a),rol_add(T,b),doc(T,_X).
*/
test(5, all(x=[x])) :-
	rol_add(T,a),rol_add(T,b),rol_member(T,a).
	
test(6, all(x=[x])) :-
	rol_add(T,a),rol_add(T,b),rol_member(T,b).
		
test(7, all(x=[])) :-
	rol_add(T,a),rol_add(T,b),rol_member(T,[]).

test(8, all(x=[])) :-
	rol_add(T,a),rol_add(T,b),rol_member(T,[b|_]).

test(9, all(x=[])) :-
	rol_add(T,a),rol_add(T,b),rol_member(T,[b|_]).

:- end_tests(theory).

:- initialization(run_tests).


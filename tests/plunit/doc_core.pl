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
	rol_add(T,a),rol_add(T,b),doc:doc(T,_X).
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


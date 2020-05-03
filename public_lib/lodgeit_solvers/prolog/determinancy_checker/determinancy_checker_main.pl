:- module(_, [
	op(812,fx,!),
	op(812,fx,?),
	'!'/1,
	'!'/2,
	'!'/3,
	'?'/1
]).


%:- op(812,fx,!).
%:- op(812,fx,?).


:- if(\+current_prolog_flag(determinancy_checker__use__enforcer, true)).
:- [determinancy_checker].
:- else.
:- [determinancy_enforcer].
:- endif.


/*
prolog:message(deterministic_call_found_a_second_solution(X)) --> [deterministic_call_found_a_second_solution(X)].
prolog:message(deterministic_call_failed(X)) --> ['deterministic_call_failed'].
*/


/*
todo:
:- maplist(!member, [1], _).
*/

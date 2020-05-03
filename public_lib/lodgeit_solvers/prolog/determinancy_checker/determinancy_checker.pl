

/*
╺┳┓┏━╸╺┳╸
 ┃┃┣╸  ┃
╺┻┛┗━╸ ╹
have exactly one solution,
deterministic (det).
a fully checking implementation.
*/

'!'(X) :-
	det_with(Call_id, X),
	call(X),
	det_nbinc(Call_id, X).

/* versions with more arguments, used for example in a maplist, ie, the "meta-predicate" ("A meta-predicate is a predicate that calls other predicates dynamically[..]") gets a !something, and it calls the '!' with a bunch of additional arguments */

'!'(X, Y) :-
	det_with(Call_id, (X, Y)),
	call(X, Y),
	det_nbinc(Call_id, (X, Y)).

'!'(X, Y, Z) :-
	det_with(Call_id, (X, Y, Z)),
	call(X, Y, Z),
	det_nbinc(Call_id, (X, Y, Z)).


det_with(Call_id, Call) :-
	gensym(determinancy_checker__deterministic_call__progress, Call_id),
	(	nb_setval(Call_id, 0)
	;	(
			nb_getval(Call_id, 1)
		->	(
				nb_delete(Call_id),
				fail
			)
		;	throw(error(deterministic_call_failed(Call),_))
	)).

det_nbinc(Call_id, Call) :-
	nb_getval(Call_id, Sols),
	(	Sols = 0
	->	nb_setval(Call_id, 1)
	;	throw((deterministic_call_found_a_second_solution(Call)))).



/*
┏━┓┏━╸┏┳┓╻╺┳┓┏━╸╺┳╸
┗━┓┣╸ ┃┃┃┃ ┃┃┣╸  ┃
┗━┛┗━╸╹ ╹╹╺┻┛┗━╸ ╹
either have no solutions or have one solution,
semideterministic (semidet)
a fully checking implementation
*/

'?'(X) :-
	gensym(determinancy_checker__semideterministic_call__progress, Call_id),
	determinancy_checker_semidet_with(Call_id),
	call(X),
	determinancy_checker_semidet_nbinc(Call_id, X).

determinancy_checker_semidet_with(Call_id) :-
	nb_setval(Call_id, 0)
	;(nb_delete(Call_id),fail).

determinancy_checker_semidet_nbinc(Call_id, X) :-
	catch(
		nb_getval(Call_id, _),
		_,
		throw(semideterministic_call_has_multiple_solutions(X))
	),
	nb_delete(Call_id).


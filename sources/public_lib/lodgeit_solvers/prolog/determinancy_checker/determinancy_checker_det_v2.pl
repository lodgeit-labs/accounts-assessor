/*
╺┳┓┏━╸╺┳╸
 ┃┃┣╸  ┃
╺┻┛┗━╸ ╹
have exactly one solution,
deterministic (det).
a fully checking implementation.
*/

/*

% a more abstracted implementation:
upsides:
	less code repetition
	when you step inside a '!', it takes one skip to get to the wrapped call
downsides:
	throws don't happen right in the '!' predicate, so you cannot just press 'r' in gtrace to try the call again
*/
'!'(X) :-
	det_with(Call_id, X),
	call(X),
	det_nbinc(Call_id, X).

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

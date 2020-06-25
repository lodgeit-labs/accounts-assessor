/*
╺┳┓┏━╸╺┳╸
 ┃┃┣╸  ┃
╺┻┛┗━╸ ╹
have exactly one solution,
deterministic (det).
a fully checking implementation.
*/

% first the basic version, then versions with more arguments, used for example in a maplist, ie, the "meta-predicate" ("A meta-predicate is a predicate that calls other predicates dynamically[..]") gets a !something, and it calls the '!' with a bunch of additional arguments

'!'(Callable) :-
	/*
	setup and cleanup/throw
	*/
	gensym(determinancy_checker__deterministic_call__progress, Call_id),
	(	nb_setval(Call_id, 0)
	;	(	nb_getval(Call_id, 1)
		->	(	nb_delete(Call_id), fail)
		;	throw_string(error(determinancy_checker(deterministic_call_failed(Callable)),_)))),
	/*
	your call
	*/
	call(Callable),
	/*
	increment counter or throw
	*/
	nb_getval(Call_id, Sols),
	(	Sols = 0
	->	nb_setval(Call_id, 1)
	;	throw((deterministic_call_found_a_second_solution(Callable)))).

'!'(Callable, Arg1) :-
	/*
	setup and cleanup/throw
	*/
	gensym(determinancy_checker__deterministic_call__progress, Call_id),
	(	nb_setval(Call_id, 0)
	;	(	nb_getval(Call_id, 1)
		->	(	nb_delete(Call_id), fail)
		;	throw_string(error(deterministic_call_failed((Callable, Arg1)),_)))),
	/*
	your call
	*/
	call(Callable, Arg1),
	/*
	increment counter or throw
	*/
	nb_getval(Call_id, Sols),
	(	Sols = 0
	->	nb_setval(Call_id, 1)
	;	throw_string((deterministic_call_found_a_second_solution((Callable, Arg1))))).

'!'(Callable, Arg1, Arg2) :-
	/*
	setup and cleanup/throw
	*/
	gensym(determinancy_checker__deterministic_call__progress, Call_id),
	(	nb_setval(Call_id, 0)
	;	(	nb_getval(Call_id, 1)
		->	(	nb_delete(Call_id), fail)
		;	throw(error(deterministic_call_failed((Callable, Arg1, Arg2)),_)))),
	/*
	your call
	*/
	call(Callable, Arg1, Arg2),
	/*
	increment counter or throw
	*/
	nb_getval(Call_id, Sols),
	(	Sols = 0
	->	nb_setval(Call_id, 1)
	;	throw((deterministic_call_found_a_second_solution((Callable, Arg1, Arg2))))).


/*
alternatives: 
	rdet: uses goal expansion, which is imo pretty broken. main difference between rdet and this is that with rdet, you declare determinancy of a predicate, while with this, you declare determinancy of a call.
*/
/*

adapted from: https://stackoverflow.com/questions/39804667/has-the-notion-of-semidet-in-prolog-settled :

have exactly one solution,
	then that mode is deterministic (det);
	!
either have no solutions or have one solution,
	then that mode is semideterministic (semidet);
	?
have at least one solution but may have more,
	then that mode is multisolution (multi);
	+
	seems to be a rare case.
have zero or more solutions,
	then that mode is nondeterministic (nondet);
	this is the default.

*/


:- op(812,fx,!).
:- op(812,fx,?).


/*
╺┳┓┏━╸╺┳╸
 ┃┃┣╸  ┃
╺┻┛┗━╸ ╹
have exactly one solution,
deterministic (det);
*/

/*
a fully checking impl
*/

'!'(X) :-
	gensym(determinancy_checker__deterministic_call__progress, Call_id),
	determinancy_checker_semidet_with(Call_id),
	call(X),
	determinancy_checker_det_nbinc(Call_id, X),
	(	Call_id = 1
	->	true
	;	throw(deterministic_call_has_multiple_solutions(X))).

determinancy_checker_det_nbinc(Call_id, X) :-
	nb_getval(Call_id, Sols),
	Sols2 is Sols + 1,
	nb_setval(Call_id, Sols2).





/*
┏━┓┏━╸┏┳┓╻╺┳┓┏━╸╺┳╸
┗━┓┣╸ ┃┃┃┃ ┃┃┣╸  ┃
┗━┛┗━╸╹ ╹╹╺┻┛┗━╸ ╹
either have no solutions or have one solution,
semideterministic (semidet);
*/

'?'(X) :-
	gensym(determinancy_checker__semideterministic_call__progress, Call_id),
	determinancy_checker_semidet_with(Call_id),
	call(X),
	determinancy_checker_semidet_nbinc(Call_id, X),
	(	Call_id = 1
	->	nb_delete(Call_id)
		/* this wont happen */
	;	true).

determinancy_checker_semidet_with(Call_id) :-
	nb_setval(Call_id, 0)
	;
	(
		nb_delete(Call_id),
		fail
	).

determinancy_checker_semidet_nbinc(Call_id, X) :-
	catch(
		nb_getval(Call_id, Sols),
		_,
		throw(semideterministic_call_has_multiple_solutions(X))),
	Sols2 is Sols + 1,
	nb_setval(Call_id, Sols2).


/*
x :-
	!writeq(rrr),
	!member(X, [1,2,3]),
	!writeq(X).

test :- findall(_,x,_).
*/

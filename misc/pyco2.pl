:- use_module(library(clpfd)).
:- op(900,xfx,<=).
:- use_module(library(fnotation)).
:- fnotation_ops($>,<$).
:- op(900,fx,<$).

list_to_u([], nil).
list_to_u([H|T], Cell) :-
	proof(fr(Cell,H,Cell2)),
	list_to_u(T, Cell2).

:- discontiguous pyco0_rule/2.
:- discontiguous pyco0_rule/3.

pyco0_rule(
	'list cell helper',
	[fr(L,F,R)] <=
	[
		first(L, F),
		rest(L,R)
	]).

pyco0_rule(
	Desc,
	[first(L,F),rest(L,R)] <=
	[],
	(L = bn(_, Desc{first:F,rest:R}),register_bn(L))
	) :-
		Desc = 'list cell exists'
		.

pyco0_rule(
	Desc,
	[s_transaction_day(T,D)] <=
	[],
	(T = bn(_, Desc{day:D}),register_bn(T))
	) :-
		Desc = 's_transaction exists'.

pyco0_rule(
	'including an item',
	[s_transactions_up_to(End, All, Capped)] <=
	[
		format(user_error, 'include?~n', []),
		D #=< End,
		format(user_error, 'include?..~n', []),
		s_transaction_day(T, D),
		format(user_error, 'include ~q?....~n', [T]),
		fr(All, T, Ar),
		format(user_error, 'include ~q?......~n', [T]),
		fr(Capped, T, Cr),
		format(user_error, 'include ~q?........~n', [T]),
		s_transactions_up_to(End, Ar, Cr),
		format(user_error, 'included ~q~n', [T])
	]).

pyco0_rule(
	'filtering an item out',
	[s_transactions_up_to(End, All, Capped)] <=
	[
		D #> End,
		s_transaction_day(T, D),
		fr(All, T, Ar),
		s_transactions_up_to(End, Ar, Capped)
	]).

pyco0_rule(
	'an empty list is a filtered version of an empty list',
	[s_transactions_up_to(_, nil, nil)] <=
	[]).


pyco0_rule(
	'test query0',
	[test_statement0] <=
	[
		End = 9,
		s_transaction_day(T1, 1),
		s_transaction_day(T2, 2),
		s_transaction_day(T5, 5),
		s_transaction_day(T10, 10),
		writeln('sts.'),
		fr(All,  T1, All1),
		fr(All1, T2, All2),
		fr(All2, T5, All3),
		fr(All3, T10, nil),
		writeln('all.'),
		s_transactions_up_to(End, All, Capped),
		writeq('Capped:'),
		writeq(Capped),nl,
		%gtrace,
		list_to_u(X, Capped),
		writeq(X),nl
	]).

/*

now for the interesting stuff, requires reordering

*/

pyco0_rule(
	'test query1a',
	[test_statement1a] <=
	[
		s_transactions_up_to(_End, All, Capped),
		writeq('Capped:'),writeq(Capped),nl,
		writeq('All:'),writeq(All),nl
	]).

pyco0_rule(
	'test query1b',
	[test_statement1b] <=
	[
		End = 9,
		s_transaction_day(T1, 1),
		s_transaction_day(T2, 2),
		s_transaction_day(T5, 5),
		s_transaction_day(_T10, 10),
		s_transactions_up_to(End, _All, Capped),
		/*
		writeq('Capped:'),writeq(Capped),nl,
		writeq('All:'),writeq(All),nl,
		*/
		fr(Capped, T1, C2),
		fr(C2,T2,C3),
		fr(C3,T5,nil)
	]).


pyco0_rule(
	Desc,
	[transaction_day(T,D), transaction_source(T,S)] <=
	[],
	(T = bn(_, Desc{day:D, source:S}),register_bn(T))) :-
		Desc = 'transaction exists'.

pyco0_rule(
	's_transaction produces transaction',
	[preprocess_st(St,T)] <=
	[
		s_transaction_day(St,D),
		transaction_day(T,D),
		transaction_source(T,St)
	]).

pyco0_rule(
	's_transactions produce transactions 0',
	[preprocess_sts(nil, nil)] <=
	[]).

pyco0_rule(
	's_transactions produce transactions 1',
	[preprocess_sts(Sts,Ts)] <=
	[
		fr(Sts, St, Sts_r),
		fr(Ts, T, Ts_r),
		preprocess_st(St,T),
		preprocess_sts(Sts_r,Ts_r)
	]).

/*

now for more interesting stuff

		we dont know the s_transactions.
		pyco would (i think) produce a [first _; rest [first _; rest _]] and ep-yield.
		ep-yield is a yield, ie, a success, but variables remain unbound. If they (any?) are bound when the query is finished, the result is discarded.
		after this, it would backtrack and produce [first _; rest nil], and all the other computations would be ran again. (At least that's the case for one ordering of list rules).
		1) can we ep-yield immediately on first non-ground invoccation?
		2) can we floow the data and do the other computations first?

*/

pyco0_rule(
	'test query2',
	[test_statement2] <=
	[
		End = 9,
		s_transactions_up_to(End, All, Capped),
		writeq('Capped:'),writeq(Capped),nl,
		writeq('All:'),writeq(All),nl,
		transaction_day(T1, 1),
		transaction_day(T2, 2),
		transaction_day(T5, 5),
		transaction_day(_T10, 10),

		preprocess_sts(Sts,Ts),
		writeq('Sts:'),writeq(Sts),nl,

		fr(Ts, T1, Ts2),
		fr(Ts2, T2, Ts3),
		fr(Ts3, T5, nil)

	]).

find_rule(Query, Desc, Head_items, Body_items, Prep) :-
	(	pyco0_rule(Desc, Head_items <= Body_items, Prep)
	;	(
			pyco0_rule(Desc, Head_items <= Body_items),
			Prep = true)),
	\+ \+member(Query, Head_items).

query_term_ep_terms(Query, Query_ep_terms) :-
	Query =.. [_|Args],
	maplist(arg_ep_table_term, Args, Query_ep_terms).


matching_rule(Eps0, Query, Body_items, Eps1) :-
	find_rule(Query, Desc, Head_items, Body_items, Prep),
	debug(pyco2, '~q', [query(Desc, Query)]),
	query_term_ep_terms(Query, Query_ep_terms),
	member(Query, Head_items),
	ep_list_for_rule(Eps0, Desc, Ep_List),
	ep_ok(Ep_List, Query_ep_terms),
	append(Ep_List, [Query_ep_terms], Ep_List_New),
	Eps1 = Eps0.put(Desc, Ep_List_New),
	%debug(pyco2, 'set ~q', [ep_list(Desc, Ep_List_New)]),
	debug(pyco2, 'call prep: ~q', [Prep]),
	call(Prep)

	.

ep_list_for_rule(Eps0, Desc, X) :-
	(	get_dict(Desc, Eps0, X)
	->	true
	;	X = []).

ep_ok(Ep_List, Query_ep_terms) :-
	debug(pyco2, '~q?', [ep_ok(Ep_List, Query_ep_terms)]),
	maplist(ep_ok2(Query_ep_terms), Ep_List).

ep_ok2(Query_ep_terms, Ep_Entry) :-
	length(Query_ep_terms, L0),
	length(Ep_Entry, L1),
	assertion(L0 == L1),
	findall(x,
		(
			between(1, L0, I),
			nth1(I, Ep_Entry, Old_arg),
			nth1(I, Query_ep_terms, New_arg),
			arg_is_productively_different(Old_arg, New_arg)
		),
		Differents),
	(	Differents == []
	->	(
			debug(pyco2, 'EP!', []),
			false
		)
	;	true).


arg_ep_table_term(A, var) :-
	var(A).
arg_ep_table_term(A, const(A)) :-
	atomic(A).
arg_ep_table_term(A, bn(Uid_str, Tag)) :-
	nonvar(A),
	A = bn(Uid, Bn),
	is_dict(Bn, Tag),
	term_string(Uid, Uid_str).


%\arg_is_productively_different(var, var).
arg_is_productively_different(var, const(_)).
arg_is_productively_different(var, bn(_,_)).
arg_is_productively_different(const(_), var).
arg_is_productively_different(const(C0), const(C1)) :- C0 \= C1.
arg_is_productively_different(const(_), bn(_,_)).
arg_is_productively_different(bn(_,_), var).
arg_is_productively_different(bn(_,_), const(_)).
arg_is_productively_different(bn(Uid_old_str,Tag0), bn(Uid_new_str,Tag1)) :-
	assertion(string(Uid_old_str)),
	assertion(string(Uid_new_str)),
	/* for same uids, we fail. */
	/* for differing types, success */
	(	Tag0 \= Tag1
	->	true
	;	came_before(Uid_new_str, Uid_old_str)).


came_before(A, B) :-
	b_getval(bn_log, Bn_log),
	nth0(Ia, Bn_log, bn(A,_)),
	nth0(Ib, Bn_log, bn(B,_)),
	Ia < Ib.

register_bn(bn(Uid, Dict)) :-
	is_dict(Dict, Tag),
	b_getval(bn_log, Bn_log0),
	term_string(Uid, Uid_str),
	append(Bn_log0, [bn(Uid_str, Tag)], Bn_log1),
	b_setval(bn_log, Bn_log1),
	debug(pyco2, 'bn_log:~q', [Bn_log1]).

proof(Eps0,Query) :-
	matching_rule(Eps0,Query, Body_items,Eps1),
	/* Query has been unified with head. */
	body_proof(Eps1, Body_items).

proof(_,Query) :-
	/* this case tries to handle calling native prolog predicates */
	catch(
		(
			debug(pyco2, 'prolog goal call:~q', [Query]),
			call(Query),
			debug(pyco2, 'prolog goal succeded:~q', [Query])
		),
		error(existence_error(procedure,Name/Arity),_),
		% you'd think this would only catch when the Query term clause doesn't exist, but nope, it actually catches any nested exception. Another swipl bug?
		(
			functor(Query, Name, Arity),
			%gtrace,
			fail
		)
	).


run(Query) :-
	b_setval(bn_log, []),
	proof(eps{dummy:[]},Query).

proof(Query) :-
	proof(eps{dummy:[]},Query).


%:- proof(test_statement1).






number_of_unbound_args(Term, Count) :-
	Term =.. [_|Args],
	aggregate_all(count,
	(
		member(X, Args),
		var(X)
	),
	Count).

'pairs of Index-Num_unbound'(Body_items, Pairs) :-
	length(Body_items, L0),
	L is L0 - 1,
	findall(I-Num_unbound,
		(
			between(0,L,I),
			nth0(I,Body_items,Bi),
			number_of_unbound_args(Bi, Num_unbound)
		),
	Pairs).


pick_bi(Body_items, Bi, Body_items_next) :-
	'pairs of Index-Num_unbound'(Body_items, Pairs),
	aggregate_all(min(Num_unbound), member(_Index-Num_unbound, Pairs), Min_unbound),
	once(member(Picked_bi_index-Min_unbound, Pairs)),
	extract_element_from_list(Body_items, Picked_bi_index, Bi, Body_items_next).

body_proof(Eps1, Body_items) :-
	pick_bi(Body_items, Bi, Body_items_next),
	proof(Eps1, Bi),
	body_proof(Eps1, Body_items_next).

body_proof(_Eps1, []).

extract_element_from_list(List, Index, Element, List_without_element) :-
	findall(
		E,
		(
			nth0(I,List,E),
			I \= Index
		),
		List_without_element
	),
	nth0(Index, List, Element).






/*
ep check:
https://www.swi-prolog.org/pldoc/man?section=compare


optimization:

http://irnok.net:3030/help/source/doc/home/prolog/ontology-server/ClioPatria/lib/semweb/rdf_optimise.pl

pyco optimization:
	https://books.google.cz/books?id=oc7cBwAAQBAJ&pg=PA26&lpg=PA26&dq=prolog++variable+address&source=bl&ots=cDxavU-UaU&sig=ACfU3U0y1RnTKfJI58kykhqltp8fBNkXhA&hl=en&sa=X&ved=2ahUKEwiJ6_OWyuPnAhUx-yoKHZScAU4Q6AEwEHoECAkQAQ#v=onepage&q=prolog%20%20variable%20address&f=false

===


?x a response
?request result ?result
?response result ?result

=====

?sts0 prepreprocess ?sts1
?sts1 preprocess ?txs



{?sts0 prepreprocess ?sts1} <=
{
    ?sts0 first ?st0
    ?st0 action_verb "livestock_sell"

    .....

    ?sts0 rest ?stsr
    ?stsr prepreprocess ?sts1r.

two approaches to optimization:
    follow the data:
        ?txs are bound, so call ?sts1 preprocess ?txs first
    ep-yield earlier:
        as soon as we're called with only vars?


*/


/*
multiple heads:

[a,b] :- writeq(xxx).

?- clause([X|XX],Y).
X = a,
XX = [b],
Y = writeq(xxx).


*/

/*
ba((N,A)) :-
	call(N,A).
*/

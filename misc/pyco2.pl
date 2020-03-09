:- use_module(library(clpfd)).
:- op(900,xfx,<=).


/*actually this is where we infiloop, through setting up a rule's locals.
so that's a special case, but it would be comparable to infilooping through a builtin.
we should still be able to fix it with an ep-check.

*/

list_to_u([], nil).
list_to_u([H|T], Cell) :-
	proof(fr(Cell,H,Cell2)),
	list_to_u(T, Cell2).


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
	[]) :-
		Desc = 'list cell exists',
		L = bn($>gensym(bn), Desc{first:F,rest:R}).

pyco0_rule(
	Desc,
	[s_transaction_day(T,D)] <=
	[]) :-
		Desc = 's_transaction exists',
		T = bn($>gensym(bn), Desc{day:D}).

pyco0_rule(
	'including an item',
	[s_transactions_up_to(End, All, Capped)] <=
	[
		D #=< End,
		s_transaction_day(T, D),
		fr(All, T, Ar),
		fr(Capped, T, Cr),
		s_transactions_up_to(End, Ar, Cr)
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
		fr(All,  T1, All1),
		fr(All1, T2, All2),
		fr(All2, T5, All3),
		fr(All3, T10, nil),
		s_transactions_up_to(End, All, Capped),
		writeq('Capped:'),
		writeq(Capped),
		nl
	]).

/*

now for the interesting stuff

*/

pyco0_rule(
	'test query1',
	[test_statement1] <=
	[
		End = 9,
		s_transaction_day(T1, 1),
		s_transaction_day(T2, 2),
		s_transaction_day(T5, 5),
		s_transaction_day(_T10, 10),
		s_transactions_up_to(End, All, Capped),
		writeq('Capped:'),writeq(Capped),nl,
		writeq('All:'),writeq(All),nl
	]) :-
		/* here, Capped are known beforehand, but s_transactions_up_to will still infiloop */
		/*gtrace,*/list_to_u([T1,T2,T5], Capped).


pyco0_rule(
	Desc,
	[transaction_day(T,D), transaction_source(T,S)] <=
	[]) :-
		Desc = 'transaction exists',
		T = bn($>gensym(bn), Desc{day:D, source:S}).

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


		true
	]) :-
		/*gtrace,*/list_to_u([T1,T2,T5], Ts).

matching_rule(Query, Body_items) :-
	pyco0_rule(Desc, Head_items <= Body_items),

	Query =.. [_|Args],
	maplist(arg_ep_table_term, Args, Query_ep_terms),

	member(Query, Head_items),

	catch(
		b_getval(Desc, Ep_List0),
		error(existence_error(variable,Desc),_),
		Ep_List = ep_list([])
	),
	assertion(Ep_List0 == ep_list(Ep_List)),
	Ep_List0 = ep_list(Ep_List),

	ep_ok(Ep_List, Query_ep_terms, Desc),

	append(Ep_List, [Query_ep_terms], Ep_List_New),
	b_setval(Desc, ep_list(Ep_List_New)).


ep_ok(Ep_List, Query_ep_terms) :-
	maplist(ep_ok2, Query_ep_terms, Ep_List).

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
			writeln('EP!'),
			false
		)
	;	true).

%\arg_is_productively_different(var, var).
arg_is_productively_different(var, const(_)).
arg_is_productively_different(var, bn(_,_)).
arg_is_productively_different(const(_), var).
arg_is_productively_different(const(C0), const(C1)) :- C0 \= C1.
arg_is_productively_different(const(_), bn(_,_)).
arg_is_productively_different(bn(_,_), var).
arg_is_productively_different(bn(_,_), const(_)).
arg_is_productively_different(bn(Uid0,Tag0), bn(Uid1,Tag1)) :-
	(	Uid0 > Uid1
	->	true
	;	Tag0 \= Tag1).





proof(Query) :-
	matching_rule(Query, Body_items),
	/* Query has been unified with head */


	maplist(proof, Body_items).


arg_ep_table_term(A, var) :-
	var(A).
arg_ep_table_term(A, const(A)) :-
	atomic(A).
arg_ep_table_term(bn(Uid, Bn), bn(Uid, Tag)) :-
	is_dict(Bn, Tag).


is_arg_productively_different(Old, Now) :-



proof(Query) :-
	catch(call(Query),error(existence_error(procedure,E),_),(nonvar(E),/*writeq(E),nl,*/fail)).



%:- proof(test_statement1).













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

:- use_module(library(clpfd)).
:- op(900,xfx,<=).

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
	'list cell exists',
	[first(L,F),rest(L,R)] <=
	[]) :-
		L = u{first:F,rest:R}.

pyco0_rule(
	's_transaction exists',
	[s_transaction_day(T,D)] <=
	[]) :-
		T = u{day:D}.

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
	'test query',
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

pyco0_rule(
	'test query',
	[test_statement1] <=
	[
		End = 9,
		s_transaction_day(T1, 1),
		s_transaction_day(T2, 2),
		s_transaction_day(T5, 5),
		s_transaction_day(T10, 10),
		s_transactions_up_to(End, All, Capped),
		writeq('Capped:'),writeq(Capped),nl,
		writeq('All:'),writeq(All),nl
	]) :-
		list_to_u([T1,T2,T5], Capped).

matching_rule(Query, Body_items) :-
	pyco0_rule(_, Head_items <= Body_items),
	member(Query, Head_items).

proof(Query) :-
	matching_rule(Query, Body_items),
	maplist(proof, Body_items).

proof(Query) :-
	catch(call(Query),error(existence_error(procedure,E),_),(nonvar(E),/*writeq(E),nl,*/fail)).



:- proof(test_statement1).













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

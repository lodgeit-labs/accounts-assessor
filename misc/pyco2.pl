:- use_module(library(clpfd)).
:- op(900,xfx,<=).

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

matching_rule(Query, Body_items) :-
	pyco0_rule(_, Head_items <= Body_items),
	member(Query, Head_items).

proof(Query) :-
	matching_rule(Query, Body_items),
	maplist(proof, Body_items).

proof(Query) :-
	catch(call(Query),error(existence_error(procedure,E),_),(nonvar(E),/*writeq(E),nl,*/fail)).



:- proof(test_statement0).


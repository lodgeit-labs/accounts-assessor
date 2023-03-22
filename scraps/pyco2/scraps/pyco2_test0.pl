:- ['../../sources/public_lib/lodgeit_solvers/research/pyco2/pyco2.pl'].


pyco0_rule(
	'list cell helper',
	[fr(L,F,R)] <=
	[
		first(L, F),
		rest(L, R)
	]).

pyco0_rule(
	Desc,
	[first(Bn,F),rest(Bn,R)] <=
	[],
	mkbn(Bn, Desc{first:F,rest:R})
	) :-
		Desc = 'list cell exists'.

pyco0_rule(
	Desc,
	[s_transaction_day(Bn,D)] <=
	[],
	mkbn(Bn, Desc{day:D})
	) :- Desc = 's_transaction exists'.


pyco0_rule(
	'an empty list is a filtered version of an empty list',
	[s_transactions_up_to(_, nil, nil)] <=
	[]).

pyco0_rule(
	'including an item',
	[s_transactions_up_to(End, All, Capped)] <=
	[
		/* these format calls don't work as expected, with body items reordering */
		%format(user_error, 'include?~n', []),
		D #=< End,
		%format(user_error, 'include?..~n', []),
		s_transaction_day(T, D),
		%format(user_error, 'include ~q?....~n', [T]),
		fr(All, T, Ar),
		%format(user_error, 'include ~q?......~n', [T]),
		fr(Capped, T, Cr),
		%format(user_error, 'include ~q?........~n', [T]),
		s_transactions_up_to(End, Ar, Cr),
		%format(user_error, 'included ~q~n', [T])
		true
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
/*
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
		list_to_u(X, Capped),
		writeq(X),nl
	]).
*/


pyco0_rule(
	'test query1a',
	[test_statement1a] <=
	[
		s_transactions_up_to(_End, All, Capped),
		nl, nl, writeq('rrrCapped:'),writeq(Capped),nl,
		writeq('rrrAll:'),writeq(All),nl, nl
	]).

pyco0_rule(
	'test query1a2',
	[test_statement1a2] <=
	[
		fr(_Capped, t1, C2),
		fr(C2,t2,C3),
		fr(C3,t5,nil)
	]).

/*

 now for the interesting stuff, requires reordering of body items

*/

pyco0_rule(
	'test query1b',
	[test_statement1b(End, All, Capped)] <=
	[
		End = 9,
		s_transaction_day(T1, 1),
		s_transaction_day(T2, 2),
		s_transaction_day(T5, 5),
		s_transaction_day(_T10, 10),
		s_transactions_up_to(End, All, Capped),
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
	[transaction_day(Bn,D), transaction_source(Bn,S)] <=
	[],
	mkbn(Bn, Desc{day:D, source:S})) :-
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
		1) can we ep-yield immediately on first non-ground invocation?
		2) can we follow the data and do the other computations first?

*/

pyco0_rule(
	'test query2',
	[test_statement2(End, Ts, Capped, All)] <=
	[
		s_transactions_up_to(End, All, Capped),
		transaction_day(T1, 1),
		transaction_day(T2, 2),
		transaction_day(T5, 5),
		transaction_day(_T10, 10),

		preprocess_sts(Capped,Ts),
		%writeq('Sts:'),writeq(Sts),nl,

		fr(Ts, T1, Ts2),
		fr(Ts2, T2, Ts3),
		fr(Ts3, T5, nil),

		%print_1(Ts,Capped,All)
		%format('***~nTs: ~q ~n~nCapped: ~q ~n~nAll: ~q ~n ***~n', [Ts,All,Capped])

		true

	]).

pyco0_rule(
	'test_statement3',
	[test_statement3(End, Ts, Capped, All)] <=
	[
		s_transactions_up_to(End, All, Capped),
		transaction_day(T1, 1),
		transaction_day(T2, 2),
		transaction_day(T5, 5),
		transaction_day(_T10, 10),

		preprocess_sts(Capped,Ts),
		%writeq('Sts:'),writeq(Sts),nl,

		fr(Ts, T1, Ts2),
		fr(Ts2, T2, Ts3),
		fr(Ts3, T5, nil),

		%print_1(Ts,Capped,All)
		%format('***~nTs: ~q ~n~nCapped: ~q ~n~nAll: ~q ~n ***~n', [Ts,All,Capped])

		fr(All, _, As2),
		fr(As2, _, As3),
		fr(As3, _, nil),


		true

	]).

print_1(Ts,Capped,All) :-
	(
	format(user_error,'~nresult:~n', []),
	nicer_bn2(Ts, Ts_n),
	nicer_bn2(Capped, Capped_n),
	nicer_bn2(All, All_n),
	format(user_error,'~nTs:~n', []),
	maplist(writeln, Ts_n),
	format(user_error,'~nCapped:~n', []),
	maplist(writeln, Capped_n),
	format(user_error,'~nAll:~n', []),
	maplist(writeln, All_n),
	nl,nl,
	nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,
	true
	)
	->	true
	;	throw(xxx).





test1a :-
	findnsols(
		5000000000,
		_,
		(
			%debug(pyco_prep),
			debug(pyco_proof),
			%debug(pyco_ep),

			Q = test_statement1a,
			run(Q),
			nicer_term(Q, NQ),
			format(user_error,'~nresult: ~q~n', [NQ]),

			%nicer_arg(All, AllN),
			%format(user_error,'~nAllN: ~q~n', [AllN]),

%			nicer_bn2(All, All_n),
%			nicer_bn2(Capped, Capped_n),
%
%			format(user_error,'~nAll:~n', []),
%			maplist(writeln, All_n),
%
%			format(user_error,'~nCapped:~n', []),
%			maplist(writeln, Capped_n),

			nl,
			true

		),
		_
	),
	halt.

test1b :-
	findnsols(
		5000000000,
		_,
		(
			%debug(pyco_prep),
			debug(pyco_proof),
			%debug(pyco_ep),

			Q = test_statement1b(9, All, Capped),
			run(Q),
			%nicer_term(Q, NQ),
			%format(user_error,'~nresult: ~q~n', [NQ]),

			%nicer_arg(All, AllN),
			%format(user_error,'~nAllN: ~q~n', [AllN]),

			nicer_bn2(All, All_n),
			nicer_bn2(Capped, Capped_n),

			format(user_error,'~nAll:~n', []),
			maplist(writeln, All_n),

			format(user_error,'~nCapped:~n', []),
			maplist(writeln, Capped_n),

			nl,
			true

		),
		_
	),
	halt.


test2 :-
	findnsols(
		5000000000,
		_,
		(
			%debug(pyco_prep),
			debug(pyco_proof),
			debug(pyco_ep),
			debug(pyco_run),

			Q = test_statement3(9, Ts, Capped, All),
			run(Q),
			%nicer_term(Q, NQ),
			%format(user_error,'~nresult: ~q~n', [NQ]),

			print_1(Ts,Capped,All),

			%nicer_bn2(Ts, Ts_n),
			%nicer_bn2(All, All_n),
			%nicer_bn2(Capped, Capped_n),

			%format(user_error,'~nTs:~n', []),
			%maplist(writeln, Ts_n),

			%format(user_error,'~nCapped:~n', []),
			%maplist(writeln, Capped_n),

			%format(user_error,'~nAll:~n', []),
			%maplist(writeln, All_n),

			nl,
			true

		),
		_
	),
	halt.


:- ['../../sources/public_lib/lodgeit_solvers/prolog/pyco2/pyco2.pl'].
:- use_module(library(clpq)).


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
	'coord helper',
	[coord(Coord,Unit,Amount)] <=
	[
		coord_unit(Coord, Unit),
		coord_amount(Coord, Amount)
	]).

pyco0_rule(
	Desc,
	[coord_unit(Coord, Unit),coord_amount(Coord, Amount)] <=
	[],
	mkbn(Coord, Desc{unit:Unit,amount:Amount})
	) :-
		Desc = 'coord exists'.

pyco0_rule(
	member0,
	[
		member(Item, List)
	]
	<=
	[
		fr(List, Item, _Rest)
	]).

/*
pyco0_rule(
	vec_inverse,
	[
		vec_inverse(v, vi)
	]
	<=
	[

	]).
*/
/*
		% this doesnt help, because once you put clp attrs on a variable, if you later try to unify it with let's say an atom, clp throws. Best to just take it to python i guess. Otherwise we'd have to handle every unification manually.
nmbr(X) :-
	(rational(X),!)
	;
	(number(X),!)
	;
	(var(X),!).
*/
pyco0_rule(
	vec_inverse,
	[
		vec_inverse(V, Vi)
	]
	<=
	[
		fr(V, C1, nil),
		fr(Vi, Ci1, nil),
		cooord_inverse(C1, Ci1)
	]).
pyco0_rule(
	cooord_inverse,
	[
		cooord_inverse(C, Ci)
	]
	<=
	[
		coord(C, Unit, Amount),
		coord(Ci, Unit, Amount2),
		{Amount = -Amount2}
	]).



pyco0_rule(
	member1,
	[
		member(Item, List)
	]
	<=
	[
		fr(List, _, Rest),
		member(Item, Rest)
	]).

pyco0_rule(
	slice0,
	[
		slice(List, Item, Rest)
	]
	<=
	[
		fr(List, Item, Rest)
	]).

pyco0_rule(
	slice1,
	[
		slice(List, Item, Rest)
	]
	<=
	[
		fr(List, Skipped_item, List_tail),
		fr(Rest, Skipped_item, Rest2),
		slice(List_tail, Item, Rest2)
	]).

pyco0_rule(
	'slice out a list0',
	[
		slice_out_a_list(Whole, nil, Whole)
	]
	<=
	[
	]).

pyco0_rule(
	'slice out a list1',
	[
		slice_out_a_list(Whole, Items_sliced_out, Rest)
	]
	<=
	[
		fr(Items_sliced_out, Item, Items_sliced_out_tail),
		slice(Whole, Item, Remaining),
		slice_out_a_list(Remaining, Items_sliced_out_tail, Rest)
	]).

% preprocess s_transaction2s into transactions'
% an empty list preprocesses into an empty list.
% s_transaction2s are processed or produced in order.
% transactions are picked out from anywhere in the list.
pyco0_rule(
	'(nil, nil) has the relation "preprocess"',
	[preprocess(_,nil,nil)]
 	<=
	[]).

pyco0_rule(
	'preprocess',
	[preprocess(Verbs, S_transactions, Transactions)]
	<=
	[
		member(Verb, Verbs),
		produces(Verb, St, Ts),
		slice_out_a_list(Transactions, Ts, Transactions_rest),
		fr(S_transactions, St, S_transactions_tail),
		preprocess(Verbs, S_transactions_tail, Transactions_rest)
	]).
/*
selection of speed-optimal order of body items: perhaps this is best defined on the level of predicate definitions. Might be even more optimal on the level of rule definitions, but i'm not sure that we can realistically implement that in prolog.
So let's say preprocess/3 has delay-hint: if Verbs is unbound, shift me back by X seconds. X may be a constant or an expression possibly even calling more pyco preds, taking lengts of lists or whatnot.
The next pred invoked after preprocess/3 may shift back to, etc, until we get to the end of the body, at which point, we sort the body items by "delay-hint" and commit to the lowest.
*/
pyco0_rule(
	'produces 1',
	[produces(Verb, St, Ts)]
	<=
	[
		verb_type(Verb, basic),
		verb_counteraccount(Verb, Counteraccount),
		s_transaction(St,Verb,D,Primary_account,V,nil),
		transaction(T0,D,St,Primary_account,V),
		vec_inverse(V, Vi),
		transaction(T1,D,St,Counteraccount,Vi),
		fr(Ts,T0,Ts2),
		fr(Ts2,T1,nil)
	]).

pyco0_rule(
	'produces 2',
	[produces(Verb, St, Ts)]
	<=
	[
		verb_type(Verb, exchange),
		verb_counteraccount(Verb, Counteraccount),
		s_transaction(St,Verb,D,Primary_account,V,E),
		transaction(T0,D,St,Primary_account,V),
		transaction(T1,D,St,Counteraccount,E),
		fr(Ts,T0,Ts2),
		fr(Ts2,T1,nil)
	]).


pyco0_rule(
	Desc,
	[
		verb(Bn, Name, Type, Counteraccount),
		verb_name(Bn, Name),
		verb_type(Bn, Type),
		verb_counteraccount(Bn, Counteraccount)
	]
	<= [],
	mkbn(Bn, Desc{
		name:Name,
		type:Type,
		counteraccount:Counteraccount
	})) :- Desc = 'verb exists'.

pyco0_rule(
	Desc,
	[
		transaction(T,D,S,A,V),
		transaction_day(T,D),
		transaction_source(T,S),
		transaction_account(T,A),
		transaction_vector(T,V)
	] <=
	[],
	mkbn(T, Desc{
		day:D,
		source:S,
		account:A,
		vector:V
	})) :-
		Desc = 'transaction exists'.

pyco0_rule(
	Desc,
	[
		s_transaction(T,Verb,D,A,V,E),
		s_transaction_verb(T,Verb),
		s_transaction_day(T,D),
		s_transaction_account(T,A),
		s_transaction_vector(T,V),
		s_transaction_exchanged(T,E)
	] <=
	[],
	mkbn(T, Desc{
		verb:Verb,
		day:D,
		account:A,
		vector:V,
		exchanged:E
	})) :-
		Desc = 's_transaction exists'.


pyco0_rule(
	'default verbs',
	[
		default_verbs(Verbs, Verb0, Verb1)
	] <=
	[
		verb(Verb0, invest_in, exchange, investments),
		verb(Verb1, expense, basic, expenses),
		fr(Verbs, Verb0, Verbs2),
		fr(Verbs2, Verb1, nil)
	]).


/* inference of many s_transactions */
pyco0_rule(
	'q5',
	[
		q5(Sts, Ts0)
	] <=
	[
		fr(Ts0, T0, Ts1),
		fr(Ts1, T1, Ts2),
		fr(Ts2, T2, Ts3),
		fr(Ts3, T3, Ts4),
		fr(Ts4, T4, Ts5),
		fr(Ts5, T5, Ts6),
		fr(Ts6, T6, Ts7),
		fr(Ts7, T7, Ts8),
		fr(Ts8, T8, Ts9),
		fr(Ts9, T9, Ts10),
		fr(Ts10, T10, Ts11),
		fr(Ts11, T11, nil),
		coord(C1,'AUD',-5),fr(Vec1,C1,nil),
		coord(C2,'AUD',5),fr(Vec2,C2,nil),
		coord(C3,'AUD',-60),fr(Vec3,C3,nil),
		coord(C4,'AUD',60),fr(Vec4,C4,nil),
		transaction(T0,0,_,bank0,Vec1),
		transaction(T1,0,_,expenses,Vec2),
		transaction(T2,1,_,bank0,Vec1),
		transaction(T3,1,_,expenses,Vec2),
		transaction(T4,2,_,bank0,Vec1),
		transaction(T5,3,_,expenses,Vec2),
		transaction(T6,3,_,bank0,Vec1),
		transaction(T7,2,_,expenses,Vec2),
		transaction(T8,4,_,bank0,Vec1),
		transaction(T9,4,_,expenses,Vec4),
		transaction(T10,4,_,bank0,Vec3),
		transaction(T11,4,_,expenses,Vec2),
		default_verbs(Verbs, _, _),
		preprocess(Verbs,Sts,Ts0)
		%writeq(preprocess(Verbs,Sts,Ts0)),

	]).


test(Q) :-
	findnsols(
		5000000000,
		_,
		(
			%debug(pyco_prep),
			%debug(pyco_proof),
			%debug(pyco_ep),
			%debug(pyco_run),

			run(quiet, Q),
			print_1(Q),
			nicer_term(Q, NQ),
			format(user_error,'~nresult: ~q~n', [NQ]),
			nl,
			nl,
			true
		),
		_
	),
	halt.




print_1(Q) :-
	Q =.. [_,Sts,Ts],
	(
	format(user_error,'~nRESULT:~n', []),
	nicer_bn2(Sts, Sts_n),
	nicer_bn2(Ts, Ts_n),
	format(user_error,'~nSts:~n', []),
	maplist(writeln, Sts_n),
	format(user_error,'~nTs:~n', []),
	maplist(writeln, Ts_n),
	nl,nl,
	true
	)
	->	true
	;	throw(xxx).


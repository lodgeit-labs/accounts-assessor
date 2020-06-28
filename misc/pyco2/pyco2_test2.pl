:- [pyco2].
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

/* basic expansion of an s_transaction into two transactions */
pyco0_rule(
	'q0',
	[
		q0(Sts, Ts)
	] <=
	[
		verb_type(Expense, basic),
		verb_name(Expense, expense),
		verb_counteraccount(Expense, expenses),
		fr(Verbs, Expense, nil),
		coord(C1,'AUD',10),fr(Vec1,C1,nil),
		s_transaction(St0,Expense,day0,bank1,Vec1,nil),
		fr(Sts, St0, nil),

		preprocess(Verbs, Sts, Ts)
	]).

/* ...two Invest_in s_transactions */
pyco0_rule(
	'q1',
	[
		q1(Sts, Ts)
	] <=
	[
		default_verbs(Verbs, Invest_in, _),
		coord(C1,'AUD',-10),fr(Vec1,C1,nil),
		coord(C2,'GOOG',-10),fr(Vec2,C2,nil),
		coord(C3,'MSFT',-10),fr(Vec3,C3,nil),
		s_transaction(St0,Invest_in,0,bank1,Vec1,Vec2),
		s_transaction(St1,Invest_in,1,bank2,Vec1,Vec3),
		fr(Sts, St0, Sts1),
		fr(Sts1, St1, nil),
		preprocess(Verbs, Sts, Ts)
	]).

/* inference of one s_transaction from gl transactions */
pyco0_rule(
	'q2',
	[
		q2(Sts, Ts)
	] <=
	[
		coord(C1,'AUD',-10),fr(Vec1,C1,nil),
		coord(C2,'AUD',10),fr(Vec2,C2,nil),
		transaction(T0,0,_,bank0,Vec1),
		transaction(T1,0,_,expenses,Vec2),
		fr(Ts, T0, Ts1),
		fr(Ts1, T1, nil),
		preprocess(Verbs,Sts,Ts),
		default_verbs(Verbs, _, _)
	]).

/* inference of two s_transactions from four gl transactions */
pyco0_rule(
	'q3',
	[
		q3(Sts, Ts)
	] <=
	[%fixme
		transaction(T0,0,_,bank0,v),
		transaction(T1,0,_,expenses,vi),
		transaction(T2,0,_,bank0,v),
		transaction(T3,0,_,investments,goog),
		fr(Ts, T0, Ts1),
		fr(Ts1, T1, Ts2),
		fr(Ts2, T2, Ts3),
		fr(Ts3, T3, nil),
		preprocess(Verbs,Sts,Ts),
		default_verbs(Verbs, _, _)
	]).

/* inference of one s_transaction and one gl transaction */
pyco0_rule(
	'q4',
	[
		q4(Sts, Ts)
	] <=
	[
		fr(Sts, St0, Sts1),
		fr(Sts1, _St1, nil),
		coord(C1,'AUD',-10),fr(Vec1,C1,nil),
		coord(C2,'GOOG',10),fr(Vec2,C2,nil),
		coord(C3,'AUD',10),fr(Vec3,C3,nil),
		s_transaction(St0,Invest_in,0,bank0,Vec1,Vec2),

		fr(Ts, T0, Ts1),
		fr(Ts1, T1, Ts2),
		fr(Ts2, T2, Ts3),
		fr(Ts3, _T3, nil),
		transaction(T0,0,_,bank0,Vec1),
		transaction(T1,0,_,expenses,Vec3),
		transaction(T2,0,_,bank0,Vec1),

		preprocess(Verbs,Sts,Ts),
		default_verbs(Verbs, Invest_in, _)
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
		preprocess(Verbs,Sts,Ts0),
		default_verbs(Verbs, _, _)
	]).


test(Q) :-
	findnsols(
		5000000000,
		_,
		(
			%debug(pyco_prep),
			%debug(pyco_proof),
			%debug(pyco_ep),
			debug(pyco_run),

			run(noisy, Q),
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
	%nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,
	true
	)
	->	true
	;	throw(xxx).







/*


s_transaction pipeline:
	flip vectors (on parse)
	sort by day and vector
	s_transactions_up_to
	prepreprocess from s_transactions to s_transactions(2?):
		find action verbs
		infer_livestock_action_verb
		infer_exchanged_units_count
	"preprocess" s_transaction2s to transactions

here we'll just do:
	s_transactions_up_to
	s_transaction2s to transactions


going from s_transactions to transactions and back:

	in pseudocode:

	uid(Uid) :-
			var(Uid)
		->	gensym(Uid)
		;	true

	preprocess([St|Sts], Ts) :-
		s_transaction(St, St_Uid, ...),

		% if going from sts to ts, the st is probably an uri,
		% but if going from ts to sts, it's gonna be a bnode
		% in both cases, they're uniquely identified by their position in the list, but they could still unify, so, we need to assign a unique id extralogically

		uid(St_Uid),

		transaction(T1, T1_Uid, St, St_Uid, ...),
		member(T1, Ts),
		uid(T1_Uid),

		% (same for T2, etc)

		dif(T1_Uid, T2_Uid), etc
*/



/*
make_list([], nil).

make_list([H|T], Pyco_list) :-
	mkbn(Pyco_list, make_list{first:H,rest:R}, missing->Path),
	make_list(T, R).
*/
/*
pyco0_rule(
	'make_list0',
	[make_list([], nil)] <=
	[]).

pyco0_rule(
	'make_list1',
	[make_list(not atomic->[], nil)] <=
	[]).
*/

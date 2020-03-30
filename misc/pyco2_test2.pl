:- [pyco2].


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
	member0,
	[
		member(Item, List)
	]
	<=
	[
		fr(List, Item, _Rest)
	]).


pyco0_rule(
	vec_inverse,
	[
		vec_inverse(V, Vi)
	]
	<=
	[
		Vi = vi
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


/* basic expansion of an s_transacton into two transactions */
pyco0_rule(
	'q0',
	[
		q0(Sts, Ts)
	] <=
	[
		verb_type(Verb0, basic),
		verb_counteraccount(Verb0, expenses),
		fr(Verbs, Verb0, nil),
		s_transaction(St0,Verb0,0,bank1,v,e),
		fr(Sts, St0, nil),
		preprocess(Verbs, Sts, Ts)
	]).

/* ...two s_transactions */
pyco0_rule(
	'q1',
	[
		q1(Sts, Ts)
	] <=
	[
		default_verbs(Verbs, Verb0, _),
		s_transaction(St0,Verb0,0,bank1,v,e),
		s_transaction(St1,Verb0,1,bank2,vv,ee),
		fr(Sts, St0, Sts1),
		fr(Sts1, St1, nil),
		preprocess(Verbs, Sts, Ts)
	]).

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


pyco0_rule(
	'q2',
	[
		q2(Sts, Ts)
	] <=
	[
		transaction(T0,0,_,bank0,v),
		transaction(T1,0,_,expenses,vi),
		fr(Ts, T0, Ts1),
		fr(Ts1, T1, nil),
		preprocess(Verbs,Sts,Ts),
		default_verbs(Verbs, _, _)
	]).

pyco0_rule(
	'q3',
	[
		q3(Sts, Ts)
	] <=
	[
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


test_q0 :-
	findnsols(
		5000000000,
		_,
		(
			%debug(pyco_prep),
			debug(pyco_proof),
			%debug(pyco_ep),
			debug(pyco_run),

			Q = q0(_Sts, _Ts),
			run(Q),
			nicer_term(Q, NQ),
			format(user_error,'~nresult: ~q~n', [NQ]),
			nl,
			nl,
			true
		),
		_
	),
	halt.


test(Q) :-
	findnsols(
		5000000000,
		_,
		(
			%debug(pyco_prep),
			debug(pyco_proof),
			%debug(pyco_ep),
			debug(pyco_run),

			run(Q),
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
	format(user_error,'~nresult:~n', []),
	nicer_bn2(Sts, Sts_n),
	nicer_bn2(Ts, Ts_n),
	format(user_error,'~nSts:~n', []),
	maplist(writeln, Sts_n),
	format(user_error,'~nTs:~n', []),
	maplist(writeln, Ts_n),
	nl,nl,
	nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,nl,
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

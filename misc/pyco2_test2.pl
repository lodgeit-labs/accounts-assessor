:- [pyco2].



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
	'slice out a list',
	[
		slice_out_a_list(Whole, nil, Whole)
	]
	<=
	[
	]).

pyco0_rule(
	'slice out a list',
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
	['preprocess'(nil,nil)]
 	<=
	[]).

pyco0_rule(
	'preprocess',
	['preprocess'(S_transactions, Transactions)]
	<=
	[
		produces(St, Ts),
		slice_out_a_list(Transactions, Ts, Transactions_rest),
		fr(S_transactions, St, S_transactions_tail),
		'preprocess'(S_transactions_tail, Transactions_rest)
	]).

pyco0_rule(
	'produces 1',
	[produces(St, Ts)]
	<=
	[
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
		verb_counteraccount(Bn, Counteraccount)
	]
	<= [],
	mkbn(Bn, Desc{
		counteraccount:Counteraccount
	})) :- Desc = 'verb exists'.

pyco0_rule(
	Desc,
	[
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
	'transaction fields',
	[
		transaction(T,D,S,A,V)
	] <=
	[
		transaction_day(T,D),
		transaction_source(T,S),
		transaction_account(T,A),
		transaction_vector(T,V)
	]).

pyco0_rule(
	Desc,
	[
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
	's_transaction fields',
	[
		s_transaction(T,Verb,D,A,V,E)
	] <=
	[
		s_transaction_verb(T,Verb),
		s_transaction_day(T,D),
		s_transaction_account(T,A),
		s_transaction_vector(T,V),
		s_transaction_exchanged(T,E)
	]).

pyco0_rule(
	'q0',
	[
		q0(Sts, Ts)
	] <=
	[
		verb_counteraccount(Verb0, expenses),
		s_transaction(St0,Verb0,0,bank1,v,e),
		fr(Sts, St0, nil),
		preprocess(Sts, Ts)
	]).

pyco0_rule(
	'q1',
	[
		q1(Sts, Ts)
	] <=
	[
		verb_counteraccount(Verb0, expenses),
		s_transaction(St0,Verb0,0,bank1,v,e),
		s_transaction(St1,Verb0,1,bank2,vv,ee),
		fr(Sts, St0, Sts1),
		fr(Sts1, St1, nil),
		preprocess(Sts, Ts)
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




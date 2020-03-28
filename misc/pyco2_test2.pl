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




a pair nil - nil has the relation 'preprocess'.

a pair Sts - Ts has the relation 'preprocess' if:
	fr(Sts, St, Sts_rest),
	pick(T1, Ts, Ts2),
	pick(T2, Ts2, Ts3),
	a pair Sts_rest - Ts3 has the relation 'preprocess'.

^ the last statement would probably be tried first, with current body-reordering logic

what we should be doing instead:
	if a body item fails:
		if there were no eps in its call tree:
			fail
		else:
			put it at the end of the queue



(?c ?as ?bs) x x :-
	?c a ?as
	?c b ?bs

suc(?cr) a suc(?ar)

(?tc nil) a ?x :-




(?sts ?ts) a led




number of new binds
number of new constraints

whole body is one big term







with peano numbers:

'lists of same length'(A,B) :-
	list_length(A, L),
	list_length(B, L).


it should be noted that list_length won't necessarily be invoked directly, it could be through a helper pred.


list_length(nil, nil).
list_length(X, L) :-
	fr(X, _, Rest),
	L_minus_1 suc L
	list_length(Rest, L_minus_1)

when invoked with both args unbound, yields:
nil, nil
(_), suc(nil)
and then ep hits. or EP_YIELD's.
bn{first:_,rest:bn{_,_}}


if invoked by user:
'lists of same length'(?A,?B)
the answers should be:
nil nil
(_) (_)
ep!
.
if invoked by user:
'lists of same length'(?A,(b b))
the trace should be:
	list_length(?A, L),
		list_length(nil, zero).
			yield
	list_length((b b), zero).
		fail
	back to:
	list_length(?A, L),
		list_length(X, L).
			ep-yield






















q 'lists of same chars, of same length'(A,(x x))
m 'lists of same chars, of same length'(A,B)
b 'list of same chars, of length'(A, L),
	char(CH),
		char(a),
		this branch eventually fails
	'list of CH, of length L'(X, a, L).
	'list of CH, of length L'(nil, CH, zero).
		this branch eventually fails
until..
	char(CH),
		char(x),
	'list of CH, of length L'(X, a, L).
	'list of CH, of length L'(X, a, L).
		ep














list_length(nil, nil).
list_length(X, L) :-
	fr(X, _, Rest),
	L_minus_1 suc L
	list_length(Rest, L_minus_1)




*/



/*

bnode semantics:
	there exists


uri semantics:
	there exists AND is distinct from everything else


*/





pyco0_rule(
	Desc,
	[
		transaction_day(T,D),
		transaction_source(T,S),
		transaction_account(T,A),
		transaction_vector(T,V)
	] <=
	[],
	(T = bn(_, Desc{
		day:D,
		source:S,
		account:A,
		vector:V
	}),register_bn(T))) :-
		Desc = 'transaction exists'.

pyco0_rule(
	Desc,
	[
		s_transaction_day(T,D),
		s_transaction_account(T,A),
		s_transaction_vector(T,V)
		s_transaction_exchanged(T,E)
	] <=
	[],
	(T = bn(_, Desc{
		day:D,
		account:A,
		vector:V,
		exchanged:E
	}),register_bn(T))) :-
		Desc = 's_transaction exists'.

pyco0_rule(
	's_transaction fields',
	[
		s_transaction(T,D,A,V,E)
	] <=
	[
		s_transaction_day(T,D),
		s_transaction_account(T,A),
		s_transaction_vector(T,V)
		s_transaction_exchanged(T,E)
	]).
/*
pyco0_rule(
	's_transaction2 produces transactions',
	[preprocess_st2(St,T)] <=
	[
		s_transaction2(St,D,Primary_account,V,nil),
		verb_exchanged_account(V, Counteraccount),
		transaction(T,D,Primary_account,V),
		vec_inverse(V, Vi),
		transaction(T,D,Primary_account,V),


	]).
*/

pyco0_rule(
	's_transaction2s produce transactions 0',
	[preprocess_st2s(nil, nil)] <=
	[]).

pyco0_rule(
	's_transaction2s produce transactions 1',
	[preprocess_st2s(Sts,Ts)] <=
	[
		fr(Sts, St, Sts_r),
		fr(Ts, T, Ts_r),
		preprocess_st2(St,T),
		preprocess_st2s(Sts_r,Ts_r)
	]).





pyco0_rule(
	'test query3',
	[test_statement3(End, Ts, All, Capped)] <=
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
		fr(Ts3, T5, nil)

	]).



test2 :-
	findnsols(
		5000000000,
		_,
		(
			%debug(pyco_prep),
			%debug(pyco_proof),
			%debug(pyco_ep),

			Q = test_statement2(9, Ts, All, Capped),
			run(Q),
			nicer_term(Q, NQ),
			format(user_error,'~nresult: ~q~n', [NQ]),

			nicer_bn2(Ts, Ts_n),
			nicer_bn2(All, All_n),
			nicer_bn2(Capped, Capped_n),

			format(user_error,'~nTs:~n', []),
			maplist(writeln, Ts_n),

			format(user_error,'~nCapped:~n', []),
			maplist(writeln, Capped_n),

			format(user_error,'~nAll:~n', []),
			maplist(writeln, All_n),

			nl,
			true

		),
		_
	),
	halt.

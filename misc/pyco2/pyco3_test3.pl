:- ['../../sources/public_lib/lodgeit_solvers/prolog/pyco2/pyco3.pl'].
:- use_module(library(clpq)).



r(	exists-('fr', ['first','rest'])
	,n-'"All lists exist" - https://www.w3.org/TeamSubmission/n3/'
).



r(	exists-('coord', ['unit','amount'])
	,n-'coord exists'
).


r(
	vec_inverse(V, Vi)
		,fr(V, C1, nil)
		,fr(Vi, Ci1, nil)
		,coord_inverse(C1, Ci1)
	,n-vec_inverse
).

r(
	coord_inverse(C, Ci)
		,coord(C, Unit, Amount)
		,coord(Ci, Unit, Amount2)
		,{Amount = -Amount2}
	,n-coord_inverse
).

r(
	slice(List, Item, Rest)
		,fr(List, Item, Rest)
).

r(
	slice(List, Item, Rest)
		,fr(List, Skipped_item, List_tail)
		,fr(Rest, Skipped_item, Rest2)
		,slice(List_tail, Item, Rest2)
).

r(
	slice_out_a_list(Whole, nil, Whole)
).

r(	slice_out_a_list(Whole, Items_sliced_out, Rest)
		,fr(Items_sliced_out, Item, Items_sliced_out_tail)
		,slice(Whole, Item, Remaining)
		,slice_out_a_list(Remaining, Items_sliced_out_tail, Rest)
).

% preprocess s_transaction2s into transactions'
% an empty list preprocesses into an empty list.
% s_transaction2s are processed or produced in order.
% transactions are picked out from anywhere in the list.

delay(preprocess(Verbs, _, _),3600) :-
	var(Verbs).

r(
	n-'(nil, nil) has the relation "preprocess"'
	,preprocess(_,nil,nil)
).

r(
	preprocess(Verbs, S_transactions, Transactions)
		,member(Verb, Verbs)
		,produces(Verb, St, Ts)
		,slice_out_a_list(Transactions, Ts, Transactions_rest)
		,fr(S_transactions, St, S_transactions_tail)
		,preprocess(Verbs, S_transactions_tail, Transactions_rest)
).

/*
selection of speed-optimal order of body items: perhaps this is best defined on the level of predicate definitions. Might be even more optimal on the level of rule definitions, but i'm not sure that we can realistically implement that in prolog.
So let's say preprocess/3 has delay-hint: if Verbs is unbound, shift me back by X seconds. X may be a constant or an expression possibly even calling more pyco preds, taking lengts of lists or whatnot.
The next pred invoked after preprocess/3 may shift back too, etc, until we get to the end of the body, at which point, we sort the body items by "delay-hint" and commit to the lowest.

later we could add more meaningful units than "seconds", ie specify it as "expected cpu seconds", add "expected ram usage", etc.

*/
r(
	n-'produces 1'
	,produces(Verb, St, Ts)
		,verb_type(Verb, basic)
		,verb_counteraccount(Verb, Counteraccount)
		,s_transaction(St,Verb,D,Primary_account,V,nil)
		,transaction(T0,D,St,Primary_account,V)
		,vec_inverse(V, Vi)
		,transaction(T1,D,St,Counteraccount,Vi)
		,fr(Ts,T0,Ts2)
		,fr(Ts2,T1,nil)
).

r(
	n-'produces 2'
	,produces(Verb, St, Ts)
		,verb_type(Verb, exchange)
		,verb_counteraccount(Verb, Counteraccount)
		,s_transaction(St,Verb,D,Primary_account,V,E)
		,transaction(T0,D,St,Primary_account,V)
		,transaction(T1,D,St,Counteraccount,E)
		,fr(Ts,T0,Ts2)
		,fr(Ts2,T1,nil)
).


r(
	exists-(verb, [name, type, counteraccount])
).

r(
	exists-(transaction, [day, source, account, vector])
).

r(
	exists-(s_transaction, [verb, day, account, vector, exchanged])
).

r(
	default_verbs(Verbs, Verb0, Verb1)
		,verb(Verb0, invest_in, exchange, investments)
		,verb(Verb1, expense, basic, expenses)
		,fr(Verbs, Verb0, Verbs2)
		,fr(Verbs2, Verb1, nil)
).


/* inference of many s_transactions */
r(
	q5(Sts, Ts0)
		,fr(Ts0, T0, Ts1)
		,fr(Ts1, T1, Ts2)
		,fr(Ts2, T2, Ts3)
		,fr(Ts3, T3, Ts4)
		,fr(Ts4, T4, Ts5)
		,fr(Ts5, T5, Ts6)
		,fr(Ts6, T6, Ts7)
		,fr(Ts7, T7, Ts8)
		,fr(Ts8, T8, Ts9)
		,fr(Ts9, T9, Ts10)
		,fr(Ts10, T10, Ts11)
		,fr(Ts11, T11, nil)
		,coord(C1,'AUD',-5),fr(Vec1,C1,nil)
		,coord(C2,'AUD',5),fr(Vec2,C2,nil)
		,coord(C3,'AUD',-60),fr(Vec3,C3,nil)
		,coord(C4,'AUD',60),fr(Vec4,C4,nil)
		,transaction(T0,0,_,bank0,Vec1)
		,transaction(T1,0,_,expenses,Vec2)
		,transaction(T2,1,_,bank0,Vec1)
		,transaction(T3,1,_,expenses,Vec2)
		,transaction(T4,2,_,bank0,Vec1)
		,transaction(T5,3,_,expenses,Vec2)
		,transaction(T6,3,_,bank0,Vec1)
		,transaction(T7,2,_,expenses,Vec2)
		,transaction(T8,4,_,bank0,Vec1)
		,transaction(T9,4,_,expenses,Vec4)
		,transaction(T10,4,_,bank0,Vec3)
		,transaction(T11,4,_,expenses,Vec2)
		,preprocess(Verbs,Sts,Ts0)
		,default_verbs(Verbs, _, _)
).


test(Q) :-
	debug(pyco_prep),
	debug(pyco_proof),
	%debug(pyco_ep),
	debug(pyco_run),

	findnsols(
		5000000000,
		_,
		one_result(Q),
		_
	),
	halt.


one_result(Q) :-
	run(noisy, Q),
	print_1(Q),
	nicer_term(Q, NQ),
	format(user_error,'~nresult: ~q~n', [NQ]),
	nl,
	nl.


print_1(Q) :-
	(	print_q(Q)
	->	true
	;	throw_string('failed printing result')).

print_q(Q) :-
	Q =.. [_,Sts,Ts],
	format(user_error,'~nRESULT:~n', []),
	nicer_bn2(Sts, Sts_n),
	nicer_bn2(Ts, Ts_n),
	format(user_error,'~nSts:~n', []),
	maplist(writeln, Sts_n),
	format(user_error,'~nTs:~n', []),
	maplist(writeln, Ts_n),
	nl,nl.

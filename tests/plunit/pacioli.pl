:- ['../../lib/pacioli'].


:- begin_tests(pacioli).


test(0,all(X=[x])) :-
	vec_units(
		[
			coord(aud, _,_), 
			coord(aud, _,_), 
			coord(usd, _,_)
		], 
		Units0
	), 
	Units0 = [aud, usd],

	vec_units([], []),
	vec_units([coord(aud, 5,7), coord(aud, _,_), coord(Usd, _,_)], [aud, Usd]),
	pacioli:coord_merge(coord(Unit, 1, 2), coord(Unit, 3, 4), coord(Unit, 4, 6)),
	utils:semigroup_foldl(pacioli:coord_merge, [], []),
	utils:semigroup_foldl(pacioli:coord_merge, [value(X, 5)], [value(X, 5)]),
	utils:semigroup_foldl(pacioli:coord_merge, [coord(x, 4, 5), coord(x, 4, 5), coord(x, 4, 5)], [coord(x, 12, 15)]),
	\+utils:semigroup_foldl(pacioli:coord_merge, [coord(y, 4, 5), coord(x, 4, 5), coord(x, 4, 5)], _),
	vec_add([coord(a, 5, 1)], [coord(a, 0.0, 4)], []),
	vec_add([coord(a, 5, 1), coord(b, 0, 0.0)], [coord(b, 7, 7), coord(a, 0.0, 4)], []),
	vec_add([coord(a, 5, 1), coord(b, 1, 0.0)], [coord(a, 0.0, 4)], Res0),
	Res0 = [coord(b, 1.0, 0.0)],
	vec_add([coord(a, 5, 1), coord(b, 1, 0.0), coord(a, 8.0, 4)], [], Res1),
	Res1 = [coord(a, 8.0, 0), coord(b, 1.0, 0.0)],
	vec_add([value('AUD',25)], [value('AUD',50)], [value('AUD',75)]),
	X=x.

:- end_tests(pacioli).


/*
fixme: just check vec_add with this.
:- maplist(

		transaction_vector, 
		Transactions, 
		vec_add(
			[
				coord(aAAA, 5, 1), 
				coord(aBBB, 0, 0.0), 
				coord(aBBB, 7, 7)], 
			[coord(aAAA, 0.0, 4)]]
	), 
	check_trial_balance(Transactions).


:- maplist(transaction_vector, Transactions, [[coord(aAAA, 5, 1)], [coord(aAAA, 0.0, 4)]]), check_trial_balance(Transactions).
:- maplist(transaction_vector, Transactions, [[coord(AAA, 5, 1), coord(BBB, 0, 0.0)], [], [coord(BBB, 7, 7)], [coord(AAA, 0.0, 4)]]), check_trial_balance(Transactions).
:- maplist(transaction_vector, Transactions, [[coord(AAA, 45, 49), coord(BBB, 0, 0.0)], [], [coord(BBB, -7, -7)], [coord(AAA, 0.0, -4)]]), check_trial_balance(Transactions).
*/
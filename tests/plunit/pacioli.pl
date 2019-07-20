:- ['../../lib/pacioli'].


:- begin_tests(pacioli).


test(0) :-
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
	vec_add([value('AUD',25)], [value('AUD',50)], [value('AUD',75)]).

:- end_tests(pacioli).


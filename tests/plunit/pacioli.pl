:- ['../../lib/pacioli'].


:- begin_tests(pacioli).

test(0, all((D,C) = [(0, 2000)])) :-
	pacioli:dr_cr_coord(u, D, C, coord(u, -2000)).


test(0,all(Units = [[aud, usd]])) :-
	vec_units(
		[
			coord(aud, _), 
			coord(aud, _), 
			coord(usd, _)
		], 
		Units
	).

test(2) :-
	vec_units([], []),
	vec_units(
		[
			coord(aud, 7), 
			coord(aud, _), 
			coord(_, _)
		], 
		Units
	), 
	Units = [_, aud].


test(3) :-
	pacioli:coord_merge(coord(Unit, 1), coord(Unit, -3), coord(Unit, -2)).
	
test(1,all(x=[x])) :-
	utils:semigroup_foldl(pacioli:coord_merge, [], []),
	utils:semigroup_foldl(pacioli:coord_merge, [value(X, 5)], [value(X, 5)]),
	utils:semigroup_foldl(pacioli:coord_merge, [coord(x, -1), coord(x, -1), coord(x, -1)], [coord(x, -3)]),
	\+utils:semigroup_foldl(pacioli:coord_merge, [coord(y, -1), coord(x, -1), coord(x, -1)], _).
	
test(1,all(x=[x])) :-
	vec_add([coord(a, 5)], [coord(a, -5)], []).

test(1,all(x=[x])) :-
	vec_add([coord(a, 5), coord(b, 0.0)], [coord(b, 0), coord(a, -5)], []).

test(1,all(Res0 = [[coord(b, 1.0)]])) :-
	vec_add([coord(a, 4), coord(b, 1.0)], [coord(a, -4)], Res0).

test(1,all(Res1 = [[coord(a, 8.0), coord(b, 1.0)]])) :-
	vec_add([coord(a, 5), coord(b, 1.0), coord(a, 3.0)], [], Res1).

test(1,all(R = [[value('AUD',75)]])) :-
	vec_add([value('AUD',25)], [value('AUD',50)], R).

:- end_tests(pacioli).



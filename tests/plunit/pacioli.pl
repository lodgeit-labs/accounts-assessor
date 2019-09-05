:- ['../../lib/pacioli'].


:- begin_tests(pacioli).


test(0,all(Units = [[aud, usd]])) :-
	vec_units(
		[
			coord(aud, _,_), 
			coord(aud, _,_), 
			coord(usd, _,_)
		], 
		Units
	).

test(2) :-
	vec_units([], []),
	vec_units(
		[
			coord(aud, 5,7), 
			coord(aud, _,_), 
			coord(_, _,_)
		], 
		Units
	), 
	Units = [_, aud].


test(3) :-
	pacioli:coord_merge(coord(Unit, 1, 2), coord(Unit, 3, 4), coord(Unit, 4, 6)).
	
test(1,all(x=[x])) :-
	utils:semigroup_foldl(pacioli:coord_merge, [], []),
	utils:semigroup_foldl(pacioli:coord_merge, [value(X, 5)], [value(X, 5)]),
	utils:semigroup_foldl(pacioli:coord_merge, [coord(x, 4, 5), coord(x, 4, 5), coord(x, 4, 5)], [coord(x, 12, 15)]),
	\+utils:semigroup_foldl(pacioli:coord_merge, [coord(y, 4, 5), coord(x, 4, 5), coord(x, 4, 5)], _).
	
test(1,all(x=[x])) :-
	vec_add([coord(a, 5, 1)], [coord(a, 0.0, 4)], []).

test(1,all(x=[x])) :-
	vec_add([coord(a, 5, 1), coord(b, 0, 0.0)], [coord(b, 7, 7), coord(a, 0.0, 4)], []).

test(1,all(Res0 = [[coord(b, 1.0, 0.0)]])) :-
	vec_add([coord(a, 5, 1), coord(b, 1, 0.0)], [coord(a, 0.0, 4)], Res0).

test(1,all(Res1 = [[coord(a, 8.0, 0), coord(b, 1.0, 0.0)]])) :-
	vec_add([coord(a, 5, 1), coord(b, 1, 0.0), coord(a, 8.0, 4)], [], Res1).

test(1,all(R = [[value('AUD',75)]])) :-
	vec_add([value('AUD',25)], [value('AUD',50)], R).

:- end_tests(pacioli).



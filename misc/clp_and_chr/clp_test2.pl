:- use_module(library(clpq)).

test(Start, N, List) :-
	gen_list(Start, N, List).

gen_list(_, 0, []).
gen_list(Previous_Value, N, [Value | Rest]) :-
	{N > 0},
	{Value = Previous_Value - 2},
	{M = N - 1},
	gen_list(Value, M, Rest).

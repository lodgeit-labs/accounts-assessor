main :-
	format("X: ~w~nY: ~w~n", [X, Y]),
	f([0, 0, X, Y]).

f(Lin) :-
	Lin = [_, _ | Rest],
	format("Rest: ~w~n", [Rest]).

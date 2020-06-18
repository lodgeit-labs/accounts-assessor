:- module(clp_nonlinear, [solve/2]).

:- use_module(library(clpq)).
:- use_module(library(clpfd)).

solve(X, Q) :-
	findall(
		F,
		(
			label([X]),
			F = X,
			\+assert_q_constraints(Q)
		),
		Fs
	),
	new_constraints(X, Fs),
	assert_q_constraints(Q).

assert_q_constraints([]).
assert_q_constraints([C | Cs]) :-
	{ C },
	assert_q_constraints(Cs).

new_constraints(_, []).
new_constraints(X, [Y | Ys]) :-
	X #\= Y,
	new_constraints(X, Ys).

fd_rat((Num1/Den1) + (Num2/Den2), (Num3/Den3)) :-
	Num3 #= (Num1*Den2) + (Num2*Den1),
	Den3 #= (Den1 * Den2).

/*
graph_add((X, foo, 1)),
Doc = [(X, foo, 1)],
graph_add((Y, foo, _)),
Doc = [(X, foo, 1), (Y, foo, _)],
X = Y
Doc = [(X, foo, 1), (X, foo, _)],
(X foo Y1, X foo Y2) => (Y1 = Y2),
Doc = [(X, foo, 1)].


*/

graph_add(T, [], [T]).
graph_add((S1, P1, O1), [(S2, P2, O2) | Rest], ...) :-
	% are they the same?

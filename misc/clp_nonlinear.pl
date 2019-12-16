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

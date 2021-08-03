:- use_module(library(clpz)).
:- use_module(library(format)).


reduction(An/Ad, An2/Ad2) :-
	An = An2 * Af,
	Ad = Ad2 * Af.


add(Aout,Bout,Cout) :-
	reduction(An/Ad, Aout),
	reduction(Bn/Bd, Bout),
	reduction(Cn/Cd, Cout),
	An2 #= An * Bd,
	Bn2 #= Bn * Ad,
	Cn #= An2 + Bn2,
	Cd #= Ad * Bd.


missing_dot :-
	add(41152/259, 54/78, X),writeq(X),nl.


%add(41152r259 - 5592134817830753r35184372088832,


%:- initialization((missing_dot,halt)).

:- use_module(library(chr)).

:- chr_constraint fact/3.

fact(S, P, O), fact(S, P, O) <=> fact(S, P, O).

fact(HP, a, hp_arrangement) ==> fact(HP, cash_price, _).
fact(HP, a, hp_arrangement), fact(HP, cash_price, X), fact(HP, cash_price, Y) ==> X = Y.
fact(HP, a, hp_arrangement) ==> fact(HP, interest_rate, _).
fact(HP, a, hp_arrangement), fact(HP, interest_rate, X), fact(HP, interest_rate, Y) ==> X = Y.
fact(HP, a, hp_arrangement), fact(HP, cash_price, X), fact(HP, interest_rate, Y) ==> ground(X) | Y is X - 2.
fact(HP, a, hp_arrangement), fact(HP, cash_price, X), fact(HP, interest_rate, Y) ==> ground(Y) | X is Y + 2.



:- fact(hp1, a, hp_arrangement), fact(hp1, cash_price, 20).
/*
	fact(hp1, cash_price, 20).
	fact(hp1, interest_rate, 18).
	fact(hp1, a, hp_arrangement).
*/

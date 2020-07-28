:- use_module(library(clpz)).


/*
rationals with clpfd. A rational is:
```
Numerator
--------
Denominator
```
`Numerator // Denominator` or `Numerator div Denominator` never appears.

clpfd gets stuck enumerating the answer.

*/


rat_add(Xn/Xd,Yn/Yd,Zn/Zd) :-
	Xd #> 0,
	Yd #> 0,
	Zd #> 0,
	ResD #> 0,

	Xd #< 2^999999,
	Yd #< 2^999999,
	Zd #< 2^999999,
	ResD #< 2^999999,

	ResD #= Xd * Yd,
	ResN #= Xd * Yn + Yd * Xn,
	
	ResD * Zn #= ResN * Zd.




x :-
	rat_add(5/3,6/4,W),
	W = Wn/_,
	writeq(W),nl,
	indomain(Wn),
	writeq(W),nl
.

y :-
	rat_add(Wn/Wd,6/4,13/7),
	label([Wn]),
	W = Wn/Wd,
	writeq(W),nl
.


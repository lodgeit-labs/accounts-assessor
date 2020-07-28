:- use_module(library(clpfd)).


/*
interval arithmetic with clpfd. 
*/


lmt(L, A, U) :-
	Al is L*10^20,
	Au is U*10^20,
	round(Al, Alr),
	round(Au, Aur),
	A #>= Alr, A #< Aur.

mlt(A * B = C) :-
	%A * B #= C * 10^10.
	A #= (C * (10^20)) // B.
	

x :-
	gtrace,

	/* input: "A = 1" (precision:one digit) */
	lmt(0.5, A, 1.5),
	lmt(120.546879654654, C, 120.546879654655),
	mlt(A * B = C),
/*	write_term(B,[attributes(portray)]),
	nl,*/
	
	findall(_,
		(
%			gtrace,
			labeling([bisect], [B]),
			%write_term(B,[attributes(portray)]),
			nl
		),
	_).
	
	
:- x.

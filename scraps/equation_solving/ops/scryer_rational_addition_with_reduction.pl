:- use_module(library(clpz)).
:- use_module(library(format)).




reduction(An/Ad, NormN/NormD, Af) :-
	An = Af * NormN,
	Ad = Af * NormD,
	Af #> 0.



add_reduced(Aout,Af,Bout,Bf,Cout,Cf) :-
	reduction(An/Ad, Aout, Af),
	reduction(Bn/Bd, Bout, Bf),
	reduction(Cn/Cd, Cout, Cf),
	An2 #= An * Bd,
	Bn2 #= Bn * Ad,
	Cn #= An2 + Bn2,
	Cd #= Ad * Bd.

mult_reduced(Aout,Af,Bout,Bf,Cout,Cf) :-
	reduction(An/Ad, Aout, Af),
	reduction(Bn/Bd, Bout, Bf),
	reduction(Cn/Cd, Cout, Cf),
	An2 #= An * Bd,
	Bn2 #= Bn * Ad,
	Cn #= An2 * Bn2,
	Cd #= Ad * Bd.



test_add1 :-
	add_reduced(41152/259,1, 54/78,1, C,Cf1),
	mult_reduced(C,Cf2, 52/1,1, X,Xf),


	C = Cn/Cd,
	X = Xn/Xd,
	findall(_, 
		 (
			 Cn #< 99999999999999999,
			 Cn #> -9999999999999999,
			 Cd #< 99999999999999999,
			 Cd #> -9999999999999999,
			 Vars = [Cf1,Cf2,Xf, Cn, Cd , Xn, Xd],
			 writeq(Vars),nl,
			 labeling([ff], Vars),
			 writeq(Vars),nl
		),
		 _).

/*
└─< (master)* >──» scryer-prolog scryer_rational_addition_with_reduction.pl -g test_add1                           0 < 12:19:09
537307/3367
1074614/6734
1611921/10101
3223842/20202
?- 
*/

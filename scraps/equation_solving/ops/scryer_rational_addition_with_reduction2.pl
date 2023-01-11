:- use_module(library(clpz)).
:- use_module(library(format)).



/* A + B = C, A * B = C, only the C is thought to be denormalized.
*/



reduction(An/Ad, NormN/NormD, Af) :-
	An = Af * NormN,
	Ad = Af * NormD,
	Af #> 0/*,
	Af #< 9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999*/.



add_reduced(An/Ad,Bn/Bd,Cout,Cf) :-
	reduction(Cn/Cd, Cout, Cf),
	An2 #= An * Bd,
	Bn2 #= Bn * Ad,
	Cn #= An2 + Bn2,
	Cd #= Ad * Bd.

mult_reduced(An/Ad,Bn/Bd,Cout,Cf) :-
	reduction(Cn/Cd, Cout, Cf),
	Cn #= An * Bn,
	Cd #= Ad * Bd.



test_add1 :-
	add_reduced(41152/259,54/78, C,Cf1),
	mult_reduced(C, 52/1, X,Xf),


	C = Cn/Cd,
	X = Xn/Xd,
	
	
	findall(_, 
		 (
			 /*Cn #< 99999999999999999,
			 Cn #> -9999999999999999,
			 Cd #< 99999999999999999,
			 Cd #> -9999999999999999,*/
			 Vars = [Cf1,Xf, Cn, Cd , Xn, Xd],
			 writeq(Vars),nl,
			 labeling([ff], Vars),
			 writeq(Vars),nl
		),
		 _).

:- use_module(library(clpz)).
:- use_module(library(format)).



/*
reduction(An/Ad, NormN/NormD) :-
	An = Af * NormN,
	Ad = Af * NormD,
	Af #> 0.


add_reduced(Aout,Bout,Cout) :-
	reduction(An/Ad, Aout),
	reduction(Bn/Bd, Bout),
	reduction(Cn/Cd, Cout),
	An2 #= An * Bd,
	Bn2 #= Bn * Ad,
	Cn #= An2 + Bn2,
	Cd #= Ad * Bd.
*/


add(An/Ad,Bn/Bd,Cn/Cd) :-
	An2 #= An * Bd,
	Bn2 #= Bn * Ad,
	Cn #= An2 + Bn2,
	Cd #= Ad * Bd.


test_add1 :-
	
	add(41152/259, 54/78, C),
	C = Cn/Cd,
	
	findall(_, 
		 (
			 Cn #< 999999999999,
			 Cn #> -999999999999,
			 Cd #< 999999999999,
			 Cd #> -999999999999,
			 labeling([bisect, leftmost], [Cn, Cd]),
			 writeq(C),
			 nl
		),
		 _).

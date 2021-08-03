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



test_add1 :-
	add_reduced(41152/259,Af, 54/78,Bf, C,Cf),
	Af = 1,
	Bf = 1,
	Cf = _,
	C = Cn/Cd,
	
	findall(_, 
		 (
			 Cn #< 99999999999999999,
			 Cn #> -9999999999999999,
			 Cd #< 99999999999999999,
			 Cd #> -9999999999999999,
			 labeling([/*bisect, leftmost*/], [Cn, Cd/*,Af,Bf,Cf*/]),
			 writeq(C),
			 nl
		),
		 _).

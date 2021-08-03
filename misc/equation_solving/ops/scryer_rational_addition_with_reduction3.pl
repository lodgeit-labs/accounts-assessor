:- use_module(library(clpz)).
:- use_module(library(format)).

/* 
A + B = C, A * B = C, only the C is thought to be denormalized.
*/

reduction(An/Ad, NormN/NormD, Af) :-
	An = Af * NormN,
	Ad = Af * NormD,
	Af #> 0.

eval(An/Ad,'+',Bn/Bd,'=',Cout,Cf) :-
	reduction(Cn/Cd, Cout, Cf),
	An2 #= An * Bd,
	Bn2 #= Bn * Ad,
	Cn #= An2 + Bn2,
	Cd #= Ad * Bd.

eval(An/Ad,'*',Bn/Bd,'=',Cout,Cf) :-
	reduction(Cn/Cd, Cout, Cf),
	Cn #= An * Bn,
	Cd #= Ad * Bd.

breakdown(N/D,[N,D]).

test1 :-
	maplist(eval,[
		(41152/259, '+', 54/78, '=', C),
		(C, '*', 52/1, '=', D),
		(X, '+', 154/78, '=', D)
	], Norm_factors),
	maplist(breakdown, [C,D,X], Nums),
	
	findall(_, 
		 (
			 flatten([Norm_factors, Nums], Vars),
			 writeq(Vars),nl,
			 labeling([ff], Vars),
			 writeq(Vars),nl
		),
		 _).

:- module(_,[]).
:- use_module(constraint_store, []).

explain :-
	constraint_store:output(Constraints),
	findall(
		Triple,
		(
			doc(X,Y,Z),
			Triple = (X,Y,Z),
			ground(Triple),



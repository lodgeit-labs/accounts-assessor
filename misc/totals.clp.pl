:- use_module(library(clpq)).

totals([N|Numbers], [R|Running_Sum], Prev_Sum) :-
	{R = Prev_Sum + N},
	totals(Numbers, Running_Sum, R).

totals([], [], _).


/*

?- totals([1,2,3,4,5],[1,3,6,X,Y],0).
X = 10,
Y = 15.

?- totals([1,2,3,A,5],[1,3,6,X,Y],0).
{Y=11+A, X=6+A}.

?- 
*/

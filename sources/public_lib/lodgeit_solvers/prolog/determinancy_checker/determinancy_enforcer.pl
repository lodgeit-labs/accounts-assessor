/*
a "performant" implmentation/stub, it cuts after first solution and doesn't check if there were more.
*/


'!'(X) :-
	(call(X)->true;throw(deterministic_call_failed(X))).

'!'(X,A1) :-
	(call(X,A1)->true;throw(deterministic_call_failed((X,A1)))).

'!'(X,A1,A2) :-
	(call(X,A1,A2)->true;throw(deterministic_call_failed((X,A1,A2)))).

'?'(X) :-
	call(X),!.


/*
a "performant" implmentation/stub, it cuts after first solution and doesn't check if there were more.
*/


'!'(X) :-
	(call(X)->true;throw(deterministic_call_failed(X))).

'?'(X) :-
	call(X),!.


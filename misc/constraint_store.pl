:- module(_,[]).

init :-
	b_setval(constraints_store,_A_List).

add(C) :-
	b_getval(constraints_store,List),
	member(C, List).

output :-
	b_getval(constraints_store,List),
	constraints_json(List).

constraints_json(H, []) :-
	(var(H);H=[]),
	!.

constraints_json([H|T], Json) :-
	H =.. [Json],
	!.
	
constraints_json([H|T], [JsonH|JsonT]) :-
	H =.. [Functor|Args],
	JsonH = _{op:Functor, args:Args_Json},
	constraints_json(Args, Args_Json),
	dict_pairs(Args_Json, Functor, Pairs),
	constraints_json(T, JsonT).
	
	
	

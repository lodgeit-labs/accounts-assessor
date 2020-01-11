/*
	given a list of terms, for example, of transactions, and a Selector_Predicate, for example transaction_account_id,
	produce a dict with keys returned by the selector, and values lists of terms
*/
sort_into_dict(Selector_Predicate, Ts, D) :-
	sort_into_dict(Selector_Predicate, Ts, _{}, D).

:- meta_predicate sort_into_dict(2, ?, ?, ?).

sort_into_dict(Selector_Predicate, [T|Ts], D, D_Out) :-
	call(Selector_Predicate, T, A),
	(
		L = D.get(A)
	->
		true
	;
		L = []
	),
	append(L, [T], L2),
	D2 = D.put(A, L2),
	sort_into_dict(Selector_Predicate, Ts, D2, D_Out).

sort_into_dict(_, [], D, D).

sort_into_assoc(Selector_Predicate, Ts, D) :-
	empty_assoc(A),
	sort_into_assoc(Selector_Predicate, Ts, A, D).

:- meta_predicate sort_into_assoc(2, ?, ?, ?).

sort_into_assoc(Selector_Predicate, [T|Ts], D, D_Out) :-
	call(Selector_Predicate, T, A),
	(
		get_assoc(A, D, L)
	->
		true
	;
		L = []
	),
	append(L, [T], L2),
	put_assoc(A, D, L2, D2),
	sort_into_assoc(Selector_Predicate, Ts, D2, D_Out).

sort_into_assoc(_, [], D, D).



:- meta_predicate find_thing_in_tree(?, 2, 3, ?).

find_thing_in_tree(Root, Matcher, _, Root) :-
	call(Matcher, Root).

find_thing_in_tree([Entry|_], Matcher, Children_Yielder, Thing) :-
	find_thing_in_tree(Entry, Matcher, Children_Yielder, Thing).

find_thing_in_tree([_|Entries], Matcher, Children_Yielder, Thing) :-
	find_thing_in_tree(Entries, Matcher, Children_Yielder, Thing).

find_thing_in_tree(Root, Matcher, Children_Yielder, Thing) :-
	call(Children_Yielder, Root, Child),
	find_thing_in_tree(Child, Matcher, Children_Yielder, Thing).



path_get_dict((X/Y), Dict, Y_Value) :-
	path_get_dict(X, Dict, X_Value),
	path_get_dict(Y, X_Value, Y_Value).

path_get_dict(K, Dict, V) :-
	K \= (_/_),
	get_dict(K, Dict, V).



unzip([], [], []).
unzip([X,Y|T], [X|XT], [Y|YT]) :-
	unzip(T, XT, YT).



remove_before(Slash, Name_In, Name_Out) :-
   once((
   memberchk(Slash, Name_In)
   ->
     reverse(Name_In, RName),
     append(RFName, [Slash|_R1], RName),
     reverse(RFName, Name_Out)
   ;
     Name_Out = Name_In)
    ).




add(Open_List, Item) :-
	once((
		member(M, Open_List),
		var(M),
		Item = M)).

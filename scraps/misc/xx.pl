path_term_to_list(Bulk/Atom, List) :-
    freeze(Atom,atomic(Atom)),
    !,
    append(List_rest, [Atom], List),
    path_term_to_list(Bulk, List_rest),
    !.

path_term_to_list(Bulk, [Bulk]) :-
	atomic(Bulk),!.
	


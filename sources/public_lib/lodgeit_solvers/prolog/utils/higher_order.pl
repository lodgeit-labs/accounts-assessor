
/* standard library only has maplist up to arity 5, maplist/6 is not in standard library */
:- meta_predicate maplist6(6, ?, ?, ?, ?, ?).
:- meta_predicate maplist6_(?, ?, ?, ?, ?, 6).

maplist6(Goal, List1, List2, List3, List4, List5) :-
    maplist6_(List1, List2, List3, List4, List5, Goal).

maplist6_([], [], [], [], [], _).

maplist6_([Elem1|Tail1], [Elem2|Tail2], [Elem3|Tail3], [Elem4|Tail4], [Elem5|Tail5], Goal) :-
    call(Goal, Elem1, Elem2, Elem3, Elem4, Elem5),
    maplist6_(Tail1, Tail2, Tail3, Tail4, Tail5, Goal).


/*Like foldl, but without initial value. No-op on zero- and one- item lists.*/
:- meta_predicate semigroup_foldl(3, ?, ?).
semigroup_foldl(_Goal, [], []).

semigroup_foldl(_Goal, [Item], [Item]).

semigroup_foldl(Goal, [H1, H2 | T], V) :-
    call(Goal, H1, H2, V1),
    semigroup_foldl(Goal, [V1 | T], V).


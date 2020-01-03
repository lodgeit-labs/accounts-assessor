:-  op(  1,  fx,   [ not ]).
:-  op(  1,  xfx,  [ and ]).
:-  op(  1,  xfx,  [ or ]).
:-  op(  1,  xfx,  [ implies ]).


signature([p/0, f/1, g/1, r/2, q/2]).

in_signature(S, T) :-
	T =.. [F | Args],
	member(F/Arity, S),
	length(Args, Arity).

prop(not X) :- prop(X).
prop(X and Y) :- prop(X), prop(Y). 
prop(X or Y) :- prop(X), prop(Y).
prop(X implies Y) :- prop(X), prop(Y).
prop(T) :- signature(S), in_signature(S, T).
prop(forall(X,Y)) :- var(X), prop(Y).
prop(exists(X,Y)) :- var(X), prop(Y).


% these predicates are used to convert an FOL formula to an equisatisfiable propositional CNF formula
remove_implications(T, (not X2) or Y2) :- 
	T = (X implies Y),
	remove_implications(X, X2),
	remove_implications(Y, Y2).
remove_implications(T, T) :- \+(T == (_ implies _)).

% need generic tree operations; shouldn't need to explicitly recurse here, formula should just be expressed
% in terms of one level of transformation, and recursion should be handled by some kind of tree-map/fold of that
% transformation.
push_negation_inward(not (not X), X2) :-
	push_negation_inward(X, X2).
push_negation_inward(not (X and Y), (not X2) or (not Y2)) :-
	push_negation_inward(X, X2),
	push_negation_inward(Y, Y2).
push_negation_inward(not (X or Y), (not X2) and (not Y2)) :-
	push_negation_inward(X, X2),
	push_negation_inward(Y, Y2).
push_negation_inward(not T, not T) :- signature(S), in_signature(S, T).
push_negation_inward(not (forall(X,Y)), exists(X, not Y2)) :-
	push_negation_inward(Y, Y2).
push_negation_inward(not (exists(X,Y)), forall(X, not Y2)) :-
	push_negation_inward(Y, Y2).


% need generic operations for this; maybe abstract binding trees?
rename_duplicate_bound_vars(forall(X, Y1) and forall(X, Y2), forall(X, Y1) and forall(_,Y2)).
rename_duplicate_bound_vars(forall(X, Y1) or  forall(X, Y2), forall(X, Y1) or  forall(_,Y2)).
rename_duplicate_bound_vars(forall(X, Y1) and exists(X, Y2), forall(X, Y1) and exists(_,Y2)).
rename_duplicate_bound_vars(forall(X, Y1) or  exists(X, Y2), forall(X, Y1) or  exists(_,Y2)).
rename_duplicate_bound_vars(exists(X, Y1) and exists(X, Y2), exists(X, Y1) and exists(_,Y2)).
rename_duplicate_bound_vars(exists(X, Y1) or  exists(X, Y2), exists(X, Y1) or  exists(_,Y2)).
rename_duplicate_bound_vars(exists(X, Y1) and forall(X, Y2), exists(X, Y1) and forall(_,Y2)).
rename_duplicate_bound_vars(exists(X, Y1) or  forall(X, Y2), exists(X, Y1) or  forall(_,Y2)).
rename_duplicate_bound_vars(forall(X, Y1) and forall(X2, Y2), forall(X, Y1) and forall(X2,Y2)) :- \+X == X2.
rename_duplicate_bound_vars(forall(X, Y1) or  forall(X2, Y2), forall(X, Y1) or  forall(X2,Y2)) :- \+X == X2.
rename_duplicate_bound_vars(forall(X, Y1) and exists(X2, Y2), forall(X, Y1) and exists(X2,Y2)) :- \+X == X2.
rename_duplicate_bound_vars(forall(X, Y1) or  exists(X2, Y2), forall(X, Y1) or  exists(X2,Y2)) :- \+X == X2.
rename_duplicate_bound_vars(exists(X, Y1) and exists(X2, Y2), exists(X, Y1) and exists(X2,Y2)) :- \+X == X2.
rename_duplicate_bound_vars(exists(X, Y1) or  exists(X2, Y2), exists(X, Y1) or  exists(X2,Y2)) :- \+X == X2.
rename_duplicate_bound_vars(exists(X, Y1) and forall(X2, Y2), exists(X, Y1) and forall(X2,Y2)) :- \+X == X2.
rename_duplicate_bound_vars(exists(X, Y1) or  forall(X2, Y2), exists(X, Y1) or  forall(X2,Y2)) :- \+X == X2.

rename_duplicate_bound_vars2(T, T2) :-
	T =.. [F, Arg1, Arg2],
	( F = and ; F = or ),
	Arg1 =.. [F1, Var1, Body1],
	Arg2 =.. [F2, Var2, Body2],
	( F1 = forall ; F1 = exists),
	( F2 = forall ; F2 = exists),
	(
		Var1 == Var2
	->
		(
			subst(Var2, Var_Fresh, Body2, Body2_Sub),
			Body12 =.. [F, Body1, Body2_Sub],
			Arg2_Sub =.. [F2, Var_Fresh, Body12],
			T2 =.. [F1, Var1, Arg2_Sub]
		)
	;
		(
			Body12 =.. [F, Body1, Body2],
			Arg2_Sub =.. [F2, Var2, Body12],
			T2 =.. [F1, Var1, Arg2_Sub]
		)
	).

/*
move_quantifiers_left...

skolemize...

remove_universal_quantifiers...

convert_to_cnf...
*/

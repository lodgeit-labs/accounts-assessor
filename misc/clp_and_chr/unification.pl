/*
% same as =/2 in terms of what arguments it succeeds with but doesn't actually unify
% should be equivalent to unifiable/2
unify_check(X,_) :- var(X), !.
unify_check(_,Y) :- var(Y), !.
unify_check(X,Y) :- X == Y.

% should basically be subsumes_term, with subs
% unify with subs, but treating variables on RHS as constants
unify2(X,Y,Subs,New_Subs) :- var(X), \+((member(K:_, Subs), X == K)), New_Subs = [X:Y | Subs].
unify2(X,Y,Subs,Subs) :- var(X), member(K:V, Subs), X == K, !, Y == V.
unify2(X,Y,Subs,Subs) :- nonvar(X), X == Y.

unify2_args([], [], Subs, Subs).
unify2_args([Query_Arg | Query_Args], [Store_Arg  | Store_Args], Subs, New_Subs) :-
	unify2(Query_Arg, Store_Arg, Subs, Next_Subs),
	unify2_args(Query_Args, Store_Args, Next_Subs, New_Subs).

unify2_facts(Query_Fact, Store_Fact, Subs, New_Subs) :-
	Query_Fact =.. [fact | Query_Args],
	Store_Fact =.. [fact | Store_Args],
	unify2_args(Query_Args, Store_Args, Subs, New_Subs).

% same as unify2 but actually binds the LHS instead of using subs
% should be equivalent to subsumes_term, maybe w/ some variation on scope of the binding
unify3(X,Y) :- var(X), X = Y.
unify3(X,Y) :- nonvar(X), X == Y.

unify3_args([], []).
unify3_args([X | XArgs], [Y | YArgs]) :-
	unify3(X,Y),
	unify3_args(XArgs, YArgs).
unify3_fact(XFact, YFact) :-
	XFact =.. [fact | XArgs],
	YFact =.. [fact | YArgs],
	unify3_args(XArgs, YArgs).

% this stuff is clunky i'm still figuring out some issues wrt dealing w/ vars in the kb (facts) vs. vars in the rules etc..
find_fact(S, P, O) :-
	'$enumerate_constraints'(fact(S1, P1, O1)),
	unify2_facts(fact(S2,P2,O2), fact(S1,P1,O1), [S2:S,P2:P,O2:O], _).

% need this version because sometimes you want to use it as a variable, sometimes you want to use it as a constant, ex..
% assuming L bound to a variable in the kb already:
% 	\+find_fact(L, length, _) 
% 	L should be treated like a constant, because it's already bound to something in the kb
% 	_ should be treated like a variable, because it hasn't been
find_fact2(S, P, O, Subs) :-
	%format("find_fact2(~w, ~w, ~w)~n", [S, P, O]),
	'$enumerate_constraints'(fact(S1, P1, O1)),

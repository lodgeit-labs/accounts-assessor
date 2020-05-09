:- use_module(library(chr)).
:- use_module(library(clpq)).

:- chr_constraint fact/3, rule/0, start/1, clpq/1, clpq/0, countdown/1, next/1.


% same as =/2 in terms of what arguments it succeeds with but doesn't actually unify
unify_check(X,_) :- var(X), !.
unify_check(_,Y) :- var(Y), !.
unify_check(X,Y) :- X == Y.

% unify with subs, but treating variables on RHS as constants
unify2(X,Y,Subs,New_Subs) :- var(X), \+((member(K:_, Subs), X == K)), New_Subs = [X:Y | Subs].
unify2(X,Y,Subs,Subs) :- var(X), member(K:V, Subs), !, X == K, Y == V.
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


find_fact(S, P, O) :-
	'$enumerate_constraints'(fact(S1, P1, O1)),
	unify2_facts(fact(S2,P2,O2), fact(S1,P1,O1), [S2:S,P2:P,O2:O], _).

% LIST THEORY
% length exists and is unique
rule, fact(L, a, list) ==> \+find_fact(L, length, _) | fact(L, length, _).
rule, fact(L, a, list), fact(L, length, X) \ fact(L, length, Y) <=> X = Y.

% a cell can only be in one list
rule, fact(X, list_in, L1) \ fact(X, list_in, L2) <=> L1 = L2.

% list index exists and is unique
rule, fact(X, list_in, _) ==> \+find_fact(X, list_index, _) | fact(X, list_index, _).
rule, fact(X, list_index, I1) \ fact(X, list_index, I2) <=> I1 = I2.

% there is only one cell at any given index
rule, fact(L, a, list), fact(X, list_in, L), fact(X, list_index, I) \ fact(Y, list_in, L), fact(Y, list_index, I) <=> X = Y.


% if non-empty then first exists, is unique, is in the list, and has list index 1
rule, fact(L, a, list), fact(_, list_in, L) ==> \+find_fact(L, first, _) | fact(L, first, _).
rule, fact(L, a, list), fact(L, first, X) \ fact(L, first, Y) <=> X = Y.
rule, fact(L, a, list), fact(L, first, First) ==> \+find_fact(First, list_in, L) | fact(First, list_in, L).
rule, fact(L, a, list), fact(L, first, First) ==> \+find_fact(First, list_index, 1) | fact(First, list_index, 1).

% if non-empty, and N is the length of the list, then last exists, is unique, is in the list, and has list index N
rule, fact(L, a, list), fact(_, list_in, L) ==> \+find_fact(L, last, _) | fact(L, last, _).
rule, fact(L, a, list), fact(L, last, X) \ fact(L, last, Y) <=> X = Y.
rule, fact(L, a, list), fact(L, last, Last) ==> \+find_fact(Last, list_in, L) | fact(Last, list_in, L). 
rule, fact(L, a, list), fact(L, last, Last), fact(L, length, N) ==> \+find_fact(Last, list_index, N) | fact(Last, list_index, N).

% the list index of any item is between 1 and the length of the list
rule, fact(L, a, list), fact(X, list_in, L), fact(X, list_index, I), fact(L, length, N) ==> clpq({I >= 1}), clpq({I =< N}).

% every cell has a unique value
rule, fact(L, a, list), fact(Cell, list_in, L) ==> \+find_fact(Cell, value, _) | fact(Cell, value, _).
rule, fact(L, a, list), fact(Cell, list_in, L), fact(Cell, value, X) \ fact(Cell, value, Y) <=> X = Y.

% if element type is unique
rule, fact(L, a, list), fact(L, element_type, X) \ fact(L, element_type, Y) <=> X = Y.

% if list has an element type, then every element of that list has that type
rule, fact(L, a, list), fact(L, element_type, T), fact(Cell, list_in, L), fact(Cell, value, V) ==> \+fact(V, a, T) | fact(V, a, T).

% if previous item exists, then it's unique
rule, fact(L, a, list), fact(Cell, list_in, L), fact(Cell, prev, X) \ fact(Cell, prev, Y) <=> X = Y.

% if next item exists, then it's unique
rule, fact(L, a, list), fact(Cell, list_in, L), fact(Cell, next, X) \ fact(Cell, next, Y) <=> X = Y.

% if X is the previous item before Y, then Y is the next item after X, and vice versa.
% the next and previous items of an element 
rule, fact(L, a, list), fact(Cell, list_in, L), fact(Cell, prev, Prev) ==> \+find_fact(Prev, next, Cell) | fact(Prev, next, Cell).
rule, fact(L, a, list), fact(Cell, list_in, L), fact(Cell, prev, Prev) ==> \+find_fact(Prev, list_in, L) | fact(Prev, list_in, L).
rule, fact(L, a, list), fact(Cell, list_in, L), fact(Cell, next, Next) ==> \+find_fact(Next, prev, Cell) | fact(Next, prev, Cell).
rule, fact(L, a, list), fact(Cell, list_in, L), fact(Cell, next, Next) ==> \+find_fact(Next, list_in, L) | fact(Next, list_in, L).

% the next item after the item at list index I has list index I + 1
rule, fact(L, a, list), fact(Cell, list_in, L), fact(Cell, list_index, I), fact(Cell, next, Next), fact(Next, list_index, J) ==> clpq({J = I + 1}).


rule, fact(S, P, O) \ fact(S, P, O) <=> true.

rule <=> clpq.
clpq \ clpq(Constraint) <=> call(Constraint).
clpq, countdown(N) <=> N > 0 | M is N - 1, next(M).
next(0) <=> true.
next(M) <=> nl, countdown(M), rule.

start(N) <=> N > 0 | countdown(N), rule.
start(0) <=> true.

/*
  ?- fact(List, a, list), fact(X, list_in, List), fact(List, length, 1), start(2).
  fact(X, value, _),
  fact(List, last, X),
  fact(List, first, X),
  fact(X, list_index, 1),
  fact(List, length, 1),
  fact(X, list_in, List),
  fact(List, a, list).

*/

/*
 27,406
 14,629
 13,953
*/

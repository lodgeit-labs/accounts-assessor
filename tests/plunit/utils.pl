:- ['../../lib/utils'].

:- begin_tests(utils).

test(0) :-
	findall(X, semigroup_foldl(atom_concat, [], X), [[]]),
	findall(X, semigroup_foldl(atom_concat, [aaa], X), [[aaa]]),
	findall(X, semigroup_foldl(atom_concat, [aaa, bbb], X), [[aaabbb]]),
	findall(X, semigroup_foldl(atom_concat, [aaa, bbb, ccc], X), [[aaabbbccc]]).

test(1) :-
	findall(X, semigroup_foldl(add, [1, 2, 3, 4], X), [[10]]).

test(2) :-
	findall(X, semigroup_foldl(mult, [1, 2, 3, 4], X), [[24]]).

test(3) :-
	findall(X, semigroup_foldl(mult_or_add, [1, 2, 3, 4], X), [[10],[24],[13],[36],[9],[20],[10],[24]]).

:- end_tests(utils).



add(X,Y,Z) :- Z is X + Y.
mult(X,Y,Z) :- Z is X * Y.
mult_or_add(X,Y,Z) :- Z is X + Y.
mult_or_add(X,Y,Z) :- Z is X * Y.


/*
curiously, while 
```
a([],[]).
a([I],[I]).
```
doesn't leave a choice point:
```
?- a([],[]).
true.
```
,
```
b(_,[],[]).
b(_,[I],[I]).
```
does:
```
?- b(x,[],[]).
true ;
false.
```
*/
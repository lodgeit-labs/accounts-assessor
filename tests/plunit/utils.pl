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

test(4) :-
	compile_with_variable_names_preserved((A=B), _N), var(A), var(B).

test(5, all(D=[_{x:3}])) :-
	X = 3, dict_from_vars(D, [X]).

test(6, all(D = [_{x:x, y:y}])) :-
	X = x, Y = y, dict_from_vars(D, [Y, X]).

test(7, all(D = [_{x:3, y:xyz, z:3}])) :-
	X = 3, Y = _, Z = X, dict_from_vars(D, [X, Y, Z]).

test(8, all((Start_Date, End_Date, Accounts) = [(x, y, z)])) :-
	dict_vars(_{start_date:x, end_date:y, accounts:z}, [Accounts, Start_Date, End_Date]).

test(9, all((End_Date, Accounts) = [(y, z)])) :-
	dict_vars(_{start_date:x, end_date:y, accounts:z}, [Accounts, End_Date]).

/*test(10, throws(_Error)) :-
	End_Date = _, goal_expansion(dict_vars(_{accounts:z}, [End_Date]), _Code).*/

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
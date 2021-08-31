:- ['../../../sources/public_lib/lodgeit_solvers/prolog/utils//utils'].

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

test(b5, all(Y=[3])) :-
	X = 3, dict_from_vars(D, [X]), Y = D.x.

test(6, all(D = [_{x:x, y:y}])) :-
	X = x, Y = y, dict_from_vars(D, [Y, X]).

test(7, all(D = [_{x:3, y:xyz, z:3}])) :-
	X = 3, Y = _, Z = X, dict_from_vars(D, [X, Y, Z]).

test(8, all((Start_Date, End_Date, Accounts) = [(x, y, z)])) :-
	dict_vars(_{start_date:x, end_date:y, accounts:z}, [Accounts, Start_Date, End_Date]).

test(9, all((End_Date, Accounts) = [(y, z)])) :-
	dict_vars(_{start_date:x, end_date:y, accounts:z}, [Accounts, End_Date]).

/*test(b8, throws(error(existence_error(_,_,_),_))) :-
	dict_vars(_{z:z}, [A]), A=A.*/ % evaluates at compile time?

/* uhh, was existence_error wrapped by error by the stacktrace hook? if yes, we should run it through an automatic potential unwrapper before checking here */
test(b9, throws(/*error(existence_error(_,_),_)*/existence_error(_,_,_))) :-
	get_a(_{z:z}).
	
get_a(Dict) :-
	dict_vars(Dict, [a]).
	
/*test(10, throws(_Error)) :-
	End_Date = _, goal_expansion(dict_vars(_{accounts:z}, [End_Date]), _Code).*/

stuff([a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,1,2,3,4,5,6,7,8,9]).

dummy_pairs(Pairs) :-
	findall((Key,Value), (
		stuff(Stuff),
		member(_, Stuff),
		member(Key, Stuff),
		member(Value, Stuff)
		),
	Pairs).
	
test(11, all(Xs = [[x]])) :-
	sort_pairs_into_dict_test1(Xs).
	
sort_pairs_into_dict_test1(Xs) :-
	findall(x,
		 (
			dummy_pairs(Pairs),
			sort_pairs_into_dict(Pairs,Dict),
			stuff(Stuff),
			Dict.s = Stuff
		),
		 Xs).
	 
	 

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

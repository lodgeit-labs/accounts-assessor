:- use_module(library(chr)).
:- use_module(library(clpq)).

:- chr_constraint fact/3, rule/0, start/1, clpq/1, clpq/0, countdown/1, next/1.


% same as =/2 in terms of what arguments it succeeds with but doesn't actually unify
unify_check(X,_) :- var(X), !.
unify_check(_,Y) :- var(Y), !.
unify_check(X,Y) :- X == Y.

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

% need this version because sometimes you want to use it as a variable, sometimes you want to use it as a constant, ex..
% \+find_fact(L, length, _)
% L should be treated like a constant, because it's already bound to something in the kb
% _ should be treated like a variable, because it hasn't been
find_fact2(S, P, O, Subs) :-
	%format("find_fact2(~w, ~w, ~w)~n", [S, P, O]),
	'$enumerate_constraints'(fact(S1, P1, O1)),
	unify2_facts(fact(S, P, O), fact(S1, P1, O1), Subs, _).




% LIST THEORY
% length exists and is unique
rule, fact(L, a, list) ==> \+find_fact2(L1, length, _, [L1:L]) | fact(L, length, _).
%rule, fact(L, a, list), fact(L, length, X) \ fact(L, length, Y) <=> X = Y.

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
rule, fact(L, a, list), fact(L, element_type, T), fact(Cell, list_in, L), fact(Cell, value, V) ==> \+find_fact2(V1, a, T1, [V1:V, T1:T]) | fact(V, a, T).

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





% HP ARRANGEMENTS & HP INSTALLMENTS THEORY

% hp arrangements have a unique begin date
rule, fact(HP, a, hp_arrangement) ==> \+find_fact2(HP1, begin_date, _, [HP1:HP]) | fact(HP, begin_date, _).
rule, fact(HP, a, hp_arrangement), fact(HP, begin_date, X) \ fact(HP, begin_date, Y) <=> X = Y.

% hp arrangements have a unique end date
rule, fact(HP, a, hp_arrangement) ==> \+find_fact2(HP1, end_date, _, [HP1:HP]) | fact(HP, end_date, _).
rule, fact(HP, a, hp_arrangement), fact(HP, end_date, X) \ fact(HP, end_date, Y) <=> X = Y.

% hp arrangements have a unique cash price
rule, fact(HP, a, hp_arrangement) ==> \+find_fact2(HP1, cash_price, _, [HP1:HP]) | fact(HP, cash_price, _).
rule, fact(HP, a, hp_arrangement), fact(HP, cash_price, X) \ fact(HP, cash_price, Y) <=> X = Y.

% hp arrangements have a unique interest rate
rule, fact(HP, a, hp_arrangement) ==> \+find_fact2(HP1, interest_rate, _, [HP1:HP]) | fact(HP, interest_rate, _).
rule, fact(HP, a, hp_arrangement), fact(HP, interest_rate, X) \ fact(HP, interest_rate, Y) <=> X = Y.

% hp arrangements have a unique repayment period
rule, fact(HP, a, hp_arrangement) ==> \+find_fact2(HP1, repayment_period, _, [HP1:HP]) | fact(HP, repayment_period, _).
rule, fact(HP, a, hp_arrangement), fact(HP, repayment_period, X) \ fact(HP, repayment_period, Y) <=> X = Y.

% hp arrangements have a unique repayment amount
rule, fact(HP, a, hp_arrangement) ==> \+find_fact2(HP1, repayment_amount, _, [HP1:HP]) | fact(HP, repayment_amount, _).
rule, fact(HP, a, hp_arrangement), fact(HP, repayment_amount, X) \ fact(HP, repayment_amount, Y) <=> X = Y.

% hp arrangements have a unique number of installments
rule, fact(HP, a, hp_arrangement) ==> \+find_fact2(HP1, number_of_installments, _, [HP1:HP]) | fact(HP, number_of_installments, _).
rule, fact(HP, a, hp_arrangement), fact(HP, number_of_installments, X) \ fact(HP, number_of_installments, Y) <=> X = Y.

% hp arrangements have a unique list of hp_installments
rule, fact(HP, a, hp_arrangement) ==> \+find_fact2(HP1, installments, _, [HP1:HP]) | fact(HP, installments, _).
rule, fact(HP, a, hp_arrangement), fact(HP, installments, X) \ fact(HP, installments, Y) <=> X = Y.
rule, fact(HP, a, hp_arrangement), fact(HP, installments, Installments) ==> \+find_fact(Installments, a, list) | fact(Installments, a, list).
rule, fact(HP, a, hp_arrangement), fact(HP, installments, Installments) ==> \+find_fact(Installments, element_type, hp_installment) | fact(Installments, element_type, hp_installment).


% installments have a unique opening date
rule, fact(Installment, a, hp_installment) ==> \+find_fact2(Installment1, opening_date, _, [Installment1:Installment]) | fact(Installment, opening_date, _).
rule, fact(Installment, a, hp_installment), fact(Installment, opening_date, X) \ fact(Installment, opening_date, Y) <=> X = Y.

% installments have a unique opening balance
rule, fact(Installment, a, hp_installment) ==> \+find_fact2(Installment1, opening_balance, _, [Installment1:Installment]) | fact(Installment, opening_balance, _).
rule, fact(Installment, a, hp_installment), fact(Installment, opening_balance, X) \ fact(Installment, opening_balance, Y) <=> X = Y.

% installments have a unique payment amount
rule, fact(Installment, a, hp_installment) ==> \+find_fact2(Installment1, payment_amount, _, [Installment1:Installment]) | fact(Installment, payment_amount, _).
rule, fact(Installment, a, hp_installment), fact(Installment, payment_amount, X) \ fact(Installment, payment_amount, Y) <=> X = Y.

% installments have a unique interest rate
rule, fact(Installment, a, hp_installment) ==> \+find_fact2(Installment1, interest_rate, _, [Installment1:Installment]) | fact(Installment, interest_rate, _).
rule, fact(Installment, a, hp_installment), fact(Installment, interest_rate, X) \ fact(Installment, interest_rate, Y) <=> X = Y.

% installments have a unique interest amount
rule, fact(Installment, a, hp_installment) ==> \+find_fact2(Installment1, interest_amount, _, [Installment1:Installment]) | fact(Installment, interest_amount, _).
rule, fact(Installment, a, hp_installment), fact(Installment, interest_amount, X) \ fact(Installment, interest_amount, Y) <=> X = Y.

% installments have a unique closing date
rule, fact(Installment, a, hp_installment) ==> \+find_fact2(Installment1, closing_date, _, [Installment1:Installment]) | fact(Installment, closing_date, _).
rule, fact(Installment, a, hp_installment), fact(Installment, closing_date, X) \ fact(Installment, closing_date, Y) <=> X = Y.

% installments have a unique closing balance
rule, fact(Installment, a, hp_installment) ==> \+find_fact2(Installment1, closing_balance, _, [Installment1:Installment]) | fact(Installment, closing_balance, _).
rule, fact(Installment, a, hp_installment), fact(Installment, closing_balance, X) \ fact(Installment, closing_balance, Y) <=> X = Y.

% installments have a unique hp arrangement
rule, fact(HP, a, hp_arrangement), fact(HP, installments, Installments), fact(Cell, list_in, Installments), fact(Cell, value, Installment), fact(Installment, a, hp_installment) ==> \+find_fact(Installment, hp_arrangement, HP) | fact(Installment, hp_arrangement, HP).
rule, fact(Installment, a, hp_installment), fact(Installment, hp_arrangement, X) \ fact(Installment, hp_arrangement, Y) <=> X = Y.

% if the cash price is different from the final balance, there must be an installment
rule, fact(HP, a, hp_arrangement), fact(HP, cash_price, Cash_Price), fact(HP, final_balance, Final_Balance), fact(HP, installments, Installments) ==> \+find_fact2(_, list_in, Installments1, [Installments1:Installments]), nonvar(Cash_Price), nonvar(Final_Balance), Cash_Price \== Final_Balance | fact(_, list_in, Installments).

% opening balance of first installment is the cash price of the arrangement
rule, fact(HP, a, hp_arrangement), fact(HP, installments, Installments), fact(HP, cash_price, Cash_Price), fact(Installments, first, First), fact(First, value, First_Installment), fact(First_Installment, opening_balance, Opening_Balance) ==> Cash_Price = Opening_Balance.

% payment amount of each installment is repayment amount of the arrangement (doesn't account for balloon payments or submarines)
rule, fact(HP, a, hp_arrangement), fact(Installment, hp_arrangement, HP), fact(HP, repayment_amount, Repayment_Amount), fact(Installment, payment_amount, Payment_Amount) ==> Repayment_Amount = Payment_Amount.

% interest rate for each installment is the interest rate of the arrangement
rule, fact(HP, a, hp_arrangement), fact(Installment, hp_arrangement, HP), fact(HP, interest_rate, Interest_Rate), fact(Installment, interest_rate, Installment_Interest_Rate) ==> Interest_Rate = Installment_Interest_Rate.

% interest amount for each installment is the interest rate of the installment times the opening balance of the installment
rule, fact(Installment, a, hp_installment), fact(Installment, opening_balance, Opening_Balance), fact(Installment, interest_rate, Interest_Rate), fact(Installment, interest_amount, Interest_Amount) ==> clpq({Interest_Amount = Opening_Balance*Interest_Rate}).

% closing balance of each installment is opening balance + interest amount - payment amount
rule, fact(Installment, a, hp_installment), fact(Installment, opening_balance, Opening_Balance), fact(Installment, payment_amount, Payment_Amount), fact(Installment, interest_amount, Interest_Amount), fact(Installment, closing_balance, Closing_Balance) ==> clpq({Closing_Balance = Opening_Balance + Interest_Amount - Payment_Amount}).

% opening balance of the next installment is the closing balance of the current installment (by extension, closing balance of the previous installment is opening balance of current installment)
rule, fact(HP, a, hp_arrangement), fact(HP, installments, Installments), fact(Cell, list_in, Installments), fact(Cell, value, Installment), fact(Installment, closing_balance, Closing_Balance), fact(Cell, next, Next_Cell), fact(Next_Cell, value, Next_Installment), fact(Next_Installment, opening_balance, Opening_Balance) ==> Closing_Balance = Opening_Balance.

% 
rule, fact(HP, a, hp_arrangement), fact(HP, repayment_amount, Repayment_Amount), fact(HP, installments, Installments), fact(Installment_Cell, list_in, Installments), fact(Installment_Cell, value, Installment), fact(Installment, closing_balance, Closing_Balance) ==> nonvar(Closing_Balance), nonvar(Repayment_Amount), Closing_Balance >= Repayment_Amount, \+find_fact2(Installment_Cell1, next, _, [Installment_Cell1:Installment_Cell]) | fact(Installment_Cell, next, _).

% 
rule, fact(HP, a, hp_arrangement), fact(HP, cash_price, Cash_Price), fact(HP, installments, Installments), fact(Installment_Cell, list_in, Installments), fact(Installment_Cell, value, Installment), fact(Installment, opening_balance, Opening_Balance) ==> nonvar(Cash_Price), nonvar(Opening_Balance), Opening_Balance < Cash_Price, \+find_fact2(Installment_Cell1, prev, _, [Installment_Cell1:Installment_Cell]) | fact(Installment_Cell, prev, _). 



rule, fact(S, P, O) \ fact(S, P, O) <=> (P == closing_balance -> format("deduplicate: ~w ~w ~w~n", [S, P, O]) ; true).

rule <=> clpq.
clpq \ clpq(Constraint) <=> call(Constraint).
clpq, countdown(N) <=> N > 0 | M is N - 1, format("~ncountdown ~w~n~n", [M]), countdown(M), rule.
clpq, countdown(0) <=>
	format("Done: facts = [~n", []),
	findall(
		_,
		(
			'$enumerate_constraints'(fact(S,P,O)),
			\+((
				P \== closing_balance,
				P \== opening_balance,
				P \== list_index,
				P \== value
			)),
			((ground(O), O = (_ rdiv _))
			-> O2 is float(O)
			; O2 = O
			),
			format("fact(~w,~w,~w)~n", [S,P,O2])
		),
		_
	),
	format("]~n~n",[]), fail,
	true.
%next(0) <=> true.
%next(M) <=> nl, countdown(M), rule.

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

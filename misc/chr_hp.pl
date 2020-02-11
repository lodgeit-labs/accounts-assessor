:- use_module(library(chr)).
:- use_module(library(clpq)).
:- use_module(library(clpfd)).

:- chr_constraint fact/3, rule/0, start/2, clpq/1, clpq/0, countdown/2, next/1.


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

find_fact3(S, P, O, Subs, New_Subs) :-
	'$enumerate_constraints'(fact(S1,P1,O1)),
	unify2_facts(fact(S,P,O), fact(S1,P1,O1), Subs, New_Subs).

find_fact4(S,P,O, Subs) :-
	'$enumerate_constraints'(fact(S1,P1,O1)),
	unify2_facts(fact(S,P,O), fact(S1,P1,O1), Subs, _),
	S = S1,
	P = P1,
	O = O1.

clpfd_leap_year(Year) :-
	(
		0 #= Year mod 400
	->	true
	;	(
			0 #= Year mod 4,
			0 #\= Year mod 100
		)
	).

month_lengths([31,28,31,30,31,30,31,31,30,31,30,31]).
month_length(Year, 2, 29) :- clpfd_leap_year(Year), !.
month_length(_, Month, Length) :- month_lengths(Lengths), nth1(Month, Lengths, Length).


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



% DATE & TIME THEORY
% month intervals have a unique year
rule, fact(Interval, a, month_interval) ==> \+find_fact2(Interval1, year, _, [Interval1:Interval]) | fact(Interval, year, _).
rule, fact(Interval, a, month_interval), fact(Interval, year, X) \ fact(Interval, year, Y) <=> X = Y.

rule, fact(Interval, a, month_interval) ==> \+find_fact2(Interval1, month, _, [Interval1:Interval]) | fact(Interval, month, _).
rule, fact(Interval, a, month_interval), fact(Interval, month, X) \ fact(Interval, month, Y) <=> X = Y.
rule, fact(Interval, a, month_interval), fact(Interval, month, Month) ==> Month in 1..12.

rule, fact(Date, a, date) ==> \+find_fact2(Date1, year, _, [Date1:Date]) | fact(Date, year, _).
rule, fact(Date, a, date), fact(Date, year, X) \ fact(Date, year, Y) <=> X = Y.

rule, fact(Date, a, date) ==> \+find_fact2(Date1, month, _, [Date1:Date]) | fact(Date, month, _).
rule, fact(Date, a, date), fact(Date, month, X) \ fact(Date, month, Y) <=> X = Y.
rule, fact(Date, a, date), fact(Date, month, Month) ==> Month in 1..12.

rule, fact(Date, a, date) ==> \+find_fact2(Date1, day, _, [Date1:Date]) | fact(Date, day, _).
rule, fact(Date, a, date), fact(Date, day, X) \ fact(Date, day, Y) <=> X = Y.


% HP ARRANGEMENTS & HP INSTALLMENTS THEORY


% hp arrangements have a unique begin date
rule, fact(HP, a, hp_arrangement) ==> \+find_fact2(HP1, begin_date, _, [HP1:HP]) | fact(HP, begin_date, _).
rule, fact(HP, a, hp_arrangement), fact(HP, begin_date, X) \ fact(HP, begin_date, Y) <=> X = Y.
rule, fact(HP, a, hp_arrangement), fact(HP, begin_date, Begin_Date) ==> \+find_fact2(Begin_Date1, a, date, [Begin_Date1:Begin_Date]) | fact(Begin_Date, a, date).

% hp arrangements have a unique end date
rule, fact(HP, a, hp_arrangement) ==> \+find_fact2(HP1, end_date, _, [HP1:HP]) | fact(HP, end_date, _).
rule, fact(HP, a, hp_arrangement), fact(HP, end_date, X) \ fact(HP, end_date, Y) <=> X = Y.
rule, fact(HP, a, hp_arrangement), fact(HP, end_date, End_Date) ==> \+find_fact2(End_Date1, a, date, [End_Date1:End_Date]) | fact(End_Date, a, date).

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


% installments have a unique installment period
rule, fact(Installment, a, hp_installment) ==> \+find_fact2(Installment1, installment_period, _, [Installment1:Installment]) | fact(Installment, installment_period, _).
rule, fact(Installment, a, hp_installment), fact(Installment, installment_period, X) \ fact(Installment, installment_period, Y) <=> X = Y.
rule, fact(Installment, a, hp_installment), fact(Installment, installment_period, Installment_Period) ==> \+find_fact2(Installment_Period1, a, month_interval, [Installment_Period1:Installment_Period]) | fact(Installment_Period, a, month_interval).

% installments have a unique opening date
rule, fact(Installment, a, hp_installment) ==> \+find_fact2(Installment1, opening_date, _, [Installment1:Installment]) | fact(Installment, opening_date, _).
rule, fact(Installment, a, hp_installment), fact(Installment, opening_date, X) \ fact(Installment, opening_date, Y) <=> X = Y.
rule, fact(Installment, a, hp_installment), fact(Installment, opening_date, Opening_Date) ==> \+find_fact2(Opening_Date1, a, date, [Opening_Date1:Opening_Date]) | fact(Opening_Date, a, date).

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
rule, fact(Installment, a, hp_installment), fact(Installment, closing_date, Closing_Date) ==> \+find_fact2(Closing_Date1, a, date, [Closing_Date1:Closing_Date]) | fact(Closing_Date, a, date).

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

/*
% begin date of hp arrangement is the opening date of the first installment
rule, fact(HP, a, hp_arrangement), fact(HP, begin_date, Begin_Date), fact(HP, installments, Installments), fact(Installments, first, First_Cell), fact(First_Cell, value, First_Installment), fact(First_Installment, installment_period, Installment_Period), fact(Begin_Date, year, Begin_Year), fact(Begin_Date, month, Begin_Month), fact(Installment_Period, year, Installment_Year), fact(Installment_Period, month, Installment_Month) ==> Begin_Year = Installment_Year, Begin_Month = Installment_Month.

rule, fact(HP, a, hp_arrangement), fact(HP, installments, Installments), fact(Installment_Cell, list_in, Installments), fact(Installment_Cell, next, Next_Installment_Cell), fact(Installment_Cell, value, Installment), fact(Installment, installment_period, Installment_Period), fact(Installment_Period, year, Installment_Year), fact(Installment_Period, month, Installment_Month), fact(Next_Installment_Cell, value, Next_Installment), fact(Next_Installment, installment_period, Next_Installment_Period), fact(Next_Installment_Period, year, Next_Installment_Year), fact(Next_Installment_Period, month, Next_Installment_Month) ==> 
*/
rule, fact(HP, a, hp_arrangement), fact(HP, begin_date, Begin_Date), fact(Begin_Date, year, Begin_Year), fact(Begin_Date, month, Begin_Month), fact(HP, installments, Installments), fact(Installment_Cell, list_in, Installments), fact(Installment_Cell, list_index, Installment_Number), fact(Installment_Cell, value, Installment), fact(Installment, installment_period, Installment_Period), fact(Installment_Period, year, Installment_Year), fact(Installment_Period, month, Installment_Month) ==> clpq(N #= (Installment_Number - 1)), clpq(V #= (Begin_Month + N)), clpq(Installment_Year #= Begin_Year +((V - 1) // 12)), clpq(Installment_Month #= (((V - 1) rem 12) + 1)).

rule, fact(Installment, a, hp_installment), fact(Installment, installment_period, Installment_Period), fact(Installment_Period, year, Installment_Year), fact(Installment_Period, month, Installment_Month), fact(Installment, opening_date, Opening_Date), fact(Opening_Date, year, Opening_Year), fact(Opening_Date, month, Opening_Month), fact(Opening_Date, day, Opening_Day) ==> Opening_Year = Installment_Year, Opening_Month = Installment_Month, Opening_Day = 1.

rule, fact(Installment, a, hp_installment), fact(Installment, installment_period, Installment_Period), fact(Installment_Period, year, Installment_Year), fact(Installment_Period, month, Installment_Month), fact(Installment, closing_date, Closing_Date), fact(Closing_Date, year, Closing_Year), fact(Closing_Date, month, Closing_Month) ==> Closing_Year = Installment_Year, Closing_Month = Installment_Month.

rule, fact(Installment, a, hp_installment), fact(Installment, installment_period, Installment_Period), fact(Installment_Period, year, Installment_Year), fact(Installment_Period, month, Installment_Month), fact(Installment, closing_date, Closing_Date), fact(Closing_Date, day, Closing_Day) ==> nonvar(Installment_Year), nonvar(Installment_Month) | month_length(Installment_Year, Installment_Month, Closing_Day).

% end date of hp arrangement is the closing date of the last installment
%rule, fact(HP, a, hp_arrangement), fact(HP, end_date, End_Date), fact(HP, installments, Installments), fact(Installments, last, Last_Cell), fact(Last_Cell, value, Last_Installment), fact(Last_Installment, closing_date, Closing_Date) ==> End_Date = Closing_Date.


rule, fact(S, P, O) \ fact(S, P, O) <=> (P == closing_balance -> format("deduplicate: ~w ~w ~w~n", [S, P, O]) ; true).

rule <=> clpq.
clpq \ clpq(Constraint) <=> call(Constraint).
clpq, countdown(N, Done) <=> N > 0 | M is N - 1, format(user_error, "~ncountdown ~w~n~n", [M]), countdown(M, Done), rule.
clpq, countdown(0, Done) <=>
	format(user_error, "Done: facts = [~n", []),
	findall(
		_,
		(
			'$enumerate_constraints'(fact(S,P,O)),
			/*
			\+((
				P \== closing_date,
				P \== opening_date,
				P \== list_index,
				P \== value,
				P \== installment_period,
				P \== year,
				P \== month,
				P \== day,
				( P \== a ; O \== date)
			)),
			((ground(O), O = (_ rdiv _))
			-> O2 is float(O)
			; O2 = O
			),
			*/
			format(user_error, "fact(~w,~w,~w)~n", [S,P,O])
		),
		_
	),
	format(user_error, "]~n~n",[]), %fail,
	Done = done,
	true.
%next(0) <=> true.
%next(M) <=> nl, countdown(M), rule.

start(N, Done) <=> N > 0 | countdown(N, Done), rule.
start(0, Done) <=> Done = done.

% General pattern here:
% we have flexible objects that need to be translated back into standard data formats.



% exclude all list definition triples except for occurrences of L a list and Obj Attr L
% on finding a list (i.e. L a list), perform chr_list_to_rdf_list
% exclude any other triples if they include variables
% 
% translate all vars to bnodes, maintaining subs
%


% currently loses variable identities; actually only loses variable identities when printing for some reason and the
% identities are still maintained in the New_Facts output... ?
get_chr_facts(Found_Facts, Current_Facts, Current_Lists, Current_Facts, Current_Lists) :-
	% every chr fact is in the list; done.
	\+((
		'$enumerate_constraints'(fact(S,P,O)),
		\+((
			member(fact(S1,P1,O1), Found_Facts),
			S == S1,
			P == P1,
			O == O1
		))
	)).
get_chr_facts(Found_Facts, Current_Facts, Lists, New_Facts, New_Lists) :-
	% if there is a CHR fact
	'$enumerate_constraints'(fact(S,P,O)),
	%format("Fact: ~w ~w ~w~n", [S, P, O]),
	% and no identical fact in the already-found facts
	\+((
		member(fact(S1,P1,O1), Found_Facts),
		S == S1,
		P == P1,
		O == O1
	)),
	% then cut, add it to the already-found facts, and continue
	!,

	% exclude these triples
	(
		\+member(P, [first, last, length, element_type, list_in, list_index, value, next, prev])
	->	Next_Facts = [fact(S,P,O) | Current_Facts]
	;	Next_Facts = Current_Facts
	),
	(
		fact(S,P,O) = fact(S, a, list)
	-> 	Next_Lists = [S | Lists]
	;	Next_Lists = Lists
	),
	%format("Found fact: ~w ~w ~w~n", [S,P,O]),
	get_chr_facts([fact(S,P,O) | Found_Facts], Next_Facts, Next_Lists, New_Facts, New_Lists).
/*
print_facts :-
	get_chr_facts([], Facts),
	print_facts_helper(Facts).

print_facts_helper([]) :- nl.
print_facts_helper([fact(S,P,O)| Facts]) :-
	format("~w ~w ~w~n", [S, P, O]),
	print_facts_helper(Facts).
*/


% convert a chr list to a regular prolog list
chr_list_to_prolog_list(L, List) :-
	find_fact4(L1, a, list, [L1:L]), !,
	find_fact4(L1, first, First_Item, [L1:L]), !,
	chr_list_to_prolog_list_helper(L, First_Item, List).

chr_list_to_prolog_list_helper(L, Item, [fact(Item, value, Value) | Rest]) :-
	find_fact4(Item1, value, Value, [Item1:Item]),
	(
		find_fact4(L1, last, Item1, [L1:L, Item1:Item])
	->	Rest = []
	;	(
			find_fact4(Item1, next, Next_Item, [Item1:Item])
		->	% could infloop if the list is cyclic, but current rules should rule out that possibility
			chr_list_to_prolog_list_helper(L, Next_Item, Rest)
		;	true
		)
	).

chr_list_to_rdf_list(CHR_List, RDF_List, RDF_List_Triples, Subs) :-
	chr_list_to_prolog_list(CHR_List, Prolog_List),
	(
		Prolog_List = []
	->	RDF_List = rdf:nil,
		RDF_List_Triples = [],
		Subs = []
	;	gensym(bn, RDF_List),
		prolog_list_to_rdf_list(Prolog_List, RDF_List, RDF_List_Triples, Subs)
	).

prolog_list_to_rdf_list([], rdf:nil, [], []).
prolog_list_to_rdf_list([fact(Cell, value, X)], URI, [fact(URI, rdf:first, X), fact(URI, rdf:rest, rdf:nil)], [Cell:URI]).
prolog_list_to_rdf_list([fact(Cell, value, X), fact(Next_Cell, value, Y) | Xs], URI, [fact(URI, rdf:first, X), fact(URI, rdf:rest, Next_URI) | Rest_Triples], [Cell:URI | Rest_Subs]) :-
	gensym(bn, Next_URI),
	(
		nonvar(Xs)
	->	prolog_list_to_rdf_list([fact(Next_Cell, value, Y) | Xs], Next_URI, Rest_Triples, Rest_Subs)
	;	Rest_Triples = [fact(Next_URI, rdf:first, Y)], Rest_Subs = [Next_Cell:Next_URI]
	).


get_chr_list_triples([], [], []).
get_chr_list_triples([L | Ls], [L_Triples | Ls_Triples], [[L:L_Bnode | Subs] | Rest_Subs]) :-
	chr_list_to_rdf_list(L, L_Bnode, L_Triples, Subs),
	get_chr_list_triples(Ls, Ls_Triples, Rest_Subs).

chr_filter_vars([], _, []).
chr_filter_vars([Fact | Facts], Subs, New_Facts) :-
	apply_subs_to_fact(Subs, Fact, New_Fact),
	(
		ground(New_Fact)
	-> 	New_Facts = [New_Fact | Rest_Facts]
	;	New_Facts = Rest_Facts
	),
	chr_filter_vars(Facts, Subs, Rest_Facts).

map_args(P, Term, New_Term) :-
	Term =.. [F | Args],
	maplist(P, Args, New_Args),
	New_Term =.. [F | New_Args].

mapflat(P, List, New_List) :-
	maplist(P, List, New_List_Nested),
	flatten(New_List_Nested, New_List).

apply_subs_to_facts(_, [], []).
apply_subs_to_facts(Subs, [Fact | Facts], [New_Fact | New_Facts]) :-
	apply_subs_to_fact(Subs, Fact, New_Fact),
	apply_subs_to_facts(Subs, Facts, New_Facts).

apply_subs_to_fact(Subs, Fact, New_Fact) :-
	Fact =.. [fact | Args],
	apply_subs_to_args(Subs, Args, New_Args),
	New_Fact =.. [fact | New_Args].

apply_subs_to_args(_, [], []).
apply_subs_to_args(Subs, [Arg | Args], [New_Arg | New_Args]) :-
	apply_subs_to_arg(Subs, Arg, New_Arg),
	apply_subs_to_args(Subs, Args, New_Args).

apply_subs_to_arg([], Arg, Arg).
apply_subs_to_arg([K:V | Rest_Subs], Arg, New_Arg) :-
	(	Arg == K
	->	New_Arg = V
	;	apply_subs_to_arg(Rest_Subs, Arg, New_Arg)
	). 

extract_chr_facts(Output_With_RDF_Values) :-
	get_chr_facts([], [], [], Facts, Lists),
	get_chr_list_triples(Lists, List_Triples, Subs),
	flatten(List_Triples, List_Triples_Flat),
	flatten(Subs, Subs_Flat),
	apply_subs_to_facts(Subs_Flat, List_Triples_Flat, List_Triples_Sub),
	chr_filter_vars(Facts, Subs_Flat, New_Facts),
	append(New_Facts, List_Triples_Sub, Output),
	make_rdf_values(Output, Output_With_RDF_Values).

% replace attributes with rdf:values
make_rdf_values(Facts, New_Facts) :-
	get_objects(Facts, Objects),
	make_object_attributes(Facts, Objects, New_Facts).
	
	% replace attributes with rdf:values
get_objects([], []).
get_objects([fact(S, P, O) | Facts], Objects) :-
	(
		P = a,
		O \= list
	->	Objects = [S | Rest_Objects]
	;	Objects = Rest_Objects
	),
	get_objects(Facts, Rest_Objects).

make_object_attributes([], _, []).
make_object_attributes([fact(S,P,O) | Facts], Objects, New_Facts) :-
	(
		member(S,Objects),
		P \= a
	-> 	gensym(bn,URI),
		New_Facts = [fact(S,P,URI),fact(URI,rdf:value,O) | Rest_Facts]
	;	New_Facts = [fact(S,P,O) | Rest_Facts]
	),
	make_object_attributes(Facts, Objects, Rest_Facts).

print_facts2([]) :- nl.
print_facts2([fact(S,P,O) | Rest]) :-
	format("~w ~w ~w~n", [S,P,O]),
	print_facts2(Rest).

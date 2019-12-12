:- dynamic found_data/4.

fresh_bnode(Bnode) :-
	gensym(bn, Bnode).

% solve a set of fields
% until fields = new fields, find new fields
% 

solve([]).
solve([Goal | Rest]) :-
	(
		Goal = concept_data(_,_,_,_)
	->
		query(Goal)
	;
		call(Goal)
	),
	solve(Rest).

solve2([]).
solve2([Goal | Rest]) :-
	(
		Goal = concept_data(C,S,P,O)
	->
		found_data(C,S,P,O)
	;
		call(Goal)	
	),
	solve2(Rest).



query(concept_data(C, S, P, O)) :-
	
	(
		% basically because of this part
		% 2nd version is trying to implement it like Installment next Next_Installment,
		% but this matches with the first/second installment so it doesn't continue generating
		% the rest of the solutions
		found_data(C, S, P, O)
	/*
	->
		true
	*/
	;
	
		(
			query2(concept_data(C, S, P, O), Head),
			findall(
				_,
				(
					member(concept_data(C1, S1, P1, O1), Head),
					assertz(found_data(C1, S1, P1, O1))
				),
				_
			)
		)
	
	)
	.
	

query2(concept_data(C, S, P, O), Head) :-
	(
		(
			implication(Head, Body),
			member(concept_data(C, S, P, O), Head)
		)
	->
		solve2(Body)
	).


/*
query3(concept_data(C, S, P, O)) :-
	biimplication(LHS, RHS),
	(
		(
			member(concept_data(C, S, P, O), LHS),
			solve2(RHS)
		)
	->
		true
	;
		(
			member(concept_data(C, S, P, O), RHS),
			solve2(LHS)
		)
	).
*/

found_data(context, my_node, a, my_value).
found_data(context, my_node, a, my_value2).
found_data(context, my_node, c, my_value).
found_data(context, my_hp, is_a, hp_arrangement).
found_data(context, my_hp, numberOfInstallments, 5).

implication(Head, Body) :- biimplication(Head, Body).
implication(Head, Body) :- biimplication(Body, Head).

% installments implementation 1
implication( % so this here is one-way or bi? one-way
	[
		concept_data(C, HP, installment, Installment),
		concept_data(C, Installment, installmentNumber, Installment_Number)
	],
	[
		concept_data(C, HP, is_a, hp_arrangement),
		concept_data(C, HP, numberOfInstallments, Number_Of_Installments),
		range_inclusive(1,Number_Of_Installments,1,Installment_Number),
		fresh_bnode(Installment)
	]
).



% installments implementation 2
% this second implementation doesn't work yet w/ the current query system
implication(
	[
		concept_data(C, HP, firstInstallment, Installment),
		concept_data(C, Installment, arrangement, HP),
		concept_data(C, Installment, is_a, hp_installment),
		concept_data(C, Installment, installmentNumber, 1)
	],
	[
		concept_data(C, HP, is_a, hp_arrangement),
		fresh_bnode(Installment)
	]
).

implication(
	[
		concept_data(C, Installment, arrangement, HP),
		concept_data(C, Installment, is_a, hp_installment),
		concept_data(C, Installment, installmentNumber, SX),
		concept_data(C, Prev_Installment, next, Installment),
		concept_data(C, Installment, prev, Prev_Installment)
	],
	[
		concept_data(C, HP, is_a, hp_arrangement),
		concept_data(C, HP, numberOfInstallments, N),
		N > 1,
		concept_data(C, Prev_Installment, arrangement, HP),
		% hm, this would only work the first time it's generating these bnodes
		%\+concept_data(C, Prev_Installment, next, _),
		concept_data(C, Prev_Installment, installmentNumber, X),
		X < N,
		fresh_bnode(Installment),
		(SX is X + 1)
	]
).

implication(
	[
		concept_data(C, HP, lastInstallment, Installment)
	],
	[
		concept_data(C, HP, is_a, hp_arrangement),
		concept_data(C, HP, numberOfInstallments, N),
		concept_data(C, Installment, is_a, hp_installment),
		concept_data(C, Installment, arrangement, HP),
		concept_data(C, Installment, installmentNumber, N)
	]
).

% implementation 3; with lists
implication(
	[
		concept_data(C, HP, installmentsList, Installments)
	],
	[
		
	]
).


% we dont write prolog rules directly but store the rules like this so it doesn't infloop on this mutual recursion?
% well we don't have to store the rules like this it's just the representation i was testing with
% could be stored as regular prolog rules 
% a(S,X) :- b(S,X).
implication(
	[
		concept_data(C, S, a, X)		
	],
	[
		concept_data(C, S, b, X)
	]
).

% b(S,X) :- a(S,X).
implication(
	[
		concept_data(C, S, b, X)
	],
	[
		concept_data(C, S, a, X)
	]
).

% bi-implication basically short-hand for the above
biimplication(
	[
		concept_data(C, S, c, X)
	],
	[
		concept_data(C, S, d, X)
	]
).



range_inclusive(Start, _, _, Value) :-
	Start = Value.

range_inclusive(Start, Stop, Step, Value) :-
	Next_Start is Start + Step,
	Next_Start =< Stop,
	range_inclusive(Next_Start, Stop, Step, Value).




% conflict
%	* no solution
% 	* due to conflicting constants

% ambiguity
%	* multiple solutions
%		* if so, why not allow multiple valid solutions?

% missing data
%	* variables

% difference between ambiguity and missing data?
 

:- use_module(library(chr)).
:- use_module(library(clpq)).
:- use_module(library(clpfd)).

:- chr_constraint fact/3, rule/0, start/2, clpq/1, clpq/0, countdown/2, next/1, old_clpq/1, block/0.


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
	% this isn't quite clpfd-like yet cause of the ->
	/*
	(
		0 #= Year mod 400
	->	true
	;	(
			0 #= Year mod 4,
			0 #\= Year mod 100
		)
	).
	*/


month_lengths([31,28,31,30,31,30,31,31,30,31,30,31]).
month_length(Year, 2, 29) :- clpfd_leap_year(Year), !.
month_length(_, Month, Length) :- month_lengths(Lengths), nth1(Month, Lengths, Length).
/*
tuples_in([[Y,M,Ds]], [[1004,1,31],[1004,2,29],[1005,1,31],[1005,2,28]])...

1 	31
2 	28 or 29
3 	31
4 	30
5 	31
6 	30
7 	31
8 	31
9 	30
10 	31
11 	30
12 	31

tuples_in(
	[[Month.number, Month.length]],
	[1,31],
	[2,28], [2,29],
	[3,31],


length(Month, N) -> Day in 1..N,
length(Month, N) -> N in 28..31,

(Month = 1) | (Month = 3) | (Month = 5) | (Month = 7) | (Month = 8) | (Month = 10) | (Month = 12) <-> length(Month, 31)
(Month = 4) | (Month = 6) | (Month = 9) | (Month = 11) <-> length(Month, 30)
(Month = 2) <-> length(Month, 28) | length(Month, 29)




*/

chr_fields(hp_arrangement, [
	_{
		key:begin_date,
		type:date,
		unique:true,
		required:true
	},
	_{
		key:end_date,
		type:date,
		unique:true,
		required:true
	},
	_{
		key:cash_price,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:interest_rate,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:repayment_amount,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:number_of_installments,
		type:integer,
		unique:true,
		required:true
	},
	_{
		key:installments,
		type:list(hp_installment),
		unique:true,
		required:true
	}
]).


chr_fields(hp_installment, [
	_{
		key:hp_arrangement,
		type:hp_arrangement,
		unique:true,
		required:true
	},
	_{
		key:opening_date,
		type:date,
		unique:true,
		required:true
	},
	_{
		key:opening_balance,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:payment_amount,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:interest_rate,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:interest_amount,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:closing_date,
		type:date,
		unique:true,
		required:true
	},
	_{
		key:closing_balance,
		type:rational,
		unique:true,
		required:true
	}
]).

chr_fields(list, [
	_{
		key:length,
		type:integer,
		required:true
	_{
		key:element_type,
		/* type should be type but let's not go there right now */
		unique:true /* just because for now we don't have any interpretation of a list with multiple element types */
	},
	_{
		key:first,
		/*can we make this theory work over regular rdf list representation? (i.e. no distinction between lists and list-cells) */
		type:list_cell
		unique:true
		/*required:false % existence is dependent on length, exists exactly when length is non-zero / list is non-empty */
	},
	_{
		key:last,
		type:list_cell,
		unique:true
		/*required:false % existence is dependent on length, exists exactly when length is non-zero / list is non-empty */
	}
]).

chr_fields(list_cell, [
	_{
		key:value,
		/* type: self.list.element_type */
		unique:true,
		required:true
	},
	_{
		key:list,
		type:list,
		unique:true,
		required:true
	},
	_{
		key:index,
		type:integer,
		unique:true,
		required:true	
	},
	_{
		key:next,
		type:list_cell,
		unique:true
		/* required: false % exists exactly when this is not the last element */
	},
	_{
		key:previous,
		type:list_cell,
		unique:true
		/* required: false % exists exactly when this is not the first element */
	}
]).

chr_field(date, [
	_{
		key:year,
		type:integer,
		unique:true,
		required:true
	},
	_{
		key:month,
		type:integer, /* type should actually be something that actually represents a specific month object, so that we can do like self.month.length */
		unique:true,
		required:true
	},
	_{
		key:day,
		type:integer, 
		unique:true,
		required:true
	}
]).


chr_fields(dummy, [
	_{
		key:foo,
		type:date,
		unique:true,
		required:true
	},
	_{
		key:bar,
		type:dummy
	}
]).

initialize_relations :-
	findall(
		Relation:Fields,
		chr_fields(Relation,Fields),
		Relations
	),
	maplist(initialize_relation, Relations).

initialize_relation(Relation:Fields) :-
	fact(Relation, a, relation),
	maplist(initialize_field(Relation), Fields).

initialize_field(Relation, Field) :-
	gensym(field, Field_Bnode),
	fact(Relation, field, Field_Bnode),
	dict_pairs(Field, _, Field_Attributes),
	initialize_field_attributes(Field_Bnode, Field_Attributes).
	/* for some reason Field_Bnode becomes a variable when we use maplist like this... */
	%maplist([Key-Value]>>fact(Field_Bnode, Key, Value), Field_Attributes).

initialize_field_attributes(_, []).
initialize_field_attributes(Field_Bnode, [Key-Value | Rest]) :-
	fact(Field_Bnode, Key, Value),
	initialize_field_attributes(Field_Bnode, Rest).

add_attribute(S, P, O) :-
	(
		\+find_fact2(S1, P1, _, [S1:S, P1:P])
	->
		fact(S,P,O)
	;	true
	).

% LIST THEORY

% there is only one cell at any given index
rule, fact(L, a, list), fact(X, list_in, L), fact(X, list_index, I) \ fact(Y, list_in, L), fact(Y, list_index, I) <=> debug(chr_list, "there is only one cell at any given index.~n", []), X = Y.

% if non-empty then first exists, is unique, is in the list, and has list index 1
rule, fact(L, a, list), fact(_, list_in, L) ==> \+find_fact2(L1, first, _, [L1:L]) | debug(chr_list, "if non-empty then first exists.~n", []), fact(L, first, _).
rule, fact(L, a, list), fact(L, first, First) ==> \+find_fact2(First1, list_in, L1, [First1:First, L1:L]) | debug(chr_list, "first element is in the list.~n", []), fact(First, list_in, L).
rule, fact(L, a, list), fact(L, first, First) ==> \+find_fact2(First1, list_index, 1, [First1:First]) | debug(chr_list, "first element has list_index 1.~n", []), fact(First, list_index, 1).

% if non-empty, and N is the length of the list, then last exists, is unique, is in the list, and has list index N
rule, fact(L, a, list), fact(_, list_in, L) ==> \+find_fact2(L1, last, _, [L1:L]) | debug(chr_list, "if non-empty then last exists.~n", []), fact(L, last, _).
rule, fact(L, a, list), fact(L, last, Last) ==> \+find_fact2(Last1, list_in, L1, [Last1:Last, L1:L]) | debug(chr_list, "last element is in the list.~n", []), fact(Last, list_in, L). 
rule, fact(L, a, list), fact(L, last, Last), fact(L, length, N) ==> \+find_fact2(Last1, list_index, N1, [Last1:Last, N1:N]) | debug(chr_list, "index of last element is the length of the list.~n", []), fact(Last, list_index, N).

% the list index of any item is between 1 and the length of the list
rule, fact(L, a, list), fact(X, list_in, L), fact(X, list_index, I), fact(L, length, N) ==> debug(chr_list, "the list index of any item is between 1 and the length of the list.~n", []), clpq({I >= 1}), clpq({I =< N}).

% if list has an element type, then every element of that list has that type
rule, fact(L, a, list), fact(L, element_type, T), fact(Cell, list_in, L), fact(Cell, value, V) ==> \+find_fact2(V1, a, T1, [V1:V, T1:T]) | debug(chr_list, "if list has an element type, then every element of that list has that type.~n", []), fact(V, a, T).

% if X is the previous item before Y, then Y is the next item after X, and vice versa.
% the next and previous items of an element are in the same list as that element 
rule, fact(L, a, list), fact(Cell, list_in, L), fact(Cell, prev, Prev) ==> \+find_fact(Prev, next, Cell) | debug(chr_list, "if X is the previous item before Y, then Y is the next item after X.~n", []), fact(Prev, next, Cell).
rule, fact(L, a, list), fact(Cell, list_in, L), fact(Cell, prev, Prev) ==> \+find_fact(Prev, list_in, L) | debug(chr_list, "the previous item of an item is in the same list.~n", []), fact(Prev, list_in, L).
rule, fact(L, a, list), fact(Cell, list_in, L), fact(Cell, next, Next) ==> \+find_fact(Next, prev, Cell) | debug(chr_list, "if X is the next item after Y, then Y is the previous item before X.~n", []), fact(Next, prev, Cell).
rule, fact(L, a, list), fact(Cell, list_in, L), fact(Cell, next, Next) ==> \+find_fact(Next, list_in, L) | debug(chr_list, "the next item of an item is in the same list.~n", []), fact(Next, list_in, L).

% the next item after the item at list index I has list index I + 1
rule, fact(L, a, list), fact(Cell, list_in, L), fact(Cell, list_index, I), fact(Cell, next, Next), fact(Next, list_index, J) ==> debug(chr_list, "the next item after the item at list index I has list index I + 1", []), clpq({J = I + 1}).

% OBJECTS/RELATIONS THEORY
/*
Required field:
 "required" here doesn't mean the user must explicitly supply the field, it just means that the field will always be created if it hasn't been supplied,
 i.e. it's an existence assertion
*/
rule,
fact(Object, a, Type) 
==> assert_relation_constraints(Type, Object).


/* Unique field: */
rule,
	fact(Object, a, Type),
	fact(Type, a, relation),
	fact(Type, field, Field),
	fact(Field, key, Key),
	fact(Field, unique, true),
	fact(Object, Key, X) 
	\ 
	fact(Object, Key, Y)
	<=>
	debug(chr_object, "unique field rule: object=~w, type=~w, field=~w~n", [Object, Type, Key]),
	(	X = Y 
	-> 	true 
	; 	format(
			user_error,
			"Error: field ~w.~w must be unique but two distinct instances were found: `~w ~w ~w` and `~w ~w ~w`~n",
			[Type, Key, Object, Key, X, Object, Key, Y]
		),
		fail
	).

/* Typed field:	*/
rule,
	fact(Object, a, Type),
	fact(Type, a, relation),
	fact(Type, field, Field),
	fact(Field, key, Key),
	fact(Field, type, Field_Type),
	fact(Object, Key, Value)
	==>
	debug(chr_object, "typed field rule: object=~w, type=~w, field=~w, field_type=~w, value=~w~n", [Object, Type, Key, Field_Type, Value]),
		(
			Field_Type = list(Element_Type)
		->	add_attribute(Value, a, list(Element_Type)),
			add_attribute(Value, element_type, Element_Type)
		;	add_attribute(Value, a, Field_Type)
		).

% HP ARRANGEMENTS & HP INSTALLMENTS THEORY

% HP ARRANGEMENT GLOBAL CONSTRAINTS
rule,
	fact(HP, a, hp_arrangement)
	==>
	clp(
	/* Note that all of these HP parameters are redundant and just referencing values at the endpoints of the HP installments "curve" */
	First_Installment 			= HP.installments.first_value,
	Last_Installment 			= HP.installments.last_value,
	HP.cash_price 				= First_Installment.opening_balance,
	HP.begin_date				= First_Installment.opening_date, /* needs payment type parameter */
	HP.final_balance 			= Last_Installment.closing_balance,
	HP.end_date 				= Last_Installment.closing_date,
	HP.number_of_installments 	= Last_Installment.number,


	% special formula: repayment amount
	% the formula doesn't account for balloons/submarines and other variations
	P0 = HP.cash_price,    		% P0 = principal / balance at t = 0
	PN = HP.final_balance, 		% PN = principal / balance at t = N
	IR = HP.interest_rate,
	R = HP.repayment_amount,
	N = HP.number_of_installments,
	R = (P0 * (1 + (IR/12))^N - PN)*((IR/12)/((1 + (IR/12))^N - 1))
	).


/*
like...
	body items \
	rule
	==>
	head(	% just takes the head term and runs it but applying stuff like . notation or asserting triples that necessarily exist
			% but haven't been asserted yet, it should really just be the first time it encounters an object it asserts all the
			% necessarily-existing attributes so that they can be referenced without error. if they don't necessarily exist and
			% they're referenced without being matched in the body then we'll assume it's an error
			% ex.. if you reference HP.cash_price that should always be fine because it necessarily exists
			% but if you reference List_Item.next, and it doesn't exist, then maybe that's an error
			% we differentiate explicitly in the attribute definitions for each type
		asserted constraints
	),
?
*/


% CONSTRAINTS ABOUT ANY GIVEN INSTALLMENT:

rule,
	fact(HP, a, hp_arrangement),
	fact(HP, has_installment, Installment),
	fact(Installment, list_cell, Installment_Cell)
	==>
	clp(
	Installment:hp_arrangement		= HP,
	Installment:interest_rate 		= HP:normal_interest_rate,
	Installment:payment_amount 		= HP:normal_payment_amount,		% needs to account for balloon payments
	Installment:interest_amount 	= Installment:opening_balance * Installment:interest_rate,
	Installment:closing_balance 	= Installment:opening_balance + Installment:interest_amount - Installment:payment_amount,

	Installment_Cell.index 			= Installment.number,
	Installment_Cell.next			= Installment.next,
	Installment_Cell.previous		= Installment.previous,

	/* calculating installment period from index
	note adding: must be same units; //12 is converting units of months to units of years,
	% with approximation given by rounding down, which is done because the remainder is given
	% as a separate quantity

	 % taking rem in this context requires correction for 0-offset of month-index, ex.. january = 1,
	(year,month) is effectively a kind of compound unit

	% offset is inverse of error
	% 
	*/
	Offset 	#= (HP.begin_month - 1) + (Installment.number - 1), % month's unit and installment index have +1 0-offset, -1 is 0-error (deviation from 0)
	Year 	#= HP.begin_date.year + (Offset // 12),
	Month	#= ((Offset rem 12) + 1), 							% +1 is return to 0-offset of the month's unit

	% just assuming that the opening date is the 1st of the month and closing date is last of the month
	Installment.opening_date = date(Year, Month, 1),
	Installment.closing_date = date(Year, Month, month_length(Installment_Year, Installment_Month)),

	% special formula: closing balance to calculate the closing balance directly from the hp parameters.
	% NOTE: approximation errors in input can cause it to calculate a non-integer installment index
	/*
	P0 = HP.cash_price,
	I = HP.installment_number
	R = HP.repayment_amount
	IR = HP.interest_rate
	PI = P0*(1 + (IR/12))^I - R*((1 + (IR/12))^I - 1)/(IR/12)
	*/
	).





% Constraint relating adjacent installments: continuity principle
% Other constraints are handled by the list theory.
rule,
	fact(HP, a, hp_arrangement),
	fact(HP, has_installment, Installment),
	fact(Installment, next, Next_Installment)
	==>
	clp(
	Installment.closing_balance = Next_Installment.opening_balance
	).


% i was holding off on these rules in particular cause i'm trying to patch them into the other rules, where possible
% you can delete it or whatever, i'm just doing it so i can read it now ah sure

/*
% 
% if the cash price is different from the final balance, there must be an installment
rule, fact(HP, a, hp_arrangement), fact(HP, cash_price, Cash_Price), fact(HP, final_balance, Final_Balance), fact(HP, installments, Installments) ==> \+find_fact2(_, list_in, Installments1, [Installments1:Installments]), nonvar(Cash_Price), nonvar(Final_Balance), Cash_Price \== Final_Balance | debug(chr_hp, "if the cash price is different from the final balance, there must be an installment.~n", []), fact(_, list_in, Installments).

% this isn't a logical validity it's just a heuristic meant to generate the list when the parameters are underspecified
% if closing balance is greater than or equal to repayment amount, there should be another installment after it
rule, fact(HP, a, hp_arrangement), fact(HP, repayment_amount, Repayment_Amount), fact(HP, installments, Installments), fact(Installment_Cell, list_in, Installments), fact(Installment_Cell, value, Installment), fact(Installment, closing_balance, Closing_Balance) ==> nonvar(Closing_Balance), nonvar(Repayment_Amount), Closing_Balance >= Repayment_Amount, \+find_fact2(Installment_Cell1, next, _, [Installment_Cell1:Installment_Cell]) | debug(chr_hp, "if closing balance is greater than or equal to repayment amount, there should be another installment after it.~n", []), fact(Installment_Cell, next, _).

% this on the other hand is a logical validity:
% if closing balance is not equal to the final balance then there should be another installment after it


% if opening_balance of the installment is less than the cash price of the arrangement, there should be another installment before it
rule, 
	fact(HP, a, hp_arrangement), 
	fact(HP, cash_price, Cash_Price), 
	fact(HP, installments, Installments), 
	fact(Installment_Cell, list_in, Installments), 
	fact(Installment_Cell, value, Installment), 
	fact(Installment, opening_balance, Opening_Balance) 
	==> 
	nonvar(Cash_Price), 
	nonvar(Opening_Balance), 
	Opening_Balance < Cash_Price, 
	\+find_fact2(Installment_Cell1, prev, _, [Installment_Cell1:Installment_Cell]) 
	| 
	debug(chr_hp, "if opening balance is less than the cash price of the arrangement, there should be another installment before it.~n", []), 
	fact(Installment_Cell, prev, _). 

% this is handled by the list theory
% if the index of an installment is the same as the number of installments, then it's the last installment
rule, fact(HP, a, hp_arrangement), fact(HP, number_of_installments, Number_Of_Installments), fact(HP, installments, Installments), fact(Installment, list_in, Installments), fact(Installment, list_index, Number_Of_Installments) ==> fact(Installments, last, Installment).


% if number of installments is nonvar then you can generate all the installments
rule, 
	fact(HP, a, hp_arrangement), 
	fact(HP, number_of_installments, Number_Of_Installments), 
	fact(HP, installments, Installments) 
	==> 
	\+'$enumerate_constraints'(block), 
	nonvar(Number_Of_Installments) 
	| 
	generate_installments(Installments, Number_Of_Installments).
*/


/*
This is a catch-all for fact deduplication.
*/
rule, fact(S, P, O) \ fact(S, P, O) <=> true.


head([]) :-
	rule.
head([Constraint | Constraints ]) :-
	Constraint =.. [F | Args],
	% F must be a relation, can't have '2 + 2' as a constraint, it's just a number not a constraint.
	
	(
		nonvar(F), /* can we ever have a var here? hypothetically we could ask something like 5 ? 2*/
	->	true
	;	format(user_error, "ERROR: variable relations not currently supported, in `~w`~n", [Constraint])
	(
		relation(F, $>length(Args))
	-> 	true
	; 	format(user_error, "ERROR: no known relation `~w/~w` in `~w`~n", [F, $>length(Args), Constraint])
	),
	maplist(head_arg, Args, New_Args),
	New_Constraint =.. [F | New_Args] % should only fail in the event of programmer / environment error
	call(New_Constraint).

head_arg(Arg, Arg) :- 
	var(Arg), !.
head_arg(Arg, New_Arg) :- 
	Arg =.. [F], !,
head_arg(Arg, New_Arg) :-
	Arg =.. [':' | Dot_Args], !,
	(
		Dot_Args = [Object, Attribute] 
	-> 	true 
	; 	format(user_error, "ERROR: invalid application of ':' in `~w`~n", [Arg]),
		fail
	),
	Attribute = [F | Attribute_Args],
	(
		F = ':'
	->	(
			Attribute_Args = [X]
		->	
		;	(
				Attribute_Args = [X, Y | Rest]

	Dot_Args = [Object, Attribute],
	find_fact3(Object1, Attribute, Value1, [Object1:Object], Subs),
	get_sub(Value1, Subs, Value),
	

head_arg(Arg, New_Arg) :-
	nonvar(Arg),
	Arg =.. [F, X | Xs],
	function(F, $>length([X | Xs])),


relation('fact',3).
relation('=',2).
relation('>',2).
relation('>=',2).
relation('<',2).
relation('=<',2).
relation('#=',2).	% equality constrained to integers, should be driven by the types
function('+',2).
function('*',2).
function('-',2).


/*
Hopefully all the other rules fully finish executing before this one fires?
*/
rule <=> clpq.

clpq \ clpq(Constraint) <=> (
		call(Constraint)
	->	(true, old_clpq(Constraint))
	;	(
			format(user_error, "Error: failed to apply constraint `~w`~n", [Constraint]),
			constraint_to_float(Constraint, Float_Constraint),
			format(user_error, "as float: `~w`~n", [Float_Constraint]),
			print_constraints,
			fail
		)
	).

clpq, countdown(N, Done) <=> N > 0 | M is N - 1, format(user_error, "~ncountdown ~w~n~n", [M]), countdown(M, Done), rule.
clpq, countdown(0, Done) <=>
	Done = done,
	true.
%next(0) <=> true.
%next(M) <=> nl, countdown(M), rule.

start(N, Done) <=> N > 0 | debug(chr_hp), debug(chr_object), debug(chr_list), debug(chr_date), initialize_relations, countdown(N, Done), rule.
start(0, Done) <=> Done = done.

% General pattern here:
% we have flexible objects that need to be translated back into standard data formats.

constraint_to_float(Constraint, Float_Constraint) :-
	(
		nonvar(Constraint)
	->
		Constraint =.. [F | Args],
		(
			F = rdiv
		->	rat_to_float(Constraint, Float_Constraint)
		;	maplist(constraint_to_float, Args, Float_Args),
			Float_Constraint =.. [F | Float_Args]
		)
	;	Float_Constraint = Constraint
	).

print_constraints :-
	findall(
		_,
		(
			'$enumerate_constraints'(CHR),
			(
				CHR = clpq(Constraint)
			;	CHR = old_clpq(Constraint)
			),
			format(user_error, "~w~n", [Constraint])
		),
		_
	).

generate_installments(List, 0) :- format(user_error, "generate_installments(~w, 0)~n", [List]).
generate_installments(List, N) :-
	format(user_error, "generate_installments(~w, ~w)~n", [List, N]),
	N > 0,
	fact(Cell, list_in, List),
	fact(Cell, list_index, N),
	M is N - 1,
	generate_installments(List, M).

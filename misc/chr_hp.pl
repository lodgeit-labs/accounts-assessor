:- use_module(library(chr)).
:- use_module(library(clpq)).
:- use_module(library(clpfd)).

:- ['./clpfd_datetime.pl'].

:- op(100, yfx, ':').	% for left-associativity of x:y:z

:- chr_constraint fact/3, rule/0, start/2, clpq/1, clpq/0, countdown/2, next/1, old_clpq/1, block/0.

find_fact(S,P,O) :-
	debug(find_fact, "find_fact(~w,~w,~w):~n", [S,P,O]),
	'$enumerate_constraints'(fact(S1,P1,O1)),
	debug(find_fact, "find_fact(~w,~w,~w): trying `fact(~w,~w,~w)`~n", [S,P,O, S1,P1,O1]),
	maplist(find_fact_unify, [S,P,O], [S1,P1,O1]),
	debug(find_fact, "find_fact(~w,~w,~w): Success.~n", [S,P,O]).

find_fact_unify(X,Y) :-
	var(X),
	X = Y.

find_fact_unify(kb_var(X),kb_var(Y)) :-
	!,
	X == Y.
find_fact_unify(X, Y) :-
	X == Y.

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
	},
	_{
		key:element_type,
		/* type should be type but let's not go there right now */
		unique:true /* just because for now we don't have any interpretation of a list with multiple element types */
	},
	_{
		key:first,
		/*can we make this theory work over regular rdf list representation? (i.e. no distinction between lists and list-cells) */
		type:list_cell,
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

chr_fields(date, [
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
	},
	_{
		key:day_of_week,
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

/*
add_attribute(S, P, O) :-
	(
		\+find_fact2(S1, P1, _, [S1:S, P1:P])
	->
		fact(S,P,O)
	;	true
	).
*/

% LIST THEORY

/*
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
*/


% OBJECTS/RELATIONS THEORY
/*
Required field:
 "required" here doesn't mean the user must explicitly supply the field, it just means that the field will always be created if it hasn't been supplied,
 i.e. it's an existence assertion
*/
/*
rule,
fact(Object, a, Type) 
==> assert_relation_constraints(Type, Object).
*/

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
	debug(chr_object, "CHR: unique field rule: object=~w, type=~w, field=~w~n", [Object, Type, Key]),
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
	debug(chr_object, "CHR: typed field rule: object=~w, type=~w, field=~w, field_type=~w, value=~w~n", [Object, Type, Key, Field_Type, Value]),
		(
			Field_Type = list(Element_Type)
		->	fact(Value, a, list(Element_Type)),
			fact(Value, element_type, Element_Type)
		;	fact(Value, a, Field_Type)
		).


% HP ARRANGEMENTS & HP INSTALLMENTS THEORY

% HP ARRANGEMENT GLOBAL CONSTRAINTS
	fact(HP, a, hp_arrangement) \
	rule
	<=>
	assert_constraints([
	/* Note that all of these HP parameters are redundant and just referencing values at the endpoints of the HP installments "curve" */
	First_Installment 			= HP:installments:first_value,
	Last_Installment 			= HP:installments:last_value,
	HP:cash_price 				= First_Installment:opening_balance,
	HP:begin_date				= First_Installment:opening_date, /* needs payment type parameter */
	HP:final_balance 			= Last_Installment:closing_balance,
	HP:end_date 				= Last_Installment:closing_date,
	HP:number_of_installments 	= Last_Installment:number,


	% special formula: repayment amount
	% the formula doesn't account for balloons/submarines and other variations
	P0 = HP:cash_price,    		% P0 = principal / balance at t = 0
	PN = HP:final_balance, 		% PN = principal / balance at t = N
	IR = HP:interest_rate,
	R = HP:repayment_amount,
	N = HP:number_of_installments,
	{R = (P0 * (1 + (IR/12))^N - PN)*((IR/12)/((1 + (IR/12))^N - 1))}
	]).


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
	fact(HP, a, hp_arrangement),
	fact(HP, has_installment, Installment),
	fact(Installment, list_cell, Installment_Cell) \
	rule
	<=>
	add_constraints([

	% relate installment parameters to HP parameters
	Installment:hp_arrangement		= HP,
	Installment:interest_rate 		= HP:normal_interest_rate,
	Installment:payment_amount 		= HP:normal_payment_amount,		% needs to account for balloon payments


	% relate opening balance, interest rate, interest amount, payment amount, and closing balance
	{Installment:interest_amount 	= Installment:opening_balance * Installment:interest_rate},
	{Installment:closing_balance 	= Installment:opening_balance + Installment:interest_amount - Installment:payment_amount},

	% let the installment object be treated as a list-cell
	Installment_Cell:index 			= Installment:number,
	Installment_Cell:next			= Installment:next,
	Installment_Cell:previous		= Installment:previous,



	/* calculating installment period from index
	note adding: must be same units; //12 is converting units of months to units of years,
	% with approximation given by rounding down, which is done because the remainder is given
	% as a separate quantity

	 % taking rem in this context requires correction for 0-offset of month-index, ex.. january = 1,
	(year,month) is effectively a kind of compound unit

	% offset is inverse of error
	% 
	*/
	Offset 	#= (HP:begin_month - 1) + (Installment:number - 1), % month's unit and installment index have +1 0-offset, -1 is 0-error (deviation from 0)
	Year 	#= HP:begin_date:year + (Offset // 12),
	Month	#= ((Offset mod 12) + 1), 							% +1 is return to 0-offset of the month's unit

	% just assuming that the opening date is the 1st of the month and closing date is last of the month
	Installment:opening_date:year = Year,
	Installment:opening_date:month = Month,
	Installment:opening_date:day = 1,
	Installment:closing_date:year = Year,
	Installment:closing_date:month = Month,
	Installment:closing_date:day = Installment:closing_date:month_length %,
	%Installment:closing_date:day = Month_Length
	]).

	% special formula: closing balance to calculate the closing balance directly from the hp parameters.
	% NOTE: approximation errors in input can cause it to calculate a non-integer installment index
	/*
	P0 = HP.cash_price,
	I = HP.installment_number
	R = HP.repayment_amount
	IR = HP.interest_rate
	PI = P0*(1 + (IR/12))^I - R*((1 + (IR/12))^I - 1)/(IR/12)
	*/



% Constraint relating adjacent installments: continuity principle
% Other constraints are handled by the list theory.
	fact(HP, a, hp_arrangement),
	fact(HP, has_installment, Installment),
	fact(Installment, next, Next_Installment) \
	rule
	<=>
	add_constraints([
	Installment:closing_balance = Next_Installment:opening_balance
	]).


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


add_constraints(Constraints) :-
	maplist(add_constraint, Constraints),
	rule.

add_constraint(Constraint) :-
	transform_constraint(Constraint, New_Constraint),
	debug(add_constraint, "add_constraint(~w): Transformed constraint: in=`~w`, out=`~w`~n", [Constraint, Constraint, New_Constraint]),
	(
		Constraint = fact(S, P, O)
	->	debug(add_constraint, "add_constraint(~w): Fact constraint...~n", [Constraint]),
		add_fact(S,P,O),
		debug(add_constraint, "add_constraint(~w): Added fact...~n", [Constraint]),
		(
			P = 'a'
		->	(
				atom(O)
			->	chr_fields(O, Attributes),
				debug(add_constraint, "add_constraint(~w): Adding attributes...~n", [Constraint]),
				maplist(add_attribute(S), Attributes),
				(
					O = date
				->	debug(add_constraint, "add_constraint(~w): Adding date constraints...~n", [Constraint]),
					date_constraints(Date),
					add_fact(S, dict, Date),
					debug(add_constraint, "add_constraint(~w): Created attribute dict...~n", [Constraint]),
					add_fact(S, year, kb_var(Date.year)),
					debug(add_constraint, "add_constraint(~w): Initialized attribute `year`~n", [Constraint]),
					add_fact(S, month, kb_var(Date.month)),
					add_fact(S, day, kb_var(Date.day)),
					add_fact(S, day_of_week, kb_var(Date.day_of_week)),
					debug(add_constraint, "add_constraint(~w): Related dict attributes and triples attributes~n", [Constraint])
				;	true
				)
			;	format(user_error, "ERROR: add_constraint(~w): type must be an atom in `~w`~n", [Constraint, Constraint]),
				fail
			)
		;	true
		)
	;	call(New_Constraint)
	),
	debug(add_constraint, "add_constraint(~w): Success.~n", [Constraint]).

add_fact(S1,P1,O1) :-
	debug(add_fact, "add_fact(~w,~w,~w): Mapping vars:", [S1,P1,O1]),
	% don't add triples that already exist
	maplist([X,X]>>(var(X) -> X = kb_var(_) ; true), [S1,P1,O1], [S,P,O]),
	debug(add_fact, " ~w~n", [[S,P,O]]),
	(	\+find_fact(S,P,O)
	->	
		% don't add extra attributes when the attribute is unique
		debug(add_fact, "add_fact(~w,~w,~w): Fact doesn't exist...~n", [S1,P1,O1]),
		(
			P = 'a'
		->	(
				find_fact(S,a,O1)
			->	(
					O == O1
				->	true
				;	format(user_error, "ERROR: asserting `~w a ~w` when fact `~w a ~w` already exists~n", [S,O,S,O1]),
					fail
				)
			;	debug(add_fact, "add_fact(~w,~w,~w): Adding fact...~n",[S1,P1,O1]),
				fact(S,P,O)
			)
		;
			(
				find_fact(S,a,T)
			->	debug(add_fact, "add_fact(~w,~w,~w): Found type: `~w a ~w`~n", [S1,P1,O1,S,T]),
				(
					find_fact(T, field, Field),
					find_fact(Field, key, P)
				->	debug(add_fact, "add_fact(~w,~w,~w): Found matching key: `~w key ~w`~n", [S1,P1,O1,Field,P]),
					(	\+find_fact(Field, unique, true)
					->	fact(S,P,O)
					;	(	
							find_fact(S, P, O2)
						->	debug(add_fact, "add_fact(~w,~w,~w): Found existing attribute: `~w ~w ~w`, unifying.~n", [S1,P1,O1, S,P,O2]),
							(
								O = O2
							->	true
							;	format(user_error, "ERROR: add_fact(~w,~w,~w): Inconsistency: `~w` \\= `~w`, when setting attribute `~w:~w`~n", [S1,P1,O1,O,O2,S,P]),
								fail
							)
						;	debug(add_fact, "add_fact(~w,~w,~w): No existing attribute, Adding fact...~n", [S1,P1,O1]),
							fact(S,P,O)
						)
					)
				;	debug(add_fact, "add_fact(~w,~w,~w): No matching key. Adding fact.~n", [S1,P1,O1]),
					fact(S,P,O)
				)
			;	debug(add_fact, "add_fact(~w,~w,~w): Adding fact...~n", [S1,P1,O1]),
				fact(S,P,O)
			)
		)
	;	debug(add_fact, "add_fact(~w,~w,~w): Not adding fact...~n", [S1,P1,O1])
	),
	debug(add_fact, "add_fact(~w,~w,~w): Success.~n", [S1,P1,O1]).


transform_constraint('{}'(Constraint), '{}'(New_Constraint)) :-
	!,
	transform_constraint(Constraint, New_Constraint).
transform_constraint(fact(S,P,O), fact(S1,P1,O1)) :-
	!,
	maplist([X,Y]>>transform_term(X,Y,_{with_kb_vars:true}), [S,P,O], [S1,P1,O1]).

transform_constraint(Constraint, New_Constraint) :-
	(
		var(Constraint)
	-> 	format(user_error, "ERROR: variable constraints not currently supported~n", []), fail
	;	true
	),
	Constraint =.. [F | Args],
	length(Args, N),
	(
		nonvar(F) /* can we ever have a var here? hypothetically we could ask something like 5 ? 2*/
	->	true
	;	format(user_error, "ERROR: variable relations not currently supported, in `~w`~n", [Constraint])
	),
	(
		relation(F, N)
	-> 	true
	; 	format(user_error, "ERROR: no known relation `~w/~w` in `~w`~n", [F, N, Constraint])
	),
	maplist(
		[X,Y]>>(transform_term(X,Y,_{with_kb_vars:false})),
		Args,
		New_Args
	),
	New_Constraint =.. [F | New_Args]. % should only fail in the event of programmer / environment error

transform_term(kb_var(Term), New_Term, Opts) :- 
	!,
	debug(transform_term,"transform_term#kb_var(kb_var(~w),~w,~w):~n", [kb_var(Term), New_Term, Opts]),
	(
		get_dict(with_kb_vars,Opts,true)
	->	New_Term = kb_var(Term)
	;	New_Term = Term
	),
	debug(transform_term, "transform_term#kb_var(kb_var(~w),~w,~w): Success.~n", [kb_var(Term), New_Term, Opts]).


transform_term(Term, Term, _) :- 
	debug(transform_term, "transform_term#function(~w, ~w, _):~n", [Term, Term]),
	Term =.. [Term],
	(
		atomic(Term)
	->	true
	;	format(user_error, "ERROR: transform_term#atomic(~w, ~w, _): non-atomic atom? `~w`~n", [Term, Term, Term]),
		fail
	),
	!,
	debug(transform_term, "transform_term#function(~w, ~w, _): Success.~n", [Term, Term]).

transform_term(Object:Attribute, New_Term, Opts) :-
	!,
	debug(transform_term, "transform_term#':'(~w, ~w, ~w):~n", [Object:Attribute, New_Term, Opts]),
	transform_attribute([Object,Attribute], New_Term1),
	(
		New_Term1 = kb_var(Term)
	->	(
			get_dict(with_kb_vars,Opts,true)
		->	debug(transform_term, "transform_term#':'(~w, ~w, ~w): with_kb_vars=true~n", [Object:Attribute, New_Term, Opts]),
			New_Term = kb_var(Term)
		;	debug(transform_term, "transform_term#':'(~w, ~w, ~w): with_kb_vars=false~n", [Object:Attribute, New_Term, Opts]),
			New_Term = Term
		)
	;	debug(transform_term, "transform_term#':'(~w, ~w, ~w): ~n", [Object:Attribute, New_Term, Opts]),
		New_Term = New_Term1
	),
	debug(transform_term, "transform_term#':'(~w, ~w, ~w):Success.~n", [Object:Attribute, New_Term, Opts]).

transform_term(Term, New_Term, Opts) :- 
	debug(transform_term, "transform_term#function(~w, ~w, ~w):~n", [Term, New_Term, Opts]),
	Term =.. [F | Args],
	length(Args, N),
	(
		function(F, N)
	-> 	true
	; 	format(user_error, "ERROR: transform_term#function(~w, ~w, ~w): no known function `~w/~w` in `~w`~n", [Term, New_Term, Opts, F, N, Term]),
		fail
	),
	maplist([X,Y]>>transform_term(X,Y,Opts), Args, New_Args),
	New_Term =.. [F | New_Args],
	debug(transform_term, "transform_term#function(~w, ~w, ~w): Success.~n", [Term, New_Term, Opts]).


transform_attribute([Object, Attribute], New_Object) :-
	debug(transform_attribute, "transform_attribute#1(~w,~w):~n", [[Object, Attribute], New_Object]),
	\+((\+var(Object), \+atom(Object), \+(Object = kb_var(_)))),
	(
		atom(Attribute)
	->	true
	;	format(user_error, "ERROR: transform_attribute#1(~w, ~w): attribute must be an atom in `~w:~w`~n", [[Object, Attribute], New_Object, Object, Attribute]),
		fail
	),
	!,
	transform_attribute_helper(Object, Attribute, New_Object),
	debug(transform_attribute, "transform_attribute#1(~w,~w): Success.~n", [[Object, Attribute], New_Object]).

transform_attribute([Object, Attribute], New_Object) :-
	debug(transform_attribute, "transform_attribute#2(~w,~w):~n", [[Object, Attribute], New_Object]),
	(
		Object =.. [':' | [Object_B, Attribute_B]],
		atom(Attribute)
	->	transform_attribute([Object_B, Attribute_B], Next_Object),
		transform_attribute_helper(Next_Object, Attribute, New_Object)
	;	format(user_error, "ERROR: transform_attribute#2(~w,~w): invalid attribute access: `~w:~w`~n", [[Object, Attribute], New_Object, Object, Attribute]),
		fail
	),
	debug(transform_attribute, "transform_attribute#2(~w,~w):~n", [[Object, Attribute], New_Object]).


transform_attribute_helper(Next_Object, Attribute, New_Object) :-
	debug(transform_attribute_helper, "transform_attribute_helper(~w,~w,~w):~n", [Next_Object, Attribute, New_Object]),
	(
		find_fact(Next_Object, a, date)
	->	debug(transform_attribute_helper, "transform_attribute_helper(~w,~w,~w): date object...~n", [Next_Object, Attribute, New_Object]),
		(
			find_fact(Next_Object, dict, Dict)
		->	debug(transform_attribute_helper, "transform_attribute_helper(~w,~w,~w): found dict: ~w~n", [Next_Object, Attribute, New_Object, Dict]),
			(
				get_dict(Attribute, Dict, X)
			->	New_Object = kb_var(X)
			;	format(user_error, "ERROR: transform_attribute_helper(~w,~w,~w): object `~w` has no attribute `~w`~n", [Next_Object, Attribute, New_Object, Next_Object, Attribute]),
				fail
			)
		;	format(user_error, "PROGRAMMER ERROR: transform_attribute_helper(~w,~w,~w): date object `~w` has no attribute dict~n", [Next_Object, Attribute, New_Object, Next_Object]),
			fail
		)
	;	debug(transform_attribute_helper, "transform_attribute_helper(~w,~w,~w): other type...~n", [Next_Object, Attribute, New_Object]),
		find_fact(Next_Object, Attribute, New_Object)
	),
	debug(transform_attribute_helper, "transform_attribute_helper(~w,~w,~w): Success.~n", [Next_Object, Attribute, New_Object]).


add_attribute(Object, Attribute) :-
	debug(add_attribute, "add_attribute(~w,~w): Adding attribute: ~w.~w~n", [Object, Attribute, Object, Attribute]),
	(
		get_dict(key, Attribute, Key)
	->	true
	;	format(user_error, "ERROR: add_attribute(~w,~w): attribute must have key~n", [Object, Attribute])
	),
	(
		atom(Key)
	->	true
	;	format(user_error, "ERROR: add_attribute(~w,~w): attribute key must be an atom, found: `~w`~n", [Object, Attribute, Key])
	),
	(
		get_dict(required, Attribute, true)
	->	debug(add_attribute, "add_attribute(~w,~w): Required...~n", [Object, Attribute]),
		add_fact(Object, Key, _)
	;	true
	),
	debug(add_attribute, "add_attribute(~w,~w): Success.~n", [Object, Attribute]).


relation('fact',3).
relation('=',2).
relation('>',2).
relation('>=',2).
relation('<',2).
relation('=<',2).
relation('#=',2).	% equality constrained to integers, should be driven by the types
relation('@=',2).

function('+',2).
function('*',2).
function('-',2).
function('//',2).
function('mod',2).
function('^',2).
function('..',2).
function('in',2).




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

get_sub(Var, [K:V | Rest], Sub) :-
	(
		Var == K
	->	Sub = V
	;	get_sub(Var, Rest, Sub)
	).



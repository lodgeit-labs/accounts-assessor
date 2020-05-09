/*
:- module(solver, [initialize_relations/0, add_constraints/1]).

:- use_module(library(chr)).
:- use_module(library(clpq)).
:- use_module(library(clpfd)).
% :- use_module(library(interpolate)). % currently not using due to bugs, but would be nice

:- op(100, yfx, ':').	% for left-associativity of x:y:z
*/

find_fact(S,P,O) :-
	debug(find_fact, "find_fact(~w,~w,~w):~n", [S,P,O]),
	'$enumerate_constraints'(fact(S1,P1,O1)),
	debug(find_fact_all, "find_fact(~w,~w,~w): trying `fact(~w,~w,~w)`~n", [S,P,O, S1,P1,O1]),
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





initialize_relations :-
	findall(
		Relation:Fields,
		user:chr_fields(Relation,Fields),
		Relations
	),
	maplist(initialize_relation, Relations).

initialize_relation(Relation:Fields) :-
	fact(Relation, a, relation),
	fact(Relation, dict, Fields),
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





add_constraints(Constraints) :-
	debug(add_constraints, "add_constraints(~w):~n", [Constraints]),
	maplist(add_constraint, Constraints),
	debug(add_constraints, "add_constraints(~w): Success.~n", [Constraints]).

add_constraint(Constraint) :-
	debug(add_constraint, "add_constraint(~w):~n", [Constraint]),
	transform_constraint(Constraint, New_Constraint),
	debug(add_constraint, "add_constraint(~w): Transformed constraint: in=`~w`, out=`~w`~n", [Constraint, Constraint, New_Constraint]),
	(
		New_Constraint = fact(S, P, O)
	->	debug(add_constraint, "add_constraint(~w): Fact constraint...~n", [Constraint]),
		add_fact(S,P,O),
		debug(add_constraint, "add_constraint(~w): Added fact...~n", [Constraint]),
		(
			P = 'a'
		->	debug(add_constraint, "add_constraint(~w): Instance declaration...~n", [Constraint]),
			(
				atom(O)
			->	debug(add_constraint, "add_constraint(~w): Type is an atom...~n", [Constraint]),
				(
					O = date
				->	debug(add_constraint, "add_constraint(~w): Adding date constraints...~n", [Constraint]),
					date_constraints(Date),
					add_fact(S, dict, Date),
					debug(add_constraint, "add_constraint(~w): Created attribute dict...~n", [Constraint]),
					add_fact(S, year, kb_var(Date.year)),
					add_fact(S, month, kb_var(Date.month)),
					add_fact(S, day, kb_var(Date.day)),
					add_fact(S, day_of_week, kb_var(Date.day_of_week)),
					debug(add_constraint, "add_constraint(~w): Related dict attributes and triples attributes~n", [Constraint])
				;	true
				),
				(
					find_fact(O, dict, Attributes)
				->
					debug(add_constraint, "add_constraint(~w): Adding attributes...~n", [Constraint]),
					maplist(add_attribute(S), Attributes),
					(	O = hp_arrangement
					->	find_fact(S, installments, Installments),
						add_fact(Installments, first, First_Cell),
						add_fact(First_Cell, value, First_Installment),
						add_constraint(fact(First_Installment, a, hp_installment)),
						add_fact(Installments, last, Last_Cell),
						add_fact(Last_Cell, value, Last_Installment),
						add_constraint(fact(Last_Installment, a, hp_installment))
					;	true
					)
				; debug(add_constraint, "add_constraint(~w): No type attributes...~n", [Constraint])
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
	debug(add_fact, "add_fact(~w,~w,~w): Mapping vars: fact(~w, ~w, ~w) -> ", [S1,P1,O1, S1, P1, O1]),
	% don't add triples that already exist
	maplist([X,X]>>(var(X) -> X = kb_var(_) ; true), [S1,P1,O1], [S,P,O]),
	debug(add_fact, "fact(~w, ~w, ~w)~n", [S, P, O]),
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
					->	debug(add_fact, "add_fact(~w,~w,~w): Key is not unique, adding fact... ~n", [S1, P1, O1]),
						fact(S,P,O)
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
	debug(transform_constraint, "transform_constraint#'{}'({~w}, {~w}):~n", [Constraint, New_Constraint]),
	!,
	transform_constraint(Constraint, New_Constraint),
	debug(transform_constraint, "transform_constraint#'{}'({~w}, {~w}): Success.~n", [Constraint, New_Constraint]).

transform_constraint(fact(S,P,O), fact(S1,P1,O1)) :-
	debug(transform_constraint, "transform_constraint#fact(~w, ~w):~n", [fact(S,P,O), fact(S1,P1,O1)]),
	!,
	maplist([X,Y]>>transform_term(X,Y,_{with_kb_vars:true}), [S,P,O], [S1,P1,O1]),
	debug(transform_constraint, "transform_constraint#fact(~w, ~w): Success.~n", [fact(S,P,O), fact(S1,P1,O1)]).

transform_constraint(Constraint, New_Constraint) :-
	debug(transform_constraint, "transform_constraint#default(~w, ~w):~n", [Constraint, New_Constraint]),
	(
		nonvar(Constraint)
	-> 	true
	;	format(user_error, "ERROR: transform_constraint#default(~w, ~w): variable constraints not currently supported~n", []),
		fail
	),
	Constraint =.. [R | Args],
	length(Args, N),
	(
		nonvar(R) /* can we ever have a var here? hypothetically we could ask something like 5 ? 2*/
	->	true
	;	format(user_error, "ERROR: transform_constraint#default(~w, ~w): variable relations not currently supported, in `~w`~n", [Constraint]),
		fail
	),
	(
		relation(R, N)
	-> 	true
	; 	format(user_error, "ERROR: transform_constraint#default(~w, ~w): no known relation `~w/~w` in `~w`~n", [R, N, Constraint]),
		fail
	),
	debug(transform_constraint, "transform_constraint#default(~w, ~w): Found relation: R = `~w/~w`, Args = `~w`~n", [Constraint, New_Constraint, R, N, Args]),
	maplist(
		[X,Y]>>(transform_term(X,Y,_{with_kb_vars:false})),
		Args,
		New_Args
	),
	New_Constraint =.. [R | New_Args], % should only fail in the event of programmer / environment error
	debug(transform_constraint, "transform_constraint#default(~w, ~w): Success.~n", [Constraint, New_Constraint]).

transform_term(kb_var(Term), New_Term, Opts) :- 
	!,
	debug(transform_term,"transform_term#kb_var(~w,~w,~w):~n", [kb_var(Term), New_Term, Opts]),
	(
		get_dict(with_kb_vars,Opts,true)
	->	New_Term = kb_var(Term)
	;	New_Term = Term
	),
	debug(transform_term, "transform_term#kb_var(~w,~w,~w): Success.~n", [kb_var(Term), New_Term, Opts]).


transform_term(Term, Term, Opts) :- 
	debug(transform_term, "transform_term#atomic(~w, ~w, ~w):~n", [Term, Term, Opts]),
	Term =.. [Term],
	(
		atomic(Term)
	->	true
	;	format(user_error, "ERROR: transform_term#atomic(~w, ~w, ~w): non-atomic atom? `~w`~n", [Term, Term, Opts, Term]),
		fail
	),
	!,
	debug(transform_term, "transform_term#atomic(~w, ~w, ~w): Success.~n", [Term, Term, Opts]).

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
	debug(transform_term, "transform_term#function(~w, ~w, ~w): Valid function application; transforming args:~n", [Term, New_Term, Opts]),
	maplist(
		% weird behavior here; if the Opts dict is just used inside the body of the function being mapped, it ends up
		% getting replaced by a variable.
		call([Opts, X,Y]>>(
			debug(transform_term, "Transforming term: ~w, opts=~w~n", [X,Opts]),
			transform_term(X,Y,Opts)
		), Opts),
		Args,
		New_Args
	),
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
	debug(transform_attribute, "transform_attribute#2(~w,~w): Success ~n", [[Object, Attribute], New_Object]).


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
			;	format(user_error, "ERROR: transform_attribute_helper(~w,~w,~w): date object `~w` has no attribute `~w`~n", [Next_Object, Attribute, New_Object, Next_Object, Attribute]),
				fail
			)
		;	format(user_error, "PROGRAMMER ERROR: transform_attribute_helper(~w,~w,~w): date object `~w` has no dict~n", [Next_Object, Attribute, New_Object, Next_Object]),
			fail
		)
	;	debug(transform_attribute_helper, "transform_attribute_helper(~w,~w,~w): other type...~n", [Next_Object, Attribute, New_Object]),
		(
			find_fact(Next_Object, Attribute, New_Object)
		->	true
		;	format(user_error, "ERROR: transform_attribute_helper(~w,~w,~w): object `~w` has no attribute `~w`~nCurrent KB:~n", [Next_Object, Attribute, New_Object, Next_Object, Attribute]),
			findall(
				_,
				(
					'$enumerate_constraints'(fact(S,P,O)),
					format(user_error, "~w ~w ~w~n", [S,P,O])
				),
				_
			),
			fail
		)
	),
	debug(transform_attribute_helper, "transform_attribute_helper(~w,~w,~w): Success.~n", [Next_Object, Attribute, New_Object]).


add_attribute(Object, Attribute) :-
	debug(add_attribute, "add_attribute(~w,~w): Adding attribute: ~w.~w~n", [Object, Attribute, Object, Attribute.key]),
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
	->	debug(add_attribute__details, "add_attribute(~w,~w): Required...~n", [Object, Attribute]),
		add_constraint(fact(Object, Key, X)),
		(
			get_dict(type, Attribute, Type)
		->	debug(add_attribute__details, "add_attribute(~w, ~w): type=~w...~n", [Object, Attribute, Type]),
			(
				Type = list(Element_Type)
			->	add_constraint(fact(X, a, list)),
				add_constraint(fact(X, element_type, Element_Type))
			;
				add_constraint(fact(X, a, Type))
			)
		;	true
		)
	;	true
	),
	debug(add_attribute__details, "add_attribute(~w,~w): Success.~n", [Object, Attribute]).


relation('fact',3).
relation('=',2).
relation('#=',2).	% equality constrained to integers, should be driven by the types
relation('>',2).
relation('#>',2).
relation('>=',2).
relation('#>=',2).
relation('<',2).
relation('#<', 2).
relation('=<',2).
relation('#=<',2).
%relation('@=',2).
relation('in',2).

/*
Nat * Nat -> Nat
Integer * Integer -> Integer
Rational * Rational -> Rational
Real * Real -> Real
*/
function('+',2).

/*
Nat * Nat -> Nat
Integer * Integer -> Integer
Rational * Rational -> Rational
Real * Real -> Real
*/
function('*',2).

/*
Nat * Nat -> Integer
Integer * Integer -> Integer
Rational * Rational -> Rational
Real * Real -> Real
*/
function('-',2).

/*
Nat * Nat -> Rational
Integer * Integer -> Rational
Rational * Rational -> Rational
Real * Real -> Real
*/
function('/',2).
function('//',2).
function('mod',2).
function('^',2).
function('..',2).	% X..Y returns {Z | X =< Z =< Y}

round_n_places(N, X, Y) :-
	Y is round(X*(10^N))/(10^N).

run_solver(Constraints) :-
	initialize_relations,
	catch_with_backtrace(
		(
			add_constraints(Constraints),
			rule,
			writeln("Solving done.")
		),
		Error,
		(
			print_message(error, Error),
			fail
		)
	).

show_list(List, Prev_Objects) :-
	debug(show_list, "show_list(~w, ~w): ...~n", [List, Prev_Objects]),
	find_fact(List, first, First),
	show_fact([List, first, First]),
	(
		find_fact(List, element_type, Element_Type)
	->	show_fact([List, element_type, Element_Type])
	;	true
	),
	Prev_Objects2 = [List | Prev_Objects],
	show_list_helper(First, Prev_Objects2),
	debug(show_list, "show_list(~w, ~w): done.~n", [List, Prev_Objects]).

show_list_helper(Cell, Prev_Objects) :-
	debug(show_list_helper, "show_list_helper(~w, ~w): ...~n", [Cell, Prev_Objects]),
	Prev_Objects2 = [Cell | Prev_Objects],
	(
		find_fact(Cell, value, Value)
	->	show_fact([Cell, value, Value]),
		show_object_helper(Value, Prev_Objects2)
	;	true
	),
	(
		find_fact(Cell, next, Next_Cell)
	->	debug(show_list_helper, "show_list_helper(~w, ~w): next cell: `~w`~n", [Cell, Prev_Objects, Next_Cell]),
		show_list_helper(Next_Cell, Prev_Objects2)
	;	debug(show_list_helper, "show_list_helper(~w, ~w): no next cell.~n", [Cell, Prev_Objects]),
		true
	),
	debug(show_list_helper, "show_list_helper(~w, ~w): done.~n", [Cell, Prev_Objects]).

show_date(Date) :-
	find_fact(Date, year, Year),
	find_fact(Date, month, Month),
	find_fact(Date, day, Day),
	format(user_error, "~w = ~w-~w-~w~n", [Date, Year, Month, Day]).

show_object(Object) :-
	debug(show_object, "show_object(~w): ...~n", [Object]),
	show_object_helper(Object, []).

show_fact(Fact) :-
	maplist([X,Y]>>(X = kb_var(Y) -> true ; X = Y), Fact, New_Fact),
	maplist([X,Y]>>((ground(X), X = (_ rdiv _)) -> Z is float(X), round_n_places(2, Z, Y) ; X = Y), New_Fact, New_Fact2),
	format(user_error, "~w ~w ~w~n", New_Fact2). 

show_object_helper(Object, Prev_Objects) :-
	debug(show_object_helper, "show_object_helper(~w, ~w): ...~n", [Object, Prev_Objects]),
	(
		find_fact(Object, a, Type)
	->	debug(show_object_helper_details, "show_object_helper(~w, ~w): `~w` has type `~w`~n", [Object, Prev_Objects, Object, Type]),
		\+member2(Object, Prev_Objects),
		Prev_Objects2 = [Object | Prev_Objects],
		(
			(	Type = list
			->	!,
				show_fact([Object, a, Type]),
				show_list(Object, Prev_Objects2)
			)
			;
			(	Type = date
			->	!,
				show_date([Object, a, Type])
			)
			;
			(
				chr_fields(Type, Attributes)
			->	!,
				show_fact([Object, a, Type]),
				debug(show_object_helper_details, "show_object_helper(~w, ~w): `~w` has attributes ~w~n", [Object, Prev_Objects, Type, Attributes]),
				findall(
					_,
					(
						member(Attribute, Attributes),
						get_dict(key, Attribute, Key),
						debug(show_object_helper_details, "show_object_helper(~w, ~w): `~w` has attribute `~w`~n", [Object, Prev_Objects, Object, Key]),
						(
							find_fact(Object, Key, Value)
						->	show_fact([Object, Key, Value]),
							show_object_helper(Value, Prev_Objects2)
						)
					),
					_
				)
			)
			;
			(
				%format(user_error, "ERROR: show_object_helper(~w, ~w): unknown type `~w`~n", [Object, Prev_Objects, Type]),
				fail
			)
		)
	;	debug(show_object_helper_details, "show_object_helper(~w, ~w): `~w` has no type.~n", [Object, Prev_Objects, Object]),
		true
	).

show_constraints :-
	findall(
		_,
		(
			'$enumerate_constraints'(fact(Object,a,Type)),
			(
				member(Type, [
					hp_arrangement
				])
			->	show_object(Object)
			)
		),
		_
	).

member2(X, [Y | _]) :- X == Y, !.
member2(X, [Y | Rest]) :- X \== Y, member2(X, Rest).

repl :-
	prompt(_, '> '),
	repeat,
	read(Command),
	(Command = quit -> !, fail ; true),
	(Command = end_of_file -> writeln(""), !, fail ; true),
	(
		call(Command)
	->	writeln("true.")
	;	writeln("false.")
	),
	fail.

test1 :-
	debug_in(
		[
			chr_hp_arrangement,
			chr_list,
			chr_list_guard,
			show_list,
			show_list_helper,
			chr_list_allow
		],
		(
			run_solver([
				/*
				assert_object(HP,
					_{
							a: 						hp_arrangement,
							cash_price:				5953.20,
							normal_interest_rate:	0.13,
							number_of_installments:	36,
							final_balance:			5.11
					}
				)
				*/
				fact(HP, a, hp_arrangement),
				HP:cash_price = 5953.20,
				HP:normal_interest_rate = 0.13,
				HP:number_of_installments = 36,
				HP:final_balance = 5.11
			]),
			format(user_error, "Solving done.~n",[]),
			show_constraints
		)
	).

debug_in(Topics, P) :-
	convlist([Topic,Topic]>>(\+debugging(Topic)), Topics, Topics_Not_Already_Debugging),
	maplist(debug, Topics),
	call(P),
	maplist(nodebug, Topics_Not_Already_Debugging).


:- module(theory_object, []).

:- chr_constraint
	fact/3,
	rule/0.


% OBJECTS/RELATIONS THEORY
/*
Required field:
 "required" here doesn't mean the user must explicitly supply the field, it just means that the field will always be created if it hasn't been supplied,
 i.e. it's an existence assertion, the field should probably be "exists" rather than "required"
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
		->	fact(Value, a, list),
			fact(Value, element_type, Element_Type)
		;	fact(Value, a, Field_Type)
		).

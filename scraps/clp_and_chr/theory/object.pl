/*
fact(Object, a, Type),
fact(Type, a, relation),
fact(Type, field, Field),
fact(Field, key, Key),
fact(Field, unique, true),
fact(Object, Key, X) 
\ 
rule,
fact(Object, Key, Y)
<=>
debug(chr_object, "CHR: unique field rule: object=~w, type=~w, field=~w, ~w =? ~w, : ... ", [Object, Type, Key, X, Y]),
(	X = Y 
-> 	true 
; 	format(
		user_error,
		"~nError: field ~w.~w must be unique but two distinct instances were found: `~w ~w ~w` and `~w ~w ~w`~n",
		[Type, Key, Object, Key, X, Object, Key, Y]
	),
	fail
),
debug(chr_object, "done. ~n", []),
rule.
*/




/* Typed field:	*/
/*
fact(Object, a, Type),
fact(Type, a, relation),
fact(Type, field, Field),
fact(Field, key, Key),
fact(Field, type, Field_Type),
fact(Object, Key, Value)
\
rule
<=>
\+find_fact(typed_field_rule, fired_on, [Object, Field])
|
fact(typed_field_rule, fired_on, [Object, Field]),
debug(chr_object, "CHR: typed field rule: object=~w, type=~w, field=~w, field_type=~w, value=~w: ... ~n", [Object, Type, Key, Field_Type, Value]),
(
	Field_Type = list(Element_Type)
->	fact(Value, a, list),
	fact(Value, element_type, Element_Type)
;	fact(Value, a, Field_Type)
),
debug(chr_object, "CHR: typed field rule: object=~w, type=~w, field=~w, field_type=~w, value=~w: ... done. ~n", [Object, Type, Key, Field_Type, Value]),
rule.
*/

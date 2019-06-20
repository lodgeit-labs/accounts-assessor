:- module(utils, [
	user:goal_expansion/2, inner_xml/3, write_tag/2, fields/2, fields_nothrow/2, numeric_fields/2, 
	pretty_term_string/2, pretty_term_string/2, with_info_value_and_info/3, trim_atom/2]).
:- use_module(library(xpath)).

	


% this gets the children of an element with ElementXPath
inner_xml(Dom, Element_XPath, Children) :-
	xpath(Dom, Element_XPath, element(_,_,Children)).

trimmed_field(Dom, Element_XPath, Value) :-
	xpath(Dom, Element_XPath, element(_,_,[Child_Atom])),
	trim_atom(Child_Atom, Value).
	
trim_atom(Child_Atom, Value) :-
	atom_string(Child_Atom, Child),
	split_string(Child, "", "\s\t\n", [Value_String]),
	atom_string(Value, Value_String).


write_tag(Tag_Name,Tag_Value) :-
	string_concat("<",Tag_Name,Open_Tag_Tmp),
	string_concat(Open_Tag_Tmp,">",Open_Tag),
	string_concat("</",Tag_Name,Closing_Tag_Tmp),
	string_concat(Closing_Tag_Tmp,">",Closing_Tag),
	write(Open_Tag),
	write(Tag_Value),
	writeln(Closing_Tag).

numeric_field(Dom, Name_String, Value) :-
	trimmed_field(Dom, //Name_String, Value_Atom),
	atom_number(Value_Atom, Value).


% case with default value
fields(Dom, [Name_String, Value_And_Default|Rest]) :-
	nonvar(Value_And_Default),
	!,
	(Value, Default_Value) = Value_And_Default,
	(
		(
			trimmed_field(Dom, //Name_String, Value),
			!
		);
			Value = Default_Value
	),
	fields(Dom, Rest).

fields(Dom, [Name_String, Value|Rest]) :-
	(
		(
			trimmed_field(Dom, //Name_String, Value),
			!
		);
		(
			pretty_term_string(Dom, Dom_String),
			atomic_list_concat([Name_String, " field missing in ", Dom_String], Error),
			throw(Error)
		)
	),
	fields(Dom, Rest).

fields(_, []).

fields_nothrow(Dom, [Name_String, Value|Rest]) :-
	trimmed_field(Dom, //Name_String, Value),
	fields_nothrow(Dom, Rest).

fields_nothrow(_, []).

numeric_fields(Dom, [Name_String, Value_And_Default|Rest]) :-
	nonvar(Value_And_Default),
	!,
	(Value, Default_Value) = Value_And_Default,
	(
		(
			numeric_field(Dom, Name_String, Value),
			!
		);
		Value = Default_Value
	),
	numeric_fields(Dom, Rest).

numeric_fields(Dom, [Name_String, Value|Rest]) :-
	(
		(
			numeric_field(Dom, Name_String, Value),
			!
		);
		(
			string_concat(Name_String, " field missing", Error),
			throw(Error)
		)
	),
	numeric_fields(Dom, Rest).

numeric_fields(_, []).



pretty_term_string(Term, String) :-
	pretty_term_string(Term, String, []).

pretty_term_string(Term, String, Options) :-
	new_memory_file(X),
	open_memory_file(X, write, S),
	print_term(Term, [output(S), write_options([
		numbervars(true),
		quoted(true),
		portray(true)
		| Options])]),
	close(S),
	memory_file_to_string(X, String).


with_info_value_and_info(with_info(Value, Info), Value, Info).








:- multifile user:goal_expansion/2.
:- dynamic user:goal_expansion/2.

/*executed at compile time, passess X through, and binds Names to info suitable for term_string*/	
user:goal_expansion(
	compile_with_variable_names_preserved(X, variable_names(Names))
, X) :-
	term_variables(X, Vars),
	maplist(my_variable_naming, Vars, Names).

my_variable_naming(Var, (Name = Var)) :-
	var_property(Var, name(Name)).
	
/*usage:
x([S2,' ', S3,' ', S4]) :-
	described_formula((
		AC=4444*X,
		X = Z/3,
		true
	), Namings),
	described_formula((
		AC=4444*X,
		X = Z/3,
		true
	), Namings),
	Z = 27,
	writeln(''),
	print_term(AC, [Namings]),
	writeln(''),
	described_formula((
		AC2=4*XX,
		XX = Z/3,
		true
	), Namings2),
	writeln(''),
	print_term(AC2, [Namings2]),
	writeln(''),

	true.
:- x(S).

*/





% scraps:

/*
replace_underscores_in_variable_names_with_spaces(variable_names(Names0), variable_names(Names1)) :-
	maplist(replace_underscores_in_variable_names_with_spaces2, Names0, Names1).

replace_underscores_in_variable_names_with_spaces2((Name0 = Var), (Name1 = Var)) :-
	re_replace('_'/a, ' ', Name0, Name1).
*/
/*usage:
replace_underscores_in_variable_names_with_spaces(variable_names([('Na_me' = Var)]), X). 
X = variable_names(['Na me'=Var]).
*/

/*
fields_to_numeric([NameString, Atom | Fields_Rest], [NameString, Number | Numeric_Fields_Rest]) :-
	atom_number(Atom, Number),
	fields_to_numeric(Fields_Rest, Numeric_Fields_Rest).
	
fields_to_numeric([], []).
*/

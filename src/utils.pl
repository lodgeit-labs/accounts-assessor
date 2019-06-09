% this gets the children of an element with ElementXPath
inner_xml(Dom, Element_XPath, Children) :-
	xpath(Dom, Element_XPath, element(_,_,Children)).

write_tag(Tag_Name,Tag_Value) :-
	string_concat("<",Tag_Name,Open_Tag_Tmp),
	string_concat(Open_Tag_Tmp,">",Open_Tag),
	string_concat("</",Tag_Name,Closing_Tag_Tmp),
	string_concat(Closing_Tag_Tmp,">",Closing_Tag),
	write(Open_Tag),
	write(Tag_Value),
	writeln(Closing_Tag).

numeric_field(Dom, Name_String, Value) :-
	inner_xml(Dom, //Name_String, [Value_Atom]),
	atom_number(Value_Atom, Value).

/*
fields_to_numeric([NameString, Atom | Fields_Rest], [NameString, Number | Numeric_Fields_Rest]) :-
	atom_number(Atom, Number),
	fields_to_numeric(Fields_Rest, Numeric_Fields_Rest).
	
fields_to_numeric([], []).
*/
	
fields(Dom, [Name_String, Value|Rest]) :-
	(
		(
			inner_xml(Dom, //Name_String, [Value]),
			!
		);
		(
			string_concat(Name_String, " field missing", Error),
			throw(Error)
		)
	),
	fields(Dom, Rest).

fields(_, []).

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




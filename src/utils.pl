% this gets the children of an element with ElementXPath
inner_xml(DOM, ElementXPath, Children) :-
	xpath(DOM, ElementXPath, element(_,_,Children)).

write_tag(TagName,TagValue) :-
	string_concat("<",TagName,OpenTagTmp),
	string_concat(OpenTagTmp,">",OpenTag),
	string_concat("</",TagName,ClosingTagTmp),
	string_concat(ClosingTagTmp,">",ClosingTag),
	write(OpenTag),
	write(TagValue),
	writeln(ClosingTag).

numeric_field(DOM, NameString, Value) :-
	inner_xml(DOM, //NameString, [ValueAtom]),
	atom_number(ValueAtom, Value).

/*
fields_to_numeric([NameString, Atom | Fields_Rest], [NameString, Number | Numeric_Fields_Rest]) :-
	atom_number(Atom, Number),
	fields_to_numeric(Fields_Rest, Numeric_Fields_Rest).
	
fields_to_numeric([], []).
*/
	
fields(DOM, [NameString, Value|Rest]) :-
	(
		(
			inner_xml(DOM, //NameString, [Value]),
			!
		);
		(
			string_concat(NameString, " field missing", Error),
			throw(Error)
		)
	),
	fields(DOM, Rest).

fields(_, []).

numeric_fields(DOM, [NameString, Value|Rest]) :-
	(
		(
			numeric_field(DOM, NameString, Value),
			!
		);
		(
			string_concat(NameString, " field missing", Error),
			throw(Error)
		)
	),
	numeric_fields(DOM, Rest).

numeric_fields(_, []).

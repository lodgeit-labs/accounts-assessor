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

field(DOM, NameString, ValueAtom) :-
	inner_xml(DOM, //NameString, [ValueAtom]).

numeric_fields(_, []).

numeric_fields(DOM, [NameString, Value|Rest]) :-
	field(DOM, NameString, ValueAtom),
	atom_number(ValueAtom, Value),
	numeric_fields(DOM, Rest).
	
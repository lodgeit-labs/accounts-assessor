
sanitize_xml_comment(In, Out) :-
	string_chars(In, Chars),
	sanitize_xml_comment2(Chars, Chars_Out),
	string_chars(Out, Chars_Out).

print_xml_comment(String) :-
	string(String),
	print_xml_comment_string(String),
	!.

print_xml_comment(Term) :-
	term_string(Term, String, [quoted(false)]),
	print_xml_comment_string(String),
	!.

print_xml_comment_string(String) :-
	sanitize_xml_comment(String, Comment),
	format('<!-- ~w -->\n', [Comment]).

sanitize_xml_comment2(In, Out) :-
	append(Head, ['-', '-'|Rest], In),
	append(Head, ['(','-',')','(','-',')'|Chars_Out_Rest], Out),
	sanitize_xml_comment2(Rest, Chars_Out_Rest),
	!.

sanitize_xml_comment2(X, X).




sane_xml_write(Stream, Xml) :-
	sane_xml(Xml, Xml2),
	xml_write(Stream, Xml2, []).

sane_xml(In, Out) :-
	is_list(In),
	flatten(In, F),
	exclude(var, F, In2),
	maplist(sane_xml, In2, X),
	flatten(X, Out),!.

sane_xml(element(Tag, Attrs1, Children1), element(Tag, Attrs4, Children4)) :-
	flatten(Attrs1, Attrs2),
	flatten(Children1, Children2),
	exclude(var, Attrs2, Attrs3),
	exclude(var, Children2, Children3),
	maplist(sane_attr, Attrs3, Attrs4),
	maplist(sane_xml, Children3, Children4),!.

sane_xml(X, X) :-
	string(X),!.

sane_xml(X, X) :-
	atomic(X),!.

sane_xml(In, Out) :-
	throw(failed_sanitizing_xml(In, Out)).

sane_attr(K=sane_id(V), K=Sane_V) :-
	sane_id(V, Sane_V),!.

sane_attr(X,X).

/* create or find a sanitized id usable in xml, given any term */

sane_id(Id, Prefix, Sane) :-
	doc(Id, l:sane, (Prefix,Sane), xml),!.

sane_id(Id, Prefix, Sane) :-
	sane_xml_element_id_from_term(Id, Prefix, Sane),
	doc_add(Id, l:sane, (Prefix,Sane), xml),!.

sane_id(Id, Sane) :-
	sane_id(Id, '', Sane).

sane_xml_element_id_from_term(Term, Prefix, Id) :-
	round_term(Term, Term2),
	term_string(Term2, String, [quoted(false)]),
	atomics_to_string([Prefix, String], String2),
	string_codes(String2, [H|T]),
	`_` = [Underscore],
	replace_char_if_not(xmlNameStartChar, Underscore, H, H2),
	maplist(replace_char_if_not(xmlNameChar, Underscore), T, T2),
	string_codes(Id, [H2|T2]).

xmlNameStartChar(X) :- member(X, `:_`).
xmlNameStartChar(X) :- char_type(X, alnum).

/*						 | [#xC0-#xD6] |
                          [#xD8-#xF6] | [#xF8-#x2FF] |
                          [#x370-#x37D] | [#x37F-#x1FFF] |
                          [#x200C-#x200D] | [#x2070-#x218F] |
                          [#x2C00-#x2FEF] | [#x3001-#xD7FF] |
                          [#xF900-#xFDCF] | [#xFDF0-#xFFFD] |
                          [#x10000-#xEFFFF]*/

xmlNameChar(X) :- xmlNameStartChar(X).
 xmlNameChar(X) :- member(X, `-.`).

/*
      					| #xB7 |
                        [#x0300-#x036F] | [#x203F-#x2040]*/

% https://stackoverflow.com/questions/1077084/what-characters-are-allowed-in-dom-ids

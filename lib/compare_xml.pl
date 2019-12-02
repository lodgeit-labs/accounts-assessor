% ===================================================================
% Project:   LodgeiT
% Date:      2019-07-09
% ===================================================================

:- module(compare_xml, [run/2, compare_xml_dom/2, compare_xml_dom/3]).

%--------------------------------------------------------------------
% Modules
%--------------------------------------------------------------------

:- asserta(user:file_search_path(library, '../prolog_xbrl_public/xbrl/prolog')).
:- use_module(library(xbrl/utils), []).
:- use_module(library(xpath)).


% compare_xml_files
run(RPath1, RPath2) :-
	writeln("run"),
	absolute_file_name(RPath1, APath1, [access(read)]),
	writeln(APath1),
	absolute_file_name(RPath2, APath2, [access(read)]),
	writeln(APath2),
	writeln(""),

	load_xml(APath1, DOM1, [space(sgml)]),
	writeln("DOM1:"),
	writeln(DOM1),
	writeln(""),
	load_xml(APath2, DOM2, [space(sgml)]),
	writeln("DOM2:"),
	writeln(DOM2),
	writeln(""),

	(
		compare_xml_dom(DOM1, DOM2),
		writeln("XMLs equal.")
	;
		compare_xml_dom(DOM1, DOM2, Error),
		writeln(Error)
	).


compare_atoms(A,B,Error,Path, Item) :-
	(
		atom_number(A,A_Num),
		atom_number(B,B_Num),
		float(A_Num),
		float(B_Num),
		!,
		(
			utils:floats_close_enough(A_Num, B_Num)
		;
			atomic_list_concat([A_Num, " != ", B_Num, " at ", Path, "[", Item, "]"], Error)
		)
	;
		(
			A = B
		;
			atomic_list_concat([A, " != ", B, " at ", Path, "[", Item, "]"], Error)
		)
	).

compare_xml_attrs([],[]) :-
	writeln("compare_xml_attrs"),
	writeln("no attributes").

compare_xml_attrs([Attr1 | Attrs1], [Attr2 | Attrs2]) :-
	writeln("compare_xml_attrs"),
	writeln("Attr1:"),
	writeln(Attr1),
	writeln(""),
	writeln("Attr2:"),
	writeln(Attr2),
	writeln(""),
	compare_xml_attrs(Attrs1,Attrs2).

compare_xml_dom([], [], _Error, _Path, _Num) :-!.

% can move some of this stuff into pattern matching in the head w/ multiple rules
% but i'll save that for later
% change this into an xml_diff(DOM1, DOM2, Difference) predicate
% xml_equal(DOM1, DOM2) = xml_diff(DOM1, DOM2, [])
/*
compare_xml_dom([_ | _], [], 'element count differs, _, _).
compare_xml_dom([], [_|_], 'element count differs, _, _).
*/
compare_xml_dom(Elements1, Elements2, Error, Path, Num) :-
	(
		(
			length(Elements1, Len),
			length(Elements2, Len)
		)
	->
		(	
			Elements1 = [Elem1 | Siblings1], 
			Elements2 = [Elem2 | Siblings2],
			(
				Elem1 = element(Tag1, Attrs1,Children1),
				Elem2 = element(Tag2, Attrs2,Children2),
				!,
				(
					Tag1 = Tag2,
					!,
					(
						% 
						Attrs1 = Attrs2,
						!,
						atomic_list_concat([Path,"/",Tag1],Path_Tag1),
						compare_xml_dom(Children1, Children2, Error, Path_Tag1,0),
						(
							var(Error),
							!,
							Next_Num is Num + 1,
							compare_xml_dom(Siblings1, Siblings2, Error, Path, Next_Num)
						;
							true
						)
					;
					(
						term_string(Attrs1, Attrs1_Str, []),
						term_string(Attrs2, Attrs2_Str, []),
						atomic_list_concat(["Attributes don't match at ", Path, "/", Tag1, "[", Num, "]:\n", Attrs1_Str, ' vs \n', Attrs2_Str], Error)
					)
					)
				;
					atomic_list_concat(["Tags don't match: ", Tag1, " and ", Tag2, " at ", Path, "[", Num, "]"], Error)
				)
			;
				atom(Elem1),
				atom(Elem2),
				compare_atoms(Elem1, Elem2, Error, Path, Num),
				(
					var(Error),
					!,
					Next_Num is Num + 1,
					compare_xml_dom(Siblings1,Siblings2, Error, Path, Next_Num)
				;
					true
				)
			)
		)
		;
		(
			Error = 'element counts differ'
		)
	).

compare_xml_dom(A, B, Error) :-
	compare_xml_dom(A, B, Error, "", 0).

compare_xml_dom(A, B) :-
	compare_xml_dom(A, B, Error),
	var(Error).

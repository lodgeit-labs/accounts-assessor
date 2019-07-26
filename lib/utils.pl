:- module(utils, [
		user:goal_expansion/2, 
		inner_xml/3, 
		open_tag/1, 
		close_tag/1, 
		write_tag/2, 
		fields/2, 
		field_nothrow/2, 
		numeric_fields/2, 
		pretty_term_string/2, 
		trim_atom/2, 
		maplist6/6, 
		throw_string/1, 
		semigroup_foldl/3,
		get_indentation/2,
		without_nonalphanum_chars/2,
		floats_close_enough/2,
		coord_is_almost_zero/1]).

		
:- use_module(library(xpath)).


:- multifile user:goal_expansion/2.
:- dynamic user:goal_expansion/2.


/*executed at compile time, passess X through, and binds Names to info suitable for term_string*/	

user:goal_expansion(
	compile_with_variable_names_preserved(X, variable_names(Names))
, X) :-
	term_variables(X, Vars),
	maplist(my_variable_naming, Vars, Names).

/*compile_with_variable_names_preserved usage:
x([S2,' ', S3,' ', S4]) :-
	compile_with_variable_names_preserved((
		AC=4444*X,
		X = Z/3,
		true
	), Namings),
	compile_with_variable_names_preserved((
		AC=4444*X,
		X = Z/3,
		true
	), Namings),
	Z = 27,
	writeln(''),
	print_term(AC, [Namings]),
	writeln(''),
	compile_with_variable_names_preserved((
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

/*
goal_expansion of magic_formula this takes X, which is the parsed terms, and returns Code, at compile time.
Code can actually be printed out, and we should probably split this into two phases,
where the first generates an actual source file.
At any case there are some tradeoffs to consider, and i think this is more of a fun hack that can get
some simple calculators into production quickly, not a perfect solution.
*/
user:goal_expansion(
	magic_formula(X), Code
) :-
	term_variables(X, Vars),
	maplist(my_variable_naming, Vars, Names),
	Namings = variable_names(Names),
	expand_formulas(Namings, X, [], Expansions),
	expand_formulas_to_code(Expansions, Code)/*,
	Code = (AAA,BBB,_),
	writeln(AAA),
	writeln('------'),
	writeln(BBB),
	writeln('------')*/.

expand_formulas_to_code([], (true)).
	
expand_formulas_to_code([H|T], Expansion) :-
	H = (New_Formula, S1, Description, _A),
	New_Formula = (V is Rhs),
	Expansion = ((
		writeln(''),
		%write('<!-- '), write(S1), writeln(': -->'),
		write('<!-- '), writeln(' -->'),
		assertion(ground(((S1,Rhs)))),
		New_Formula,
		/*nonvar(V), silence singleton variable warning, doesn't work */ 
		utils:open_tag(S1),  format('~2f', [V]), utils:close_tag(S1), 
		write_tag([S1, '_Formula'], Description),
		term_string(Rhs, A_String),
		atomic_list_concat([S1, ' = ', A_String], Computation_String),
		write_tag([S1, '_Computation'], Computation_String)
		), Tail),
	expand_formulas_to_code(T, Tail).

expand_formula(Namings, (A=B), _Es_In, ((A is B), S1, Description, A)):-
	term_string(A, S1, [Namings]),
	term_string(B, S2, [Namings]),
	atomic_list_concat([S1, ' = ', S2], Description).

expand_formulas(Namings, (F, Fs), Es_In, Es_Out) :-
	expand_formula(Namings, F, Es_In, E),
	append(Es_In, [E], Es2),
	expand_formulas(Namings, Fs, Es2, Es_Out),!.

expand_formulas(Namings, F,  Es_In, Es_Out) :-
	expand_formula(Namings, F, Es_In, E),
	append(Es_In, [E], Es_Out).
		
my_variable_naming(Var, (Name = Var)) :-
	var_property(Var, name(Name)).
		





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


write_tag(Tag_Name_Input,Tag_Value) :-
	flatten([Tag_Name_Input], Tag_Name_List),
	atomic_list_concat(Tag_Name_List, Tag_Name),
	string_concat("<",Tag_Name,Open_Tag_Tmp),
	string_concat(Open_Tag_Tmp,">",Open_Tag),
	string_concat("</",Tag_Name,Closing_Tag_Tmp),
	string_concat(Closing_Tag_Tmp,">",Closing_Tag),
	write(Open_Tag),
	write(Tag_Value),
	writeln(Closing_Tag).

open_tag(Name) :-
	flatten(['<', Name, '>'], L),
	atomic_list_concat(L, S),
	write(S).

close_tag(Name) :-
	flatten(['</', Name, '>\n'], L),
	atomic_list_concat(L, S),
	write(S).

	
numeric_field(Dom, Name_String, Value) :-
	trimmed_field(Dom, //Name_String, Value_Atom),
	atom_number(Value_Atom, Value).


/* take a list of field names and variables that the contents extracted from xml are bound to
a (variable, default value) tuple can also be passed */
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

/* if default is not passed, throw error if field's tag is not found*/
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


/* try to extract a field, possibly fail*/
field_nothrow(Dom, [Name_String, Value]) :-
	trimmed_field(Dom, //Name_String, Value).

/* extract fields and convert to numbers*/
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


/* pretty-print term with print_term, capture the output into a string*/
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



/* standard library only has maplist up to arity 5, maplist/6 is not in standard library */
:- meta_predicate maplist6(6, ?, ?, ?, ?, ?).
:- meta_predicate maplist6_(?, ?, ?, ?, ?, 6).

maplist6(Goal, List1, List2, List3, List4, List5) :-
    maplist6_(List1, List2, List3, List4, List5, Goal).

maplist6_([], [], [], [], [], _).

maplist6_([Elem1|Tail1], [Elem2|Tail2], [Elem3|Tail3], [Elem4|Tail4], [Elem5|Tail5], Goal) :-
    call(Goal, Elem1, Elem2, Elem3, Elem4, Elem5),
    maplist6_(Tail1, Tail2, Tail3, Tail4, Tail5, Goal).


    
/*Like foldl, but without initial value. No-op on zero- and one- item lists.*/
:- meta_predicate semigroup_foldl(3, ?, ?).
semigroup_foldl(_Goal, [], []).

semigroup_foldl(_Goal, [Item], [Item]).

semigroup_foldl(Goal, [H1, H2 | T], V) :-
    call(Goal, H1, H2, V1),
    semigroup_foldl(Goal, [V1 | T], V).




   
/* throw a string(Message) term, these errors are caught by our http server code and turned into nice error messages */
throw_string(List_Or_Atom) :-
	flatten([List_Or_Atom], List),
	atomic_list_concat(List, String),
	throw(string(String)).


get_indentation(Level, Indentation) :-
	Level > 0,
	Level2 is Level - 1,
	get_indentation(Level2, Indentation2),
	atomic_list_concat([Indentation2, ' '], Indentation).

get_indentation(0, ' ').

without_nonalphanum_chars(Atom1, Atom2) :-
	atom_chars(Atom1, Atom1_Chars),
	maplist(replace_nonalphanum_char_with_underscore, Atom1_Chars, Atom2_Chars),
	atom_chars(Atom2, Atom2_Chars).
	
replace_nonalphanum_char_with_underscore(Char1, Char2) :-
	char_type(Char1, alnum)
		->
	Char1 = Char2
		;
	Char2 = '_'.
	
	
	
% define the value to compare expected float value with the actual float value
% we need this value as float operations generate different values after certain precision in different machines
float_comparison_max_difference(0.00000001).
	
floats_close_enough(Value1, Value2) :-
	float_comparison_max_difference(Max),
	ValueDifference is abs(Value1 - Value2),
	ValueDifference =< Max.

coord_is_almost_zero(coord(_, D, C)) :-
	floats_close_enough(D, 0),
	floats_close_enough(C, 0).


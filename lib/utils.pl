:- module(utils, [
		user:goal_expansion/2, 
		/*user:goal_expansion(dict_vars(Dict, Vars_List), Code)*/
		/*user:goal_expansion(dict_from_vars(Dict, Vars_List), Code)*/
		/*user:goal_expansion(magic_formula(X), Code)*/
		/*user:goal_expansion(compile_with_variable_names_preserved(X, variable_names(Names)), X)*/
		inner_xml/3, 
		inner_xml_throw/3,
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
		replace_nonalphanum_chars_with_underscore/2,
		floats_close_enough/2,
		replace_chars_in_atom/4,
		filter_out_chars_from_atom/3,
		is_uri/1,
		sort_into_dict/3,
		capitalize_atom/2,
		path_get_dict/3,
		report_currency_atom/2,
		  dict_json_text/2,
		  catch_maybe_with_backtrace/3,
		  find_thing_in_tree/4]).


		
:- use_module(library(http/json)).
:- use_module(library(xpath)).
:- use_module(library(rdet)).


:- rdet(report_currency_atom/2).


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
	writeln('------')
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
		


		
/* take a list of variables, produce a dict with lowercased variable names as keys, and variables themselves as values.
see plunit/utils for examples*/
user:goal_expansion(
	dict_from_vars(Dict, Vars_List), Code
) :-
	maplist(var_to_kv_pair, Vars_List, Pairs),
	Code = dict_create(Dict, _, Pairs).

user:goal_expansion(
	dict_from_vars(Dict, Name, Vars_List), Code
) :-
	maplist(var_to_kv_pair, Vars_List, Pairs),
	Code = dict_create(Dict, Name, Pairs).

var_to_kv_pair(Var, Pair) :-
	var_property(Var, name(Name)),
	downcase_atom(Name, Name_Lcase),
	Pair = Name_Lcase-Var.

/* take a list of variables, unify them with values of Dict, using lowercased names of those variables as keys.
see plunit/utils for examples*/
user:goal_expansion(
	dict_vars(Dict, Vars_List), Code
) :-
	dict_vars_assignment(Vars_List, Dict, Code).

user:goal_expansion(
	dict_vars(Dict, Tag, Vars_List), Code
) :-
	Code = (is_dict(Dict, Tag), Code0),
	dict_vars_assignment(Vars_List, Dict, Code0).

dict_vars_assignment([Var|Vars], Dict, Code) :-
	var_property(Var, name(Key)),
	downcase_atom(Key, Key_Lcase),
	
	%Code0 = get_dict_ex(Key_Lcase, Dict, Var), % not supported in some versions?
	Code0 = ((get_dict(Key_Lcase, Dict, Var)->true;throw(existence_error(key, Key_Lcase, Dict)))),
	
	Code = (Code0, Codes),
	dict_vars_assignment(Vars, Dict, Codes).

dict_vars_assignment([], _, true).
	
	
	
	
	

% this gets the children of an element with ElementXPath
inner_xml(Dom, Element_XPath, Children) :-
	xpath(Dom, Element_XPath, element(_,_,Children)).

inner_xml_throw(Dom, Element_XPath, Children) :-
	(
		xpath(Dom, Element_XPath, element(_,_,Children))
	->
		true
	;
		(
			pretty_term_string(Element_XPath, Element_XPath_Str),
			throw_string(['element missing:', Element_XPath_Str])
		)
	).
	
trimmed_field(Dom, Element_XPath, Value) :-
	xpath(Dom, Element_XPath, element(_,_,[Child_Atom])),
	trim_atom(Child_Atom, Value).
	
trim_atom(Atom, Trimmed_Atom) :-
	atom_string(Atom, Atom_String),
	trim_string(Atom_String, Trimmed_String),
	%split_string(Atom_String, "", "\s\t\n", [Trimmed_String]),
	atom_string(Trimmed_Atom, Trimmed_String).

trim_string(String, Trimmed_String) :-
	split_string(String, "", "\s\t\n", [Trimmed_String]).

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
			pretty_term_string(Name_String, Pretty_Name_String),
			atomic_list_concat([Pretty_Name_String, " field missing in ", Dom_String], Error),
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


dict_json_text(Dict, Text) :-
	new_memory_file(X),
	open_memory_file(X, write, S),
	json_write(S, Dict, [serialize_unknown(true)]),
	close(S),
	memory_file_to_string(X, Text).

:- multifile term_dict/4.
term_dict(
	coord(U, D, C),
	coord{unit:U, debit:D, credit:C}
).
	
json:json_write_hook(Term, Stream, _, _) :-
	term_dict(Term, Dict),
	json_write(Stream, Dict, [serialize_unknown(true)]).

	
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

replace_nonalphanum_chars_with_underscore(Atom1, Atom2) :-
	atom_chars(Atom1, Atom1_Chars),
	maplist(replace_nonalphanum_char_with_underscore, Atom1_Chars, Atom2_Chars),
	atom_chars(Atom2, Atom2_Chars).
	
capitalize_atom(Atom1, Atom2) :-
	atom_chars(Atom1, Atom1_Chars),
	[First_Char|Atom1_Chars_Rest] = Atom1_Chars,
	char_type(Upper, to_upper(First_Char)),
	[Upper|Atom1_Chars_Rest] = Atom2_Chars,
	atom_chars(Atom2, Atom2_Chars).
	
replace_nonalphanum_char_with_underscore(Char1, Char2) :-
	char_type(Char1, alnum)
		->
	Char1 = Char2
		;
	Char2 = '_'.


:- meta_predicate replace_chars_in_atom(1, +, +, -).

replace_chars_in_atom(Predicate, Replacement, Atom_In, Atom_Out) :-
	atom_chars(Atom_In, Atom1_Chars),
	maplist(replace_char_if(Predicate, Replacement), Atom1_Chars, Atom2_Chars),
	atom_chars(Atom_Out, Atom2_Chars).

replace_char_if(Predicate, Replacement, Char_In, Char_Out) :-
	call(Predicate, Char_In) -> Char_Out = Char_In ; Char_Out = Replacement.

not_alnum(Char) :-
	char_type(Char, alnum).


%whitespace_chars("\s\t\n").



:- meta_predicate filter_out_chars_from_atom(1, +, -).

filter_out_chars_from_atom(Predicate, Atom_In, Atom_Out) :-
	atom_chars(Atom_In, Atom1_Chars),
	findall(
		[Char],
		member(Char, Atom1_Chars),
		Char_Lists),
	maplist(atom_chars, Atom1_Char_Atoms, Char_Lists),
	exclude(Predicate, Atom1_Char_Atoms, Atom2_Char_Atoms),
	atomic_list_concat(Atom2_Char_Atoms, Atom_Out).
	

	
% define the value to compare expected float value with the actual float value
% we need this value as float operations generate different values after certain precision in different machines
float_comparison_max_difference(0.000001).
	
floats_close_enough(Value1, Value2) :-
	float_comparison_max_difference(Max),
	ValueDifference is abs(Value1 - Value2),
	ValueDifference =< Max.

is_uri(URI) :-
	% atom_prefix is deprecated
	atom_prefix(URI,"http").


% basically "index by" Selector_Predicate (or really the values of the 2nd arg to it)
sort_into_dict(Selector_Predicate, Ts, D) :-
	sort_into_dict(Selector_Predicate, Ts, _{}, D).

:- meta_predicate sort_into_dict(2, ?, ?, ?).

sort_into_dict(Selector_Predicate, [T|Ts], D, D_Out) :-
	call(Selector_Predicate, T, A),
	(
		L = D.get(A)
	->
		true
	;
		L = []
	),
	append(L, [T], L2),
	D2 = D.put(A, L2),
	sort_into_dict(Selector_Predicate, Ts, D2, D_Out).

sort_into_dict(_, [], D, D).

path_get_dict((X/Y), Dict, Y_Value) :-
	path_get_dict(X, Dict, X_Value),
	path_get_dict(Y, X_Value, Y_Value).

path_get_dict(K, Dict, V) :-
	K \= (_/_),
	get_dict(K, Dict, V).

	
	
report_currency_atom(Report_Currency_List, Report_Currency_Atom) :-
	(
		Report_Currency_List = [Report_Currency]
	->
		atomic_list_concat(['(', Report_Currency, ')'], Report_Currency_Atom)
	;
		Report_Currency_Atom = ''
	).

/*catch_with_backtrace doesnt exist on older swipl's*/
catch_maybe_with_backtrace(A,B,C) :-
	(
		current_predicate(catch_with_backtrace/3)
	->
		catch_with_backtrace(A,B,C)
	;
		catch(A,B,C)
	).
	

:- meta_predicate find_thing_in_tree(?, 2, 3, ?).

find_thing_in_tree(Root, Matcher, _, Root) :-
	call(Matcher, Root).
						 
find_thing_in_tree([Entry|_], Matcher, Children_Yielder, Thing) :-
	find_thing_in_tree(Entry, Matcher, Children_Yielder, Thing).
	
find_thing_in_tree([_|Entries], Matcher, Children_Yielder, Thing) :-
	find_thing_in_tree(Entries, Matcher, Children_Yielder, Thing).	
				 
find_thing_in_tree(Root, Matcher, Children_Yielder, Thing) :-
	call(Children_Yielder, Root, Child),
	find_thing_in_tree(Child, Matcher, Children_Yielder, Thing).
	
						 

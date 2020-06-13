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
		open_tag(S1),  format('~2f', [V]), close_tag(S1),
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

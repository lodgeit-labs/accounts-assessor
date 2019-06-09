
my_variable_naming(Var, (Name = Var)) :-
	var_property(Var, name(Name)).
	
goal_expansion(described_formula(X, variable_names(Namings)), X) :-
	term_variables(X, Vars),
	maplist(my_variable_naming, Vars, Namings).

/*
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


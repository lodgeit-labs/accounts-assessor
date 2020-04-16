:- use_module(library(fnotation)).
:- fnotation_ops($>,<$).
:- op(900,fx,<$).

:- ['../../public_lib/xbrl/prolog/xbrl/compile_with_variable_names_preserved.pl'].

user:term_expansion(
	p(X)
,
	p(X, Names)
) :-
	term_variables(X, Vars),
	maplist(try_get_variable_naming, Vars, Names).

try_get_variable_naming(Var, (Name = Var)) :-
	var_property(Var, name(Name)),
	!.
try_get_variable_naming(Var, ('_' = Var)).



collect_rules :-

	/* make sure no  */
	(
		(
				catch(p(Bad),_,false),
				throw('p/1 declaration remained unexpanded'(Bad))
		);
		true
	),


	p(Decl, Names),
	print_term(Decl, [variable_names(Names)]),
	nl,nl,
	fail.
collect_rules2 :-
	p(Decl),
	print_term(Decl,[]),
	fail.

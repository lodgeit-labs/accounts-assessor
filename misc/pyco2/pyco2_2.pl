:- use_module(library(semweb/rdf11),except(['{}'/1])).
:- use_module(library(fnotation)).
:- fnotation_ops($>,<$).
:- op(900,fx,<$).

:- ['../../public_lib/xbrl/prolog/xbrl/compile_with_variable_names_preserved.pl'].

user:term_expansion(P, pyco2_2_rule(Id, Head, Body, Notes, Cnls, Names)) :-
	P =.. [r|X],
	gensym(r, Id),
	term_variables(P, Vars),
	maplist(try_get_variable_naming, Vars, Names),
	p_decl_to_rule2(X, Head, Body, Notes, Cnls),
	assertion(nonvar(Head)).


try_get_variable_naming(Var, (Name = Var)) :-
	var_property(Var, name(Name)),
	!.
try_get_variable_naming(Var, ('_' = Var)).



collect_rules :-

	/* make sure no 'p' declarations reamined unexpanded */
	(
		(
				catch(p(Bad),_,false),
				throw('p/1 declaration remained unexpanded'(Bad))
		);
		true
	),

	pyco2_2_rule(Id, Head, Body, Notes, Cnls, Names),
	print_term(pyco2_2_rule(Id, Head, Body, Notes, Cnls), [variable_names(Names)]),
	nl,nl,
	fail.

/*collect_rules2 :-
	p(Decl),
	print_term(Decl,[]),
	fail.*/



/*
we'll use use Id in place of Desc (for ep identification etc).
*/
p_decl_to_rule2([H|T], Head, Body, Notes, Cnls) :-
	H = bc,!,
	p_decl_to_rule2([n - bc|T], Head, Body, Notes, Cnls).

p_decl_to_rule2([H|T], Head, Body, [Note|Notes], Cnls) :-
	H = n - Note,!,
	p_decl_to_rule2(T, Head, Body, Notes, Cnls).

p_decl_to_rule2([H|T], Head, Body, Notes, [(Lang - Cnl)|Cnls]) :-
	H = Lang - Cnl,!,
	p_decl_to_rule2(T, Head, Body, Notes, Cnls).

p_decl_to_rule2([H|T], Head, Body, Notes, Cnls) :-
	var(Head),!,
	flatten([H], Head),
	p_decl_to_rule2(T, Head, Body, Notes, Cnls).

p_decl_to_rule2([H|T], Head, [Body_head|Body_tail], Notes, Cnls) :-
	Body_head = H,
	p_decl_to_rule2(T, Head, Body_tail, Notes, Cnls).

p_decl_to_rule2([], _Head, [], [], []).









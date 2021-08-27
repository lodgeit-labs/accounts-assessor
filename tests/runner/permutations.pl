

:- use_module(library(fnotation)).
:- fnotation_ops($>,<$).
:- op(900,fx,<$).


saved_testcase(1).
saved_testcase(2).


parameters_permutation(Params_dict) :-
	saved_testcase(Testcase),

	member(Mode, ['remote', 'subprocess']),

	(	Mode == 'subprocess'
	->	member(Die_on_error, [true, false])
	;	true),

	Vars = [
		testcase-Testcase,
		mode-Mode,
		die_on_error-Die_on_error
	],
	foldl(add_ground_parameter_to_dict, Vars, params{}, Params_dict).


add_ground_parameter_to_dict(Name-Var, In, Out) :-
	ground(Var),
	Out = In.put(Name,Var).


add_ground_parameter_to_dict(_-Var, In, In) :-
	var(Var).

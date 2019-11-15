#!/usr/bin/env swipl

:- use_module(utils).

/*
running this takes a while because it first does just a load to find compile errors, and then runs swipl again to actually execute goal. Maybe next version will consult Script directly, but idk how to eval() a goal, except by parsing it first..
*/

shell2(Cmd) :-
	shell2(Cmd, _).

shell2(Cmd_In, Exit_Status) :-
	flatten([Cmd_In], Cmd_Flat),
	atomic_list_concat(Cmd_Flat, Cmd),
	%format(user_error, '~w\n\n', [Cmd]),
	shell(Cmd, Exit_Status).

maybe_halt_on_err :- 
	opts(Opts),
	memberchk(halt_on_problems(Halt), Opts),
	(
		Halt = true
	->
		halt_on_problems
	;
		true
	).

halt_on_problems :-
	opts(Opts),
	(
		(memberchk(problem_lines_whitelist(Whitelist_File), Opts), nonvar(Whitelist_File))
	->
		Err_Grep = ['grep -E -i "Warn|err" err | grep -q -v -x -F -f ', Whitelist_File]
	;
		Err_Grep = 'grep -q -E -i "Warn|err" err'
	),
	(
		shell2(Err_Grep, 0)
	 ->
	 	(
			format(user_error, "that's an error, halting.\n", []),
	 		halt 
		)
	;
		true
	).

maybe_clean_terminal :-
	opts(Opts),
	memberchk(clear_terminal(Clear), Opts),
	(
		Clear = true
	->
		(
			shell2('echo "\e[3J" 1>&2'),
			shell2('timeout 3 reset')

		)
	;
		true
	).

x(Source_File, Goal) :-
	format(user_error, '============...\n', []),
	opts(Opts),
	memberchk(debug(Debug), Opts),
	(
		Debug = true
	->
		Optimization = ''
	;
		Optimization = '-O'
	),
	atomic_list_concat(['swipl ', Optimization, ' -s ', Source_File], Load_Cmd),
	maybe_clean_terminal,
	shell2([Load_Cmd, ' -g "halt."  2>&1  |  tee err']),
	maybe_halt_on_err,
	format(user_error, 'ok...\n', []),
	shell2([Load_Cmd, ' -g "', Goal, ', halt."  2>&1 1> arrr.xml | tee err']),
	maybe_halt_on_err,
	opts(Opts),
	memberchk(viewer(Viewer), Opts),
	shell2([Viewer, ' arrr.xml']),
	halt.

:- 
	Spec = [
		[opt(viewer), type(atom), default(vim), shortflags([v]), longflags([viewer])]
		,[opt(debug), type(boolean), default(true), shortflags([d]), longflags([debug])]
		,[opt(halt_on_problems), type(boolean), default(true), shortflags([h]), longflags([halt_on_problems])]
		,[opt(problem_lines_whitelist), type(atom), longflags([problem_lines_whitelist])]
		,[opt(clear_terminal), type(boolean), default(false), shortflags([c]), longflags([clear_terminal])]
	],
	opt_arguments(Spec, Opts, Args0),
	(Args0 = ['--'|Args]; Args = Args0),
	assert(opts(Opts)),
	compile_with_variable_names_preserved(
		Expected_Args = [Source_File, Goal],
		Var_Names
	),
	(
		Expected_Args = Args
	->
		x(Source_File, Goal)
	;
		(
			format(string(Err), 'positional arguments parsing error, ~W expected, found:~k.', [Expected_Args, [Var_Names], Args]),
			throw(exception(Err))
		)
	),
	halt.

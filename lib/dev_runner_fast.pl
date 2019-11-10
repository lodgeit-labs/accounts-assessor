shell2(Cmd) :-
	shell2(Cmd, _).

shell2(Cmd_In, Exit_Status) :-
	flatten([Cmd_In], Cmd_Flat),
	atomic_list_concat(Cmd_Flat, Cmd),
	format(user_error, '~w\n\n', [Cmd]),
	shell(Cmd, Exit_Status).

halt_on_err :-
	Err_Grep = 'grep -q -E -i "Warn|err" err',
	(shell2(Err_Grep, 0) -> halt ; true).

clean_terminal :-
	shell2('echo "\e[3J" 1>&2'),
	shell2('reset').

x :-
	current_prolog_flag(argv, Argv), 
	(
		(
			Argv=[Viewer, Script, Goal]
		;
			Argv=['--', Viewer, Script, Goal] % swipl 8.1.11 weirdness
		)
	->
		true
	;
		(
			format(user_error, 'argument parsing failed.', []),
			halt
		)
	),
	atomic_list_concat(['swipl -O -s ', Script], Load_Cmd),
	%clean_terminal,
	shell2([Load_Cmd, ' -g "halt."  2>&1  |  tee err']),
	halt_on_err,
	format(user_error, 'ok...\n', []),
	shell2([Load_Cmd, ' -g "', Goal, ', halt."  2>&1 1> arrr.xml | tee err']),
	halt_on_err,
	shell2([Viewer, ' arrr.xml']),
	halt.

:- x.


/*

running this takes a while because it first does just a load to find compile errors, and then runs swipl again to actually execute goal. Maybe next version will consult Script directly, but idk how to eval() a goal, except by parsing it first..

*/

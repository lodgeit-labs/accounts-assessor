shell2(Cmd) :-
	shell2(Cmd, _).

shell2(Cmd_In, Exit_Status) :-
	flatten([Cmd_In], Cmd_Flat),
	atomic_list_concat(Cmd_Flat, Cmd),
	%write(Cmd), writeln('   ...'),
	shell(Cmd, Exit_Status).

halt_on_err :-
	Err_Grep = 'grep -q -E -i "Warn|err" err',
	(shell2(Err_Grep, 0) -> halt ; true).

clean_terminal :-
	shell2('echo -e "\e[3J"'),
	shell2('reset').

x :-
	((current_prolog_flag(argv, [Viewer, Script, Goal]),!)
		;(format(user_error, 'argument parsing failed.', []), halt)),
	atomic_list_concat(['swipl -s ', Script], Load_Cmd),
	clean_terminal,
	shell2([Load_Cmd, ' -g "halt."  2>&1  |  tee err']),
	halt_on_err,
	shell2([Load_Cmd, ' -g "', Goal, ', halt."  2>&1 1> arrr.xml | tee err']),
	halt_on_err,
	shell2([Viewer, ' arrr.xml']),
	halt.

:- x.

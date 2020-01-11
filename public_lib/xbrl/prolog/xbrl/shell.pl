shell2(Cmd) :-
	shell2(Cmd, _).

shell2(Cmd_In, Exit_Status) :-
	shell3(Cmd_In, [exit_status(Exit_Status)]).

shell3(Cmd_In, Options) :-
	flatten([Cmd_In], Cmd_Flat),
	atomic_list_concat(Cmd_Flat, " ", Cmd),
	(	memberchk(print_command(true), Options)
	->	format(user_error, '~w\n\n', [Cmd])
	;	true),
	shell(Cmd, Exit_Status),
	(	memberchk(exit_status(E), Options)
	->	E = Exit_Status
	;	true),
	(	memberchk(command(C), Options)
	->	C = Cmd
	;	true).

/* for gnome-terminal and ..? */
print_clickable_link(Url, Title) :-
	atomics_to_string([">&2 printf '\e]8;;", Url,"\e\\   ", Title, "   \e]8;;\e\\\n'"],  S), shell2(S).

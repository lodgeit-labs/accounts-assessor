/*:- use_module(library(debug)).

:- multifile
    user:message_hook/3.

:- debug(halt).

user:message_hook(Term, Level, Lines) :-
	(Level = warning;Level = error),
	write('yo '),
	writeq(message_hook(Term, Level, Lines)),
   '$messages':print_system_message(Term, Level, Lines),
   nl.
*/


/*
user:message_hook(Term, Level, Lines) :-
    fatal(Term, Level),
    !,
    '$messages':print_system_message(Term, error, Lines),
    halt(1).
user:message_hook(Term, Level, _Lines) :-
    debug_level(Level),
    debug(halt, 'Got ~p at level ~p', [Term, Level]),
    fail.


debug_level(warning).
debug_level(error).


fatal(_, error).
fatal(goal_failed(directive, _Goal), warning).
fatal(initialization_failure(_Goal, _Ctx), warning).
*/

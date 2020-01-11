
/*
	throw a string(Message) term, these errors are caught by our http server code and turned into nice error messages
*/
throw_string(List_Or_Atom) :-
	flatten([List_Or_Atom], List),
	atomic_list_concat(List, String),
	throw(string(String)).


/*
	catch_with_backtrace doesnt exist on older swipl's
*/
catch_maybe_with_backtrace(A,B,C) :-
	(	current_predicate(catch_with_backtrace/3)
	->	catch_with_backtrace(A,B,C)
	;	catch(A,B,C)).


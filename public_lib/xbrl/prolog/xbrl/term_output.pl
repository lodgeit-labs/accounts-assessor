

/* pretty-print term with print_term, capture the output into a string*/
pretty_term_string(Term, String) :-
	pretty_term_string(Term, String, []).

pretty_term_string(Term, String, Options) :-
	setup_call_cleanup(
		new_memory_file(X),
		(
			open_memory_file(X, write, S),
			print_term(Term, [output(S), write_options([
				numbervars(true),
				quoted(true),
				portray(true)
				| Options])]),
			close(S),
			memory_file_to_string(X, String)
		),
		free_memory_file(X)).

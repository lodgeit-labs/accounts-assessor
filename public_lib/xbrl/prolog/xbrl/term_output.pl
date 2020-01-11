

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



string_to_json(String, Json_Dict) :-
	setup_call_cleanup(
		new_memory_file(X),
		(
			open_memory_file(X, write, W),
			write(W, String),
			close(W),
			open_memory_file(X, read, R),
			json_read_dict(R, Json_Dict),
			close(R)),
		free_memory_file(X)).



:- multifile term_dict/2.

term_dict(
	Value,
	value{unit:U, amount:A}
) :-
	Value=value(_,_),
	round_term(Value,value(U, A)).

json:json_write_hook(Term, Stream, _, _) :-
	term_dict(Term, Dict),
	json_write(Stream, Dict, [serialize_unknown(true)]).

dict_json_text(Dict, Text) :-
	setup_call_cleanup(
		new_memory_file(X),
		(
			open_memory_file(X, write, S),
			json_write(S, Dict, [serialize_unknown(true)/*,todo tag(type)*/]),
			close(S),
			memory_file_to_string(X, Text)
		),
		free_memory_file(X)).

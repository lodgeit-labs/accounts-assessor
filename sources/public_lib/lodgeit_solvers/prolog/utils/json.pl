string_to_json_dict(String, Json_Dict) :-
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

/*
also research:
https://www.swi-prolog.org/pldoc/man?section=termtojson
*/

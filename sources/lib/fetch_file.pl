



 fetch_file_from_url(loc(absolute_url,Url), loc(absolute_path, Path)) :-
	/* fixme ensure the host isnt localhost / local network */
	/*uri_components(Url, Components),
	writeq(Components),nl,*/
	/* fixme https://stackoverflow.com/questions/34301697/curl-from-shell-path-with-spaces */
	services_server_shell_cmd(['curl', Url, '-o', Path]).



 services_rpc(Path, Cmd, Response) :-
	atomics_to_string([$>services_server, '/', Path], Url),
	%merge_dicts(cmd{'jsonrpc':"2.0",'id':"0"}, Cmd, Cmd2),
	json_post(Url, Cmd, Response).



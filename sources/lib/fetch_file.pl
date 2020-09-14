:- use_module(library(http/http_json)).
:- use_module(library(http/json)).
:- use_module(library(http/http_client)).
:- use_module(library(http/http_open)).


services_server(S) :-
	current_prolog_flag(services_server, S).


fetch_file_from_url(loc(absolute_url,Url), loc(absolute_path, Path)) :-
	/* fixme ensure the host isnt localhost / local network */
	/*uri_components(Url, Components),
	writeq(Components),nl,*/
	/* fixme https://stackoverflow.com/questions/34301697/curl-from-shell-path-with-spaces */
	services_server_shell_cmd(['curl', Url, '-o', Path]).

services_server_shell_cmd(Cmd) :-
	format(string(Url), '~w/shell/rpc/', [$>services_server(<$)]),
	debug(shell, 'POST: ~w', Url),
	json_post(Url, _{cmd:Cmd,quiet_success:true}, _).

json_post(Url, Payload, Response) :-
	http_post(Url, json(Payload), Response, [content_type('application/json'), json_object(dict)]).

/*,'method':"agraph_sparql","params":{"sparql":"clear graphs"}}'*/
internal_services_rpc(Cmd, Result) :-
	'='(Url, $>atomics_to_string([$>services_server, '/rpc/'])),
	merge_dicts(cmd{'jsonrpc':"2.0",'id':"curltext"}, Cmd, Cmd2),
	json_post(Url, Cmd2, Response),
	(	get_dict(result, Response, Result)
	->	true
	;	throw(Response)).



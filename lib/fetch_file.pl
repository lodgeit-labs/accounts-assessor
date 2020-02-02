:- use_module(library(http/http_json)).
:- use_module(library(http/json)).
:- use_module(library(http/http_client)).
:- use_module(library(http/http_open)).


services_server(S) :-
	current_prolog_flag(services_server, S).


fetch_file_from_url(loc(absolute_url,Url), loc(absolute_path, Path)) :-
	/* fixme ensure the host isnt localhost / local network */
	/*uri_components(Url, Components),
	gtrace,
	writeq(Components),nl,*/
	services_server_shell_cmd(['curl', Url, '-o', Path]).

services_server_shell_cmd(Cmd) :-
	format(string(Url), '~w/shell/rpc/', [$>services_server(<$)]),
	debug(endpoint_tests, 'POST: ~w', Url),
	json_post(Url, _{cmd:Cmd,quiet_success:true}).

json_post(Url, Payload) :-
	http_post(Url, json(Payload), json(Response), [content_type('application/json')]),
	(	Response.status == ok
	->	true
	;	throw(Response)).


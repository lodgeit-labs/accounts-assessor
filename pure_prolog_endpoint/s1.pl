:- debug.
:- use_module(library(http/http_server)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_header)).
:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).
:- use_module(library(pprint)).


:- ['../src/sbe'].

:- http_handler(root(sbe), sbe_request, [methods([post])]).

server() :-
	http_server(http_dispatch, [port(7777)]).


sbe_request(Request) :-
	http_read_json_dict(Request, Data),
	% term_string(Data, DS),
	sbe(Data, Reply),	
	reply_json(Reply),
	true.

maybe_add_response_to_history(History, Response, HistoryWithResponse) :-
	LastQuestion = dict{question_id: Q, response: -1},
	member(LastQuestion, History),
	select(LastQuestion, History, History2),
	append([dict{question_id: Q, response: Response}], History2, HistoryWithResponse), !.
		
maybe_add_response_to_history(History, _Response, History).

sbe(In, Out) :-
	maybe_add_response_to_history(In.current_state, In.response, History),
	Out = json([current_state=History]),
	true.
	

:- server.
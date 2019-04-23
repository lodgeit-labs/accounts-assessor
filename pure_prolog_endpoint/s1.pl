% The original nomenclature is by now a bit confusing. "state" is a list of {question_id, response} objects.



:- debug.
:- use_module(library(http/http_server)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_header)).
:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).
:- use_module(library(pprint)).


:- ['../src/sbe'].

:- http_handler(root(sbe), sbe_request, [methods([post]), workers(0)]).

server() :-
	http_server(http_dispatch, [port(7777)]).


sbe_request(Request) :-
	http_read_json_dict(Request, Data),
	% term_string(Data, DS),
	sbe(Data, Reply),	
	reply_json(Reply),
	true.

match_response_with_last_question(dict{current_state: History, response: Response}, HistoryWithResponse, CurrentQuestionId) :-
	LastQuestion = dict{question_id: CurrentQuestionId, response: -1},
	member(LastQuestion, History),
	select(LastQuestion, History, History2),
	append([dict{question_id: CurrentQuestionId, response: Response}], History2, HistoryWithResponse), !.
		
match_response_with_last_question(_In, _History, 0).

sbe(In, Out) :-
	match_response_with_last_question(In, History, CurrentQuestionId),
	history_json_to_tuples(History, HistoryTuples),
	sbe_next_state(HistoryTuples, CurrentQuestionId, NextQuestionId, NextPrompt),
	sbe_response(NextQuestionId, NextPrompt, History, Out),
	% term_string(NextQuestionId,S),
	print_term(NextQuestionId,[]),
	true.
	
sbe_response(-1, _NextPrompt, _History, dict{answer: "No"}).
sbe_response(-2, _NextPrompt, _History, dict{answer: "Yes"}).
sbe_response(NextQuestionId, NextPrompt, History, Out) :-
	Out = dict{question: NextPrompt, state: NewHistory},
	append(History, [dict{
		question_id: NextQuestionId, 
		response: -1}], NewHistory). 

history_json_to_tuples([Json|JsonRest], [Tuple|TuplesRest]) :-
	Json = (Tuple.question_id, Tuple.response),
	history_json_to_tuples(JsonRest, TuplesRest).

history_json_to_tuples([], []).


:- server.
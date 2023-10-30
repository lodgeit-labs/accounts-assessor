:- module(chat, [chat_response/4, chat_preprocess/4, history_json_to_tuples/2, match_response_with_last_question/3]).

/*
swipl version 8 required.
*/

/*
example interaction:

>> curl -L -S --fail --header 'Content-Type: application/json' --data '{"type":"residency","current_state":[]}' http://localhost:7788/chat
{"result":{"question":"Do you live in Australia?","state":[{"question_id":1,"response":-1}]}}⏎
*/
/*
 The original nomenclature is by now a bit confusing.
"state" is a list of {question_id, response} objects, would be better called history.
"question id" is the state of the FSM.
*/

/*TODO: 
revive tests, add more tests

sbe question ids start at 0, residency at 1, change sbe

in case of complete failure, alternative framework: https://www.d3web.de/Wiki.jsp?page=Bike%20Diagnosis
*/


chat_response(NextQuestionId, NextPrompt, History, Out) :-
	Out = dict{question: NextPrompt, state: NewHistory},
	append(History, [dict{
		question_id: NextQuestionId, 
		response: -1}], NewHistory). 

chat_preprocess(In, History, CurrentQuestionId, HistoryTuples) :-
	match_response_with_last_question(In, History, CurrentQuestionId),
	history_json_to_tuples(History, HistoryTuples).

history_json_to_tuples([Json|JsonRest], [Tuple|TuplesRest]) :-
	Json = dict{question_id: QuestionId, response: Response},
	Tuple = (QuestionId, Response),
	history_json_to_tuples(JsonRest, TuplesRest).

history_json_to_tuples([], []).

match_response_with_last_question(In, HistoryWithResponse, CurrentQuestionId) :-
	get_dict(current_state, In, History),
	get_dict(response, In, Response),
	LastQuestion = dict{question_id: CurrentQuestionId, response: -1},
	member(LastQuestion, History),
	select(LastQuestion, History, History2),
	append([dict{question_id: CurrentQuestionId, response: Response}], History2, HistoryWithResponse), !.
		
match_response_with_last_question(In, In.current_state, 0).






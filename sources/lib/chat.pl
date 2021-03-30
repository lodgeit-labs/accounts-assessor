:- module(chat, [chat_response/4, chat_preprocess/4, history_json_to_tuples/2, match_response_with_last_question/3]).

/*
swipl version 8 required.
*/

/*
curl -vv --request POST --header "Content-Type: application/json" --data '{"current_state":[]}' http://dev-node.uksouth.cloudapp.azure.com:7778/residency
*/

/* The original nomenclature is by now a bit confusing. 
"state" is a list of {question_id, response} objects, would be better called history.
"question id" is the state of the FSM.
*/

/*TODO: 
add more tests
sbe question ids start at 0, residency at 1, change sbe
alternative framework: https://www.d3web.de/Wiki.jsp?page=Bike%20Diagnosis
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



/*
example interaction:

koom@koom-KVM ~/l/src> curl -d '{"current_state":[]}' -H "Content-Type: application/json" -X POST  http://localhost:7777/sbe
{
  "question":"Are you a Sole trader, Partnership, Company or Trust?",
  "state": [ {"question_id":0, "response":-1} ]
}

koom@koom-KVM ~/l/src> curl -d '{"current_state":[{"response": -1, "question_id": 0}],"response":1}' -H "Content-Type: application/json" -X POST  http://localhost:7777/sbe
{
  "question":"Did you operate a business for all of the income year?",
  "state": [
    {"question_id":0, "response":1},
    {"question_id":1, "response":-1}
  ]
}

or:
 {'status': 'error'}
...
*/

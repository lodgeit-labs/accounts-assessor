% ===================================================================
% Project:   LodgeiT
% Module:    sbe.pl
% Date:      2019-06-06
% ===================================================================


:- module(sbe, [sbe_request/1]).

:- use_module(library(http/http_json)).
:- use_module('../../lib/prompt', [prompt/3]).
:- use_module('../../lib/chat').


sbe_request(Request) :-
	http_read_json_dict(Request, Data),
	sbe_step(Data, Reply),	
	reply_json(Reply),
	true.

sbe_step(In, Out) :-
	preprocess(In, History, CurrentQuestionId, HistoryTuples),
	sbe_next_state(HistoryTuples, CurrentQuestionId, NextQuestionId, NextPrompt),
	(
		sbe_result(NextQuestionId, Out); 
		response(NextQuestionId, NextPrompt, History, Out)
	).

% -------------------------------------------------------------------
% Small Business Entity test. -1 == No, -2 == Yes
% -------------------------------------------------------------------

sbe_result(-1, dict{answer: "No"}).
sbe_result(-2, dict{answer: "Yes"}).

% sbe_question(History, StateId, NextYesState, NextNoState, Prompt)

sbe_question(_, 0, 1, -1, "Are you a Sole trader, Partnership, Company or Trust?").
sbe_question(_, 1, 3, 2,  "Did you operate a business for all of the income year?").
sbe_question(_, 2, 3, -1, "Did you operate a business for part of the income year?").
sbe_question(_, 3, -2, -1, "Was your aggregated turnover less than $10,000,000?").

% first call is: [], 0, ?, ?

sbe_next_state(History, Last_question, Next_question, Prompt) :-
	% if we have a negative answer to the last sbe_question
	member((Last_question, 0), History),
	% look up the No state to go to
	sbe_question(History, Last_question, _, Next_question, _),
	(
		Next_question < 0;
		sbe_question(History, Next_question, _, _, Prompt)
	).

sbe_next_state(History, Last_question, Next_question, Prompt) :-
	% if we have a positive answer to the last sbe_question
	member((Last_question, 1), History),
	% look up the Yes state to go to
	sbe_question(History, Last_question, Next_question, _, _),
	(
		Next_question < 0;
		sbe_question(History, Next_question, _, _, Prompt)
	).
	
sbe_next_state(History, Last_question, Last_question, Prompt) :-
	% otherwise
	\+ member((Last_question, _), History),
	% look up the prompt
	sbe_question(History, Last_question, _, _, Prompt).


% Carrys out a sbe_dialog with the user based on the Deterministic Finite State Machine above.
% History is a list of pairs of sbe_questions and answers received so far, state identifies
% the current state of the machine, Response refers to the 1 or 0 value given as an
% answer to the sbe_question askwed while in this state.

sbe_dialog(History, State, Answer, ScriptedAnswers) :-
	% unify ScriptedAnswer with the head of ScriptedAnswers, to be passed to prompt.
	% if ScriptedAnswers is not a list, leave ScriptedAnswer unbound.
	(compound(ScriptedAnswers) -> ScriptedAnswers = [ScriptedAnswer|ScriptedAnswersTail] ;true),

	sbe_next_state(History, State, NextState, NextQuestion),
	NextState \= -1, NextState \= -2, NextState \= -3,

	prompt(NextQuestion, Response, ScriptedAnswer),

	NextHistory = [(NextState, Response) | History],
	%write("NextHistory:"), writeln(NextHistory),

	sbe_dialog(NextHistory, NextState, Answer, ScriptedAnswersTail), !.

% The base case of the sbe_dialog. The residency of the user is determined by the final state
% of the Deterministic Finite State Machine above.

sbe_dialog(History, State, Answer, _) :-
	sbe_next_state(History, State, Answer, ""),
	((Answer = -1, writeln("Not SBE."));(Answer = -2, writeln("SBE."))).



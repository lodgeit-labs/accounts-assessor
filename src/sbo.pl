% this is an experimental adjustment to the residency program, seeing if we can make it
% more maintainable this way

% Small Business Entity test. -1 == No, -2 == Yes

% question(History, StateId, NextYesState, NextNoState, Prompt)

question(_, 0, 1, -1, "Are you a: Sole trader, Partnership, Company, or Trust?").
question(_, 1, 3, 2,  "Did you operate a business for all of the income year?").
question(_, 2, 3, -1, "Did you operate a business for part of the income year?").
question(_, 3, -2, -1, "Was your aggregated turnover less than $10,000,000?").




% first call is: [], 0, ?, ?

next_state(History, LastQuestion, NextQuestion, Prompt) :-
	% if we have a negative answer to the last question
	member((LastQuestion, 0), History),
	% look up the No state to go to
	question(History, LastQuestion, _, NextQuestion, _),
	(
		NextQuestion < 0;
		question(History, NextQuestion, _, _, Prompt)
	).

next_state(History, LastQuestion, NextQuestion, Prompt) :-
	% if we have a positive answer to the last question
	member((LastQuestion, 1), History),
	% look up the Yes state to go to
	question(History, LastQuestion, NextQuestion, _, _),
	(
		NextQuestion < 0;
		question(History, NextQuestion, _, _, Prompt)
	).
	
next_state(History, LastQuestion, LastQuestion, Prompt) :-
	% otherwise
	\+ member((LastQuestion, _), History),
	% look up the prompt
	question(History, LastQuestion, _, _, Prompt).






:- [prompt].

% Carrys out a dialog with the user based on the Deterministic Finite State Machine above.
% History is a list of pairs of questions and answers received so far, state identifies
% the current state of the machine, Response refers to the 1 or 0 value given as an
% answer to the question askwed while in this state, and Resident is -1, -2, or -3
% depending on whether the user is an Australian, temporary, or foreign resident for tax
% purposes respectively.

dialog(History, State, Resident, ScriptedAnswers) :-
	% unify ScriptedAnswer with the head of ScriptedAnswers, to be passed to prompt.
	% if ScriptedAnswers is not a list, leave ScriptedAnswer unbound.
	(compound(ScriptedAnswers) -> ScriptedAnswers = [ScriptedAnswer|ScriptedAnswersTail] ;true),

	next_state(History, State, Next_State, Next_Question),
	Next_State \= -1, Next_State \= -2, Next_State \= -3,

	prompt(Next_Question, Response, ScriptedAnswer),

	Next_History = [(Next_State, Response) | History],
	write("Next_History:"), writeln(Next_History),

	dialog(Next_History, Next_State, Resident, ScriptedAnswersTail), !.

% The base case of the dialog. The residency of the user is determined by the final state
% of the Deterministic Finite State Machine above.

dialog(History, State, Resident, _) :-
	next_state(History, State, Resident, "").



test0() :-
	% for example dialog([], 0, _, -1,  `ynynnnnnnynn`), ideally shouldn't unify, 
	% the correct result is -2, but dialog backtracks until it finds a next_state that matches

	dialog([], 0, Result0, `n`), Result0 = -1,
	dialog([], 0, Result1, `ynn`), Result1 = -1,
	dialog([], 0, Result2, `ynyn`), Result2 = -1,
	dialog([], 0, Result3, `ynyy`), Result3 = -2,
	dialog([], 0, Result4, `yyn`), Result4 = -1,
	dialog([], 0, Result5, `yyy`), Result5 = -2,
	
	writeln("all tests pass."),
	writeln("").

:- test0.

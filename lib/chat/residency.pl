:- module(residency, [residency_request/1]).

:- use_module(library(http/http_json)).
:- use_module('../prompt', [prompt/3]).
:- use_module('../chat').


residency_request(Request) :-
	http_read_json_dict(Request, Data),
	residency_step(Data, Reply),	
	reply_json(Reply),
	true.

residency_step(In, Out) :-
	preprocess(In, History, CurrentQuestionId, HistoryTuples),
	next_state(HistoryTuples, CurrentQuestionId, NextQuestionId, NextPrompt),
	(
		residency_result(NextQuestionId, Out); 
		response(NextQuestionId, NextPrompt, History, Out)
	).
	
% The predicate "returns" 1 if the given element is in the given list and "returns" 0 if
% otherwise.

indicator(Element, List, 1) :- member(Element, List).

indicator(Element, List, 0) :- \+ member(Element, List).

% A Deterministic Finite State Machine for determining if the user is an Australian
% resident for tax purposes.

residency_result(-1, dict{answer: "Australian"}).
residency_result(-2, dict{answer: "temporary"}).
residency_result(-3, dict{answer: "foreign"}).

% Resides Test

next_state(_, 0, 1, "Do you live in Australia?").

next_state(_, 1, 2, "Do you maintain a permanent base in Australia?").

next_state(_, 2, 3, "Are you in Australia frequently?").

% one of the above three questions was answered no, let's give it another chance
next_state(History, 3, 4, "Is your usual most common place of residence in Australia?") :-
	indicator((1, 1), History, I1),
	indicator((2, 1), History, I2),
	indicator((3, 1), History, I3),
	I1 + I2 + I3 < 3, !.

next_state(_, 3, -1, "").

next_state(History, 4, 5, "Do you reside in Australia more than you reside elsewhere?") :-
	indicator((1, 1), History, I1),
	indicator((2, 1), History, I2),
	indicator((3, 1), History, I3),
	indicator((4, 1), History, I4),
	I1 + I2 + I3 + I4 < 3, !.

next_state(_, 4, -1, "").


% if less than 3 above questions were answered positively, we try the:

% Domicile Test

next_state(History, 5, 6, "Do you rent a house, room or apartment in Australia to dwell in?") :-
	indicator((1, 1), History, I1),
	indicator((2, 1), History, I2),
	indicator((3, 1), History, I3),
	indicator((4, 1), History, I4),
	indicator((5, 1), History, I5),
	I1 + I2 + I3 + I4 + I5 < 3, !.

next_state(_, 5, -1, "").

next_state(History, 6, 7, "Do you own a house in Australia?") :-
	member((6, 0), History), !.

next_state(_, 6, -1, "").

next_state(History, 7, 8, "Is the house or any part of the house maintained for you to live in?") :-
	member((7, 1), History), !.

/* 3 - The 183 day test -> This test only applies to
individuals arriving in Australia.
You will be a resident under
this test if you spend over half
the year in Australia, unless
it is established that your
‘usual place of abode’ is
outside Australia and you
have no intention of taking
up residence here.

	
Question Set 3
Did you recently arrive in Australia?
a. IF Y, then is Q2 also Y? (do you have domicile here)
b. IF N, then Do you have any intention of taking up residence here?
IF Y, then did you spend 183 or more days in Australia?
183 Day Test is Y IF Y.

Question Set 3
Did you recently arrive in Australia?
	IF Y, then Do you have any intention of taking up residence here?
		IF Y, then did you spend 183 or more days in Australia?
			IF Y, result is resident
			IF N, go to Superannuation Fund Test
		IF N, go to Superannuation Fund Test
	IF N, go to Superannuation Fund Test
*/

next_state(_, 7, 9, "Did you recently arrive in Australia?").

next_state(History, 8, 9, "Did you recently arrive in Australia?") :-
	member((8, 0), History), !.

next_state(_, 8, -1, "").

% did recently arrive:
next_state(History, 9, 10, "Do you have any intention of taking up residence here?") :-
	member((9, 1), History), !.

% Commonwealth Superannuation Fund Test

% didnt recently arrive, so:
next_state(_, 9, 12, "Are you a Government employee?").

next_state(History, 10, 11, "Did you spend 183 or more days in Australia?") :-
	member((10, 1), History), !.

next_state(_, 10, 12, "Are you a Government employee?").

next_state(History, 11, 12, "Are you a Government employee?") :-
	member((11, 0), History), !.

next_state(_, 11, -1, "").

next_state(History, 12, 13, "Are you eligible to contribute to a Public Sector Superannuation Scheme?") :-
	member((12, 1), History), !.

% Temporary Resident? Domicile Test for Spouse

next_state(_, 12, 14, "Do you hold a temporary visa?").

next_state(History, 13, 14, "Do you hold a temporary visa?") :-
	member((13, 0), History), !.

next_state(_, 13, -1, "").

next_state(History, 14, -3, "") :-
  member((14, 0), History), !.

next_state(_, 14, 15, "Does your spouse rent a house, room or apartment in Australia to dwell in?").

next_state(History, 15, 16, "Does your spouse own a house in Australia?") :-
	member((15, 0), History), !.

next_state(_, 15, -3, "").

next_state(History, 16, 17, "Is the house or any part of the house maintained for your spouse to live in?") :-
	member((16, 1), History), !.

next_state(_, 16, -2, "").

next_state(History, 17, -3, "") :-
  member((17, 1), History), !.

next_state(_, 17, -2, "").


% Carrys out a dialog with the user based on the Deterministic Finite State Machine above.
% History is a list of pairs of questions and answers received so far, state identifies
% the current state of the machine, Response refers to the 1 or 0 value given as an
% answer to the question askwed while in this state, and Resident is -1, -2, or -3
% depending on whether the user is an Australian, temporary, or foreign resident for tax
% purposes respectively.

dialog(History, State, Response, Resident, ScriptedAnswers) :-
	Next_History = [(State, Response) | History],

	write("Next_History:"), writeln(Next_History),
	% unify ScriptedAnswer with the head of ScriptedAnswers, to be passed to prompt.
	% if ScriptedAnswers is not a list, leave ScriptedAnswer unbound.
	(compound(ScriptedAnswers) -> ScriptedAnswers = [ScriptedAnswer|ScriptedAnswersTail] ;true),

	next_state(Next_History, State, Next_State, Next_Question),
	Next_State \= -1, Next_State \= -2, Next_State \= -3,
	prompt(Next_Question, Next_Response, ScriptedAnswer),
	dialog(Next_History, Next_State, Next_Response, Resident, ScriptedAnswersTail), !.

% The base case of the dialog. The residency of the user is determined by the final state
% of the Deterministic Finite State Machine above.

dialog(History, State, Response, Resident, _) :-
	Next_History = [(State, Response) | History],
	next_state(Next_History, State, Resident, "").

dialog(Result, Answers) :-
	dialog([], 0, _, Result, Answers).

dialog(Result) :-
	dialog([], 0, _, Result, ``).


% notes:
% Have you been in Australia, either continuously or intermittently, for 183 days or more in the income year? *
% https://www.ato.gov.au/Individuals/International-tax-for-individuals/Work-out-your-tax-residency/
% https://www.ato.gov.au/Individuals/Ind/Resident-for-tax-if-WHM-/?=redirected
% https://www.ato.gov.au/Calculators-and-tools/Host/?=redirected_residencytests&anchor=AreYouAResident%20#AreYouAResident/questions
% https://www.ato.gov.au/law/view/document?Docid=TXR/TR9817/NAT/ATO/00001

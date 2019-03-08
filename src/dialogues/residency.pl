% The predicate "returns" 1 if the given element is in the given list and "returns" 0 if
% otherwise.

indicator(Element, List, 1) :- member(Element, List).

indicator(Element, List, 0) :- \+ member(Element, List).

% A Deterministic Finite State Machine for determining if the user is an Australian
% resident for tax purposes.

next_state(_, 0, 1, "Do you live in Australia?").

next_state(_, 1, 2, "Do you maintain a permanent base in Australia?").

next_state(_, 2, 3, "Are you in Australia frequently?").

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

next_state(_, 7, 9, "Did you recently arrive in Australia?").

next_state(History, 8, 9, "Did you recently arrive in Australia?") :-
	member((8, 0), History), !.

next_state(_, 8, -1, "").

next_state(History, 9, 10, "Did you spend 183 or more days in Australia?") :-
	member((9, 1), History), !.

next_state(_, 9, 12, "Are you a Government employee?").

next_state(History, 10, 11, "Do you have any intention of taking up residence here?") :-
	member((10, 1), History), !.

next_state(_, 10, 12, "Are you a Government employee?").

next_state(History, 11, 12, "Are you a Government employee?") :-
	member((11, 0), History), !.

next_state(_, 11, -1, "").

next_state(History, 12, 13, "Are you eligible to contribute to a Public Sector Superannuation Scheme?") :-
	member((12, 1), History), !.

next_state(_, 12, -2, "").

next_state(History, 13, -2, "") :-
	member((13, 0), History), !.

next_state(History, 13, -1, "") :-
	member((13, 1), History), !.

% Prints the prompt Prompt. Unifies Bool with 1 if the user enters 'Y' or 'y'. Unifies
% Bool with 0 if the user enters 'N' or 'n'. Repeats the prompt if the answer is not one
% of the four aforementioned characters.

prompt(Prompt, Bool) :-
	string_concat(Prompt, " (y/Y/n/N): ", Formatted_Prompt),
	write(Formatted_Prompt),
	get(Answer),
	((Answer = 89; Answer = 121) -> Bool = 1;
	(Answer = 78; Answer = 110) -> Bool = 0;
	prompt(Prompt, Bool)).

% Carrys out a dialog with the user based on the Deterministic Finite State Machine above.
% History is a list of pairs of questions and answers received so far, state identifies
% the current state of the machine, Response refers to the 1 or 0 value given as an
% answer to the question askwed while in this state, and Resident is -1 or -2 depending on
% whether the user is an Australian or foreign resident for tax purposes respectively.

dialog(History, State, Response, Resident) :-
	Next_History = [(State, Response) | History],
	next_state(Next_History, State, Next_State, Next_Question),
	Next_State \= -1, Next_State \= -2,
	prompt(Next_Question, Next_Response),
	dialog(Next_History, Next_State, Next_Response, Resident), !.

% The base case of the dialog. The residency of the user is determined by the final state
% of the Deterministic Finite State Machine above.

dialog(History, State, Response, Resident) :-
	Next_History = [(State, Response) | History],
	next_state(Next_History, State, Resident, _).


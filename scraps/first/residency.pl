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

% Does the resides test by using redundant questions. The five answers are unified to
% variables A1 to A5. The last variable is unified to 1 if the user is definitely a
% resident and 0 otherwise.

prompt_set1(A1, A2, A3, A4, A5, Resident) :-
	prompt("Do you live in Australia?", A1),
	prompt("Do you maintain a permanent base in Australia?", A2),
	prompt("Are you in Australia frequently?", A3),
	((A1 + A2 + A3 < 3) ->
	(prompt("Is your usual most common place of residence in Australia?", A4),
	((A1 + A2 + A3 + A4 < 3) ->
	(prompt("Do you reside in Australia more than you reside elsewhere?", A5),
	Resident = A5);
	Resident = 1));
	Resident = 1).

% Does the domicile test by using redundant questions. The three answers are unified to
% variables A1 to A3. The last variable is unified to 1 if the user is definitely a
% resident and 0 otherwise.

prompt_set2(A1, A2, A3, Resident) :-
	prompt("Do you rent a house, room or apartment in Australia to dwell in?", A1),
	((A1 = 0) ->
	(prompt("Do you own a house in Australia?", A2),
	((A2 = 1) ->
	(prompt("Is the house or any part of the house maintained for you to live in?", A3),
	Resident = A3);
	Resident = 0));
	Resident = 1).

% Does the 183 day test. The three answers are unified to variables A1 to A3. The last
% variable is unified to 1 if the user is definitely a resident and 0 otherwise.

prompt_set3(A1, A2, A3, Resident) :-
	prompt("Did you recently arrive in Australia?", A1),
	((A1 = 1) ->
	(prompt("Did you spend 183 or more days in Australia?", A2),
	((A2 = 1) ->
	(prompt("Do you have any intention of taking up residence here?", A3),
	(A3 = Resident));
	Resident = 0));
	Resident = 0).

% Does the Commonwealth superannuation fund test. The two answers are unified to variables
% A1 to A2. The last variable is unified to 1 if the user is definitely a resident and 0
% otherwise.

prompt_set4(A1, A2, Resident) :-
	prompt("Are you a Government employee?", A1),
	((A1 = 1) ->
	(prompt("Are you eligible to contribute to a Public Sector Superannuation Scheme?", A2),
	Resident = A2);
	Resident = 0).

% Applies all four residency tests in order to determine if the user is an Australian
% resident for tax purposes. The predicate succeeds if the user is an Australian resident
% for tax purposes, otherwise it fails.

resident() :-
	prompt_set1(_, _, _, _, _, 1);
	prompt_set2(_, _, _, 1);
	prompt_set3(_, _, _, 1);
	prompt_set4(_, _, 1).


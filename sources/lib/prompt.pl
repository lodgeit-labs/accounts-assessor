% ===================================================================
% Project:   LodgeiT
% Module:    propmt.pl
% Date:      2019-06-06
% ===================================================================

:- module(prompt, [prompt/3]).

% -------------------------------------------------------------------
% Prints the prompt Prompt. Unifies Bool with 1 if the user enters 'Y' or 'y'. Unifies
% Bool with 0 if the user enters 'N' or 'n'. Repeats the prompt if the answer is not one
% of the four aforementioned characters.
% -------------------------------------------------------------------

prompt(Prompt, Bool, ScriptedAnswer) :-

	string_concat(Prompt, " (y/Y/n/N): ", Formatted_Prompt),
	write(Formatted_Prompt),
	((integer(ScriptedAnswer), Answer = ScriptedAnswer, put_char(Answer), writeln(""), !);
	writeln(""),
	get(Answer)),
	(
		(Answer = 89; Answer = 121) /*y or Y*/
	->
		Bool = 1
	; 
		(
			(Answer = 78; Answer = 110) /*n or N*/
		->
			Bool = 0
		;  
			prompt(Prompt, Bool, _)
		)
	).

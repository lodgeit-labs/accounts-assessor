% Prints the prompt Prompt. Unifies Bool with 1 if the user enters 'Y' or 'y'. Unifies
% Bool with 0 if the user enters 'N' or 'n'. Repeats the prompt if the answer is not one
% of the four aforementioned characters.

prompt(Prompt, Bool, ScriptedAnswer) :-
	string_concat(Prompt, " (y/Y/n/N): ", Formatted_Prompt),

	% this was write. write seems to not guarantee that the output is flushed, so i was getting empty prompts.
	write(Formatted_Prompt),

	% -> would be cleaner than cut?
	((integer(ScriptedAnswer), Answer = ScriptedAnswer, put_char(Answer), writeln(""), !);
	
	writeln(""),
	get(Answer)),

	((Answer = 89; Answer = 121) -> Bool = 1;
	(Answer = 78; Answer = 110) -> Bool = 0;
	% otherwise,
	prompt(Prompt, Bool, _)).

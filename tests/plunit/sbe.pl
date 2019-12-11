:- ['../../lib/sbe'].

:- begin_tests(sbe).
test(0) :-
	% fixme, for example sbe_dialog([], 0, _, -1,  `ynynnnnnnynn`), ideally shouldn't unify, 
	% the correct result is -2, but sbe_dialog backtracks until it finds a sbe_next_state that matches,
	% that's why the ResultX variables here

	sbe:sbe_dialog([], 0, Result0, `n`), Result0 = -1,
	sbe:sbe_dialog([], 0, Result1, `ynn`), Result1 = -1,
	sbe:sbe_dialog([], 0, Result2, `ynyn`), Result2 = -1,
	sbe:sbe_dialog([], 0, Result3, `ynyy`), Result3 = -2,
	sbe:sbe_dialog([], 0, Result4, `yyn`), Result4 = -1,
	sbe:sbe_dialog([], 0, Result5, `yyy`), Result5 = -2.

:- end_tests(sbe).

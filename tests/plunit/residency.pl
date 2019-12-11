:- ['../../lib/residency'].

:- begin_tests(residency).

test(0) :-
	% for example dialog([], 0, _, -1,  `ynynnnnnnynn`), ideally shouldn't unify, 
	% the correct result is -2, but dialog backtracks until it finds a next_state that matches

	residency:dialog([], 0, _, Result0, `yyy`), Result0 = -1,
	residency:dialog([], 0, _, Result1, `ynyy`), Result1 = -1,
	residency:dialog([], 0, _, Result2, `ynynnnnnnynn`), Result2 = -2,
	residency:dialog([], 0, _, Result3, `nnnnnnnnnnnnnnnnnn`), Result3 = -3,
	residency:dialog([], 0, _, Result4, `nnyynnnyynyy`), Result4 = -1,
	
	true.

:- end_tests(residency).


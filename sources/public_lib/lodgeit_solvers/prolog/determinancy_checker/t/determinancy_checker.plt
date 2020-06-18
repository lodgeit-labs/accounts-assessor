:- ['../determinancy_checker_main.pl'].


:- begin_tests(determinancy_checker_full).


test(t40, throws(deterministic_call_failed(_))) :-
	!fail
.

test(t40, throws(deterministic_call_found_a_second_solution(_))) :-
	findall(_,!member(_, [t40,t40]),_).

test(t50) :-
	findall(_,(
		!writeq(rrr),
		?member(X, [t50]),
		!writeq(X)
),_).

test(t100) :-
	findall(_,(
		!writeq(rrr),
		?member(X, []),
		!writeq(X)
),_).

test(t100, throws(semideterministic_call_has_multiple_solutions(_))) :-
	nl,
	findall(_,(
		!writeq(t100rrr),
		?member(X, [1,2]),
		!writeq(X)
),_).



:- end_tests(determinancy_checker_full).

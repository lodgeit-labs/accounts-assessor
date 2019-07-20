:- ['../../lib/utils'].

:- begin_tests(utils).

test(0) :-
	semigroup_foldl(atom_concat, [], []),
	semigroup_foldl(atom_concat, [aaa], [aaa]),
	semigroup_foldl(atom_concat, [aaa, bbb], [aaabbb]),
	semigroup_foldl(atom_concat, [aaa, bbb, ccc], [aaabbbccc]).

:- end_tests(utils).




:- [pyco2].



pyco0_rule(
	'list cell helper',
	[fr(L,F,R)] <=
	[
		first(L, F),
		rest(L, R)
	]).

pyco0_rule(
	Desc,
	[first(L,F),rest(L,R)] <=
	[],
	(L = bn(_, Desc{first:F,rest:R}),register_bn(L))
	) :-
		Desc = 'list cell exists'.


pyco0_rule(
	'lists of same chars, of same length',
	['lists of same chars, of same length'(A,B)]
	<=
	[
		'list of same chars, of length'(A, L),
		'list of same chars, of length'(B, L)
	]).


pyco0_rule(
	'list of same chars, of length',
	['list of same chars, of length'(X, L)]
	<=
	[
		char(Ch),
		'list of CH, of length L'(X, Ch, L)
	]).


pyco0_rule(
	'list of Ch, of length L, base case',
	['list of Ch, of length L'(nil, Ch, 0)]
	<=
	[
		'list of Ch, of length L'(X, Ch, L),
		fr(X, F, R),
		Ch = F,
		L_next is L - 1,
		'list of Ch, of length L'(R, Ch, Lp)
	]).

char(a).
char(b).

pyco0_rule(
	'q1',
	[q1(L,F,R)] <=
	[
		fr(L, F, R)
	]).

test2 :-
	findnsols(
		5000000000,
		_,
		(
			%debug(pyco_prep),
			%debug(pyco_proof),
			%debug(pyco_ep),

			Q = q1(L,F,R),
			run(Q),
			format(user_error,'~nresult: ~q~n', [Q]),

			nl,
			true
		),
		_
	),
	halt.

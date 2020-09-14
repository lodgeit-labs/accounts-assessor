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
	mkbn(L, Desc{first:F,rest:R})
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
		'list of Ch, of length L'(X, Ch, L)
	]).


pyco0_rule(
	'list of Ch, of length L, base case',
	['list of Ch, of length L'(nil, _, 0)]
	<=
	[
	]).

pyco0_rule(
	'list of Ch, of length L, recursing',
	['list of Ch, of length L'(X, Ch, L)]
	<=
	[
		L #> 0,
		L_next #= L - 1,
		fr(X, F, R),
		Ch = F,
		'list of Ch, of length L'(R, Ch, L_next)
	]).

char(a).
char(b).

pyco0_rule(
	'q1',
	[q1(L,F,R)] <=
	[
		fr(L, F, R)
	]).

pyco0_rule(
	'q2',
	[q2(A,B)] <=
	[
		fr(B,_,nil),'lists of same chars, of same length'(A,B)
	]).
pyco0_rule(
	'q3',
	[q3(A,B)] <=
	[
		fr(B,_,L1),fr(L1,_,L2),fr(L2,_,nil),'lists of same chars, of same length'(A,B)
		%fr(L2,_,nil),fr(L1,_,L2),fr(B,_,L1),'lists of same chars, of same length'(A,B)
	]).

test0 :-
	findnsols(
		10,
		_,
		(
			%debug(pyco_prep),
			debug(pyco_proof),
			%debug(pyco_ep),

			Q = q1(_L,_F,_R),
			run(Q),
			format(user_error,'~nresult: ~q~n', [Q]),

			nl,
			true
		),
		_
	).

test1 :-
	findnsols(
		1000,
		_,
		(
			%debug(pyco_prep),
			debug(pyco_proof),
			debug(pyco_run),
			%debug(pyco_ep),
			Q = 'lists of same chars, of same length'(_A,_B),
			run(Q),
			nicer_term(Q, NQ),
			format(user_error,'~nresult: ~q~n', [NQ]),

			nl,
			true
		),
		_
	).

test2 :-
	findnsols(
		200,
		_,
		(
			debug(pyco_prep),
			debug(pyco_proof),
			%debug(pyco_ep),
			Q = q2(_,_),
			run(Q),
			format(user_error,'~nresult: ~q~n', [Q]),

			nl,
			true
		),
		_
	).
test3 :-
	findnsols(
		200,
		Q,
		(
			%debug(pyco_prep),
			debug(pyco_proof),
			%debug(pyco_ep),
			Q = q3(_,_),
			run(Q),
			nicer_term(Q, NQ),
			format(user_error,'~nresult: ~q~n', [NQ]),
			%format(user_error,'~nresult: ~q~n', [Q]),
			nl
		),
		Sols
	),
	format(user_error,'~nresults: ~q~n', [Sols])
	.

run0() :-
	(
		writeln("choice 1")
	;
		writeln("choice 2")
	).

run1() :-
	(
		writeln("choice 1"),
		fail
	;
		writeln("choice 2")
	).

run2() :-
	(
		writeln("choice 1"),
		!,
		fail
	;
		writeln("choice 2")
	).

run3() :-
	pred(X),
	(
		writeln(X),
		!,
		fail
	;
		writeln("choice 2")
	).

run4A() :-
	pred(X),
	!,
	writeln("run4A:"),
	writeln(X).

run4() :-
	pred(X),
	writeln("run4:"),
	writeln(X),
	run4A.


pred(1).
pred(2).

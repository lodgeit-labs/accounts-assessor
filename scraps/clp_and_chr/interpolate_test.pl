:- use_module(library(interpolate)).

main :-
	debug(main),
	X = 1, X = X,
	Y = 2, Y = Y,
	debug(main, "X = $X, Y = $Y", []).

main2 :-
	_X = ["January"],
	_Months = [
		[1,		31,					"January"], % why can't "January" be an integer? :)
		[2,		 _,					"February"],
		[3,		31, 				"March"],
		[4,		30, 				"April"],
		[5,		31, 				"May"],
		[6,		30, 				"June"],
		[7,		31, 				"July"],
		[8,		31, 				"August"],
		[9,		30, 				"September"],
		[10,	31, 				"October"],
		[11,	30, 				"November"],
		[12,	31, 				"December"]
	].

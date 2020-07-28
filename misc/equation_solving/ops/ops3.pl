:- use_module(library(clpq)).


/*
interval arithmetic with clpq. Numbers are assumed to have precision expressed by number of digits.


*/

x :-

	/* input: A = 1 */
	{A >= 0.5, A < 1.5},
	/* input: B = 11 */
	{C >= 10.5, C < 11.5},
	{A * B = C},
	write_term(B,[attributes(portray)]),
	nl,
	minimize(B),
	write_term(B,[attributes(portray)]),
	
	
	
	nl
	
	
	
	
	.

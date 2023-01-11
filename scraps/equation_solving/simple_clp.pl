:- use_module(library(clpq)).

:- {
	Assets - Liabilities = Equity,
	Assets = Wells_Fargo_Bank,
	Liabilities = Amex_Credit_Card,
	Equity = _Share_Capital,
	Wells_Fargo_Bank = 100,
	Amex_Credit_Card = -50},
	writeq(Equity).
/*
prints 150 when run
first thing to note is that this isnt actually mainly a logic program in the sense of using prolog language constructs. Rather, it uses a mathematical solver library available in prolog
the idea with that is that logic programming works by exhaustively trying out all available combinations of assignments of variables, But that can only work if there isn't an infinite number of possible values 
second thing: it doesn't deal with units. We cannot write 100USD and -50USD and expect it to print 150USD
third thing: it can solve complex linear equations, but it cannot answer why equity is 150
well, i would give our python solver's output for comparison, but it still needs some work
*/
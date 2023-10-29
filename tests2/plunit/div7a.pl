:- ['../../sources/lib/div7a.pl'].

:- begin_tests(div7a).

test(t1) :-
	write("t1...").
	Loan = [
		[date(2014,6,30), loan_start{term:7, repayments:[]}],
    	[date(2019,6,30), opening_balance{amount:1000}]
	],

	[D, repayment{amount:200}],
	[D, interest{amount:50}],
	[D, end],

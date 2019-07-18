:- ['../../lib/exchange_rates'].
:- ['../../lib/days'].

:- begin_tests(exchange_rates).

test(0) :-
	% Let's check the exchange rate predicate for historical correctness:
	write("Are the certain exchange rates from the API matching manually obtained ones? Also, do the manual overrides work?"),
	findall(Exchange_Rate, 

		% fixme i've changed date representation from absolute days to date term
		(absolute_day(date(2015, 6, 30), Day),
		(
			% note these are OR-ed
			exchange_rate([], Day, 'AUD', 'USD', Exchange_Rate);
			exchange_rate([], Day, 'AUD', 'MXN', Exchange_Rate);
			exchange_rate([], Day, 'AUD', 'AUD', Exchange_Rate);
			exchange_rate([], Day, 'AUD', 'HKD', Exchange_Rate);
			exchange_rate([], Day, 'AUD', 'RON', Exchange_Rate);
			exchange_rate([], Day, 'AUD', 'HRK', Exchange_Rate);
			exchange_rate([], Day, 'AUD', 'CHF', Exchange_Rate);
			
			% "manual override" by providing a table of exchange_rate's
			exchange_rate(
						[exchange_rate(Day, 'USD', 'ZWD', 10000000000000000000000000)], 
						Day, 'USD', 'ZWD', Exchange_Rate)
		)), Results),
		writeln(Results),
		Expected = [0.7690034364261168, 12.050309278350516, 1, 5.961512027491408, 3.0738831615120277,
	  	5.21979381443299, 0.7156701030927833, 10000000000000000000000000],
		writeln(Expected),
		Expected = Results.



:- end_tests(exchange_rates).




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


test(0) :-
	exchange_rate([], date(2016,7,6), 'USD', 'USD', One), One =:= 1.

test(0) :-
	exchange_rate([], date(2016,7,6), 'USD', 'AUD', _X).
	
test(1) :-
	exchange_rate(
	[
		exchange_rate(date(2017,7,1),'SG_Issuer_SA','USD',10),
		exchange_rate(date(2018,6,30),'SG_Issuer_SA','USD',40),
		exchange_rate(date(2017,7,1),'USD','AUD',1.4492753623188408),
		exchange_rate(date(2018,6,30),'USD','AUD',1.4285714285714286)
	], 
	date(2018,6,30),
	'SG_Issuer_SA',
	'AUD',
	_).
	
test(2) :-
	exchange_rate(
	[
		exchange_rate(date(2017,7,1),'SG_Issuer_SA','USD',10),
		exchange_rate(date(2018,6,30),'SG_Issuer_SA','USD',40),
		exchange_rate(date(2017,7,1),'USD','AUD',1.4492753623188408),
		exchange_rate(date(2018,6,30),'USD','AUD',1.4285714285714286)
	], 
	date(2018,6,30),
	without_currency_movement_against_since('SG_Issuer_SA','USD', ['AUD'],date(2017,7,1)),
	'AUD',
	57.97101449275363).



:- end_tests(exchange_rates).


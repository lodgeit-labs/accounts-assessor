:- ['../../lib/exchange_rates'].
:- ['../../lib/exchange'].
:- ['../../lib/days'].
:- use_module('../../lib/utils',	[floats_close_enough/2]).

:- begin_tests(exchange_rates).

test(0) :-
	% Let's check the exchange rate predicate for historical correctness:
	write("Are the certain exchange rates from the API matching manually obtained ones? Also, do the manual overrides work?"),
	findall(
		Exchange_Rate, 
		(
			date(2015, 6, 30) = Day,
			(
				exchange_rate([], Day, 'AUD', 'USD', Exchange_Rate)
				;exchange_rate([], Day, 'AUD', 'MXN', Exchange_Rate)
				;exchange_rate([], Day, 'AUD', 'AUD', Exchange_Rate)
				;exchange_rate([], Day, 'AUD', 'HKD', Exchange_Rate)
				;exchange_rate([], Day, 'AUD', 'RON', Exchange_Rate)
				;exchange_rate([], Day, 'AUD', 'HRK', Exchange_Rate)
				;exchange_rate([], Day, 'AUD', 'CHF', Exchange_Rate)
				;			
				% "manual override" by providing a table of exchange_rate's
				exchange_rate(
						[exchange_rate(Day, 'USD', 'ZWD', 10000000000000000000000000)], 
						Day, 'USD', 'ZWD', Exchange_Rate)
			)
		), 
		Results
	),
	nl,
	writeln(Results),
	Expected = [
		0.7699260716985955,12.091173105558404,1.0,5.96822130139064,3.0939671672725986,5.248065560744857,0.7202689197783229,
		10000000000000000000000000],
	writeln(Expected),
	maplist(floats_close_enough, Results, Expected).


test(1) :-
	exchange_rate([], date(2016,7,6), 'USD', 'USD', One), One =:= 1.

test(2) :-
	exchange_rate([], date(2016,7,6), 'USD', 'AUD', _X).
	
test(3) :-
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
	
test(4) :-
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
	X),
	floats_close_enough(X, 57.97101449275363).


test(4) :-
	vec_change_bases(Exchange_Rates, Day, Bases, [A | As], Bs) :-
	coord(without_movement_after('SG Issuer_SA_USD_1',
					     date(2018,7,13)),
		      0,
		      140000),
		      

:- end_tests(exchange_rates).


	%append(Exchange_Rates, [], Exchange_Rates_With_Inferred_Values),
/*	
	exchange_rate(
		Exchange_Rates_With_Inferred_Values, date(2018,12,30), 
		'CHF','AUD',
		RRRRRRRR),
	print_term(RRRRRRRR,[]),*/
	/*
	exchange_rate(
		Exchange_Rates_With_Inferred_Values, End_Days, 
		without_currency_movement_against_since('Raiffeisen Switzerland_B.V.', 
		'USD', ['AUD'],date(2018,7,2)),
		'AUD',
		RRRRRRRR),
	print_term(RRRRRRRR,[]),
	*/
	

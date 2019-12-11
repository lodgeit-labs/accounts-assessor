:- ['../../lib/exchange_rates'].
:- ['../../lib/exchange'].
:- ['../../lib/days'].
:- use_module(library(xbrl/utils),	[floats_close_enough/2]).

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


test(5, all( [R0, R1, R2] = [ [
	[ coord('AUD', 0.0, 40.0) ],
	[ coord('AUD', 0.0, 30.0) ],
	[ coord('AUD', 0.0, 30.0) ]
	] ] ) ) :-
	Rates = [
		exchange_rate(date(2018,7,1),'SG Issuer_SA_USD_1','AUD',40),
		exchange_rate(date(2018,7,12),'SG Issuer_SA_USD_1','AUD',30),
		exchange_rate(date(2018,7,13),'SG Issuer_SA_USD_1','AUD',40)
	],
	vec_change_bases(Rates, date(2018,7,1), ['AUD'], 
		[coord(without_movement_after('SG Issuer_SA_USD_1', date(2018,7,12)), 0, 1)], R0),
	vec_change_bases(Rates, date(2018,7,12), ['AUD'], 
		[coord(without_movement_after('SG Issuer_SA_USD_1', date(2018,7,12)), 0, 1)], R1),
	vec_change_bases(Rates, date(2018,7,13), ['AUD'], 
		[coord(without_movement_after('SG Issuer_SA_USD_1', date(2018,7,12)), 0, 1)], R2).
		      
test(6, all( [R0, R1, R2] = [ [
	[ coord('xxx', 0.0, 40.0) ],
	[ coord('xxx', 0.0, 360.0) ],
	[ coord('xxx', 0.0, 360.0) ]
	] ] ) ) :-
	Rates = [
		exchange_rate(date(2018,7,1),'SG Issuer_SA_USD_1','USD',40),
		exchange_rate(date(2018,7,12),'SG Issuer_SA_USD_1','USD',30),
		exchange_rate(date(2018,7,13),'SG Issuer_SA_USD_1','USD',40),
		exchange_rate(date(2018,7,1),'USD','xxx',1),
		exchange_rate(date(2018,7,12),'USD','xxx',12),
		exchange_rate(date(2018,7,13),'USD','xxx',13),
		exchange_rate(date(2018,7,20),'USD','xxx',20)
	],
	vec_change_bases(Rates, date(2018,7,1), ['xxx'], 
		[coord(without_movement_after('SG Issuer_SA_USD_1', date(2018,7,12)), 0, 1)], R0),
	vec_change_bases(Rates, date(2018,7,12), ['xxx'], 
		[coord(without_movement_after('SG Issuer_SA_USD_1', date(2018,7,12)), 0, 1)], R1),
	vec_change_bases(Rates, date(2018,7,13), ['xxx'], 
		[coord(without_movement_after('SG Issuer_SA_USD_1', date(2018,7,12)), 0, 1)], R2).
		      

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
	

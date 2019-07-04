% ===================================================================
% Project:   LodgeiT
% Module:    exchange_rates.pl
% Date:      2019-06-02
% ===================================================================

:- module(exchange_rates, [exchange_rate/5, is_exchangeable_into_request_bases/4]).

:- use_module(library(http/http_open)).
:- use_module(library(http/json)).
:- use_module(days, [gregorian_date/2]).
:- use_module(library(persistency)).
:- use_module(utils, [pretty_term_string/2]).

% -------------------------------------------------------------------
% Obtains all available exchange rates on the day Day using an arbitrary base currency
% from exchangeratesapi.io. The results are memoized because this operation is slow and
% use of the web endpoint is subject to usage limits. The web endpoint used is
% https://openexchangerates.org/api/historical/YYYY-MM-DD.json?app_id=677e4a964d1b44c99f2053e21307d31a .

:- dynamic exchange_rates/2.

:- persistent(persistently_cached_exchange_rates(day: any, rates:list)).

:- initialization(init).

init :-
	db_attach('tmp/persistently_cached_exchange_rates.pl' , []),
	test0.

exchange_rates(Day, Exchange_Rates) :-
	with_mutex(db, exchange_rates2(Day, Exchange_Rates)).

exchange_rates2(Day, Exchange_Rates) :-
	/*fixme: if yesterday we tried to fetch exchange rates for today, we got an empty list, we should invalidate it.
	we can probably presume that the dates in the request are utc.*/
	(persistently_cached_exchange_rates(Day, Exchange_Rates),!)
	;
	fetch_exchange_rates(Day, Exchange_Rates).

fetch_exchange_rates(Date, Exchange_Rates) :-
	format_time(string(Date_Str), "%Y-%m-%d", Date),
	string_concat("http://openexchangerates.org/api/historical/", Date_Str, Query_Url_A),
	string_concat(Query_Url_A, ".json?app_id=677e4a964d1b44c99f2053e21307d31a", Query_Url),
	format(user_error, '~w ...', [Query_Url]),
	catch(
		http_open(Query_Url, Stream, []),
		% this will happen for dates in future or otherwise not found in their db
		% note that connection error or similar should still propagate and halt the program.
		error(existence_error(_,_),_),
		(
			assert_persistently_cached_exchange_rates(Day, []),
			false
		)
	),
	json_read(Stream, json(Response), []),
	member(rates = json(Exchange_Rates_Uppercase), Response),
	findall(
		Currency_Lowercase = Rate,
		(
			member(Currency_Uppercase = Rate, Exchange_Rates_Uppercase),
			upcase_atom(Currency_Uppercase, Currency_Lowercase)
		),
		Exchange_Rates
	),
	close(Stream),
	format(user_error, '..ok.\n', []),
	assert_persistently_cached_exchange_rates(Day, Exchange_Rates).

% % Predicates for asserting that the fields of given exchange rates have particular values

% The day to which the exchange rate applies
exchange_rate_day(exchange_rate(Day, _, _, _), Day).
% The source currency of this exchange rate
exchange_rate_src_currency(exchange_rate(_, Src_Currency, _, _), Src_Currency).
% The destination currency of this exchange rate
exchange_rate_dest_currency(exchange_rate(_, _, Dest_Currency, _), Dest_Currency).
% The actual rate of this exchange rate
exchange_rate_rate(exchange_rate(_, _, _, Rate), Rate).

% the exchange rates from openexchangerates.org are symmetric, meaning without fees etc

% Obtains the exchange rate from Src_Currency to Dest_Currency on the day Day using the
% given lookup table.

symmetric_exchange_rate(Table, Day, Src_Currency, Report_Currency, Exchange_Rate) :-
	Src_Currency = without_currency_movement_against_since(Goods_Unit, Purchase_Currency, [Report_Currency], Purchase_Date),
	exchange_rate(Table, Purchase_Date, 
		Purchase_Currency, Report_Currency, Old_Rate),
	exchange_rate(Table, Day, 
		Purchase_Currency, Report_Currency, New_Rate),
	exchange_rate(Table, Day, Goods_Unit, Report_Currency, Current),
	Exchange_Rate is Current / New_Rate * Old_Rate.
	
symmetric_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate) :-
  member(exchange_rate(Day, Src_Currency, Dest_Currency, Exchange_Rate), Table),!.

symmetric_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate) :-
  member(exchange_rate(Day, Dest_Currency, Src_Currency, Inverted_Exchange_Rate), Table),
  Inverted_Exchange_Rate =\= 0,
  Exchange_Rate is 1 / Inverted_Exchange_Rate,!.

% Obtains the exchange rate from Src_Currency to Dest_Currency on the day Day using the
% exchange_rates predicate.

symmetric_exchange_rate(_, Day, Src_Currency, Dest_Currency, Exchange_Rate) :-
	exchange_rates(Day, Exchange_Rates),
	member(Src_Currency = Src_Exchange_Rate, Exchange_Rates),
	member(Dest_Currency = Dest_Exchange_Rate, Exchange_Rates),
	Exchange_Rate is Dest_Exchange_Rate / Src_Exchange_Rate.
	
% Derive an exchange rate from the source to the destination currency by chaining together
% =< Length exchange rates.
equivalence_exchange_rate(_, _, Currency, Currency, 1, _Length).
  
equivalence_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate, Length) :-
  Length > 0,
	(
		var(Dest_Currency)
	->
		true
	;
		Dest_Currency \= Src_Currency
	),
  symmetric_exchange_rate(Table, Day, Src_Currency, Int_Currency, Head_Exchange_Rate),
  New_Length is Length - 1,
  equivalence_exchange_rate(Table, Day, Int_Currency, Dest_Currency, Tail_Exchange_Rate, New_Length),
  Exchange_Rate is Head_Exchange_Rate * Tail_Exchange_Rate, !.


% Derive an exchange rate from the source to the destination currency by chaining together
% =< 2 exchange rates.

exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate) :-
/*
	Dest_Currency can be var.
	(
		ground((Table, Day, Src_Currency, Dest_Currency))
	->
		true
	;
		throw('sssss')
	),*/
	all_exchange_rates(Table, Day, Src_Currency, Dest_Currency, Exchange_Rates_Full),
	(
		Exchange_Rates_Full = []
	->
		(
			format(user_error, 'no exchange rate found: Day:~w, Src_Currency:~w, Dest_Currency:~w\n', [Day, Src_Currency, Dest_Currency])
			,fail
		)
	;
		true
	),
	findall(
		params(Day, Src_Currency, Dest_Currency),
		member(rate(Day, Src_Currency, Dest_Currency, Exchange_Rate), Exchange_Rates_Full),
		Params_List_Unsorted
	),
	sort(Params_List_Unsorted, Params_List),
	member(params(Day, Src_Currency, Dest_Currency), Params_List),
	findall(
		Exchange_Rate,
		member(rate(Day, Src_Currency, Dest_Currency, Exchange_Rate), Exchange_Rates_Full),
		Exchange_Rates
	),
	sort(Exchange_Rates, Exchange_Rates_Sorted),
	(
		Exchange_Rates_Sorted = [Exchange_Rate]
	->
		true
	;
		(
			pretty_term_string(Exchange_Rates_Sorted, Str),
			atomic_list_concat(['multiple different exchange rates found: ', Str], Err_Msg),
			throw(Err_Msg)
		)
	),
	(
		Exchange_Rates = [Exchange_Rate]
	->
		true
	;
		(
			format(user_error, 'multiple equal exchange rates found: Day:~w, Src_Currency:~w, Dest_Currency:~w, Exchange_Rates:~w\n', [Day, Src_Currency, Dest_Currency, Exchange_Rates])
			/*,throw('multiple equal exchange rates found')*/
			,Exchange_Rates = [Exchange_Rate|_]
		)
	).	
	
all_exchange_rates(Table, Day, Src_Currency, Dest_Currency, Exchange_Rates_Full) :-
	findall(
		rate(Day, Src_Currency, Dest_Currency, Exchange_Rate),
		(
			(
				equivalence_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate_Raw, 2)
			;
				symmetric_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate_Raw)
			),
			% force everything into float
			Exchange_Rate is 0.0 + Exchange_Rate_Raw
		),
		Exchange_Rates_Full
	).


is_exchangeable_into_request_bases(Table, Day, Src_Currency, Bases) :-
	member(Dest_Currency, Bases),
	exchange_rate(Table, Day, Src_Currency, Dest_Currency, _Exchange_Rate),
	!.

	
test0 :-
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


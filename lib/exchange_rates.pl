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

:- persistent(cached_exchange_rates(day: integer, rates:list)).

:- initialization(db_attach('tmp/cached_exchange_rates.pl' , [])).

exchange_rates(Day, Exchange_Rates) :-
	with_mutex(db, exchange_rates2(Day, Exchange_Rates)).

exchange_rates2(Day, Exchange_Rates) :-
	(cached_exchange_rates(Day, Exchange_Rates),!)
	;
	fetch_exchange_rates(Day, Exchange_Rates).

fetch_exchange_rates(Day, Exchange_Rates) :-
	gregorian_date(Day, Date),
	format_time(string(Date_Str), "%Y-%m-%d", Date),
	string_concat("http://openexchangerates.org/api/historical/", Date_Str, Query_Url_A),
	string_concat(Query_Url_A, ".json?app_id=677e4a964d1b44c99f2053e21307d31a", Query_Url),
	catch(
		http_open(Query_Url, Stream, []),
		% this will happen for dates in future or otherwise not found in their db
		% note that connection error or similar should still propagate and halt the program.
		% todo: does this leave the stream open?
		existence_error(_,_),
		false
	),
	json_read(Stream, json(Response), []),
	member(rates = json(Exchange_Rates), Response),
	close(Stream),
	assert_cached_exchange_rates(Day, Exchange_Rates).

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

symmetric_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate) :-
  member(exchange_rate(Day, Src_Currency, Dest_Currency, Exchange_Rate), Table).

symmetric_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate) :-
  member(exchange_rate(Day, Dest_Currency, Src_Currency, Inverted_Exchange_Rate), Table),
  Inverted_Exchange_Rate =\= 0,
  Exchange_Rate is 1 / Inverted_Exchange_Rate.

% Obtains the exchange rate from Src_Currency to Dest_Currency on the day Day using the
% exchange_rates predicate.

symmetric_exchange_rate(_, Day, Src_Currency_Upcased, Dest_Currency_Upcased, Exchange_Rate) :-
	exchange_rates(Day, Exchange_Rates),
	member(Src_Currency = Src_Exchange_Rate, Exchange_Rates),
	member(Dest_Currency = Dest_Exchange_Rate, Exchange_Rates),
	Exchange_Rate is Dest_Exchange_Rate / Src_Exchange_Rate,
	upcase_atom(Src_Currency, Src_Currency_Upcased),
	upcase_atom(Dest_Currency, Dest_Currency_Upcased).

% Derive an exchange rate from the source to the destination currency by chaining together
% =< Length exchange rates.

equivalence_exchange_rate(_, _, Currency, Currency, 1, Length) :- Length >= 0, !.

equivalence_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate, Length) :-
  Length > 0,
  symmetric_exchange_rate(Table, Day, Src_Currency, Int_Currency, Head_Exchange_Rate),
  New_Length is Length - 1,
  equivalence_exchange_rate(Table, Day, Int_Currency, Dest_Currency, Tail_Exchange_Rate, New_Length),
  Exchange_Rate is Head_Exchange_Rate * Tail_Exchange_Rate, !.


% Derive an exchange rate from the source to the destination currency by chaining together
% =< 2 exchange rates.

exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate) :-
	findall(
		Exchange_Rate,
		(
			equivalence_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate_Raw, 2),
			% force everything into float
			Exchange_Rate is 0.0 + Exchange_Rate_Raw
		),
		Exchange_Rates
	),
	(
		Exchange_Rates = []
	->
	(
		format(user_error, 'no exchange rate found: Day:~w, Src_Currency:~w, Dest_Currency:~w\n', [Day, Src_Currency, Dest_Currency])
		,fail
	)
	;
		true
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

is_exchangeable_into_request_bases(Table, Day, Src_Currency, Bases) :-
	member(Dest_Currency, Bases),
	exchange_rate(Table, Day, Src_Currency, Dest_Currency, _Exchange_Rate),
	!.

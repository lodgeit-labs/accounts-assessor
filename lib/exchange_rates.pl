:- use_module(library(persistency)).

:- record exchange_rate(day, src_currency, dest_currency, rate).
% The day to which the exchange rate applies
% The source currency of this exchange rate
% The destination currency of this exchange rate
% The actual rate of this exchange rate

:- dynamic exchange_rates/2.
:- persistent(persistently_cached_exchange_rates(day: any, rates:list)).
:- initialization(init_exchange_rates).

init_exchange_rates :-
	absolute_file_name(my_cache('persistently_cached_exchange_rates.pl'), File, []),
	db_attach(File, []).

exchange_rates(Day, Exchange_Rates) :-
	with_mutex(db, exchange_rates_thread_guarded(Day, Exchange_Rates)).

/*
	do we have this cached already?
*/
exchange_rates_thread_guarded(Day, Exchange_Rates) :-
	persistently_cached_exchange_rates(Day, Exchange_Rates),
	!.

/* 
	avoid trying to fetch data from future
*/
exchange_rates_thread_guarded(Day, Exchange_Rates) :-
	date(Today),
	Day @=< Today,
	fetch_exchange_rates(Day, Exchange_Rates).

% Obtains all available exchange rates on the day Day using an arbitrary base currency
% from exchangeratesapi.io. The results are memoized because this operation is slow and
% use of the web endpoint is subject to usage limits. The web endpoint used is
% https://openexchangerates.org/api/historical/YYYY-MM-DD.json?app_id=677e4a964d1b44c99f2053e21307d31a .
% the exchange rates from openexchangerates.org are symmetric, meaning without fees etc
fetch_exchange_rates(Date, Exchange_Rates) :-
	/* note that invalid dates get "recomputed", for example date(2010,1,33) becomes 2010-02-02 */
	format_time(string(Date_Str), "%Y-%m-%d", Date),
	string_concat("http://openexchangerates.org/api/historical/", Date_Str, Query_Url_A),
	string_concat(Query_Url_A, ".json?app_id=677e4a964d1b44c99f2053e21307d31a", Query_Url),
	format(user_error, '~w ...', [Query_Url]),
	catch(
		http_open(Query_Url, Stream, []),
		% this will happen for dates in not found in their db, like too historical.
		% we don't call this predicate for future dates.
		% note that connection error or similar should still propagate and halt the program.
		error(existence_error(_,_),_),
		(
			assert_rates(Date, []),
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
	assert_rates(Date, Exchange_Rates).

/* 
	now put it in the cache file 
*/
assert_rates(Date, Exchange_Rates) :-
	/* these are debugging assertions, not fact asserts*/
	assertion(ground(Date)), 
	assertion(ground(Exchange_Rates)),
	assert_persistently_cached_exchange_rates(Date, Exchange_Rates).

/*
	this predicate deals with two special Src_Currency terms
*/
/* this one lets us compute unrealized gains without currency movement declaratively */
special_exchange_rate(Table, Day, Src_Currency, Report_Currency, Rate) :-
	Src_Currency = without_currency_movement_against_since(Goods_Unit, Purchase_Currency, [Report_Currency], Purchase_Date),
	exchange_rate2(Table, Purchase_Date, 
		Purchase_Currency, Report_Currency, Old_Rate),
	exchange_rate2(Table, Day, 
		Purchase_Currency, Report_Currency, New_Rate),
	exchange_rate2(Table, Day, Goods_Unit, Report_Currency, Current),
	Rate = Current / New_Rate * Old_Rate.

/* obtain the Report_Currency value using the with_cost_per_unit data */
special_exchange_rate(_Table, _Day, Src_Currency, Report_Currency, Rate) :-
	Src_Currency = with_cost_per_unit(_Goods_Unit, value(Report_Currency, Rate)).

% Obtains the exchange rate from Src_Currency to Dest_Currency on the day Day using the
% given lookup table.
extracted_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate) :-
  member(exchange_rate(Day, Src_Currency, Dest_Currency, Exchange_Rate), Table).

/* try to find an exchange rate in the reverse direction */
extracted_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate) :-
  member(exchange_rate(Day, Dest_Currency, Src_Currency, Inverted_Exchange_Rate), Table),
  Inverted_Exchange_Rate =\= 0,
  Exchange_Rate = 1 / Inverted_Exchange_Rate.

% Obtains the exchange rate from Src_Currency to Dest_Currency on the day Day using the
% exchange_rates predicate. Given the fetched table, this predicate works in any direction between any two currencies
fetched_exchange_rate(Day, Src_Currency, Dest_Currency, Exchange_Rate) :-
	%format(user_error, 'using API exchange rates for Day:~w, Src_Currency:~w, Dest_Currency:~w ...\n', [Day, Src_Currency, Dest_Currency]),
	%format('<!--using API exchange rates for Day:~w, Src_Currency:~w, Dest_Currency:~w ...-->\n', [Day, Src_Currency, Dest_Currency]),
	exchange_rates(Day, Exchange_Rates),
	member(Src_Currency = Src_Exchange_Rate, Exchange_Rates),
	member(Dest_Currency = Dest_Exchange_Rate, Exchange_Rates),
	Exchange_Rate = Dest_Exchange_Rate / Src_Exchange_Rate.

/* currency to itself has exchange rate 1 */
best_nonchained_exchange_rates(_, _, Src_Currency, Src_Currency, [(Src_Currency, 1)]).
	
best_nonchained_exchange_rates(Table, Day, Src_Currency, Dest_Currency, Rates) :-
	findall((Dest_Currency, Rate), special_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Rate), Rates1),
	(Rates1 \= [] -> Rates = Rates1;
	(findall((Dest_Currency, Rate), extracted_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Rate), Rates2),
	(Rates2 \= [] -> Rates = Rates2;
	(findall((Dest_Currency, Rate), fetched_exchange_rate(Day, Src_Currency, Dest_Currency, Rate), Rates3),
	(Rates3 \= [] -> Rates = Rates3;
	fail))))).
	
best_nonchained_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Rate) :-
	best_nonchained_exchange_rates(Table, Day, Src_Currency, Dest_Currency, Rates),
	member((Dest_Currency, Rate), Rates).

% Derive an exchange rate from the source to the destination currency by chaining together
% =< Length exchange rates.
chained_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate, _) :-
	best_nonchained_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate).

chained_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate, Length) :-
	Length > 0,
	(
		var(Dest_Currency)
	->
		true
	;
		Dest_Currency \= Src_Currency
	),
	/* get conversions into any currency */
	best_nonchained_exchange_rate(Table, Day, Src_Currency, Int_Currency, Head_Exchange_Rate),
	Int_Currency \= Src_Currency,
	New_Length is Length - 1,
	chained_exchange_rate(Table, Day, Int_Currency, Dest_Currency, Tail_Exchange_Rate, New_Length),
	Exchange_Rate = Head_Exchange_Rate * Tail_Exchange_Rate.

/* cant take historical eachange rate and chain it with a nonhistorical one*/
without_movement_after(Table, Exchange_Date, Src, Dst, Rate) :-
	Src = without_movement_after(Unit, Freeze_Date),
	(
		Freeze_Date @> Exchange_Date
	->
		Exchange_Date2 = Exchange_Date
	;
		Exchange_Date2 = Freeze_Date 
	),
	exchange_rate2(Table, Exchange_Date2, Unit, Dst, Rate).
	
all_exchange_rates(Table, Day, Src_Currency, Dest_Currency, Exchange_Rates_Full) :-
	assertion(nonvar(Dest_Currency)),
	findall(
		(Dest_Currency, Rate), 
		without_movement_after(Table, Day, Src_Currency, Dest_Currency, Rate),
		Best_Rates1
	),
	(
		Best_Rates1 \= []
	-> 
		Best_Rates = Best_Rates1
	;
		/*(
			is called by chained_exchange_rate:
			best_nonchained_exchange_rates(Table, Day, Src_Currency, Dest_Currency, Best_Rates)
		->
			true
		;*/
		(
			fail
		->
			%finding all exchange rates just to make sure they are all the same:
			findall((Dest_Currency, Rate), chained_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Rate, 2), Best_Rates)
		;			
			(
				Best_Rates = [(Dest_Currency, Rate)], 
				once(chained_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Rate, 2))
			)
		)
	),
	force_rates_into_float(Day, Src_Currency, Best_Rates, Exchange_Rates_Full).

force_rates_into_float(Day, Src_Currency, Best_Rates, Exchange_Rates_Full) :-
	findall(
		rate(Day, Src_Currency, Dest_Currency, Exchange_Rate),
		(
			member((Dest_Currency,Exchange_Rate_Raw), Best_Rates),
			% force everything into float
			Exchange_Rate is 0.0 + Exchange_Rate_Raw
		),
		Exchange_Rates_Full
	).
	
% Derive an exchange rate from the source to the destination currency by chaining together
% =< 2 exchange rates.

exchange_rate2(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate_Out) :-
	/*either we will allow this pred to take unbound arguments or not, not decided yet, hence the sorting by params below */
	assertion(ground((Table, Day, Src_Currency, Dest_Currency))),
	all_exchange_rates(Table, Day, Src_Currency, Dest_Currency, Exchange_Rates_Full),
	findall(
		params(Day, Src_Currency, Dest_Currency),
		member(rate(Day, Src_Currency, Dest_Currency, _), Exchange_Rates_Full),
		Params_List_Unsorted
	),
	sort(Params_List_Unsorted, Params_List),
	member(params(Day, Src_Currency, Dest_Currency), Params_List),
	findall(
		Rate,
		(
			member(rate(Day, Src_Currency, Dest_Currency, Rate_Term), Exchange_Rates_Full),
			Rate is Rate_Term
		),
		Exchange_Rates
	),
	sort(Exchange_Rates, Exchange_Rates_Sorted),
	findall(
		_,
		(
			member(R1, Exchange_Rates_Sorted),
			member(R2, Exchange_Rates_Sorted),
			(
				floats_close_enough(R1, R2)
			->
				true
			;
				(
					format(string(Str), 'multiple different exchange rates found for: Day:~w, Src_Currency:~w, Dest_Currency:~w, rates found:~w\n', [Day, Src_Currency, Dest_Currency, Exchange_Rates_Sorted]),
					throw_string(Str)
				)
			)
		),
		_
	),
	Exchange_Rates_Sorted = [Exchange_Rate_Out|_].

:- table(exchange_rate/5).
exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate_Out) :-
	%write(exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate_Out)),writeln('...'),
	exchange_rate2(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate_Out)
	%,writeln('ok')
	.

%:- table(exchange_rate_throw/5).
exchange_rate_throw(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate_Out) :-
	(
		exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate_Out)
	->
		true
	;
		(
			format(string(Msg1), 'no exchange rate found: Day:~w, Src_Currency:~w, Dest_Currency:~w\n', [Day, Src_Currency, Dest_Currency]),
			date(Today),
			(
				Day @> Today
			->
				Msg2 = ', date in future?'
			;
				Msg2 = ''
			),
			throw_string([Msg1, Msg2])
		)
	).

	
is_exchangeable_into_request_bases(Table, Day, Src_Currency, Bases) :-
	member(Dest_Currency, Bases),
	exchange_rate(Table, Day, Src_Currency, Dest_Currency, _Exchange_Rate).


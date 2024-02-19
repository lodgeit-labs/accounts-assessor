:- use_module(library(persistency)).

:- record exchange_rate(day, src_currency, dest_currency, rate).
% The day to which the exchange rate applies
% The source currency of this exchange rate
% The destination currency of this exchange rate
% The actual rate of this exchange rate

% ________
%< lookup >
% --------
%        \   ^__^
%         \  (oo)\_______
%            (__)\       )\/\
%                ||----w |
%                ||     ||

:- dynamic exchange_rates/2.
:- persistent(persistently_cached_exchange_rates(day: any, rates:list)).
%:- initialization(init_exchange_rates).

%init_exchange_rates :-
%	for shared cache:
%	absolute_file_name(my_cache('persistently_cached_exchange_rates.pl'), File, []),
%	db_attach(File, []).

init_exchange_rates_tmp_cache :-
	absolute_tmp_path(loc(file_name, 'exchange_rates.pl'), loc(absolute_path, File)),	
	db_attach(File, []).


/*
	do we have this cached already?
*/
exchange_rates(Day, Exchange_Rates) :-
	cf(persistently_cached_exchange_rates(Day, Exchange_Rates)),
	!.

/* 
	avoid trying to fetch data from future
*/
exchange_rates(Day, Exchange_Rates) :-
	date(Today),
	% 2, because timezones and stuff. This should result in us not making queries for exchange rates more than 48h into the future, but definitely not to errorneously refusing to query because we think Day is in future when it isnt.
	add_days(Today, 2, Tomorrow),
	Day @=< Tomorrow,
	cf(fetch_exchange_rates(Day, Exchange_Rates)).

% Obtains all available exchange rates on the day Day using an arbitrary base currency
% from exchangeratesapi.io. The results are memoized because this operation is slow and
% use of the web endpoint is subject to usage limits. The web endpoint used is
% https://openexchangerates.org/api/historical/YYYY-MM-DD.json?app_id=677e4a964d1b44c99f2053e21307d31a .
% the exchange rates from openexchangerates.org are symmetric, meaning without fees etc
fetch_exchange_rates(Date, Exchange_Rates) :-
	/* note that invalid dates get "recomputed", for example date(2010,1,33) becomes 2010-02-02 */
	format_time(string(Date_Str), "%Y-%m-%d", Date),
	
	%string_concat("http://openexchangerates.org/api/historical/", Date_Str, Query_Url_A),
	%string_concat(Query_Url_A, ".json?app_id=677e4a964d1b44c99f2053e21307d31a", Query_Url),
	atomic_list_concat([$>manager_url(<$), '/exchange_rates/', Date_Str], Query_Url),
	
	format(user_error, '~w ...', [Query_Url]),
	catch(
		http_open(Query_Url, Stream, [request_header('User-Agent'='Robust1')]),
		error(existence_error(_,_),_),
		(
			% this will happen for dates not found in their db, like too historical.
			% ideally, we just wouldn't call this predicate for future dates, but what is a future date?
			%assert_rates(Date, []),
			false
		)
	),
	json_read(Stream, json(Response), []),
	member(rates = json(Exchange_Rates_Uppercase), Response),
	findall(
		Currency_Lowercase = Rate,
		(
			member(Currency_Uppercase = Rate0, Exchange_Rates_Uppercase),
			Rate is rationalize(Rate0),
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
	assertion(ground(Date)),
	assertion(ground(Exchange_Rates)),
	assert_persistently_cached_exchange_rates(Date, Exchange_Rates).

/*
	this predicate deals with two special Src_Currency terms
*/
/*
This one lets us compute unrealized gains excluding forex declaratively. The computation uses exchange day's unit values, and the difference between exchange day's currency rate and purchase date currency rate. Therefore, purchase date's unit value does not have to be entered.
*/
 special_exchange_rate(Table, Day, Src_Currency, Report_Currency, Rate) :-
	Src_Currency = without_currency_movement_against_since(
		Goods_Unit,
		Purchase_Currency,
		[Report_Currency],
		Purchase_Date
	),
	exchange_rate2(Table, Purchase_Date, 
		Purchase_Currency, Report_Currency, Old_Rate),
	exchange_rate2(Table, Day, 
		Purchase_Currency, Report_Currency, New_Rate),
	exchange_rate2(Table, Day, Goods_Unit, Report_Currency, Current),
	{Rate = Current / New_Rate * Old_Rate}.

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
  {Exchange_Rate = 1 / Inverted_Exchange_Rate}.

% Obtains the exchange rate from Src_Currency to Dest_Currency on the day Day using the
% exchange_rates predicate. Given the fetched table, this predicate works in any direction between any two currencies
fetched_exchange_rate(Day, Src_Currency, Dest_Currency, Exchange_Rate) :-
	%format(user_error, 'using API exchange rates for Day:~w, Src_Currency:~w, Dest_Currency:~w ...\n', [Day, Src_Currency, Dest_Currency]),
	%format('<!--using API exchange rates for Day:~w, Src_Currency:~w, Dest_Currency:~w ...-->\n', [Day, Src_Currency, Dest_Currency]),
	exchange_rates(Day, Exchange_Rates),
	member(Src_Currency = Src_Exchange_Rate, Exchange_Rates),
	member(Dest_Currency = Dest_Exchange_Rate, Exchange_Rates),
	{Exchange_Rate = Dest_Exchange_Rate / Src_Exchange_Rate}.

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
	{Exchange_Rate = Head_Exchange_Rate * Tail_Exchange_Rate}.

/*
Cant take historical exchange rate and chain it with a nonhistorical one.
In other words, if we aquire, before report start, an investment in a foreign currency,
then our historical gains on that investement are expressed with help of without_movement_after.
It makes sure that not only is the unit value from correct date used, but that also the subsequent conversion into report currency is done at that date's rates.
*/
 without_movement_after(Table, Exchange_Date, Src, Dst, Rate) :-
	Src = without_movement_after(Unit, Freeze_Date),
	% let Exchange_Date2 be the smaller of Exchange_Date and Freeze_Date
	(	Freeze_Date @> Exchange_Date
	->	Exchange_Date2 = Exchange_Date
	;	Exchange_Date2 = Freeze_Date),
	exchange_rate2(Table, Exchange_Date2, Unit, Dst, Rate).
	
 all_exchange_rates(Table, Day, Src_Currency, Dest_Currency, Exchange_Rates_Full) :-
	assertion(nonvar(Dest_Currency)),
	findall(
		(Dest_Currency, Rate), 
		without_movement_after(Table, Day, Src_Currency, Dest_Currency, Rate),
		Best_Rates1
	),
	(	Best_Rates1 \= []
	->	Best_Rates = Best_Rates1
	;	(	false
		->	%for debugging, find all exchange rates just to make sure they are all the same:
			!findall(
				(Dest_Currency, Rate),
				chained_exchange_rate(Table, Day, Src_Currency, Dest_Currency, Rate, 2),
				Best_Rates
			)
		;	(
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
			Exchange_Rate is rationalize(Exchange_Rate_Raw)
		),
		Exchange_Rates_Full
	).
	
% Derive an exchange rate from the source to the destination currency by chaining together
% =< 2 exchange rates.

exchange_rate2(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate_Out) :-
	/*either we will allow this pred to take unbound arguments or not, not decided yet, hence the sorting by params below */
	assertion(ground((Table, Day, Src_Currency, Dest_Currency))), % if inputs must be ground, the below can be greatly simplified
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
	
	% this is the only useful part - check each rate against each other, if they differ, throw
	findall(
		_,
		(
			member(R1, Exchange_Rates_Sorted),
			member(R2, Exchange_Rates_Sorted),
			(	floats_close_enough(R1, R2)
			->	true
			;	(
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
	push_format('~q', [exchange_rate(Day, Src_Currency, Dest_Currency)]),
	%write(exchange_rate(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate_Out)),writeln('...'),
	exchange_rate2(Table, Day, Src_Currency, Dest_Currency, Exchange_Rate_Out),
	pop_format
	.

exchange_rate_throw(Table, Day, Src, Dest, Exchange_Rate_Out) :-
	(	exchange_rate(Table, Day, Src, Dest, Exchange_Rate_Out)
	->	true
	;	exchange_rate_do_throw(Day, Src, Dest)).

exchange_rate_do_throw(Day, Src, Dest) :-
	(	'is required exchange rate physically in future'(Day)
	->	Msg2 = ', date in future?'
	;	Msg2 = ''),
	throw_format('no exchange rate found: Day:~w, Src:~w, Dest:~w~w\n', [Day, Src, Dest, Msg2]).

'is required exchange rate physically in future'(Day) :-
	!date(Today),
	Day @> Today.

	
is_exchangeable_into_request_bases(Table, Day, Src_Currency, Bases) :-
	member(Dest_Currency, Bases),
	exchange_rate(Table, Day, Src_Currency, Dest_Currency, _Exchange_Rate).


/*
┏━╸╻ ╻╺┳╸┏━┓┏━┓┏━╸╺┳╸
┣╸ ┏╋┛ ┃ ┣┳┛┣━┫┃   ┃
┗━╸╹ ╹ ╹ ╹┗╸╹ ╹┗━╸ ╹
*/
 extract_exchange_rates :-
	(	at_cost
	->	Exchange_Rates = []
	;	extract_exchange_rates1(Exchange_Rates)),
	!add_comment_stringize('Exchange rates extracted', Exchange_Rates),
	!result_add_property(l:exchange_rates, Exchange_Rates).


 extract_exchange_rates1(Exchange_Rates) :-
 	!get_sheet_data(ic_ui:unit_values_sheet, X),

	(	(
			doc(X, excel:has_unknown_fields, Fields0),
			!doc_list_items(Fields0, Fields),
			maplist(!parse_date_field, Fields)
		)
	->	true
	;	Fields = []),

	!doc(X, rdf:value, Items0),
	!doc_list_items(Items0, Items),
	maplist(extract_exchange_rates2(Fields), Items, Exchange_Rates0),

	flatten(Exchange_Rates0, Exchange_Rates),
	maplist(assert_ground, Exchange_Rates),
	true.


 parse_date_field(Field) :-
	!doc(Field, excel:has_header_cell_value, V),
	(	V = date(_,_,_)
	->	(
			Date = V,
			check_date(Date)
		)
	;	(	V = "opening"
		->	!result_property(l:start_date, Date))
		;	(	V = "closing"
			->	!result_property(l:end_date, Date))
			;	throw_format('unexpected unit value header (must be either "opening" or "closing" or a valid date): ~q', [V])),
	doc_add(Field, l:parsed_as_date, Date).


 extract_exchange_rates2(Fields, Item, Rates) :-

	/* Item here is a row in the unit values sheet. For each such row, there can be several "unknown field" cells, each of which contains an exchange rate. Alternatively, an Item can instead have an "l:date" property. */

	!doc_value(Item, uv:name, Src0),
	atom_string(Src,Src0),

	(	doc_value(Item, uv:currency, Dst0)
	->	atom_string(Dst, Dst0)
	;	!result_property(l:report_currency, [Dst])),

	findall(
		exchange_rate(Date, Src, Dst, V),
		(
			(
				member(Field, Fields),
				doc_value(Item, Field, V0),
				my_number_string(V,V0),
				!doc(Field, l:parsed_as_date, Date)
			)
			;
			(
				doc_value(Item, uv:date, Date),
				doc_value(Item, uv:value, V)
			)
		),
		Rates
	).



	/*If an investment was held prior to the from date then it MUST have an opening market value if the reports are expressed in.market rather than cost.You can't mix market value and cost in one set of reports. One or the other.2:27 AMi see. Have you thought about how to let the user specify the method?Andrew, 2:31 AMMarket or Cost. M or C. Sorry. Never mentioned it to you.2:44 AMyou mentioned the different approaches, but i ended up assuming that this would be best selected by specifying or not specifying the unitValues. I see there is a field for it already in the excel templateAndrew, 2:47 AMCost value per unit will always be there if there are units of anything i.e. sheep for livestock trading or shares for InvestmentsAndrew, 3:04 AMBut I suppose if you do not find any market values then assume cost basis.*/

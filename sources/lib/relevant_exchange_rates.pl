
/*
fixme, this gets also some irrelevant ones
*/
/*
print_relevant_exchange_rates_comment([], _, _, _).

print_relevant_exchange_rates_comment([Report_Currency], Report_End_Date, Exchange_Rates, Transactions) :-
	findall(
		Exchange_Rates2,
		(
			get_relevant_exchange_rates2([Report_Currency], Exchange_Rates, Transactions, Exchange_Rates2)
			;
			get_relevant_exchange_rates2([Report_Currency], Report_End_Date, Exchange_Rates, Transactions, Exchange_Rates2)
		),
		Relevant_Exchange_Rates
	),
	pretty_term_string(Relevant_Exchange_Rates, Message1c),
	atomic_list_concat([
		'\n<!--',
		'Exchange rates2:\n', Message1c,'\n\n',
		'-->\n\n'],
	Debug_Message2),
	writeln(Debug_Message2).


get_relevant_exchange_rates2([Report_Currency], Exchange_Rates, Transactions, Exchange_Rates2) :-
	% find all days when something happened
	findall(
		Date,
		(
			member(T, Transactions),
			transaction_day(T, Date)
		),
		Dates_Unsorted0
	),
	sort(Dates_Unsorted0, Dates),
	member(Date, Dates),
	%find all currencies used
	findall(
		Currency,
		(
			member(T, Transactions),
			transaction_vector(T, Vector),
			transaction_day(T,Date),
			vec_units(Vector, Vector_Units),
			member(Currency, Vector_Units)
		),
		Currencies_Unsorted
	),
	sort(Currencies_Unsorted, Currencies),
	% produce all exchange rates
	findall(
		exchange_rate(Date, Src_Currency, Report_Currency, Exchange_Rate),
		(
			member(Src_Currency, Currencies),
			\+member(Src_Currency, [Report_Currency]),
			exchange_rate(Exchange_Rates, Date, Src_Currency, Report_Currency, Exchange_Rate)
		),
		Exchange_Rates2
	).

get_relevant_exchange_rates2([Report_Currency], Date, Exchange_Rates, Transactions, Exchange_Rates2) :-
	%find all currencies from all transactions, TODO: , find only all currencies appearing in totals of accounts at the report end date
	findall(
		Currency,
		(
			member(T, Transactions),
			transaction_vector(T, Vector),
			member(coord(Currency, _), Vector)
		),
		Currencies_Unsorted
	),
	sort(Currencies_Unsorted, Currencies),
	% produce all exchange rates
	findall(
		exchange_rate(Date, Src_Currency, Report_Currency, Exchange_Rate),
		(
			member(Src_Currency, Currencies),
			\+member(Src_Currency, [Report_Currency]),
			exchange_rate(Exchange_Rates, Date, Src_Currency, Report_Currency, Exchange_Rate)
		),
		Exchange_Rates2
	).
*/

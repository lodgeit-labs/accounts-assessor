% not used, seems like there's little point keeping this up to date while we develop the new framework

do_livestock_crosscheck(Events, Natural_Increase_Costs, S_Transactions, Transactions, Opening_Costs_And_Counts, _From_Day, To_Day, Exchange_Rates, Report_Currency, Average_Costs, Type) :-
	% gather up the inputs
	natural_increase_count(Type, Events, Natural_Increase_Count),
	member(natural_increase_cost(Type, [coord(Currency, Natural_Increase_Cost_Per_Head, 0)]), Natural_Increase_Costs),
	sales_and_buys_count(Type, S_Transactions, Buys_Count, Buys_Value, Sales_Count, Sales_Value),
	events_count(Type, Events, _Borns_Count, Losses_Count, Rations_Count),
	member(Opening_Cost_And_Count, Opening_Costs_And_Counts),
	Opening_Cost_And_Count = opening_cost_and_count(Type, [coord(Currency, Opening_Cost, 0)], Opening_Count),

	compute_livestock_by_simple_calculation(
	% input
		Natural_Increase_Count,
		Natural_Increase_Cost_Per_Head,
		Sales_Count,
		Sales_Value,
		Rations_Count,
		Opening_Count,
		Opening_Cost,
		_,
		Buys_Count,
		Buys_Value,
		Losses_Count,
	% output
		Rations_Value,
		Closing_Cost,
		_,
		_,
		_,
		_,
		Natural_Increase_value,
		Average_Cost,
		Revenue,
		Livestock_COGS,
		Gross_Profit_on_Livestock_Trading,
		_Explanation),

	% now check the output
	member(Opening_Cost_And_Count, Opening_Costs_And_Counts),
	opening_cost_and_count(Type, _, _) = Opening_Cost_And_Count,

	member(Average_Cost_Exchange_Rate, Average_Costs),
	exchange_rate(_, Type, Currency, Average_Cost) = Average_Cost_Exchange_Rate,

	livestock_cogs_rations_account(Type, Cogs_Rations_Account),
	balance_by_account([], Transactions, [], _, Cogs_Rations_Account, To_Day, Cogs_Balance, _),

	(
		Cogs_Balance = [coord(Currency, 0, Rations_Value)]
	->
		true
	;
		(
			Cogs_Balance = [],
			Rations_Value =:= 0
		)
	),
	%needs updating to latest pacioli changes
	livestock_at_average_cost_at_day(Type, Transactions, Opening_Cost_And_Count, To_Day, Average_Cost_Exchange_Rate, [coord(Currency, Closing_Cost, 0)]),

	Natural_Increase_value is Natural_Increase_Count * Natural_Increase_Cost_Per_Head,

	balance_by_account(Exchange_Rates, Transactions, Report_Currency, To_Day, 'Revenue', To_Day, Revenue_Credit,_),
	vec_inverse(Revenue_Credit, [Revenue_Coord_Ledger]),
	number_coord(Currency, Revenue, Revenue_Coord),

	balance_by_account(Exchange_Rates, Transactions, Report_Currency, To_Day, 'Cost_of_Goods_Livestock', To_Day, [Cogs_Coord_Ledger],_),
	number_coord(Currency, Livestock_COGS, Cogs_Coord),

	balance_by_account(Exchange_Rates, Transactions, Report_Currency, To_Day, 'Earnings', To_Day, Earnings_Credit,_),
	vec_inverse(Earnings_Credit, [Earnings_Coord_Ledger]),
	number_coord(Currency, Gross_Profit_on_Livestock_Trading, Earnings_Coord),

	/*
	fixme, the simple calculator should total these three for all livestock types? if it should support multiple livestock datasets at once at all.
	also, ledger can process other transactions besides livestock, so these totals then wont add up.
	we should figure out how to only do these checks maybe during testing, on some pre-defined files
	*/

	compile_with_variable_names_preserved(_ = [
		Revenue_Coord_Ledger, Revenue_Coord,
		Cogs_Coord_Ledger, Cogs_Coord,
		Earnings_Coord_Ledger, Earnings_Coord
	], Namings),
	pretty_term_string(Namings, Namings_Str),
	format(user_error, 'these should match, in absence of non-livestock bank transactions, and with only one livestock type processed: ~w', [Namings_Str]).




sales_and_buys_count(Livestock_Type, S_Transactions, Buys_Count, Buys_Value, Sales_Count, Sales_Value) :-
	maplist6(sales_and_buys_count2(Livestock_Type), S_Transactions, Buys_Count_List, Buys_Value_List, Sales_Count_List, Sales_Value_List),
	sum_list(Buys_Count_List, Buys_Count),
	sum_list(Buys_Value_List, Buys_Value),
	sum_list(Sales_Count_List, Sales_Count),
	sum_list(Sales_Value_List, Sales_Value).

sales_and_buys_count2(Livestock_Type, S_Transaction, Buys_Count, Buys_Value, 0, 0) :-
	s_transaction_is_livestock_buy_or_sell(S_Transaction, _Day, Livestock_Type, Livestock_Coord, _, _, _, 0, Buys_Value),
	!,
	coord(Livestock_Type, Buys_Count, 0) = Livestock_Coord.

sales_and_buys_count2(Livestock_Type, S_Transaction, 0, 0, Sales_Count, Sales_Value) :-
	s_transaction_is_livestock_buy_or_sell(S_Transaction, _Day, Livestock_Type, Livestock_Coord, _, _, _, Sales_Value, 0),
	!,
	coord(Livestock_Type, 0, Sales_Count) = Livestock_Coord.

sales_and_buys_count2(_,_,0,0,0,0).



events_count(Type, Events, Borns, Losses, Rations) :-
	maplist(events_count2(Type), Events, Borns_List, Losses_List, Rations_List),
	sum_list(Borns_List, Borns),
	sum_list(Losses_List, Losses),
	sum_list(Rations_List, Rations).

events_count2(Type, Event, Borns, Losses, Rations) :-
	(Event = born(Type, _Day, Borns), Rations=0, Losses=0);
	(Event = loss(Type, _Day, Losses), Rations=0, Borns=0);
	(Event = rations(Type, _Day, Rations), Losses=0, Borns=0).

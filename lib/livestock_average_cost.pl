
infer_average_cost(Livestock, S_Transactions) :-
	doc(Livestock, livestock:currency, Currency),
	doc(Livestock, livestock:average_cost, Average_Cost),
	doc(Livestock, livestock:opening_cost, Opening_Cost),
	doc(Livestock, livestock:opening_count, Opening_Count),
	doc(Livestock, livestock:natural_increase_value_per_unit, Natural_Increase_Cost_Per_Head),
	doc(Livestock, livestock:born_count, Natural_Increase_Count),
	purchases_cost_and_count(Livestock, S_Transactions, Purchases_Cost, Purchases_Count),
	value_convert(Natural_Increase_Count, Natural_Increase_Cost_Per_Head, Natural_Increase_Value),
	vec_add([Opening_Cost, Purchases_Cost, Natural_Increase_Value], [], [Opening_And_Purchases_And_Increase_Value]),
	vec_add([Opening_Count, Purchases_Count, Natural_Increase_Count], [],[Opening_And_Purchases_And_Increase_Count]),
	(	is_zero(Opening_And_Purchases_And_Increase_Count)
	->	Average_Cost = value(Currency, 0)
	;	value_divide2(Opening_And_Purchases_And_Increase_Value, Opening_And_Purchases_And_Increase_Count, Average_Cost)),
	true.


% natural increase count given livestock type and all livestock events
natural_increase_count(Type, [E | Events], Natural_Increase_Count) :-
	(E = born(Type, _Day, Count) ->
		C = Count;
		C = 0),
	natural_increase_count(Type, Events, Natural_Increase_Count_1),
	Natural_Increase_Count is Natural_Increase_Count_1 + C.

natural_increase_count(_, [], 0).


/* todo this should eventually work off transactions */

purchases_cost_and_count(Livestock, S_Transactions, Cost, Count) :-
	findall(
		T,
		(
			member(T, S_Transactions),
			s_transaction_type_id(T, uri(V)),
			rdf_global_id(l:livestock_purchase,V)
		),
		Ts),
	doc(Livestock, livestock:name, Type),
	doc(Livestock, livestock:currency, Currency),
	/* a bit overcomplicated, since we should supply the currency and livestock unit in case there were no transactions. */
	maplist(purchase_cost_and_count(Type), Ts, Costs, Counts),
	foldl(coord_merge, Costs, value(Currency, 0), Cost),
	foldl(coord_merge, Counts, value(Type, 0), Count).


purchase_cost_and_count(Type, ST, Cost, Count) :-
	/* fixme, this should work off gl transactions, probably expenses? */
	s_transaction_is_livestock_buy_or_sell(ST, Date, Type, Livestock_Coord, Money_Coord),
	date_in_request_period(Date),
	is_credit(Money_Coord),
	coord_normal_side_value(Money_Coord, credit, Cost),
	coord_normal_side_value(Livestock_Coord, debit, Count).



livestock_at_average_cost_at_day(Livestock, Transactions_By_Account, End_Date, Closing_Value) :-
	livestock_count(Livestock, Transactions_By_Account, End_Date, Count),
	doc(Livestock, livestock:average_cost,  Average_Cost),
	value_convert(Count, Average_Cost, Closing_Value).

livestock_count(Livestock, Transactions_By_Account, End_Date, Count) :-
	doc(Livestock, livestock:opening_count, Opening_Count_Value),
	value_debit_vec(Opening_Count_Value, Opening_Count_Vec),
	doc(Livestock, livestock:name, Type),
	count_account(Type, Count_Account),
	balance_by_account([], Transactions_By_Account, [], _, Count_Account, End_Date, Count_Vector, _),
	vec_add(Count_Vector, Opening_Count_Vec, Closing_Vec),
	value_debit_vec(Count, Closing_Vec).




infer_average_cost(Livestock, S_Transactions) :-
	doc(Livestock, livestock:name, Type),
	doc(Livestock, livestock:currency, Currency),
	doc(Livestock, livestock:average_cost, Average_Cost),
	doc(Livestock, livestock:opening_cost, Opening_Cost),
	doc(Livestock, livestock:opening_count, Opening_Count),
	doc(Livestock, livestock:natural_increase_value_per_unit, Natural_Increase_Cost_Per_Head),
	doc(Livestock, livestock:born_count, Natural_Increase_Count),
	purchases_cost_and_count(Type, S_Transactions, Purchases_Cost, Purchases_Count),
	value_convert(Natural_Increase_Count, Natural_Increase_Cost_Per_Head, Natural_Increase_Value),
	value_sum([Opening_Cost, Purchases_Cost, Natural_Increase_Value], Opening_And_Purchases_And_Increase_Value),
	value_sum([Opening_Count, Purchases_Count, Natural_Increase_Count], Opening_And_Purchases_And_Increase_Count),
	(	is_zero(Opening_And_Purchases_And_Increase_Count)
	->	Average_Cost = value(Currency, 0)
	;	value_div(Opening_And_Purchases_And_Increase_Value, Opening_And_Purchases_And_Increase_Count, Average_Cost)),
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

purchases_cost_and_count(Type, S_Transactions, Cost, Count) :-
	purchases_cost_and_count2(Type, S_Transactions, Costs, Counts),
	flatten(Costs, Cost_Vec),
	flatten(Counts, Count_Vec),
	gtrace,
	vec_sum(Cost_Vec, Cost_Coord),
	vec_sum(Count_Vec, Count_Coord),
	make_debit(Cost_Coord, Cost),
	make_debit(Count_Coord, Count).

purchases_cost_and_count2(_, [], [], []).

purchases_cost_and_count2(Type, [ST | S_Transactions], [Cost|Costs], [Count|Counts]) :-
	gtrace,
	(	(
			s_transaction_is_livestock_buy_or_sell(ST, Date, Type, Livestock_Coord, Money_Coord),
			days:date_in_request_period(Date),
			is_credit(Money_Coord)

		)
	->	(	make_credit(Cost, Money_Coord),
			number_vec(Type, Count, Livestock_Coord)
		)
	;	purchases_cost_and_count2(Type, S_Transactions, Costs, Counts)).


livestock_at_average_cost_at_day(Livestock, Transactions_By_Account, End_Date, Closing_Value) :-
	livestock_count(Livestock, Transactions_By_Account, End_Date, Count),
	doc(Livestock, livestock:average_cost,  Average_Cost),
	value_convert(Count, Average_Cost, Closing_Value).

livestock_count(Livestock, Transactions_By_Account, End_Date, Count) :-
gtrace,
	doc(Livestock, livestock:opening_count, Opening_Count_Value),
	value_debit_vec(Opening_Count_Value, Opening_Count_Vec),
	count_account(Livestock, Count_Account),
	doc(l:request, l:accounts, Accounts),
	balance_by_account([], Accounts, Transactions_By_Account, [], _, Count_Account, End_Date, Count_Vector, _),
	vec_add(Count_Vector, Opening_Count_Vec, Closing_Vec),
	gtrace,
	value_debit_vec(Count, Closing_Vec).



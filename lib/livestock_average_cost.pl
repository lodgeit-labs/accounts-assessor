
average_cost(Type, Opening_Cost0, Opening_Count0, Info, Exchange_Rate) :-
	Info = (_From_Day, _To_Day, S_Transactions, Livestock_Events, Natural_Increase_Costs),
	/*?
	for now, we ignore _From_Day (and _To_Day),
	and use Opening_Cost and Opening_Count as stated in the request.
	*/
	Exchange_Rate = with_info(exchange_rate(_, Type, Currency, Average_Cost), Explanation),
	Explanation = {formula: Formula_String1, computation: Formula_String2},

	compile_with_variable_names_preserved((
		Natural_Increase_Value = Natural_Increase_Cost_Per_Head * Natural_Increase_Count,
		Opening_And_Purchases_And_Increase_Value_Exp = Opening_Value + Purchases_Value + Natural_Increase_Value,
		Opening_And_Purchases_And_Increase_Count_Exp = Opening_Count + Purchases_Count + Natural_Increase_Count,
		Average_Cost_Exp = Opening_And_Purchases_And_Increase_Value_Exp / Opening_And_Purchases_And_Increase_Count_Exp
	),	Names1),
	term_string(Average_Cost_Exp, Formula_String1, [Names1]),

	% now let's fill in the values
	Opening_Cost = Opening_Cost0,
	Opening_Count = Opening_Count0,
	[coord(Currency, Opening_Value, 0)] = Opening_Cost,
	member(natural_increase_cost(Type, [coord(Currency, Natural_Increase_Cost_Per_Head, 0)]), Natural_Increase_Costs),
	natural_increase_count(Type, Livestock_Events, Natural_Increase_Count),
	livestock_purchases_cost_and_count(Type, S_Transactions, Purchases_Cost, Purchases_Count),

	(
			Purchases_Cost == []
		->
			Purchases_Value = 0
		;
			[coord(Currency, 0, Purchases_Value)] = Purchases_Cost
	),

	pretty_term_string(Average_Cost_Exp, Formula_String2),

	% avoid division by zero and evaluate the formula
	Opening_And_Purchases_And_Increase_Count is Opening_And_Purchases_And_Increase_Count_Exp,
	(
		Opening_And_Purchases_And_Increase_Count > 0
	->
		Average_Cost is Average_Cost_Exp
	;
		Average_Cost = 0
	).


% natural increase count given livestock type and all livestock events
natural_increase_count(Type, [E | Events], Natural_Increase_Count) :-
	(E = born(Type, _Day, Count) ->
		C = Count;
		C = 0),
	natural_increase_count(Type, Events, Natural_Increase_Count_1),
	Natural_Increase_Count is Natural_Increase_Count_1 + C.

natural_increase_count(_, [], 0).


livestock_purchases_cost_and_count(Type, [ST | S_Transactions], Purchases_Cost, Purchases_Count) :-
	(
		(
			s_transaction_is_livestock_buy_or_sell(ST, _Day, Type, Livestock_Coord, _, Vector_Ours, _, _, _),
			Vector_Ours = [coord(_, 0, _)]
		)
		->
		(
			Livestock_Coord = coord(Type, Count, 0),
			Cost = Vector_Ours
		)
		;
		(
			Cost = [], Count = 0
		)
	),
	livestock_purchases_cost_and_count(Type, S_Transactions, Purchases_Cost_2, Purchases_Count_2),
	vec_add(Cost, Purchases_Cost_2, Purchases_Cost),
	Purchases_Count is Purchases_Count_2 + Count.

livestock_purchases_cost_and_count(_, [], [], 0).


livestock_count(Accounts, Livestock_Type, Transactions_By_Account, Opening_Cost_And_Count, To_Day, Count) :-
	opening_cost_and_count(Livestock_Type, _, Opening_Count) = Opening_Cost_And_Count,
	count_account(Livestock_Type, Count_Account),
	balance_by_account([], Accounts, Transactions_By_Account, [], _, Count_Account, To_Day, Count_Vector, _),
	vec_add(Count_Vector, [coord(Livestock_Type, Opening_Count, 0)], Count).

livestock_at_average_cost_at_day(Accounts, Livestock_Type, Transactions_By_Account, Opening_Cost_And_Count, To_Day, Average_Cost_Exchange_Rate, Cost_Vector) :-
	livestock_count(Accounts, Livestock_Type, Transactions_By_Account, Opening_Cost_And_Count, To_Day, Count_Vector),
	exchange_rate(_, _, Dest_Currency, Average_Cost) = Average_Cost_Exchange_Rate,
	[coord(_, Count, _)] = Count_Vector,
	Cost is Average_Cost * Count,
	Cost_Vector = [coord(Dest_Currency, Cost, 0)].



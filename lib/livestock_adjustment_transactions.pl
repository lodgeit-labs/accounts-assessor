% this logic is dependent on having the average cost value
livestock_adjustment_transactions(Livestock_Types, S_Transactions, Transactions) :-
   maplist(
		yield_more_transactions(S_Transactions),
		Livestock_Types,
		Lists),
	flatten(Lists, Transactions).

yield_more_transactions(S_Transactions, Livestock_Type, Rations_Transactions) :-
	maplist(preprocess_rations(Livestock_Type), Rations_Transactions),

preprocess_rations(Livestock_Type, Date, [T1, T2]]) :-
    rdf(Rations_Count)
    rdf(Average_Cost)
	exchange_rate(_, _, Currency, Average_Cost_Per_Head) = Average_Cost,
	Cost is Average_Cost_Per_Head * Count,
	livestock_account_ids(_,_,Equity_3145_Drawings_by_Sole_Trader,_)
	cogs_rations_account(Livestock_Type, Cogs_Rations_Account),
	% DR OWNERS_EQUITY -->DRAWINGS. I.E. THE OWNER TAKES SOMETHING OF VALUE.
	make_transaction(Date, 'rations', Equity_3145_Drawings_by_Sole_Trader, [coord(Currency, Cost, 0)], T1),
	%	CR COST_OF_GOODS. I.E. DECREASES COST. 	% expenses / cost of goods / stock adjustment
	make_transaction(Date, 'rations', Cogs_Rations_Account, [coord(Currency, 0, Cost)], T2),








opening_inventory_transactions(Start_Date, Opening_Costs_And_Counts, Livestock_Type, Opening_Inventory_Transactions) :-
	member(Opening_Cost_And_Count, Opening_Costs_And_Counts),
	opening_cost_and_count(Livestock_Type, Opening_Vector, _) = Opening_Cost_And_Count,
	vec_inverse(Opening_Vector, Opening_Vector_Credit),
	Opening_Inventory_Transactions = [T1, T2],
	make_transaction(Start_Date, 'livestock opening inventory', 'AssetsLivestockAtCost', Opening_Vector, T1),
	make_transaction(Start_Date, 'livestock opening inventory', 'CapitalIntroduced', Opening_Vector_Credit, T2).


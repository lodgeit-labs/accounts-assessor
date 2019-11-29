
/* prerequisite:
only livestockData with actual start year and end year should be passed here
*/
opening_inventory_transactions(Accounts, Start_Date, Livestock, [T1, T2]) :-
	/*
	so, for being able to compare multiple whole sets of inferred information,
	what we'd do here is something like
	Livestock l:variant V,
	V l:origin inference_from_ledger
	and then, if we're inferring info from a given GL, write into V,
	otherwise, look the info up from Livestock.
	not sure exactly how we'd set it up so that all that could happen seamlessly behind the scenes.
	*/
	/*
	for now, i'll just replace rdf db with something that can store arbitrary prolog things,
	and livestock:opening_cost will possibly be an unbound variable. Actually opening_cost is always expected to be provided, but this will apply to for example closing cost.
	*/
	/* this also seamlessly converts actual rdf to value/2 */
	my_rdf(Livestock, livestock:opening_cost, Cost),
	Opening_Vector = [Cost],
	vec_inverse(Opening_Vector, Opening_Vector_Credit),
	accounts:account_by_role(Accounts, 'Accounts'/'AssetsLivestockAtCost', A0),
	accounts:account_by_role(Accounts, 'Accounts'/'CapitalIntroduced', A1),
	make_transaction(End_Date, 'livestock opening inventory', A0, Opening_Vector, T1),
	make_transaction(End_Date, 'livestock opening inventory', A1, Opening_Vector_Credit, T2).


preprocess_headcount_changes(Date, Livestock, [Tx0, Tx1, Tx2]]) :-
	my_rdf(Livestock, livestock:name, Type),
	count_account(Type, Count_Account),
	/*fixme, value or number? */
	my_rdf(Livestock, livestock:born_count, A),
	make_transaction(Date, 'livestock born', Count_Account, A, Tx0),
	my_rdf(Livestock, livestock:losses_count, B),
	make_transaction(Day, 'livestock loss', Count_Account, B, Tx1),
	my_rdf(Livestock, livestock:rations_count, C),
	make_transaction(Day, 'livestock rations', Count_Account, C, Tx2).

% the average cost value has to be computed first
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
	make_transaction(Date, 'rations', Cogs_Rations_Account, [coord(Currency, 0, Cost)], T2).


closing_inventory_transactions(
	Accounts,
	Livestock_Type,
	To_Day,
	Transactions_By_Account,
	Cogs_Transactions
) :-
		livestock_at_average_cost_at_day(Accounts, Livestock_Type, Transactions_By_Account, Opening_Cost_And_Count, To_Day, Average_Cost, Closing_Debit),

		vec_sub(Closing_Debit, Opening_Cost, Adjustment_Debit),
		vec_inverse(Adjustment_Debit, Adjustment_Credit),

		Cogs_Transactions = [T1, T2],
		% expense/revenue
		make_transaction(To_Day, "livestock adjustment", Cogs_Account, Adjustment_Credit, T1),
		% assets
		make_transaction(To_Day, "livestock adjustment", 'AssetsLivestockAtAverageCost', Adjustment_Debit, T2),
		cogs_account(Livestock_Type, Cogs_Account).


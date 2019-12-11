
/* prerequisite:
only livestockData with actual start year and end year should be passed here
*/
opening_inventory_transactions(Livestock, [T1, T2]) :-
	doc:doc(Livestock, livestock:opening_cost, Cost),
	pacioli:value_debit_vec(Cost, Opening_Vector),
	pacioli:value_credit_vec(Cost, Opening_Vector_Credit),
	accounts:account_by_role('Accounts'/'AssetsLivestockAtCost', A0),
	accounts:account_by_role('Accounts'/'CapitalIntroduced', A1),
	doc:request_has_property(l:end_date, End_Date),
	make_transaction(End_Date, 'livestock opening inventory', A0, Opening_Vector, T1),
	make_transaction(End_Date, 'livestock opening inventory', A1, Opening_Vector_Credit, T2).

preprocess_headcount_changes(Livestock, [Tx0, Tx1, Tx2]) :-
	doc:request_has_property(l:end_date, Date),
	doc:doc(Livestock, livestock:name, Type),
	count_account(Type, Count_Account),
	doc:doc(Livestock, livestock:born_count, B),
	pacioli:value_debit_vec(B, B_V),
	doc:request_has_property(l:end_date, Date),
	make_transaction(Date, 'livestock born', Count_Account, B_V, Tx0),
	doc:doc(Livestock, livestock:losses_count, L),
	pacioli:value_credit_vec(L, L_V),
	make_transaction(Date, 'livestock loss', Count_Account, L_V, Tx1),
	doc:doc(Livestock, livestock:rations_count, R),
	pacioli:value_credit_vec(R, R_V),
	make_transaction(Date, 'livestock rations', Count_Account, R_V, Tx2).

% the average cost value has to be computed first
preprocess_rations(Livestock, [T1, T2]) :-
	doc:request_has_property(l:end_date, Date),
	doc:doc(Livestock, livestock:rations_count, Rations_Count),
	doc:doc(Livestock, livestock:average_cost,  Average_Cost),
	pacioli:value_convert(Rations_Count, Average_Cost, Rations_Value),
	pacioli:value_debit_vec(Rations_Value, Dr),
	pacioli:vec_inverse(Dr, Cr),
	accounts:account_by_role('Accounts'/'Drawings', Drawings),
	doc:doc(Livestock, livestock:name, Type),
	cogs_rations_account(Type, Cogs_Rations_Account),
	% DR OWNERS_EQUITY -->DRAWINGS. I.E. THE OWNER TAKES SOMETHING OF VALUE.
	make_transaction(Date, 'rations', Drawings, Dr, T1),
	%	CR COST_OF_GOODS. I.E. DECREASES COST.
	make_transaction(Date, 'rations', Cogs_Rations_Account, Cr, T2).


closing_inventory_transactions(Livestock, Transactions_By_Account, [T1, T2]) :-
	doc:request_has_property(l:end_date, Date),
	livestock_at_average_cost_at_day(Livestock, Transactions_By_Account, Date, Closing_Value),
	doc:doc(Livestock, livestock:opening_cost, Opening_Cost_Value),
	pacioli:value_subtract(Closing_Value, Opening_Cost_Value, Adjustment_Value),
	pacioli:coord_normal_side_value(Adjustment_Debit, debit, Adjustment_Value),
	pacioli:coord_normal_side_value(Adjustment_Credit,credit,Adjustment_Value),
	doc:doc(Livestock, livestock:name, Type),
	cogs_account(Type, Cogs_Account),
	accounts:account_by_role('Accounts'/'AssetsLivestockAtAverageCost', AssetsLivestockAtAverageCost),

	format(string(Description), 'livestock closing inventory adjustment', []),

	make_transaction(Date, Description, Cogs_Account, [Adjustment_Credit], T1),
	make_transaction(Date, Description, AssetsLivestockAtAverageCost, [Adjustment_Debit], T2).


/* todo what would this look like in logtalk, if these were methods on the Livestock object? */
/* todo maybe the predicate bodies could be structured into:
	computation
	accounts
	transactions
this way, the user could control the search.
*/

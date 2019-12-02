
/* prerequisite:
only livestockData with actual start year and end year should be passed here
*/
opening_inventory_transactions(Livestock, [T1, T2]) :-
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
	doc(Livestock, livestock:opening_cost, Cost),
	pacioli:value_debit_vec(Cost, Opening_Vector),
	pacioli:value_credit_vec(Cost, Opening_Vector_Credit),
	accounts:account_by_role('Accounts'/'AssetsLivestockAtCost', A0),
	accounts:account_by_role('Accounts'/'CapitalIntroduced', A1),
	doc:request_has_property(l:end_date, End_Date),
	make_transaction(End_Date, 'livestock opening inventory', A0, Opening_Vector, T1),
	make_transaction(End_Date, 'livestock opening inventory', A1, Opening_Vector_Credit, T2).

preprocess_headcount_changes(Livestock, [Tx0, Tx1, Tx2]) :-
	doc:request_has_property(l:end_date, Date),
	doc(Livestock, livestock:name, Type),
	count_account(Type, Count_Account),
	doc(Livestock, livestock:born_count, B),
	pacioli:value_debit_vec(B, B_V),
	doc:request_has_property(l:end_date, Date),
	make_transaction(Date, 'livestock born', Count_Account, B_V, Tx0),
	doc(Livestock, livestock:losses_count, L),
	pacioli:value_credit_vec(L, L_V),
	make_transaction(Date, 'livestock loss', Count_Account, L_V, Tx1),
	doc(Livestock, livestock:rations_count, R),
	pacioli:value_credit_vec(R, R_V),
	make_transaction(Date, 'livestock rations', Count_Account, R_V, Tx2).

% the average cost value has to be computed first
preprocess_rations(Livestock, [T1, T2]) :-
	doc:request_has_property(l:end_date, Date),
	doc(Livestock, livestock:rations_count, Rations_Count),
	doc(Livestock, livestock:average_cost,  Average_Cost),
	pacioli:value_convert(Rations_Count, Average_Cost, Rations_Value),
	pacioli:value_debit_vec(Rations_Value, Dr),
	pacioli:vec_inverse(Dr, Cr),
	accounts:account_by_role('Accounts'/'Drawings', Drawings),
	cogs_rations_account(Livestock, Cogs_Rations_Account),
	% DR OWNERS_EQUITY -->DRAWINGS. I.E. THE OWNER TAKES SOMETHING OF VALUE.
	make_transaction(Date, 'rations', Drawings, Dr, T1),
	%	CR COST_OF_GOODS. I.E. DECREASES COST.
	make_transaction(Date, 'rations', Cogs_Rations_Account, Cr, T2).


closing_inventory_transactions(Livestock, Transactions_By_Account, [T1, T2]) :-
	doc:request_has_property(l:end_date, Date),
	livestock_at_average_cost_at_day(Livestock, Transactions_By_Account, Date, Closing_Vec),
	doc(Livestock, livestock:opening_cost, Opening_Cost_Value),
	vec_sub(Closing_Vec, [Opening_Cost_Value], Adjustment_Debit),
	vec_inverse(Adjustment_Debit, Adjustment_Credit),
	cogs_account(Livestock, Cogs_Account),
	accounts:account_by_role('Accounts'/'AssetsLivestockAtAverageCost', AssetsLivestockAtAverageCost),
	make_transaction(Date, "livestock adjustment", Cogs_Account, Adjustment_Credit, T1),
	make_transaction(Date, "livestock adjustment", AssetsLivestockAtAverageCost, Adjustment_Debit, T2).


/* todo what would this look like in logtalk, if these were methods on the Livestock object? */
/* todo maybe the predicate bodies could be structured into:
	computation
	accounts
	transactions
this way, the user could control the search.
*/

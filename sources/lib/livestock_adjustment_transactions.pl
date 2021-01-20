
/* prerequisite:
only livestockData with actual start year and end year should be passed here
*/
opening_inventory_transactions(Livestock, [T1, T2]) :-
	doc(Livestock, livestock:opening_cost, Cost),
	value_debit_vec(Cost, Opening_Vector),
	value_credit_vec(Cost, Opening_Vector_Credit),
	account_by_role_throw(rl('Assets_Livestock_at_Cost'), A0),
	account_by_role_throw(rl('Capital_Introduced'), A1),
	result_property(l:end_date, End_Date),
	make_transaction(livestock, End_Date, 'livestock opening inventory', A0, Opening_Vector, T1),
	make_transaction(livestock, End_Date, 'livestock opening inventory', A1, Opening_Vector_Credit, T2).

preprocess_headcount_changes(Livestock, [Tx0, Tx1, Tx2]) :-
	result_property(l:end_date, Date),
	doc(Livestock, livestock:name, Type),
	livestock_count_account(Type, Count_Account),
	doc(Livestock, livestock:born_count, B),
	value_debit_vec(B, B_V),
	result_property(l:end_date, Date),
	make_transaction(livestock, Date, 'livestock born', Count_Account, B_V, Tx0),
	doc(Livestock, livestock:losses_count, L),
	value_credit_vec(L, L_V),
	make_transaction(livestock, Date, 'livestock loss', Count_Account, L_V, Tx1),
	doc(Livestock, livestock:rations_count, R),
	value_credit_vec(R, R_V),
	make_transaction(livestock, Date, 'livestock rations', Count_Account, R_V, Tx2).

% the average cost value has to be computed first
preprocess_rations(Livestock, [T1, T2]) :-
	result_property(l:end_date, Date),
	doc(Livestock, livestock:rations_count, Rations_Count),
	doc(Livestock, livestock:average_cost,  Average_Cost),
	value_convert(Rations_Count, Average_Cost, Rations_Value),
	value_debit_vec(Rations_Value, Dr),
	vec_inverse(Dr, Cr),
	account_by_role_throw(rl('Drawings'), Drawings),
	doc(Livestock, livestock:name, Type),
	livestock_cogs_rations_account(Type, Cogs_Rations_Account),
	% DR OWNERS_EQUITY -->DRAWINGS. I.E. THE OWNER TAKES SOMETHING OF VALUE.
	make_transaction(livestock, Date, 'rations', Drawings, Dr, T1),
	%	CR COST_OF_GOODS. I.E. DECREASES COST.
	make_transaction(livestock, Date, 'rations', Cogs_Rations_Account, Cr, T2).


closing_inventory_transactions(Livestock, Transactions_By_Account, [T1, T2]) :-
	result_property(l:end_date, Date),
	livestock_at_average_cost_at_day(Livestock, Transactions_By_Account, Date, Closing_Value),
	doc(Livestock, livestock:opening_cost, Opening_Cost_Value),
	value_subtract(Closing_Value, Opening_Cost_Value, Adjustment_Value),
	coord_normal_side_value(Adjustment_Debit, kb:debit, Adjustment_Value),
	coord_normal_side_value(Adjustment_Credit,kb:credit,Adjustment_Value),
	doc(Livestock, livestock:name, Type),
	livestock_cogs_account(Type, Cogs_Account),
	account_by_role_throw(rl('Assets_Livestock_at_Average_Cost'), Assets_Livestock_at_Average_Cost),

	format(string(Description), 'livestock closing inventory adjustment', []),

	make_transaction(livestock, Date, Description, Cogs_Account, [Adjustment_Credit], T1),
	make_transaction(livestock, Date, Description, Assets_Livestock_at_Average_Cost, [Adjustment_Debit], T2).


/* todo what would this look like in logtalk, if these were methods on the Livestock object? */
/* todo maybe the predicate bodies could be structured into:
	computation
	accounts
	transactions
this way, the user could control the search.
*/

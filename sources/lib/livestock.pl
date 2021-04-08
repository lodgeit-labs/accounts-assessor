
livestock_verbs([l:livestock_purchase, l:livestock_sale]).


/*
+
+
+relate_livestock_s_transaction_description_to_direction(S_Transaction) :-
+       d(S_Transaction, bst_tx:action_verb, V),
+       /* new property of action verb */
+       (d(V, is_sale, true),
+       Description = 'livestock sale')
+       ;
+       (d(V, is_purchase, true),
+       Description = 'livestock purchase').
+
+st_id_eq_t_id(Bst, Glt) :-
+       d(Bst, bst_tx:id, Id1),
+       d(Glt, glt_tx:id, Id2),
+       e(Id1, Id2).
+
+preprocess_livestock_buy_or_sell(Bst, [Bank_Txs, Livestock_Count_Transaction, Pl_Transaction]) :-
+       relate_livestock_s_transaction_description_to_direction,
+       e(Bst.day, Livestock_Count_Transaction.day),
+
*/

s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, Livestock_Coord, Money_Coord) :-
	s_transaction_day(S_Transaction, Day),
	s_transaction_type_id(S_Transaction, uri(Action_Verb)),
	s_transaction_vector(S_Transaction, [Money_Coord]),
	s_transaction_exchanged(S_Transaction, vector(Vec)),
	(rdf_global_id(l:livestock_purchase,Action_Verb);rdf_global_id(l:livestock_sale,Action_Verb)),
	!,
	Vec = [Livestock_Coord],
	coord_unit(Livestock_Coord, Livestock_Type),
	livestock_data_by_vector_unit(_, Vec).

livestock_data(Uri) :-
	doc(Uri, rdf:type, l:livestock_data).

livestock_data_by_vector_unit(Livestock, Exchanged) :-
	vector_unit(Exchanged, Unit),
	findall(
		L,
		(
			livestock_data(L),
			doc(L, livestock:name, Unit/*?*/)
		),
		Known_Livestock_Datas
	),
	length(Known_Livestock_Datas, Known_Livestock_Datas_Length),
	(   Known_Livestock_Datas_Length > 1
	->	throw_string(multiple_livestock_types_match)
	;   true),
	(	Known_Livestock_Datas_Length = 0
	->	(
			findall(U,(livestock_data(L),doc(L, livestock:name, U)),Units),
			format(user_error, 'WARNING:looking for livestock unit ~q, known units: ~q', [Unit, Units])
		)
	;	true),
	[Livestock] = Known_Livestock_Datas.

infer_livestock_action_verb(S_Transaction, NS_Transaction) :-
	s_transaction_type_id(S_Transaction, ''),
	s_transaction_exchanged(S_Transaction, vector(Exchanged)),
	/* if.. */
	livestock_data_by_vector_unit(_,Exchanged),
	s_transaction_vector(S_Transaction, Vector),
	(	is_debit(Vector)
	->	rdf_global_id(l:livestock_sale,Action_Verb)
	;	rdf_global_id(l:livestock_purchase,Action_Verb)),
	doc_set_s_transaction_field(type_id,S_Transaction, uri(Action_Verb), NS_Transaction, infer_livestock_action_verb).



preprocess_livestock_buy_or_sell(S_Transaction, [Bank_Txs, Livestock_Count_Transaction, Pl_Transaction]) :-
	s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, Livestock_Coord, Money_Coord),
	(   is_debit(Money_Coord)
	->  Description = 'livestock sale'
	;   Description = 'livestock purchase'),
	livestock_count_account(Livestock_Type, Count_Account),
	make_transaction(S_Transaction, Day, Description, Count_Account, [Livestock_Coord], Livestock_Count_Transaction),
	affect_first_account(S_Transaction, Description, Bank_Txs),
	vec_inverse([Money_Coord], Pl_Vector),
	(   is_credit(Money_Coord)
	->	(
			livestock_cogs_account(Livestock_Type, Cogs_Account),
			make_transaction(S_Transaction, Day, Description, Cogs_Account, Pl_Vector, Pl_Transaction)
		)
	;
		(
			livestock_sales_account(Livestock_Type, Sales_Account),
			make_transaction(S_Transaction, Day, Description, Sales_Account, Pl_Vector, Pl_Transaction)
		)
	).

process_livestock(Info, Livestock_Transactions) :-
	findall(L, livestock_data(L), Ls),
	maplist(process_livestock2(Info), Ls, Txs),
	flatten(Txs, Livestock_Transactions).

process_livestock2((S_Transactions, Transactions_In), Livestock, Transactions_Out) :-
	/*
	todo send livestock dates from excel and check them here
	*/
	result_property(l:start_date, Start_Date),
	result_property(l:end_date, End_Date),

	/*
	preprocess_livestock_buy_or_sell happens first, as part of preprocess_s_transaction.
	it affects bank account and livestock headcount.
	*/

	/* record opening value in assets */
	opening_inventory_transactions(Livestock, Opening_Inventory_Transactions),
	Transactions1 = Opening_Inventory_Transactions,

	/* born, loss, rations */
	preprocess_headcount_changes(Livestock, Headcount_Change_Transactions),
	append(Transactions1, Headcount_Change_Transactions, Transactions2),

	/* avg cost relies on Opening_And_Purchases_And_Increase */
	infer_average_cost(Livestock, S_Transactions),

	/* rations value is derived from avg cost */
	preprocess_rations(Livestock, Rations_Transactions),
	append(Transactions2, Rations_Transactions, Transactions3),

	/* counts were changed by buys, sells, rations, losses and natural increase */
	dict_from_vars(Static_Data0, [Start_Date, End_Date]),
	append(Transactions_In, Transactions3, Transactions_Total),

	Static_Data1 = Static_Data0.put(transactions,Transactions_Total),
	gtrace,
	%!'with current and historical earnings equity balances'(a,b,c,d),
	transactions_dict_by_account(Static_Data1, Transactions_By_Account),

	closing_inventory_transactions(Livestock, Transactions_By_Account, Closing_Transactions),
	append(Transactions3, Closing_Transactions, Transactions_Out),

	%maplist(do_livestock_cross_check(Livestock_Events, Natural_Increase_Costs, S_Transactions, Transactions_Out, Opening_Costs_And_Counts, Start_Date, End_Date, Exchange_Rates, Accounts, Report_Currency, Average_Costs), Livestocks)
	true.


livestock_units(Units) :-
	findall(
		Unit,
		(
			doc(L, rdf:type, l:livestock_data),
			doc(L, livestock:name, Unit)
		),
		Units
	).



/*


*/

increase_unrealized_gains(Static_Data, Trading_Account_Id, Purchase_Currency, Converted_Cost_Vector, Goods_With_Unit_Cost_Vector, Transaction_Day, [Ts0, Ts1]) :-
	unrealized_gains_increase_txs(Static_Data, Trading_Account_Id, Purchase_Currency, Converted_Cost_Vector, Goods_With_Unit_Cost_Vector, Transaction_Day, Txs0, Current_Txs),
	txs_to_transactions(Transaction_Day, Txs0, Ts0),
	dict_vars(Static_Data, [Start_Date]),
	(
		Transaction_Day @< Start_Date
	->
		txs_to_transactions(Start_Date, Current_Txs, Ts1)
	;
		Ts1 = []
	).	

	
increase_realized_gains(Static_Data, Trading_Account_Id, Sale_Vector, Converted_Vector, Goods_Vector, Transaction_Day, Goods_Cost_Values, Ts2) :-

	[Goods_Coord] = Goods_Vector,
	number_coord(_, Goods_Integer, Goods_Coord),
	Goods_Positive is -Goods_Integer,

	Sale_Vector = [coord(Sale_Currency, Sale_Currency_Amount, _)],
	Sale_Currency_Unit_Price is Sale_Currency_Amount / Goods_Positive,
	
	[coord(Converted_Currency, Converted_Debit, _)] = Converted_Vector,
	Sale_Unit_Price_Amount is Converted_Debit / Goods_Positive,
	maplist(
		realized_gains_txs(
			Static_Data, 
			Sale_Currency,
			Sale_Currency_Unit_Price,
			Trading_Account_Id, 
			value(Converted_Currency, Sale_Unit_Price_Amount)
		), 
		Goods_Cost_Values, Txs2
	),
	txs_to_transactions(Transaction_Day, Txs2, Ts2).

reduce_unrealized_gains(Static_Data, Trading_Account_Id, Transaction_Day, Goods_Cost_Values, Ts1) :-
	maplist(unrealized_gains_reduction_txs(Static_Data, Trading_Account_Id), Goods_Cost_Values, Txs1),
	txs_to_transactions(Transaction_Day, Txs1, Ts1).
	

/*
	txs are dicts with most of informations needed to create a transaction.
	we will produce them from a simple table:
	Account         DR           CR
	...             ...          ...
	the vectors or coords in the table will be coerced to the given side, debit or credit.
	this may seem error prone, but any issues are yet to be found, and it clarifies the logic.
*/
			
unrealized_gains_increase_txs(Static_Data, Trading_Account_Id, Purchase_Currency, Cost_Vector, Goods, Transaction_Day, Txs, Current_Txs) :-
	dict_vars(Static_Data, [Accounts, Report_Currency, Start_Date]),
	Goods = [coord(Goods_Unit, Goods_Debit, Goods_Credit)],
	Goods_Unit = with_cost_per_unit(Goods_Unit_Bare, _),
	gains_accounts(
		Accounts, Trading_Account_Id, unrealized, Goods_Unit_Bare, 
		Unrealized_Gains_Currency_Movement, Unrealized_Gains_Excluding_Forex),
	Goods_Without_Currency_Movement = [coord(
		without_currency_movement_against_since(Goods_Unit, Purchase_Currency, Report_Currency, Transaction_Day), 
		Goods_Debit, Goods_Credit)
	],
	(
		Date @>= Start_Date
	->
		dr_cr_table_to_txs([
			% Account                                                                 DR                                                               CR
			(Unrealized_Gains_Currency_Movement,                Goods_Without_Currency_Movement,        Goods),
			(Unrealized_Gains_Excluding_Forex,	                 Cost_Vector,      	                Goods_Without_Currency_Movement)
		], Txs)
	;
		(
		
			/*historical:*/
			Goods_Historical = [coord(
				without_movement_after(Goods_Unit, Start_Date), 
				Goods_Debit, Goods_Credit)
			],
			Historical_Without_Currency_Movement = [coord(
				without_movement_after(
					without_currency_movement_against_since(
						Goods_Unit, Purchase_Currency, Report_Currency, Transaction_Day
					), 
					Transaction_Day
				),
				Goods_Debit, Goods_Credit)
			],
			dr_cr_table_to_txs([
				% Account                                                                 DR                                                               CR
				(Unrealized_Gains_Currency_Movement,                Historical_Without_Currency_Movement,        Goods_Historical),
				(Unrealized_Gains_Excluding_Forex,	                Cost_Vector,       Historical_Without_Currency_Movement)
			], Historical_Txs),
		
			/*now, for tracking unrealized gains after report start date*/
			/* goods value as it was at the start date */
			Opening_Goods_Value = [coord(
				without_movement_after(Goods_Unit, Start_Date), 
				Goods_Debit, Goods_Credit)
			],
			Current_Without_Currency_Movement = [coord(
				without_currency_movement_against_since(Goods_Unit, Purchase_Currency, Report_Currency, Start_Date), 
				Goods_Debit, Goods_Credit)
			],
			dr_cr_table_to_txs([
				% Account                                                                 DR                                                               CR
				(Unrealized_Gains_Currency_Movement,                Current_Without_Currency_Movement,        Goods),
				(Unrealized_Gains_Excluding_Forex,	                Opening_Goods_Value,       Current_Without_Currency_Movement)
			], Current_Txs)
			
		)
	).

	
unrealized_gains_reduction_txs(Static_Data, Trading_Account_Id, Purchase_Info, Txs) :-
	dict_vars(Static_Data, [Accounts, Report_Currency]),

	goods(ST_Currency, Goods_Unit_Name, Goods_Count, Cost, Purchase_Date) = Purchase_Info,
	
	gains_accounts(
		Accounts, Trading_Account_Id, unrealized, Goods_Unit_Name, 
		Unrealized_Gains_Currency_Movement, Unrealized_Gains_Excluding_Forex),

	Cost = value(Cost_Currency, Cost_Amount),
	Unit_Cost_Amount is Cost_Amount / Goods_Count,
	Unit_Cost = value(Cost_Currency, Unit_Cost_Amount),
	Goods_Unit_With_Cost = with_cost_per_unit(Goods_Unit_Name, Unit_Cost),
		
	Goods_Without_Currency_Movement = [coord(
		without_currency_movement_against_since(Goods_Unit_With_Cost, ST_Currency, Report_Currency, Purchase_Date), 
		Goods_Count, 0)
	],
	Goods = value(Goods_Unit_With_Cost, Goods_Count),
	
	dr_cr_table_to_txs([
	% Account                                                                 DR                                                               CR
	(Unrealized_Gains_Currency_Movement,             Goods    ,                                   Goods_Without_Currency_Movement  ),
	(Unrealized_Gains_Excluding_Forex,					Goods_Without_Currency_Movement    ,      Cost                 )
	],
	Txs),
	Txs= [T0, T1],
	T0.comment = T1.comment,
	T0.comment = 'reduce unrealized gain by outgoing asset and its cost'.

	
realized_gains_txs(Static_Data, Sale_Currency, Sale_Currency_Unit_Price, Trading_Account_Id, Sale_Unit_Price_Converted, Purchase_Info, Txs) :-
	dict_vars(Static_Data, [Accounts, Report_Currency, Exchange_Rates]),
	goods(_ST_Currency, Goods_Unit, Goods_Count, Cost, Purchase_Date) = Purchase_Info,
	
	gains_accounts(
		Accounts, Trading_Account_Id, realized, Goods_Unit, 
		Realized_Gains_Currency_Movement, Realized_Gains_Excluding_Forex),
	
	Sale_Currency_Amount is Sale_Currency_Unit_Price * Goods_Count,
	
	/*what would be the Report_Currency value we'd get for this sale currency amount if purchase/sale currency didn't move against Report_Currency since the day of the purchase?*/
	vec_change_bases(
		Exchange_Rates, 
		Purchase_Date, 
		Report_Currency, 
		[coord(Sale_Currency, 0, Sale_Currency_Amount)],
		Sale_Without_Currency_Movement
	),
			
	value_multiply(Sale_Unit_Price_Converted, Goods_Count, Sale),
	dr_cr_table_to_txs([
	% Account                                                                 DR                                                               CR
	(Realized_Gains_Currency_Movement,	                Sale_Without_Currency_Movement,           Sale),
	(Realized_Gains_Excluding_Forex,                			        Cost,   	                    Sale_Without_Currency_Movement)
	],
	Txs).


dr_cr_table_to_txs(Table, Txs) :-
	maplist(dr_cr_table_line_to_tx, Table, Txs).
	
dr_cr_table_line_to_tx(Line, Tx) :-
	Line = (Account, Dr0, Cr0),
	flatten([Dr0], Dr1),
	flatten([Cr0], Cr1),
	maplist(make_debit, Dr1, Dr2),
	maplist(make_credit, Cr1, Cr2),
	append(Dr2, Cr2, Vector),
	Tx = tx{
		comment: _,
		comment2: _,
		account: Account,
		vector: Vector
	}.

	
txs_to_transactions(Transaction_Day, Txs, Ts) :-
	flatten([Txs], Txs_Flat),
	maplist(tx_to_transaction(Transaction_Day), Txs_Flat, Ts).

tx_to_transaction(Day, Tx, Transaction) :-
	Tx = tx{comment: Comment, comment2: Comment2, account: Account, vector: Vector},
	nonvar(Account),
	ground(Vector),
	(var(Comment) -> Comment = '?'; true),
	(var(Comment2) -> Comment2 = '?'; true),
	atomic_list_concat(['comment:', Comment, ', comment2:', Comment2], Description),
	transaction_day(Transaction, Day),
	transaction_description(Transaction, Description),
	transaction_account_id(Transaction, Account),
	transaction_vector(Transaction, Vector_Flattened),
	flatten(Vector, Vector_Flattened).
	
/*
	find accounts to affect
*/
gains_accounts(
	/*input*/
	Accounts, Trading_Account_Id, Realized_Or_Unrealized, Goods_Unit, 
	/*output*/
	Currency_Movement_Account,
	Excluding_Forex_Account
) :-
	account_by_role(Accounts, (Trading_Account_Id/Realized_Or_Unrealized), Unrealized_Gains_Account),
	account_by_role(Accounts, (Unrealized_Gains_Account/only_currency_movement), Unrealized_Gains_Currency_Movement),
	account_by_role(Accounts, (Unrealized_Gains_Account/without_currency_movement), Unrealized_Gains_Excluding_Forex),
	account_by_role(Accounts, (Unrealized_Gains_Currency_Movement/Goods_Unit), Currency_Movement_Account),
	account_by_role(Accounts, (Unrealized_Gains_Excluding_Forex/Goods_Unit), Excluding_Forex_Account).


	
/*
we bought the shares with some currency. we can think of gains as having two parts:
	share value against that currency.
	that currency value against report currency.

	Txs0 = [
		tx{
			comment: 'gains obtained by changes in price of shares against the currency we bought them for',
			comment2: '',
			account: Gains_Excluding_Forex,
			vector:  Cost_In_Purchase_Currency_Vs_Goods__Revenue
		},
		tx{
			comment: 'gains obtained by changes in the value of the currency we bought the shares with, against report currency',
			comment2: Tx2_Comment2,
			account: Gains_Currency_Movement,
			vector: Cost_In_Report_Vs_Purchase_Currency_Inverted
		}],
*/

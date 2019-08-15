
/*
	txs are dicts with most of informations needed to create a transaction.
	we will produce them from a simple table:
	Account         DR           CR
	...             ...          ...
	the vectors or coords in the table will be coerced to the given side, debit or credit.
	this may seem error prone, but any issues are yet to be found, and it clarifies the logic.
*/
			
increase_unrealized_gains(Static_Data, Description, Trading_Account_Id, Purchase_Currency, Converted_Cost_Vector, Goods_With_Unit_Cost_Vector, Transaction_Day, [Ts0, Ts1, Ts2]) :-
	unrealized_gains_increase_txs(Static_Data, Description, Trading_Account_Id, Purchase_Currency, Converted_Cost_Vector, Goods_With_Unit_Cost_Vector, Transaction_Day, Txs0, Historical_Txs, Current_Txs),
	Start_Date = Static_Data.start_date,
	add_days(Start_Date, -1, Before_Start),
	(nonvar(Txs0) -> txs_to_transactions(Transaction_Day, Txs0, Ts0) ; true),
	(nonvar(Current_Txs) -> txs_to_transactions(Start_Date, Current_Txs, Ts1) ; true),
	(nonvar(Historical_Txs) -> txs_to_transactions(Before_Start, Historical_Txs, Ts2) ; true).	

reduce_unrealized_gains(Static_Data, Description, Trading_Account_Id, Transaction_Day, Goods_Cost_Values, [Ts0, Ts1, Ts2]) :-
	maplist(unrealized_gains_reduction_txs(Static_Data, Description, Transaction_Day, Trading_Account_Id), Goods_Cost_Values, Txs0, Historical_Txs, Current_Txs),
	Start_Date = Static_Data.start_date,
	add_days(Start_Date, -1, Before_Start),
	(nonvar(Txs0) -> txs_to_transactions(Transaction_Day, Txs0, Ts0) ; true),
	(nonvar(Current_Txs) -> txs_to_transactions(Start_Date, Current_Txs, Ts1) ; true),
	(nonvar(Historical_Txs) -> txs_to_transactions(Before_Start, Historical_Txs, Ts2) ; true).	

unrealized_gains_increase_txs(Static_Data, Description, Trading_Account_Id, Purchase_Currency, Cost_Vector, Goods, Transaction_Day, Txs, Historical_Txs, Current_Txs) :-
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
		Transaction_Day @>= Start_Date
	->
		dr_cr_table_to_txs([
			% Account                               DR                                       CR
			(Unrealized_Gains_Currency_Movement,    Goods_Without_Currency_Movement,        Goods),
			(Unrealized_Gains_Excluding_Forex,	    Cost_Vector,      	                Goods_Without_Currency_Movement)
		], Txs, [Description, ' - only current period'], cr)
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
					Start_Date
				),
				Goods_Debit, Goods_Credit)
			],
			dr_cr_table_to_txs([
				% Account                             DR                                              CR
				(Unrealized_Gains_Currency_Movement,  Historical_Without_Currency_Movement,        Goods_Historical),
				(Unrealized_Gains_Excluding_Forex,	  Cost_Vector,             Historical_Without_Currency_Movement)
			], Historical_Txs, [Description, ' - historical part'], cr),
		
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
				% Account                                DR                                   CR
				(Unrealized_Gains_Currency_Movement,     Current_Without_Currency_Movement,        Goods),
				(Unrealized_Gains_Excluding_Forex,	     Opening_Goods_Value,       Current_Without_Currency_Movement)
			], Current_Txs, [Description, ' - current part'], cr)
		)
	).
	
unrealized_gains_reduction_txs(Static_Data, Description, Transaction_Day, Trading_Account_Id, Purchase_Info, Txs, Historical_Txs, Current_Txs) :-
	dict_vars(Static_Data, [Accounts, Report_Currency, Start_Date]),
	goods(Purchase_Currency, Goods_Unit_Name, Goods_Count, Cost, Purchase_Date) = Purchase_Info,

	gains_accounts(
		Accounts, Trading_Account_Id, unrealized, Goods_Unit_Name, 
		Unrealized_Gains_Currency_Movement, Unrealized_Gains_Excluding_Forex),

	Cost = value(Cost_Currency, Cost_Amount),
	Unit_Cost_Amount is Cost_Amount / Goods_Count,
	Unit_Cost = value(Cost_Currency, Unit_Cost_Amount),
	Goods_Unit = with_cost_per_unit(Goods_Unit_Name, Unit_Cost),
		
	Goods_Without_Currency_Movement = [coord(
		without_currency_movement_against_since(Goods_Unit, Purchase_Currency, Report_Currency, Purchase_Date), 
		Goods_Count, 0)
	],
	
	Goods = value(Goods_Unit, Goods_Count),
	Goods_Debit = Goods_Count, Goods_Credit = 0,
	
	/*
	the transactions produced should be an inverse of in increase ones, we should abstract out a generator of them, for a given tx date 
	*/
	
	(
		Transaction_Day @>= Start_Date
	->
		(
			dr_cr_table_to_txs([
			% Account                                 DR                                         CR
			(Unrealized_Gains_Currency_Movement,      Goods,         Goods_Without_Currency_Movement),
			(Unrealized_Gains_Excluding_Forex,        Goods_Without_Currency_Movement    ,      Cost)
			],
			Txs, [Description, ' - only current period'], dr)
		)
	;
		(
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
			% Account                                     DR                                                  CR
			(Unrealized_Gains_Currency_Movement,          Goods_Historical    ,                     Historical_Without_Currency_Movement),
			(Unrealized_Gains_Excluding_Forex,            Historical_Without_Currency_Movement    , Cost)
			],
			Historical_Txs, [Description, ' - historical part'], dr),
			
			Opening_Goods_Value = [coord(
				without_movement_after(Goods_Unit, Start_Date), 
				Goods_Debit, Goods_Credit)
			],
			Current_Without_Currency_Movement = [coord(
				without_currency_movement_against_since(Goods_Unit, Purchase_Currency, Report_Currency, Start_Date), 
				Goods_Debit, Goods_Credit)
			],
			dr_cr_table_to_txs([
				% Account                             DR                                           CR
				(Unrealized_Gains_Currency_Movement,  Goods,                  Current_Without_Currency_Movement),
				(Unrealized_Gains_Excluding_Forex,	  Current_Without_Currency_Movement,    Opening_Goods_Value)
			], Current_Txs, [Description, ' - current part'], dr)
		)
	).
/*
	T0.comment = 'reduce unrealized gain by outgoing asset and its cost'.
*/


increase_realized_gains(Static_Data, Description, Trading_Account_Id, Sale_Vector, Converted_Vector, Goods_Vector, Transaction_Day, Goods_Cost_Values, Ts2) :-

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
			Description,
			Transaction_Day,
			Sale_Currency,
			Sale_Currency_Unit_Price,
			Trading_Account_Id, 
			value(Converted_Currency, Sale_Unit_Price_Amount)
		), 
		Goods_Cost_Values, Txs2
	),
	txs_to_transactions(Transaction_Day, Txs2, Ts2).

realized_gains_txs(Static_Data, Description, _Transaction_Day, Sale_Currency, Sale_Currency_Unit_Price, Trading_Account_Id, Sale_Unit_Price_Converted, Purchase_Info, Txs) :-
	dict_vars(Static_Data, [Accounts, Report_Currency, Exchange_Rates]),
	goods(_ST_Currency, Goods_Unit, Goods_Count, Converted_Cost, Purchase_Date) = Purchase_Info,
	Sale_Currency_Amount is Sale_Currency_Unit_Price * Goods_Count,
	value_multiply(Sale_Unit_Price_Converted, Goods_Count, Sale),
	gains_accounts(
		Accounts, Trading_Account_Id, realized, Goods_Unit, 
		Realized_Gains_Currency_Movement, Realized_Gains_Excluding_Forex),
	
	/*what would be the Report_Currency value we'd get for this sale currency amount if purchase/sale currency didn't move against Report_Currency since the day of the purchase?*/
	vec_change_bases(
		Exchange_Rates, 
		Purchase_Date, 
		Report_Currency, 
		[coord(Sale_Currency, 0, Sale_Currency_Amount)],
		Sale_Without_Currency_Movement
	),
	/* Realized gains are sale price - cost. It does not matter what value we were attributing to the goods, at the date of sale or any other date.  */
	dr_cr_table_to_txs([
		% Account                                            DR                        CR
		(Realized_Gains_Currency_Movement,	     Sale_Without_Currency_Movement,       /*offset cash increase*/Sale),
		(Realized_Gains_Excluding_Forex,         Converted_Cost,                       Sale_Without_Currency_Movement)
		],
		Txs, Description, cr).

dr_cr_table_to_txs(Table, Txs, Description, Order_Hint) :-
	maplist(dr_cr_table_line_to_tx(Description, Order_Hint), Table, Txs).
	
dr_cr_table_line_to_tx(Description, Order_Hint, Line, Tx) :-
	Line = (Account, Dr0, Cr0),
	flatten([Dr0], Dr1),
	flatten([Cr0], Cr1),
	maplist(make_debit, Dr1, Dr2),
	maplist(make_credit, Cr1, Cr2),
	(
		Order_Hint = dr
	->
		append(Dr2, Cr2, Vector)
	;
		append(Cr2, Dr2, Vector)
	),
	Tx = tx{
		comment: _,
		comment2: Description,
		account: Account,
		vector: Vector
	}.

txs_to_transactions(Transaction_Day, Txs, Ts) :-
	flatten([Txs], Txs2),
	exclude(var, Txs2, Txs3),
	maplist(tx_to_transaction(Transaction_Day), Txs3, Ts).

tx_to_transaction(Day, Tx, Transaction) :-
	Tx = tx{comment: Comment, comment2: Comment2, account: Account, vector: Vector},
	nonvar(Account),
	ground(Vector),
	(var(Comment) -> Comment = '?'; true),
	(var(Comment2) -> Comment2 = '?'; true),
	flatten(['comment:', Comment, ', comment2:', Comment2], Description0),
	atomic_list_concat(Description0, Description),
	transaction_day(Transaction, Day),
	transaction_description(Transaction, Description),
	transaction_account_id(Transaction, Account),
	transaction_vector(Transaction, Vector_Flattened),
	transaction_type(Transaction, '?'),
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

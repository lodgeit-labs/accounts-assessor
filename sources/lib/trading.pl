
/*
	txs are dicts with most of informations needed to create a transaction.
	we will produce them from a simple table:
	Account         DR           CR
	...             ...          ...
	the vectors or coords in the table will be coerced to the given side, debit or credit.
	this may seem error prone, but any issues are yet to be found, and it clarifies the logic.
*/
			
 increase_unrealized_gains(St, Description, Trading_Account_Id, Purchase_Currency, Converted_Cost_Vector, Goods_With_Unit_Cost_Vector, Transaction_Day, [Ts0, Ts1, Ts2]) :-
	unrealized_gains_increase_txs(
		Description,
		Trading_Account_Id,
		Purchase_Currency,
		Converted_Cost_Vector,
		Goods_With_Unit_Cost_Vector,
		Transaction_Day,
		Txs0, Historical_Txs, Current_Txs
	),
	result_property(l:start_date, Start_Date),
	(nonvar(Txs0) ->
	txs_to_transactions(St, Transaction_Day, Txs0, Ts0) ; true),
	(nonvar(Historical_Txs) ->
	txs_to_transactions(St, Transaction_Day, Historical_Txs, Ts2) ; true),
	(nonvar(Current_Txs) ->
	txs_to_transactions(St, Start_Date, Current_Txs, Ts1) ; true).



 reduce_unrealized_gains(St, Description, Trading_Account_Id, Transaction_Day, Goods_Cost_Values, [Ts0, Ts1, Ts2]) :-
	maplist(
		unrealized_gains_reduction_txs(
			Description,
			Transaction_Day,
			Trading_Account_Id
		),
		Goods_Cost_Values,
		Txs0, Historical_Txs, Current_Txs
	),
	result_property(l:start_date, Start_Date),
	add_days(Start_Date, -1, Before_Start),
	(nonvar(Txs0) ->
	txs_to_transactions(St, Transaction_Day, Txs0, Ts0) ; true),
	(nonvar(Current_Txs) ->
	txs_to_transactions(St, Start_Date, Current_Txs, Ts1) ; true),
	(nonvar(Historical_Txs) ->
	txs_to_transactions(St, Before_Start, Historical_Txs, Ts2) ; true).


 unrealized_gains_increase_txs(
	Description,
	Trading_Account_Id,
	Purchase_Currency,
	Cost_Vector,
	Goods,
	Transaction_Day,
	Txs,
	Historical_Txs,
	Current_Txs
) :-
	result_property(l:report_currency, Report_Currency),
	result_property(l:start_date, Start_Date),
	Goods = [coord(Goods_Unit, Goods_Debit)],
	gains_accounts(
		Trading_Account_Id, unrealized, $>unit_bare(Goods_Unit),
		Currency_Movement_Account, Excluding_Forex_Account),
	Goods_Without_Currency_Movement = [coord(
		without_currency_movement_against_since(Goods_Unit, Purchase_Currency, Report_Currency, Transaction_Day), 
		Goods_Debit)
	],
	add_days(Start_Date, -1, Before_Start),
	(
		Transaction_Day @>= Start_Date
	->
		dr_cr_table_to_txs([
			% Account                               DR                                       CR
			(Currency_Movement_Account,    Goods_Without_Currency_Movement,        Goods),
			(Excluding_Forex_Account,	    Cost_Vector,      	                Goods_Without_Currency_Movement)
		], Txs, [Description, ' - single period  - unrealized gains increase at purchase'], cr)
	;
		(
			/*historical:*/
			Opening_Goods_Value = [coord(
				without_movement_after(Goods_Unit, Before_Start),
				Goods_Debit)
			],
			Historical_Without_Currency_Movement = [coord(
				without_movement_after(
					without_currency_movement_against_since(
						Goods_Unit, Purchase_Currency, Report_Currency, Transaction_Day
					), 
					Before_Start
				),
				Goods_Debit)
			],
			dr_cr_table_to_txs([
				% Account                             DR                                              CR
				(Currency_Movement_Account,  Historical_Without_Currency_Movement,        Opening_Goods_Value),
				(Excluding_Forex_Account,	  Cost_Vector,             Historical_Without_Currency_Movement)
			], Historical_Txs, [Description, ' - historical part'], cr),
		
			/*now, for tracking unrealized gains after Before_Start date*/
			/* goods value as it was at Before_Start */
			Current_Without_Currency_Movement = [coord(
				without_currency_movement_against_since(Goods_Unit, Purchase_Currency, Report_Currency, Before_Start),
				Goods_Debit)
			],
			dr_cr_table_to_txs([
				% Account                                DR                                   CR
				(Currency_Movement_Account,     Current_Without_Currency_Movement,        Goods),
				(Excluding_Forex_Account,	     Opening_Goods_Value,       Current_Without_Currency_Movement)
			], Current_Txs, [Description, ' - current part'], cr)
		)
	).


/* the transactions produced should be an inverse of the increase ones, we should abstract it out

an unrealized_gains_reduction_tx:
	when Transaction_Day @>= Start_Date:
		Purchase_Date @>= Start_Date:



*/
unrealized_gains_reduction_txs(Description, Transaction_Day, Trading_Account_Id, Purchase_Info, Txs, Historical_Txs, Current_Txs) :-
	result_property(l:report_currency, Report_Currency),
	result_property(l:start_date, Start_Date),
	add_days(Start_Date, -1, Before_Start),
	goods(Unit_Cost_Foreign, Goods_Unit_Name, Goods_Count, Cost, Purchase_Date) = Purchase_Info,
	value(Purchase_Currency,_) = Unit_Cost_Foreign,

	gains_accounts(
		Trading_Account_Id, unrealized, Goods_Unit_Name,
		Currency_Movement_Account, Excluding_Forex_Account),

	add_unit_cost_information(Goods_Unit_Name, Unit_Cost_Foreign, Goods_Unit),

	Goods = value(Goods_Unit, Goods_Count),
	Goods_Debit = Goods_Count, 

	Goods_Opening = [coord(
		without_movement_after(Goods_Unit, Before_Start),
		Goods_Debit)
	],
	vec_inverse(Goods_Opening, Goods_Opening_Cr),
	unrealized_gains_reduction_txs2(Transaction_Day, Start_Date, Before_Start, Purchase_Date,
	(
		Transaction_Day @>= Start_Date
	->
		(

			/* if purchase was made in report period, we will be reducing the gains which started at Purchase_Date */
			(	Purchase_Date @>= Start_Date
			->	(	Opening_Date = Purchase_Date,
					Cost2 = Cost)
			/* if purchase was made before report period, we will only be reducing the gains beginning with Before_Start */
			;	(	Opening_Date = Before_Start,
					Cost2 = Goods_Opening_Cr)),


			/* This value is what gives us the breakdown of gains into market and forex parts */
			Goods_Without_Currency_Movement = [coord(
				without_currency_movement_against_since(Goods_Unit, Purchase_Currency, Report_Currency, Opening_Date),
				Goods_Count)
			],


			dr_cr_table_to_txs([
				% Account                                 DR                                         CR
				(Currency_Movement_Account,      Goods,         Goods_Without_Currency_Movement),
				(Excluding_Forex_Account,        Goods_Without_Currency_Movement    ,      Cost2)
			], Txs, [Description, ' - single period - unrealized gains reduction at sale'], dr
			)
		)
	;
		(
			Historical_Without_Currency_Movement = [coord(
				without_movement_after(
					without_currency_movement_against_since(
						Goods_Unit, Purchase_Currency, Report_Currency, Transaction_Day
					), 
					Transaction_Day
				),
				Goods_Debit)
			],
				
			dr_cr_table_to_txs([
				% Account                                     DR                                                  CR
				(Currency_Movement_Account,          Goods_Opening    ,                     Historical_Without_Currency_Movement),
				(Excluding_Forex_Account,            Historical_Without_Currency_Movement    , Cost)
			], Historical_Txs, [Description, ' - historical part'], dr
			),
			Current_Without_Currency_Movement = [coord(
				without_currency_movement_against_since(Goods_Unit, Purchase_Currency, Report_Currency, Before_Start),
				Goods_Debit)
			],
			dr_cr_table_to_txs([
				% Account                             DR                                           CR
				(Currency_Movement_Account,  Goods,                  Current_Without_Currency_Movement),
				(Excluding_Forex_Account,	  Current_Without_Currency_Movement,    Goods_Opening)
			], Current_Txs, [Description, ' - current part'], dr
			)
		)
	).

/*
	T0.comment = 'reduce unrealized gain by outgoing asset and its cost'.
*/


increase_realized_gains(St, Description, Trading_Account_Id, Sale_Vector, Converted_Vector, Goods_Vector, Transaction_Day, Goods_Cost_Values, Ts2) :-

	[Goods_Coord] = Goods_Vector,
	number_coord(_, Goods_Integer, Goods_Coord),
	{Goods_Positive = -Goods_Integer},

	Sale_Vector = [coord(Sale_Currency, Sale_Currency_Amount)],
	{Sale_Currency_Unit_Price = Sale_Currency_Amount / Goods_Positive},
	
	[coord(Converted_Currency, Converted_Debit)] = Converted_Vector,
	{Sale_Unit_Price_Amount = Converted_Debit / Goods_Positive},
	
	maplist(
		realized_gains_txs(
			Description,
			Transaction_Day,
			Sale_Currency,
			Sale_Currency_Unit_Price,
			Trading_Account_Id, 
			value(Converted_Currency, Sale_Unit_Price_Amount)
		), 
		Goods_Cost_Values, Txs2
	),
	txs_to_transactions(St, Transaction_Day, Txs2, Ts2).

realized_gains_txs(Description, Transaction_Day, Sale_Currency, Sale_Currency_Unit_Price, Trading_Account_Id, Sale_Unit_Price_Converted, Purchase_Info, Txs) :-

	result_property(l:report_currency, Report_Currency),
	result_property(l:start_date, Start_Date),
	add_days(Start_Date, -1, Before_Start),

	goods(Unit_Cost_Foreign, Goods_Unit_Name, Goods_Count, Converted_Cost, Purchase_Date) = Purchase_Info,
	add_unit_cost_information(Goods_Unit_Name, Unit_Cost_Foreign, Goods_Unit),




	{Sale_Currency_Amount = Sale_Currency_Unit_Price * Goods_Count},
	value_multiply(Sale_Unit_Price_Converted, Goods_Count, Sale),
	gains_accounts(
		Trading_Account_Id, realized, Goods_Unit_Name,
		Realized_Gains_Currency_Movement, Realized_Gains_Excluding_Forex),
	
	/*what would be the Report_Currency value we'd get for this sale currency amount if purchase/sale currency didn't move against Report_Currency since the day of the purchase? This only makes sense for shares or similar where the price you sell it for is gonna be a result of healthy public trading or somesuch.*/
	
	Sale_Without_Currency_Movement = value(
		without_currency_movement_against_since(Sale_Currency, Sale_Currency, Report_Currency, Purchase_Date),
		Sale_Currency_Amount),
		
	(
		Purchase_Date @>= Start_Date
	->
		(
			dr_cr_table_to_txs([
				% Account                            DR                                CR
				(Realized_Gains_Currency_Movement,	 Sale_Without_Currency_Movement,   Sale),
				(Realized_Gains_Excluding_Forex,     Converted_Cost,                   Sale_Without_Currency_Movement)
			], Txs, Description, cr)
		)
	;
		(
			Transaction_Day @< Start_Date 
		->
			(
				
				dr_cr_table_to_txs([
					% Account                            DR                                CR
					(Realized_Gains_Currency_Movement,	 Sale_Without_Currency_Movement,   Sale),
					(Realized_Gains_Excluding_Forex,     Converted_Cost,                   Sale_Without_Currency_Movement)
				], Txs, Description, cr)
			)
		;   
			(
				/* historical purchase, current sale */
				Opening_Goods_Value = value(
					without_movement_after(Goods_Unit, Before_Start),
					Goods_Count
				),

				Sale_Without_Currency_Movement_Current = value(
					without_currency_movement_against_since(Sale_Currency, Sale_Currency, Report_Currency, Before_Start),
					Sale_Currency_Amount),
				dr_cr_table_to_txs([
					% Account                            DR                                        CR
					(Realized_Gains_Currency_Movement,	 Sale_Without_Currency_Movement_Current,   Sale),
					(Realized_Gains_Excluding_Forex,     Opening_Goods_Value,              Sale_Without_Currency_Movement_Current)
				], Txs, Description, cr)
			)
		)
	).

make_debit(value(Unit, Amount), coord(Unit, Amount)).
make_debit(coord(Unit, Dr), coord(Unit, Dr)) :- Dr >= 0.
make_debit(coord(Unit, DrA), coord(Unit, DrB)) :- DrA < 0, {DrB = -DrA}.

make_credit(value(Unit, Amount), coord(Unit, Amount2)) :- {Amount2 = -Amount}.
make_credit(coord(Unit, DrA), coord(Unit, DrB)) :- DrA > 0, {DrB = -DrA}.
make_credit(coord(Unit, Dr), coord(Unit, Dr)) :- Dr =< 0.

/*
 Order_Hint - irrelevant for functionality, ordering coords for easy reading
 Txs - output
*/
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

txs_to_transactions(St, Transaction_Day, Txs, Ts) :-
	flatten([Txs], Txs2),
	exclude(var, Txs2, Txs3),
	maplist(!tx_to_transaction(St, Transaction_Day), Txs3, Ts).

tx_to_transaction(St, Day, Tx, Transaction) :-
	Tx = tx{comment: Comment, comment2: Comment2, account: Account, vector: Vector},
	nonvar(Account),
	ground(Vector),
	(var(Comment) -> Comment = ''; true),
	(var(Comment2) -> Comment2 = ''; true),
	flatten(['comment:', Comment, ', comment2:', Comment2], Description0),
	atomic_list_concat(Description0, Description),
	flatten(Vector, Vector_Flattened),
	(!make_transaction2(St, Day, Description, Account, Vector_Flattened, '?', Transaction)).
	


	
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

unit_bare(with_cost_per_unit(Unit, _), Unit) :- !.
unit_bare(Unit, Unit).
	
add_unit_cost_information(Goods_Unit_Name, Unit_Cost, Goods_Unit) :-
	result_property(l:cost_or_market, Cost_Or_Market),
	(	Cost_Or_Market = cost
	->	Goods_Unit = with_cost_per_unit(Goods_Unit_Name, Unit_Cost)
	;	Goods_Unit = Goods_Unit_Name).


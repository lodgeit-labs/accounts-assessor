preprocess_until_error(Static_Data0, Prepreprocessed_S_Transactions, Preprocessed_S_Transactions, Transactions0, Outstanding_Out, Report_End_Date, Processed_Until) :-
	preprocess_s_transactions(Static_Data0, Prepreprocessed_S_Transactions, Preprocessed_S_Transactions, Transactions0, Outstanding_Out),
	Processed_Until = Report_End_Date.

preprocess_s_transactions(Static_Data, S_Transactions, Processed_S_Transactions, Transactions_Out, Outstanding_Out) :-
	preprocess_s_transactions2(Static_Data, S_Transactions, Processed_S_Transactions, Transactions_Out, ([],[]), Outstanding_Out, []).

/*
	call preprocess_s_transaction on each item of the S_Transactions list and do some error checking and cleaning up
*/
preprocess_s_transactions2(_, [], [], [], Outstanding, Outstanding, _).

preprocess_s_transactions2(Static_Data, [S_Transaction|S_Transactions], Processed_S_Transactions, Transactions_Out, Outstanding_In, Outstanding_Out, Debug_So_Far) :-
	dict_vars(Static_Data, [Report_Currency, Start_Date, End_Date, Exchange_Rates]),
	pretty_term_string(S_Transaction, S_Transaction_String),
	catch(
		(
			check_that_s_transaction_account_exists(S_Transaction),
			preprocess(Static_Data, S_Transaction, S_Transaction_String, Outstanding_In, Outstanding_Mid, Debug_Head, Transactions_Out_Tail, Debug_So_Far, Debug_So_Far2, Processed_S_Transactions, Processed_S_Transactions_Tail, Report_Currency, Exchange_Rates, Start_Date, End_Date, Transactions_Out)
		),
		E,
		(
			pretty_string(S_Transaction, Pretty_S_Transaction_String),
			format(string(Debug_Head), '~q~nwhen processing ~w', [E, Pretty_S_Transaction_String]),
			format(user_error, '~w~n',[Debug_Head]),
			Outstanding_In = Outstanding_Out,
			Transactions_Out = [],
			Debug_Tail = [],
			Processed_S_Transactions = [],
			add_alert('error', Debug_Head)
		)
	),
	(	var(Debug_Tail) /* debug tail is left free if processing this transaction succeeded ... */
	->	preprocess_s_transactions2(Static_Data, S_Transactions, Processed_S_Transactions_Tail, Transactions_Out_Tail,  Outstanding_Mid, Outstanding_Out, Debug_So_Far2)
	;	true).

preprocess(Static_Data, S_Transaction, S_Transaction_String, Outstanding_In, Outstanding_Mid, Debug_Head, Transactions_Out_Tail, Debug_So_Far, Debug_So_Far2, Processed_S_Transactions, Processed_S_Transactions_Tail, Report_Currency, Exchange_Rates, Start_Date, End_Date, Transactions_Out) :-
	(	preprocess_s_transaction(Static_Data, S_Transaction, Transactions0, Outstanding_In, Outstanding_Mid)
	->	true
	;	(/*gtrace,*/throw_string(unknown_error))),
	cleanup(Transactions0, Transactions_Result, S_Transaction_String, Debug_Head),
	Transactions_Out = [Transactions_Result|Transactions_Out_Tail],
	append(Debug_So_Far, [Debug_Head], Debug_So_Far2),
	Processed_S_Transactions = [S_Transaction|Processed_S_Transactions_Tail],
	check_trial_balance0_at_date_of_last_transaction_in_list(Transactions_Result, Report_Currency, Exchange_Rates, Start_Date, End_Date, Debug_So_Far, Debug_Head).

cleanup(Transactions0, Transactions_Result, S_Transaction_String, Debug_Head) :-
	% filter out unbound vars from the resulting Transactions list, as some rules do not always produce all possible transactions
	flatten(Transactions0, Transactions1),
	exclude(var, Transactions1, Transactions2),
	exclude(has_empty_vector, Transactions2, Transactions_Result),
	%pretty_transactions_string(Transactions_Result, Transactions_String),
	Transactions_String = 'todo',
	atomic_list_concat([S_Transaction_String, '==>\n', Transactions_String, '\n====\n'], Debug_Head).


check_trial_balance0_at_date_of_last_transaction_in_list(Transactions_Result, Report_Currency, Exchange_Rates, Start_Date, End_Date, Debug_So_Far, Debug_Head) :-
	Transactions_Result = [T|_],
	transaction_day(T, Transaction_Date),
	(	Report_Currency = []
	->	true
	;	check_trial_balance0(Exchange_Rates, Report_Currency, Transaction_Date, Transactions_Result, Start_Date, End_Date, Debug_So_Far, Debug_Head)).


% ----------
% This predicate takes a list of statement transaction terms and decomposes it into a list of plain transaction terms.
% ----------	

preprocess_s_transaction(Static_Data, S_Transaction, Transactions, Outstanding, Outstanding) :-
	s_transaction_type_id(S_Transaction, uri(Action_Verb)),
	member(V, $>livestock_verbs),
	rdf_global_id(V, Action_Verb),
	preprocess_livestock_buy_or_sell(Static_Data, S_Transaction, Transactions).

preprocess_s_transaction(Static_Data, S_Transaction, Transactions, Outstanding_Before, Outstanding_After) :-
	s_transaction_type_id(S_Transaction, uri(Action_Verb)),
	maplist(dif(Action_Verb), $>rdf_global_id($>livestock_verbs,<$)),
	Transactions = [Ts1, Ts2, Ts3, Ts4],
	dict_vars(Static_Data, [Report_Currency, Exchange_Rates]),
	s_transaction_exchanged(S_Transaction, vector(Counteraccount_Vector)),
	s_transaction_vector(S_Transaction, Vector_Ours),
	s_transaction_day(S_Transaction, Transaction_Date),
	Pricing_Method = lifo,
	doc(Action_Verb, l:has_id, Action_Verb_Id),
	(doc(Action_Verb, l:has_counteraccount, Exchanged_Account_Ui)->true;throw_string('action verb does not specify exchange account')),
	account_by_ui(Exchanged_Account_Ui, Exchanged_Account),
	(doc(Action_Verb, l:has_trading_account, Trading_Account_Ui)->true;true),
	account_by_ui(Trading_Account_Ui, Trading_Account),
	Description = Action_Verb_Id,
	affect_bank_account(Static_Data, S_Transaction, Description, Ts1),
	vector_unit(Vector_Ours, Bank_Account_Currency),
	vec_change_bases(Exchange_Rates, Transaction_Date, Report_Currency, Vector_Ours, Converted_Vector_Ours),
	(
		Counteraccount_Vector = []
	->
		(
			(	nonvar(Trading_Account)
			->	(throw_string(['trading account but no exchanged unit', S_Transaction]))
			;	true),
			record_expense_or_earning_or_equity_or_loan(Static_Data, S_Transaction, Action_Verb, Vector_Ours, Exchanged_Account, Transaction_Date, Description, Ts4),
			Outstanding_After = Outstanding_Before
		)
	;
		(
			is_debit(Counteraccount_Vector)
		->
			(
				(	\+is_debit(Vector_Ours)
				->	true
				;	throw_string('debit Counteraccount_Vector but debit money Vector')),

/*				Buy is
		a p:purchase_event,
		p:origin St,
		p:trading_account Trading_Account,
		p:pricing_method Pricing_Method,
		p:bank_account_currency Bank_Account_Currency,
		p:goods_vector Goods_Vector,
		p:converted_vector_ours Converted_Vector_Ours,
		p:vector_ours Vector_Ours,
		p:exchanged_account Exchanged_Account,
		p:transaction_date Transaction_Date,
		p:description Description,
		p:outstanding_in Outstanding_In,
		p:outstanding_out Outstanding_Out,
*/
        		make_buy(Static_Data, S_Transaction, Trading_Account, Pricing_Method, Bank_Account_Currency, Counteraccount_Vector, Converted_Vector_Ours, Vector_Ours, Exchanged_Account, Transaction_Date, Description, Outstanding_Before, Outstanding_After, Ts2)
			)
		;
			(
				(	\+is_credit(Vector_Ours)
				->	true
				;	throw_string('credit Counteraccount_Vector but credit money Vector')),

				make_sell(
				Static_Data, S_Transaction, Trading_Account, Pricing_Method, Bank_Account_Currency, Counteraccount_Vector, Vector_Ours,
				Converted_Vector_Ours,	Exchanged_Account, Transaction_Date, Description,	Outstanding_Before, Outstanding_After, Ts3)

			)
		)
	).

/*
	purchased shares are recorded in an assets account without conversion. The unit is optionally wrapped in a with_cost_per_unit term.
	Separately from that, we also change Outstanding with each buy or sell.
*/

make_buy(Static_Data, St, Trading_Account, Pricing_Method, Bank_Account_Currency, Goods_Vector,
	Converted_Vector_Ours, Vector_Ours,
	Exchanged_Account, Transaction_Date, Description,
	Outstanding_In, Outstanding_Out, [Ts1, Ts2]
) :-
	[Coord_Ours] = Vector_Ours,
	[Goods_Coord] = Goods_Vector,


	coord_vec(Coord_Ours_Converted, Converted_Vector_Ours),
	/* in case of an empty vector, the unit was lost, so fill it back in */
	(	Static_Data.report_currency = [Report_Currency]
	->	Coord_Ours_Converted = coord(Report_Currency, _)
	;	Coord_Ours_Converted = coord(Bank_Account_Currency, _)),


	unit_cost_value(Coord_Ours, Goods_Coord, Unit_Cost_Foreign),
	unit_cost_value(Coord_Ours_Converted, Goods_Coord, Unit_Cost_Converted),
	number_coord(Goods_Unit, Goods_Count, Goods_Coord),
	dict_vars(Static_Data, [Cost_Or_Market]),

	/*technically, the action verb could be smarter and know that the exchanged account name that user specified must correspond to an account with role 'FinancialInvestments'/name.
	some sort of generalized system is shaping up.
	*/

	financial_investments_account(Exchanged_Account,Goods_Unit,Exchanged_Account2),

	(	Cost_Or_Market = cost
	->	(
			purchased_goods_coord_with_cost(Goods_Coord, Coord_Ours, Goods_Coord_With_Cost),
			Goods_Vector2 = [Goods_Coord_With_Cost]
		)
	;	Goods_Vector2 = Goods_Vector),

	make_transaction(St, Transaction_Date, Description, Exchanged_Account2, Goods_Vector2, Ts1),

	%[coord(Goods_Unit_Maybe_With_Cost,_)] = Goods_Vector2,

	add_bought_items(
		Pricing_Method,
		outstanding(Bank_Account_Currency, Goods_Unit, Goods_Count, Unit_Cost_Converted, Unit_Cost_Foreign, Transaction_Date),
		Outstanding_In, Outstanding_Out
	),
	(nonvar(Trading_Account) ->
		increase_unrealized_gains(Static_Data, St, Description, Trading_Account, Bank_Account_Currency, Converted_Vector_Ours, Goods_Vector2, Transaction_Date, Ts2) ; true
	).


/*
wip, docizing..

make_buy(Purchase, Gl_Txs) :-

	coord_vec(Coord_Ours, Vector_Ours),
	coord_vec(Goods_Coord, Goods_Vector),

	coord_vec(Coord_Ours_Converted, Converted_Vector_Ours),

	% in case of an empty vector, the unit was lost, so fill it back in
	(	Static_Data.report_currency = [Report_Currency]
	->	Coord_Ours_Converted = coord(Report_Currency, _)
	;	Coord_Ours_Converted = coord(Bank_Account_Currency, _)),

	unit_cost_value(Coord_Ours, Goods_Coord, Unit_Cost_Foreign),
	unit_cost_value(Coord_Ours_Converted, Goods_Coord, Unit_Cost_Converted),
	number_coord(Goods_Unit, Goods_Count, Goods_Coord),
	dict_vars(Static_Data, [Accounts, Cost_Or_Market]),
	account_by_role(Accounts, Exchanged_Account/Goods_Unit, Exchanged_Account2),

	(
		(
			Cost_Or_Market = cost,
			purchased_goods_coord_with_cost(Goods_Coord, Coord_Ours, Goods_Coord_With_Cost),
			Goods_Vector2 = [Goods_Coord_With_Cost],
			doc_assert(Purchase, p:goods_with_cost_vector, Goods_Vector2)
		)
	;
		(

		)
	;	Goods_Vector2 = Goods_Vector),

	make_transaction(St, Transaction_Date, Description, Exchanged_Account2, Goods_Vector2, T1),
	member(T1, Gl_Txs),


	add_bought_items(
		Pricing_Method, 
		outstanding(Bank_Account_Currency, Goods_Unit, Goods_Count, Unit_Cost_Converted, Unit_Cost_Foreign, Transaction_Date),
		Outstanding_In, Outstanding_Out
	),


	maybe_trading_account_txs(Gl_Txs,




		increase_unrealized_gains(Static_Data, Goods_Vector2, Gl_Txs)
	).
*/

make_sell(Static_Data, St, Trading_Account, Pricing_Method, _Bank_Account_Currency, Goods_Vector,
	Vector_Ours, Converted_Vector_Ours,
	Exchanged_Account, Transaction_Date, Description,
	Outstanding_In, Outstanding_Out, [Ts1, Ts2, Ts3]
) :-
	credit_vec(Goods_Unit,Goods_Positive,Goods_Vector),
	financial_investments_account(Exchanged_Account,Goods_Unit,Exchanged_Account2),
	bank_debit_to_unit_price(Vector_Ours, Goods_Positive, Sale_Unit_Price),

	((find_items_to_sell(Pricing_Method, Goods_Unit, Goods_Positive, Transaction_Date, Sale_Unit_Price, Outstanding_In, Outstanding_Out, Goods_Cost_Values),!)
		;(throw(not_enough_goods_to_sell))),
	maplist(sold_goods_vector_with_cost(Static_Data), Goods_Cost_Values, Goods_With_Cost_Vectors),
	maplist(
		make_transaction(St, Transaction_Date, Description, Exchanged_Account2),
		Goods_With_Cost_Vectors, Ts1
	),
	(nonvar(Trading_Account) -> 
		(						
			reduce_unrealized_gains(Static_Data, St, Description, Trading_Account, Transaction_Date, Goods_Cost_Values, Ts2),

			increase_realized_gains(Static_Data, St, Description, Trading_Account, Vector_Ours, Converted_Vector_Ours, Goods_Vector, Transaction_Date, Goods_Cost_Values, Ts3)
		)
	; true
	).

bank_debit_to_unit_price(Vector_Ours, Goods_Positive, value(Unit, Number2)) :-
	Vector_Ours = [Coord],
	number_coord(Unit, Number, Coord),
	{Number2 = Number / Goods_Positive}.

	
/*	
	Transactions using currency trading accounts can be decomposed into:
	a transaction of the given amount to the unexchanged account (your bank account)
	a transaction of the transformed inverse into the exchanged account (your shares investments account)
	and a transaction of the negative sum of these into the trading cccount. 
	this "currency trading account" is not to be confused with a shares trading account.
*/

affect_bank_account(Static_Data, S_Transaction, Description0, [Ts0, Ts3]) :-
	s_transaction_account(S_Transaction, Bank_Account_Name),
	s_transaction_vector(S_Transaction, Vector),
	vector_unit(Vector, Bank_Account_Currency),
	s_transaction_day(S_Transaction, Transaction_Date),
	(	is_debit(Vector)
	->	Description1 = 'incoming money'
	;	Description1 = 'outgoing money'
	),
	[Description0, ' - ', Description1] = Description,
	dict_vars(Static_Data, [Report_Currency]),
	Bank_Account_Role = ('Banks'/Bank_Account_Name),
	account_by_role_throw(Bank_Account_Role, Bank_Account_Id),
	make_transaction(S_Transaction, Transaction_Date, Description, Bank_Account_Id, Vector, Ts0),
	/* Make a difference transaction to the currency trading account. See https://www.mathstat.dal.ca/~selinger/accounting/tutorial.html . This will track the gain/loss generated by the movement of exchange rate between our asset in foreign currency and our equity/revenue in reporting currency. */
	(	[Bank_Account_Currency] = Report_Currency
	->	true
	;	make_currency_movement_transactions(Static_Data, S_Transaction, Bank_Account_Id, Transaction_Date, Vector, [Description, ' - currency movement adjustment'], Ts3)
	).

/* Make an inverse exchanged transaction to the exchanged account.*/
record_expense_or_earning_or_equity_or_loan(Static_Data, St, Action_Verb, Vector_Ours, Exchanged_Account, Date, Description, [T0,T1]) :-
	Report_Currency = Static_Data.report_currency,
	Exchange_Rates = Static_Data.exchange_rates,
	vec_inverse(Vector_Ours, Vector_Ours2),
	vec_change_bases(Exchange_Rates, Date, Report_Currency, Vector_Ours2, Vector_Converted),
	(
		(
			%doc(Action_Verb, l:has_gst_rate, Gst_Rate^^_),
			doc(Action_Verb, l:has_gst_rate, Gst_Rate),
			Gst_Rate =\= 0
		)
	->
		(
			(
				/*we sold stuff with tax included and received money, gotta pay GST*/
				is_debit(Vector_Ours)
			->
				doc(Action_Verb, l:has_gst_payable_account, Gst_Acc)
			;
				doc(Action_Verb, l:has_gst_receivable_account, Gst_Acc)
			),
			split_vector_by_percent(Vector_Converted, Gst_Rate, Gst_Vector, Vector_Converted_Remainder),
			make_transaction(St, Date, Description, Gst_Acc, Gst_Vector, T0)
		)
	;
		Vector_Converted_Remainder = Vector_Converted
	),
	make_transaction(St, Date, Description, Exchanged_Account, Vector_Converted_Remainder, T1).
	


purchased_goods_coord_with_cost(Goods_Coord, Cost_Coord, Goods_Coord_With_Cost) :-
	unit_cost_value(Cost_Coord, Goods_Coord, Unit_Cost),
	coord(Goods_Unit, Goods_Count) = Goods_Coord,
	Goods_Coord_With_Cost = coord(
		with_cost_per_unit(Goods_Unit, Unit_Cost),
		Goods_Count
	).

unit_cost_value(Cost_Coord, Goods_Coord, Unit_Cost) :-
	Goods_Coord = coord(_, Goods_Count),
	assertion(Goods_Count > 0),
	credit_coord(Currency, Price, Cost_Coord),
	assertion(Price >= 0),

	{Unit_Cost_Amount = Price / Goods_Count},
	Unit_Cost = value(Currency, Unit_Cost_Amount).

sold_goods_vector_with_cost(Static_Data, Goods_Cost_Value, [Goods_Coord_With_Cost]) :-
	Goods_Cost_Value = goods(Unit_Cost_Foreign, Goods_Unit, Goods_Count, _Total_Cost_Value, _),
	(	Static_Data.cost_or_market = market
	->	Unit = Goods_Unit
	;	(
			%value_divide(Foreign_Cost, Goods_Count, Unit_Cost_Value),
			Unit = with_cost_per_unit(Goods_Unit, Unit_Cost_Foreign)
		)
	),
	credit_coord(Unit, Goods_Count, Goods_Coord_With_Cost).

/*
	Vector  - the amount by which the assets account is changed
	Date - transaction day
	https://www.mathstat.dal.ca/~selinger/accounting/tutorial.html#4
*/
make_currency_movement_transactions(Static_Data, St, Bank_Account, Date, Vector, Description, [Transaction1, Transaction2, Transaction3]) :-

	dict_vars(Static_Data, [Start_Date, Report_Currency]),
	/* find the account to affect */
	bank_gl_account_currency_movement_account(Bank_Account,Currency_Movement_Account),
	/*
		we will be tracking the movement of Vector (in foreign currency) against the revenue/expense in report currency. 
		the value of this transaction will grow as the exchange rate of foreign currency moves against report currency.
	*/
	without_movement(Report_Currency, Date, Vector, Vector_Exchanged_To_Report_Currency),
	[Report_Currency_Coord] = Vector_Exchanged_To_Report_Currency,
	
	(
		Date @< Start_Date
	->
		(
			/* the historical earnings difference transaction tracks asset value change against converted/frozen earnings value, up to report start date  */
			vector_without_movement_after(Vector, Start_Date, Vector_Frozen_After_Start_Date),
			make_difference_transaction(St,
				Currency_Movement_Account, Date, [Description, ' - historical part'], 
				
				Vector_Frozen_After_Start_Date,
				[Report_Currency_Coord],
				
				Transaction1),
			/* the current earnings difference transaction tracks asset value change against opening value */
			vector_without_movement_after(Vector, Start_Date, Vector_Frozen_At_Opening_Date),
			make_difference_transaction(St,
				Currency_Movement_Account, Start_Date, [Description, ' - current part'], 
				
				Vector,
				Vector_Frozen_At_Opening_Date,
				
				Transaction2)
		)
	;
		make_difference_transaction(St,
			Currency_Movement_Account, Date, [Description, ' - only current period'], 
			
			Vector,
			Vector_Exchanged_To_Report_Currency, 
			
			Transaction3
		)
	)
	.

vector_without_movement_after([coord(Unit1,D)], Start_Date, [coord(Unit2,D)]) :-
	Unit2 = without_movement_after(Unit1, Start_Date).
	
make_difference_transaction(St, Account, Date, Description, What, Against, Transaction) :-
	vec_sub(What, Against, Diff),
	/* when an asset account goes up, it rises in debit, and the revenue has to rise in credit to add up to 0 */
	vec_inverse(Diff, Diff_Revenue),
	make_transaction2(St, Date, Description, Account, Diff_Revenue, tracking, Transaction),
	transaction_type(Transaction, tracking).
	

without_movement(Report_Currency, Since, [coord(Unit, D)], [coord(Unit2, D)]) :-
	Unit2 = without_currency_movement_against_since(
		Unit, 
		Unit, 
		Report_Currency,
		Since
	).

transactions_trial_balance(Exchange_Rates, Report_Currency, Date, Transactions, Vector_Converted) :-
	maplist(transaction_vector, Transactions, Vectors_Nested),
	flatten(Vectors_Nested, Vector),
	vec_change_bases(Exchange_Rates, Date, Report_Currency, Vector, Vector_Converted).

is_livestock_transaction(X) :-
	transaction_description(X, Desc),
	(
		Desc = 'livestock sell'
	; 
		Desc = 'livestock buy'
	).

check_trial_balance(Exchange_Rates, Report_Currency, Date, Transactions) :-
	/*
	writeln("Check Trial Balance: xxxxxxxxxx"),
	writeln(Exchange_Rates),
	writeln(Transactions),
	maplist(transaction_description,Transactions, Transaction_Descriptions),
	writeln(Transaction_Descriptions),
	*/
	exclude(
		is_livestock_transaction,
		Transactions,
		Transactions_Without_Livestock
	),
	transactions_trial_balance(Exchange_Rates, Report_Currency, Date, Transactions_Without_Livestock, Total),
	(
		Total = []
	->
		true
	;
		(
			maplist(coord_is_almost_zero, Total)
		->
			true
		;
			(
				add_alert('SYSTEM_WARNING', $>format(string(<$), 'trial balance at ~w is ~w\n', [Date, Total]))
			)
		)
	).

	
% throw an error if the account is not found in the hierarchy
check_that_s_transaction_account_exists(S_Transaction) :-
	s_transaction_account(S_Transaction, Account_Name),
	bank_gl_account_by_bank_name(Account_Name, _).





fill_in_missing_units(_,_, [], _, _, []).

fill_in_missing_units(S_Transactions0, Report_End_Date, [Report_Currency], Used_Units, Exchange_Rates, Inferred_Rates) :-
	reverse(S_Transactions0, S_Transactions),
	findall(
		Rate,
		(
			member(Unit, Used_Units),
			Unit \= Report_Currency,
			\+is_exchangeable_into_request_bases(Exchange_Rates, Report_End_Date, Unit, [Report_Currency]),
			(
				Unit = without_currency_movement_against_since(Unit2,_,_,_)
				;
				Unit = Unit2
			),
			infer_unit_cost_from_last_buy_or_sell(Unit2, S_Transactions, Rate),
			Rate = exchange_rate(Report_End_Date, _, _, _)
		),
		Inferred_Rates
	).
	
 
pretty_transactions_string(Transactions, String) :-
	Seen_Units = [],
	
	pretty_transactions_string2(Seen_Units, Transactions, String).

pretty_transactions_string2(_, [], '').
pretty_transactions_string2(Seen_Units0, [Transaction|Transactions], String) :-
	transaction_day(Transaction, Date),
	term_string(Date, Date_Str),
	transaction_description(Transaction, Description),
	transaction_account(Transaction, Account),
	transaction_vector(Transaction, Vector),
	pretty_vector_string(Seen_Units0, Seen_Units1, Vector, Vector_Str),
	atomic_list_concat([
		Date_Str, ': ', Account, '\n',
		'  ', Description, '\n',
		Vector_Str,
	'\n'], Transaction_String),
	pretty_transactions_string2(Seen_Units1, Transactions, String_Rest),
	atomic_list_concat([Transaction_String, String_Rest], String).

pretty_vector_string(Seen_Units, Seen_Units, [], '').
pretty_vector_string(Seen_Units0, Seen_Units_Out, [Coord|Rest], Vector_Str) :-
	Coord = coord(Unit, Dr),
	(
		Dr >= 0
	->
		Side = 'DR'
	;
		Side = 'CR'
	),
	(
		member((Shorthand = Unit), Seen_Units0)
	->
		Seen_Units1 = Seen_Units0
	;
		(
			gensym('U', Shorthand),
			Seen_Unit = (Shorthand = Unit),
			append(Seen_Units0, [Seen_Unit], Seen_Units1)
		)
	),
	term_string(Coord, Coord_Str0),
	atomic_list_concat(['  ', Side, ':', Shorthand, ':', Coord_Str0, '\n'], Coord_Str),
	pretty_vector_string(Seen_Units1, Seen_Units_Out, Rest, Rest_Str),
	atomic_list_concat([Coord_Str, Rest_Str], Vector_Str).





check_trial_balance0(Exchange_Rates, Report_Currency, Transaction_Date, Transactions_Out, _Start_Date, End_Date, Debug_So_Far, Debug_Head) :-
	catch(
		(
			check_trial_balance(Exchange_Rates, Report_Currency, Transaction_Date, Transactions_Out),
			check_trial_balance(Exchange_Rates, Report_Currency, End_Date, Transactions_Out)
			%(
			%	Transaction_Date @< Start_Date...
		),
		E,
		(
			format(user_error, '\n\\n~w\n\n', [Debug_So_Far]),
			format(user_error, '\n\nwhen processing:\n~w', [Debug_Head]),
			pretty_term_string(E, E_Str),
			throw_string([E_Str])
		)
	).




/*
+member(Bst, Bsts),
+{
+       member(...
+       ...
+}
+
+
+
+
+affect_bank_account_gl_account(Static_Data, Bst, Description0, [Ts0, Ts3]) :-
+       d(Bst, account, Bank_Account_Name),
+       account_by_role(('Banks'/Bank_Account_Name), Gl_Bank_Account_Id),
+
+       e(Bst.day, Tx0.day),
+       e(Bst.day, Tx1.day),
+
*/

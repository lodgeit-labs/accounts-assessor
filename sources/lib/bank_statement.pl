/*
call preprocess_s_transaction on each item of the S_Transactions list and do some error checking and cleaning up
*/
 preprocess_s_transactions([], [], [], Outstanding, Outstanding).

 preprocess_s_transactions(
	[S_Transaction|S_Transactions],
	Processed_S_Transactions,
	Transactions_Out,
	Outstanding_In,
	Outstanding_Out
) :-
	(
		(
			cutoff,
			Outstanding_In = Outstanding_Out,
			Transactions_Out = [],
			Processed_S_Transactions = []
		)
	;
		(
			is_not_cutoff,
			bump_ic_n_sts_processed,
			preprocess_s_transactions2(
				[S_Transaction|S_Transactions],
				Processed_S_Transactions,
				Transactions_Out,
				Outstanding_In,
				Outstanding_Out
			)
		)
	).




 preprocess_s_transactions2(
	[S_Transaction|S_Transactions],
	Processed_S_Transactions,
	Transactions_Out,
	Outstanding_In,
	Outstanding_Out
) :-
	push_format(
		'processing source transaction:~n ~w~n', [
			$>!pretty_st_string(S_Transaction)]),

	(	current_prolog_flag(die_on_error, true)
	->	E = something_that_doesnt_unify_with_any_error
	;	true),

	catch_with_backtrace(
		!preprocess_s_transaction3(
			S_Transaction,
			Outstanding_In,
			Outstanding_Mid,
			Transactions_Out_Tail,
			Processed_S_Transactions,
			Processed_S_Transactions_Tail,
			Transactions_Out
		),
		E,
		(
		/* watch out: this re-establishes doc to the state it was before the exception */
			!handle_processing_exception(E)
		)
	),

	pop_context,

	(	var(E)
	->	(
			% recurse
			preprocess_s_transactions(
				S_Transactions,
				Processed_S_Transactions_Tail,
				Transactions_Out_Tail,
				Outstanding_Mid,
				Outstanding_Out
			)
		)
	;	(
			% give up
			Outstanding_In = Outstanding_Out,
			Transactions_Out = [],
			Processed_S_Transactions = []
		)
	).


 preprocess_s_transaction3(
	S_Transaction,
	Outstanding_In,
	Outstanding_Mid,
	Transactions_Out_Tail,
	Processed_S_Transactions,
	Processed_S_Transactions_Tail,
	Transactions_Out
) :-
	check_that_s_transaction_account_exists(S_Transaction),
	s_transaction_type_id(S_Transaction, uri(Action_Verb)),
	(	doc(Action_Verb, l:has_counteraccount, Exchanged_Account_Ui)
	->	true
	;	Exchanged_Account_Ui = ''),
	(	doc(Action_Verb, l:has_trading_account, Trading_Account_Ui)
	->	true
	;	Trading_Account_Ui = ''),
	push_format(
		'using action verb ~q:~n  exchanged account: ~q~n  trading account: ~q~n', [
			$>doc(Action_Verb, l:has_id),
			Exchanged_Account_Ui,
			Trading_Account_Ui]
	),
	!preprocess_s_transaction(
		S_Transaction,
		Transactions0,
		Outstanding_In,
		Outstanding_Mid),
	clean_up_txset(Transactions0, Transactions_Result),
	Transactions_Out = [Transactions_Result|Transactions_Out_Tail],
	Processed_S_Transactions = [S_Transaction|Processed_S_Transactions_Tail],
	!check_txsets(Transactions_Result),
	pop_context.


 clean_up_txset(Transactions0, Transactions_Result) :-
	flatten(Transactions0, Transactions1),
	exclude(var, Transactions1, Transactions2),
	exclude(has_empty_vector, Transactions2, Transactions_Result).



/*
take statement/source transaction and generate a list of plain transactios.
*/
 preprocess_s_transaction(
	S_Transaction,
	Transactions,
	Outstanding,
	Outstanding
) :-
	s_transaction_type_id(S_Transaction, uri(Action_Verb)),
	member(V, $>livestock_verbs),
	rdf_global_id(V, Action_Verb),
	cf(preprocess_livestock_buy_or_sell(S_Transaction, Transactions)).

 preprocess_s_transaction(
	S_Transaction,
	Transactions,
	Outstanding_Before,
	Outstanding_After
) :-
	s_transaction_type_id(S_Transaction, uri(Action_Verb)),
	maplist(dif(Action_Verb), $>rdf_global_id($>livestock_verbs,<$)),
	Transactions = [Ts1, Ts2, Ts3, Ts4],
	s_transaction_exchanged(S_Transaction, vector(Counteraccount_Vector)),
	/* is it time to introduce something like gtrace_on_user_error, and keep it off by default? */
	(	is_zero(Counteraccount_Vector)
	->	throw_string('exchanged 0 units?')
	;	true),
	s_transaction_vector(S_Transaction, Vector_Ours),
	s_transaction_day(S_Transaction, Transaction_Date),
	doc(Action_Verb, l:has_id, Action_Verb_Id),
	Description = Action_Verb_Id,

	extract_pricing_method(Pricing_method),
	affect_first_account(S_Transaction, Description, Ts1),

	vector_unit(Vector_Ours, Bank_Account_Currency),
	vec_change_bases($>result_property(l:exchange_rates), Transaction_Date, $>result_property(l:report_currency), Vector_Ours, Converted_Vector_Ours),
	cf(action_verb_accounts(Action_Verb,Exchanged_Account,Trading_Account)),
	(
		Counteraccount_Vector = []
	->
		(
			(	nonvar(Trading_Account)
			->	(throw_string(['trading account but no exchanged unit', S_Transaction]))
			;	true),
			cf(record_expense_or_earning_or_equity_or_loan(S_Transaction, Action_Verb, Vector_Ours, Exchanged_Account, Transaction_Date, Description, Ts4)),
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

        		make_buy(S_Transaction, Trading_Account, Pricing_method, Bank_Account_Currency, Counteraccount_Vector, Converted_Vector_Ours, Vector_Ours, Exchanged_Account, Transaction_Date, Description, Outstanding_Before, Outstanding_After, Ts2)
			)
		;
			(
				(	\+is_credit(Vector_Ours)
				->	true
				;	throw_string('credit Counteraccount_Vector but credit money Vector')),

				cf(make_sell(
				S_Transaction, Trading_Account, Pricing_method, Counteraccount_Vector, Vector_Ours,
				Converted_Vector_Ours,	Exchanged_Account, Transaction_Date, Description,	Outstanding_Before, Outstanding_After, Ts3))

			)
		)
	).

 extract_pricing_method(Pricing_method) :-
	(	report_details_property_value(ic:pricing_method, Pricing_method0)
	->	rdf_global_id(Pricing_method,Pricing_method0)
	;	Pricing_method = ic:lifo).


 action_verb_accounts(Action_Verb, Exchanged_Account,Trading_Account) :-
	push_context($>format(string(<$), 'looking up accounts of action verb ~q', [$>doc(Action_Verb, l:has_id)])),

	(	doc(Action_Verb, l:has_counteraccount, Exchanged_Account_Ui)
	->	account_by_ui(Exchanged_Account_Ui, Exchanged_Account)
	;	true),
	(	doc(Action_Verb, l:has_trading_account, Trading_Account_Ui)
	->	account_by_ui(Trading_Account_Ui, Trading_Account)
	;	true),
	pop_context.


/*
	purchased shares are recorded in an assets account without conversion. The unit is optionally wrapped in a with_cost_per_unit term.
	Separately from that, we also change Outstanding with each buy or sell.
*/

 make_buy(St, Trading_Account, Pricing_Method, Bank_Account_Currency, Goods_Vector,
	Converted_Vector_Ours, Vector_Ours,
	Exchanged_Account, Transaction_Date, Description,
	Outstanding_In, Outstanding_Out, [Ts1, Ts2]
) :-
	push_format('record purchase of ~q onto ~q', [Goods_Vector, $>account_name(Exchanged_Account)]),
	[Coord_Ours] = Vector_Ours,
	[Goods_Coord] = Goods_Vector,


	coord_vec(Coord_Ours_Converted, Converted_Vector_Ours),
	/* in case of an empty vector, the unit was lost, so fill it back in */
	result_property(l:report_currency, Report_Currency0),
	(	Report_Currency0 = [Report_Currency]
	->	Coord_Ours_Converted = coord(Report_Currency, _)
	;	Coord_Ours_Converted = coord(Bank_Account_Currency, _)),


	unit_cost_value(Coord_Ours, Goods_Coord, Unit_Cost_Foreign),
	unit_cost_value(Coord_Ours_Converted, Goods_Coord, Unit_Cost_Converted),
	number_coord(Goods_Unit, Goods_Count, Goods_Coord),
	result_property(l:cost_or_market, Cost_Or_Market),

	/*technically, the action verb could be smarter and know that the exchanged account name that user specified must correspond to an account with role 'Financial_Investments'/name.
	some sort of generalized system is shaping up.
	*/

	financial_investments_account(Exchanged_Account,Goods_Unit,Exchanged_Account2),

	(	Cost_Or_Market = cost
	->	(
			cf(purchased_goods_coord_with_cost(Goods_Coord, Coord_Ours, Goods_Coord_With_Cost)),
			Goods_Vector2 = [Goods_Coord_With_Cost]
		)
	;	Goods_Vector2 = Goods_Vector),

	(make_transaction(St, Transaction_Date, Description, Exchanged_Account2, Goods_Vector2, Ts1)),

	%[coord(Goods_Unit_Maybe_With_Cost,_)] = Goods_Vector2,

	cf(add_bought_items(
		Pricing_Method,
		outstanding(Bank_Account_Currency, Goods_Unit, Goods_Count, Unit_Cost_Converted, Unit_Cost_Foreign, Transaction_Date),
		Outstanding_In, Outstanding_Out
	)),
	(nonvar(Trading_Account) ->
		cf(increase_unrealized_gains(St, Description, Trading_Account, Bank_Account_Currency, Converted_Vector_Ours, Goods_Vector2, Transaction_Date, Ts2)) ; true
	),

	pop_context.



 money_vector_string(Vec, Str) :-
	maplist(money_value_string, Vec, Strs),
	atomics_to_string(Strs, ', ', Str).

 money_value_string(value(U, Amount), Str) :-
	format(string(Str), '~w ~w', [$>round_term(U), $>round_term(Amount)]).


 outstandings_str((Outstanding_In, Investments_In), Str) :-
	format(string(Str0), 'current outstanding investments:~noutstanding(purchase_currency, goods_unit, goods_count, unit_cost, unit_cost_foreign, purchase_date):~n~w', [$>line_per_item_write_quoted($>round_term(Outstanding_In))]),
	format(string(Str1), 'investments history:~n~w', [$>investment_str_lines($>round_term(Investments_In))]),
	atomics_to_string([Str0, Str1],'\n',Str).


 investment_str_lines(Investments,Str) :-
	maplist(investment_str_lines2,Investments,Strs),
	atomics_to_string(Strs,'\n',Str).

 investment_str_lines2(Item,Str) :-
	Item = investment(Purchase, Sales),
	format(string(Str),'~q:~n~w~n', [Purchase, $>line_per_item_write_quoted(Sales)]).

 line_per_item_write_quoted(Items, Str) :-
	maplist(line_per_item_write_quoted2,Items,Strs),
	atomics_to_string(Strs,'\n',Str).

 line_per_item_write_quoted2(Item,Str) :-
	format(string(Str),'~q', [Item]).

 make_sell(
 	St,
 	Trading_Account,
 	Pricing_Method,
 	Goods_Vector,
 	Vector_Ours,
 	Converted_Vector_Ours,
 	Exchanged_Account,
 	Transaction_Date,
 	Description,
 	Outstanding_In,
 	Outstanding_Out,
 	[Ts1, Ts2, Ts3]
) :-
	credit_vec(Goods_Unit,Goods_Positive,Goods_Vector),
	push_context(
		$>format(string(<$),
		'sell ~w of ~q for ~w',
		[
			Goods_Positive,
			Goods_Unit,
			$>money_vector_string($>vector_of_coords_vs_vector_of_values(kb:debit,Vector_Ours))])),

	financial_investments_account(Exchanged_Account,Goods_Unit,Exchanged_Account2),
	bank_debit_to_unit_price(Vector_Ours, Goods_Positive, Sale_Unit_Price),

	(	find_items_to_sell(Pricing_Method, Goods_Unit, Goods_Positive, Transaction_Date, Sale_Unit_Price, Outstanding_In, Outstanding_Out, Goods_Cost_Values)
	->	true
	;	(
			true,
			throw($>format(
				string(<$),
				'not enough outstanding stock to sell.~n~w', [
					$>outstandings_str(Outstanding_In)]))
		)
	),

	maplist(sold_goods_vector_with_cost, Goods_Cost_Values, Goods_With_Cost_Vectors),
	maplist(
		make_transaction(St, Transaction_Date, Description, Exchanged_Account2),
		Goods_With_Cost_Vectors, Ts1),

	(	nonvar(Trading_Account)
	->	(
			reduce_unrealized_gains(St, Description, Trading_Account, Transaction_Date, Goods_Cost_Values, Ts2),
			increase_realized_gains(St, Description, Trading_Account, Vector_Ours, Converted_Vector_Ours, Goods_Vector, Transaction_Date, Goods_Cost_Values, Ts3)
		)
	;	true),
	pop_context.

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

 affect_first_account(S_Transaction, Description, Ts1) :-
	!s_transaction_account(S_Transaction, uri(First_Account)),
	(	account_by_role(rl('Banks'/_), First_Account)
	->	cf(affect_bank_account(First_Account, S_Transaction, Description, Ts1))
	;	(
			s_transaction_day(S_Transaction, Transaction_Date),
			s_transaction_vector(S_Transaction, Vector),
			make_transaction(S_Transaction, Transaction_Date, Description, First_Account, Vector, Ts1)
		)
	).

 affect_bank_account(Bank_Account, S_Transaction, Description0, [Ts0, Ts3]) :-
	s_transaction_vector(S_Transaction, Vector),
	vector_unit(Vector, Bank_Account_Currency),
	s_transaction_day(S_Transaction, Transaction_Date),
	(	is_debit(Vector)
	->	Description1 = 'incoming money'
	;	Description1 = 'outgoing money'
	),
	[Description0, ' - ', Description1] = Description,
	make_transaction(S_Transaction, Transaction_Date, Description, Bank_Account, Vector, Ts0),
	/* Make a difference transaction to the currency trading account. See https://www.mathstat.dal.ca/~selinger/accounting/tutorial.html . This will track the gain/loss generated by the movement of exchange rate between our asset in foreign currency and our equity/revenue in reporting currency. */
	result_property(l:report_currency, Report_Currency),
	(	[Bank_Account_Currency] = Report_Currency
	->	true
	;	make_currency_movement_transactions(S_Transaction, Bank_Account, Transaction_Date, Vector, [Description, ' - currency movement adjustment'], Ts3)
	).

/* Make an inverse exchanged transaction to the exchanged account.*/
 record_expense_or_earning_or_equity_or_loan(St, Action_Verb, Vector_Ours, Exchanged_Account, Date, Description, [T0,T1]) :-

	result_property(l:report_currency, Report_Currency),
	result_property(l:exchange_rates, Exchange_Rates),
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

 sold_goods_vector_with_cost(Goods_Cost_Value, [Goods_Coord_With_Cost]) :-
	Goods_Cost_Value = goods(Unit_Cost_Foreign, Goods_Unit, Goods_Count, _Total_Cost_Value, _),
	result_property(l:cost_or_market, Cost_Or_Market),
	(	Cost_Or_Market = market
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

 make_currency_movement_transactions(St, Bank_Account, Date, Vector, Description, [Transaction1, Transaction2, Transaction3]) :-

	result_property(l:report_currency, Report_Currency),

	/* find the account to affect */
	bank_gl_account_currency_movement_account(Bank_Account,Currency_Movement_Account),
	/*
		we will be tracking the movement of Vector (in foreign currency) against the revenue/expense in report currency.
		the value of this transaction will grow as the exchange rate of foreign currency moves up against report currency.
	*/

	/*
	this is (?) equvalent to simply converting the vector to report currency at this date. We leave it abstract to avoid doing the conversion here, because the conversion may turn out to be unnecessary (if this tx is nullified by opposite tx later). todo other reasons?
	*/
	make_without_currency_movement_against_since(Report_Currency, Date, Vector, Vector_Exchanged_To_Report_Currency),

	difference_transactions(
		Date,
		Vector_Exchanged_To_Report_Currency,
		Vector,
		(St,Currency_Movement_Account,Description,Transaction1,Transaction2,Transaction3)
	).



 make_difference_transaction(St, Account, Date, Description, What, Against, Transaction) :-
	vec_sub(What, Against, Diff),
	/* when an asset account goes up, it rises in debit, and the revenue has to rise in credit to add up to 0 */
	vec_inverse(Diff, Diff_Revenue),
	make_transaction2(St, Date, Description, Account, Diff_Revenue, tracking, Transaction),
	transaction_type(Transaction, tracking).
	

 is_livestock_transaction(X) :-
	transaction_description(X, Desc),
	(	Desc = 'livestock sell'
	; 	Desc = 'livestock buy').


% throw an error if the account is not found in the hierarchy
 check_that_s_transaction_account_exists(S_Transaction) :-
	!s_transaction_account(S_Transaction, uri(Account)),
	!doc(Account, rdf:type, l:account, accounts).


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
	


 /*
 more like a smart compact string useful for debugging, not sure if it still works
 */
 pretty_transactions_string(Transactions, String) :-
	Seen_Units = [],
	pretty_transactions_string2(Seen_Units, Transactions, String).

 pretty_transactions_string2(_, [], '').
 pretty_transactions_string2(Seen_Units0, [Transaction|Transactions], String) :-
	transaction_day(Transaction, Date),
	pretty_term_string($>round_term(Date), Date_Str),
	transaction_description(Transaction, Description),
	account_name($>transaction_account(Transaction), Account),
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
	term_string($>round_term(Coord), Coord_Str0),
	atomic_list_concat(['  ', Side, ':', Shorthand, ':', Coord_Str0, '\n'], Coord_Str),
	pretty_vector_string(Seen_Units1, Seen_Units_Out, Rest, Rest_Str),
	atomic_list_concat([Coord_Str, Rest_Str], Vector_Str).


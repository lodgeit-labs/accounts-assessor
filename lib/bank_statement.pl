:- module(_, [
		extract_s_transaction/3, 
		preprocess_s_transactions/6,
		print_relevant_exchange_rates_comment/4,
		invert_s_transaction_vector/2, 
		fill_in_missing_units/6
		]).

:- use_module('pacioli',  [
		coord_unit/2,
		vec_inverse/2, 
		vec_add/3, 
		vec_sub/3, 
		number_coord/3,
		make_debit/2,
		make_credit/2,
		value_multiply/3,
		value_divide/3,
		is_debit/1,
		coord_is_almost_zero/1]).
:- use_module('exchange', [
		vec_change_bases/5]).
:- use_module('exchange_rates', [
		exchange_rate/5, 
		is_exchangeable_into_request_bases/4]).
:- use_module('action_verbs', []).
:- use_module('livestock', []).
:- use_module('transactions', [
		has_empty_vector/1,
		transaction_day/2,
		transaction_description/2,
		transaction_account_id/2,
		transaction_vector/2,
		transaction_type/2,
		make_transaction/5,
		make_transaction2/5
		]).
:- use_module(library(xbrl/utils), [
		pretty_term_string/2, 
		inner_xml/3, 
		write_tag/2, 
		fields/2, 
		field_nothrow/2, 
		numeric_fields/2, 
		throw_string/1]).
:- use_module('accounts', [
		account_by_role/3, 
		account_in_set/3,
		account_role_by_id/3,
		account_exists/2]).
:- use_module('days', [
		format_date/2, 
		parse_date/2,
		add_days/3]).
:- use_module('pricing', [
		add_bought_items/4, 
		find_items_to_sell/8]).
:- use_module('doc', [doc/3]).
:- use_module('s_transaction', [
		s_transaction_day/2,
		s_transaction_type_id/2,
		s_transaction_vector/2,
		s_transaction_account_id/2,
		s_transaction_exchanged/2,
		sort_s_transactions/2,
		s_transactions_up_to/3,
		s_transaction_to_dict/2
]).


:- use_module(library(semweb/rdf11)).
:- use_module(library(xpath)).
:- use_module(library(rdet)).

:- [trading].

/*TODO add more rdet declarations here*/
:- rdet(preprocess_s_transaction/5).




preprocess_s_transactions(Static_Data, S_Transactions, Processed_S_Transactions, Transactions_Out, Outstanding_Out, Debug_Info) :-
	preprocess_s_transactions2(Static_Data, S_Transactions, Processed_S_Transactions, Transactions_Out, ([],[]), Outstanding_Out, Debug_Info, []).

/*
	call preprocess_s_transaction on each item of the S_Transactions list and do some error checking and cleaning up
*/
preprocess_s_transactions2(_, [], [], [], Outstanding, Outstanding, ['done.'], _).

preprocess_s_transactions2(Static_Data, [S_Transaction|S_Transactions], Processed_S_Transactions, Transactions_Out, Outstanding_In, Outstanding_Out, [Debug_Head|Debug_Tail], Debug_So_Far) :-
	dict_vars(Static_Data, [Accounts, Report_Currency, Start_Date, End_Date, Exchange_Rates]),
	pretty_term_string(S_Transaction, S_Transaction_String),
	catch(
		(
			check_that_s_transaction_account_exists(S_Transaction, Accounts),
			catch(
				(
					(preprocess_s_transaction(Static_Data, S_Transaction, Transactions0, Outstanding_In, Outstanding_Mid)
					-> true; (/*trace,*/fail)),
					% filter out unbound vars from the resulting Transactions list, as some rules do not always produce all possible transactions
					flatten(Transactions0, Transactions1),
					exclude(var, Transactions1, Transactions2),
					exclude(has_empty_vector, Transactions2, Transactions_Result),
					pretty_transactions_string(Transactions_Result, Transactions_String),
					atomic_list_concat([S_Transaction_String, '==>\n', Transactions_String, '\n====\n'], Debug_Head),
					
					append(Debug_So_Far, [Debug_Head], Debug_So_Far2),
					Processed_S_Transactions = [S_Transaction|Processed_S_Transactions_Tail],
					Transactions_Out = [Transactions_Result|Transactions_Out_Tail],
					
					Transactions_Result = [T|_],
					transaction_day(T, Transaction_Date),
					(
						Report_Currency = []
					->
						true
					;
						check_trial_balance0(Exchange_Rates, Report_Currency, Transaction_Date, Transactions_Result, Start_Date, End_Date, Debug_So_Far, Debug_Head)
					)
				),
				not_enough_goods_to_sell,
				(
					atomic_list_concat([not_enough_goods_to_sell, ' when processing ', S_Transaction_String], Debug_Head),
					Outstanding_In = Outstanding_Out,
					Transactions_Out = [],
					Debug_Tail = [],
					Processed_S_Transactions = []
				)
			)
		),
		E,
		(
			term_string(E, E_Str),
			throw_string([E_Str, ' when processing ', S_Transaction_String]) /*hmm shouldn't throw string here*/
		)
	),
	(
		var(Debug_Tail) /* debug tail is left free if processing this transaction succeeded ... */
	->
		preprocess_s_transactions2(Static_Data, S_Transactions, Processed_S_Transactions_Tail, Transactions_Out_Tail,  Outstanding_Mid, Outstanding_Out, Debug_Tail, Debug_So_Far2)
	;
		true
	).

% ----------
% This predicate takes a list of statement transaction terms and decomposes it into a list of plain transaction terms.
% ----------	

preprocess_s_transaction(Static_Data, S_Transaction, Transactions, Outstanding, Outstanding) :-
	s_transaction_type_id(S_Transaction, uri(Action_Verb)),
	(Action_Verb = l:livestock_purchase;Action_Verb = l:livestock_sale),
	!,
	livestock:preprocess_livestock_buy_or_sell(Static_Data, S_Transaction, Transactions).

preprocess_s_transaction(Static_Data, S_Transaction, Transactions, Outstanding_Before, Outstanding_After) :-
	Transactions = [Ts1, Ts2, Ts3, Ts4],
	dict_vars(Static_Data, [Report_Currency, Exchange_Rates]),
	s_transaction_exchanged(S_Transaction, vector(Counteraccount_Vector)),
	%s_transaction_account_id(S_Transaction, Bank_Account_Name),
	s_transaction_type_id(S_Transaction, uri(Action_Verb)),
	s_transaction_vector(S_Transaction, Vector_Ours),
	s_transaction_day(S_Transaction, Transaction_Date),
	Pricing_Method = lifo,
	doc(Action_Verb, l:has_id, Action_Verb_Id),
	(doc(Action_Verb, l:has_counteraccount, Exchanged_Account)->true;throw_string('action verb does not specify exchange account')),
	(doc(Action_Verb, l:has_trading_account, Trading_Account)->true;true),
	Description = Action_Verb_Id,
	affect_bank_account(Static_Data, S_Transaction, Description, Ts1),
	pacioli:vector_unit(Vector_Ours, Bank_Account_Currency),
	vec_change_bases(Exchange_Rates, Transaction_Date, Report_Currency, Vector_Ours, Converted_Vector_Ours),
	(
		Counteraccount_Vector = []
	->
		(
			assertion(Counteraccount_Vector = []),
			record_expense_or_earning_or_equity_or_loan(Static_Data, Action_Verb, Vector_Ours, Exchanged_Account, Transaction_Date, Description, Ts4),
			Outstanding_After = Outstanding_Before
		)
	;
		(
			is_debit(Counteraccount_Vector)
		->
			make_buy(
				Static_Data, Trading_Account, Pricing_Method, Bank_Account_Currency, Counteraccount_Vector,
				Converted_Vector_Ours, Vector_Ours, Exchanged_Account, Transaction_Date, Description, Outstanding_Before, Outstanding_After, Ts2)
		;
			make_sell(
				Static_Data, Trading_Account, Pricing_Method, Bank_Account_Currency, Counteraccount_Vector, Vector_Ours,
				Converted_Vector_Ours,	Exchanged_Account, Transaction_Date, Description,	Outstanding_Before, Outstanding_After, Ts3)
		)
	).

/*
	purchased shares are recorded in an assets account without conversion. The unit is optionally wrapped in a with_cost_per_unit term.
	Separately from that, we also change Outstanding with each buy or sell.
*/
make_buy(Static_Data, Trading_Account, Pricing_Method, Bank_Account_Currency, Goods_Vector, 
	Converted_Vector_Ours, Vector_Ours,
	Exchanged_Account, Transaction_Date, Description, 
	Outstanding_In, Outstanding_Out, [Ts1, Ts2]
) :-
	[Coord_Ours] = Vector_Ours,
	[Goods_Coord] = Goods_Vector,
	[Coord_Ours_Converted] = Converted_Vector_Ours,
	unit_cost_value(Coord_Ours, Goods_Coord, Unit_Cost_Foreign),
	unit_cost_value(Coord_Ours_Converted, Goods_Coord, Unit_Cost_Converted),
	number_coord(Goods_Unit, Goods_Count, Goods_Coord),
	dict_vars(Static_Data, [Accounts, Cost_Or_Market]),
	account_by_role(Accounts, Exchanged_Account/Goods_Unit, Exchanged_Account2),
	(
		Cost_Or_Market = cost
	->
		(
			purchased_goods_coord_with_cost(Goods_Coord, Coord_Ours_Converted, Goods_Coord_With_Cost),
			Goods_Vector2 = [Goods_Coord_With_Cost]
		)
	;
		Goods_Vector2 = Goods_Vector
	),
	make_transaction(Transaction_Date, Description, Exchanged_Account2, Goods_Vector2, Ts1),
	add_bought_items(
		Pricing_Method, 
		outstanding(Bank_Account_Currency, Goods_Unit, Goods_Count, Unit_Cost_Converted, Unit_Cost_Foreign, Transaction_Date),
		Outstanding_In, Outstanding_Out
	),
	(nonvar(Trading_Account) -> 
		increase_unrealized_gains(Static_Data, Description, Trading_Account, Bank_Account_Currency, Converted_Vector_Ours, Goods_Vector2, Transaction_Date, Ts2) ; true
	).

make_sell(Static_Data, Trading_Account, Pricing_Method, _Bank_Account_Currency, Goods_Vector,
	Vector_Ours, Converted_Vector_Ours,
	Exchanged_Account, Transaction_Date, Description,
	Outstanding_In, Outstanding_Out, [Ts1, Ts2, Ts3]
) :-
	pacioli:credit_coord(Goods_Unit,Goods_Positive,Goods_Vector),
	dict_vars(Static_Data, [Accounts]),
	account_by_role(Accounts, Exchanged_Account/Goods_Unit, Exchanged_Account2),
	bank_debit_to_unit_price(Vector_Ours, Goods_Positive, Sale_Unit_Price),
	((find_items_to_sell(Pricing_Method, Goods_Unit, Goods_Positive, Transaction_Date, Sale_Unit_Price, Outstanding_In, Outstanding_Out, Goods_Cost_Values),!)
		;(throw(not_enough_goods_to_sell))),
	maplist(sold_goods_vector_with_cost(Static_Data), Goods_Cost_Values, Goods_With_Cost_Vectors),
	maplist(
		make_transaction(Transaction_Date, Description, Exchanged_Account2), 
		Goods_With_Cost_Vectors, Ts1
	),
	(nonvar(Trading_Account) -> 
		(						
			reduce_unrealized_gains(Static_Data, Description, Trading_Account, Transaction_Date, Goods_Cost_Values, Ts2),
			increase_realized_gains(Static_Data, Description, Trading_Account, Vector_Ours, Converted_Vector_Ours, Goods_Vector, Transaction_Date, Goods_Cost_Values, Ts3)
		)
	; true
	).

bank_debit_to_unit_price(Vector_Ours, Goods_Positive, value(Unit, Number2)) :-
	Vector_Ours = [Coord],
	number_coord(Unit, Number, Coord),
	Number2 is Number / Goods_Positive.

	
/*	
	Transactions using currency trading accounts can be decomposed into:
	a transaction of the given amount to the unexchanged account (your bank account)
	a transaction of the transformed inverse into the exchanged account (your shares investments account)
	and a transaction of the negative sum of these into the trading cccount. 
	this "currency trading account" is not to be confused with a shares trading account.
*/

affect_bank_account(Static_Data, S_Transaction, Description0, [Ts0, Ts3]) :-
	s_transaction_account_id(S_Transaction, Bank_Account_Name),
	s_transaction_vector(S_Transaction, Vector),
	pacioli:vector_unit(Vector, Bank_Account_Currency),
	s_transaction_day(S_Transaction, Transaction_Date),
	(	is_debit(Vector)
	->	Description1 = 'incoming money'
	;	Description1 = 'outgoing money'
	),
	[Description0, ' - ', Description1] = Description,
	dict_vars(Static_Data, [Accounts, Report_Currency]),
	Bank_Account_Role = ('Banks'/Bank_Account_Name),
	account_by_role(Accounts, Bank_Account_Role, Bank_Account_Id),
	make_transaction(Transaction_Date, Description, Bank_Account_Id, Vector, Ts0),
	/* Make a difference transaction to the currency trading account. See https://www.mathstat.dal.ca/~selinger/accounting/tutorial.html . This will track the gain/loss generated by the movement of exchange rate between our asset in foreign currency and our equity/revenue in reporting currency. */
	(	[Bank_Account_Currency] = Report_Currency
	->	true
	;	make_currency_movement_transactions(Static_Data, Bank_Account_Id, Transaction_Date, Vector, [Description, ' - currency movement adjustment'], Ts3)
	).

/* Make an inverse exchanged transaction to the exchanged account.*/
record_expense_or_earning_or_equity_or_loan(Static_Data, Action_Verb, Vector_Ours, Exchanged_Account, Date, Description, [T0,T1]) :-
	Report_Currency = Static_Data.report_currency,
	Exchange_Rates = Static_Data.exchange_rates,
	vec_inverse(Vector_Ours, Vector_Ours2),
	vec_change_bases(Exchange_Rates, Date, Report_Currency, Vector_Ours2, Vector_Converted),
	(
		(
			doc(Action_Verb, l:has_gst_rate, Gst_Rate^^_),
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
			pacioli:split_vector_by_percent(Vector_Converted, Gst_Rate, Gst_Vector, Vector_Converted_Remainder),
			make_transaction(Date, Description, Gst_Acc, Gst_Vector, T0)
		)
	;
		Vector_Converted_Remainder = Vector_Converted
	),
	make_transaction(Date, Description, Exchanged_Account, Vector_Converted_Remainder, T1).
	


purchased_goods_coord_with_cost(Goods_Coord, Cost_Coord, Goods_Coord_With_Cost) :-
	unit_cost_value(Cost_Coord, Goods_Coord, Unit_Cost),
	Goods_Coord = coord(Goods_Unit, Goods_Count),
	Goods_Coord_With_Cost = coord(
		with_cost_per_unit(Goods_Unit, Unit_Cost),
		Goods_Count
	).

unit_cost_value(Cost_Coord, Goods_Coord, Unit_Cost) :-
	Goods_Coord = coord(_, Goods_Count),
	assertion(Goods_Count > 0),
	credit_coord(Currency, Price, Cost_Coord),
	assertion(Price >= 0),
	Unit_Cost_Amount is Price / Goods_Count,
	Unit_Cost = value(Currency, Unit_Cost_Amount).

sold_goods_vector_with_cost(Static_Data, Goods_Cost_Value, [Goods_Coord_With_Cost]) :-
	Goods_Cost_Value = goods(_, Goods_Unit, Goods_Count, Total_Cost_Value, _),
	(
		Static_Data.cost_or_market = market
	->
		Unit = Goods_Unit
	;
		(
			value_divide(Total_Cost_Value, Goods_Count, Unit_Cost_Value),
			Unit = with_cost_per_unit(Goods_Unit, Unit_Cost_Value)
		)
	),
	credit_coord(Unit, Goods_Count, Goods_Coord_With_Cost).

/*
	Vector  - the amount by which the assets account is changed
	Date - transaction day
	https://www.mathstat.dal.ca/~selinger/accounting/tutorial.html#4
*/
make_currency_movement_transactions(Static_Data, Bank_Account, Date, Vector, Description, [Transaction1, Transaction2, Transaction3]) :-

	dict_vars(Static_Data, [Accounts, Start_Date, Report_Currency]),
	/* find the account to affect */
	account_role_by_id(Accounts, Bank_Account, (_/Bank_Child_Role)),
	account_by_role(Accounts, ('CurrencyMovement'/Bank_Child_Role), Currency_Movement_Account),
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
			make_difference_transaction(
				Currency_Movement_Account, Date, [Description, ' - historical part'], 
				
				Vector_Frozen_After_Start_Date,
				[Report_Currency_Coord],
				
				Transaction1),
			/* the current earnings difference transaction tracks asset value change against opening value */
			vector_without_movement_after(Vector, Start_Date, Vector_Frozen_At_Opening_Date),
			make_difference_transaction(
				Currency_Movement_Account, Start_Date, [Description, ' - current part'], 
				
				Vector,
				Vector_Frozen_At_Opening_Date,
				
				Transaction2)
		)
	;
		make_difference_transaction(
			Currency_Movement_Account, Date, [Description, ' - only current period'], 
			
			Vector,
			Vector_Exchanged_To_Report_Currency, 
			
			Transaction3
		)
	)
	.

vector_without_movement_after([coord(Unit1,D)], Start_Date, [coord(Unit2,D)]) :-
	Unit2 = without_movement_after(Unit1, Start_Date).
	
make_difference_transaction(Account, Date, Description, What, Against, Transaction) :-
	vec_sub(What, Against, Diff),
	/* when an asset account goes up, it rises in debit, and the revenue has to rise in credit to add up to 0 */
	vec_inverse(Diff, Diff_Revenue),
	make_transaction2(Date, Description, Account, Diff_Revenue, Transaction),
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
			format('<!-- SYSTEM_WARNING: trial balance is ~w at ~w -->\n', [Total, Date])
		)
	).

	
% throw an error if the s_transaction's account is not found in the hierarchy
check_that_s_transaction_account_exists(S_Transaction, Accounts) :-
	s_transaction_account_id(S_Transaction, Account_Name),
	account_by_role(Accounts, ('Banks'/Account_Name), _).


% yield all transactions from all accounts one by one.
% these are s_transactions, the raw transactions from bank statements. Later each s_transaction will be preprocessed
% into multiple transaction(..) terms.
% fixme dont fail silently
extract_s_transaction(Dom, Start_Date, Transaction) :-
	xpath(Dom, //reports/balanceSheetRequest/bankStatement/accountDetails, Account),
	catch(
		fields(Account, [
			accountName, Account_Name,
			currency, Account_Currency
			]),
			E,
			(
				pretty_term_string(E, E_Str),
				throw(http_reply(bad_request(string(E_Str)))))
			)
	,
	xpath(Account, transactions/transaction, Tx_Dom),
	catch(
		extract_s_transaction2(Tx_Dom, Account_Currency, Account_Name, Start_Date, Transaction),
		Error,
		(
			term_string(Error, Str1),
			term_string(Tx_Dom, Str2),
			atomic_list_concat([Str1, Str2], Message),
			throw(Message)
		)),
	true.

extract_s_transaction2(Tx_Dom, Account_Currency, Account, Start_Date, ST) :-
	numeric_fields(Tx_Dom, [
		debit, (Bank_Debit, 0),
		credit, (Bank_Credit, 0)]),
	fields(Tx_Dom, [
		transdesc, (Desc, '')
	]),
	(
		(
			xpath(Tx_Dom, transdate, element(_,_,[Date_Atom]))
			,
			!
		)
		;
		(
			Date_Atom=Start_Date, 
			writeln("date missing, assuming beginning of request period")
		)
	),
	parse_date(Date_Atom, Date),
	Dr is Bank_Debit - Bank_Credit,
	Coord = coord(Account_Currency, Dr),
	ST = s_transaction(Date, Desc, [Coord], Account, Exchanged),
	extract_exchanged_value(Tx_Dom, Account_Currency, Dr, Exchanged).

extract_exchanged_value(Tx_Dom, _Account_Currency, Bank_Dr, Exchanged) :-
   % if unit type and count is specified, unifies Exchanged with a one-item vector with a coord with those values
   % otherwise unifies Exchanged with bases(..) to trigger unit conversion later
   (
	  field_nothrow(Tx_Dom, [unitType, Unit_Type]),
	  (
		 (
			field_nothrow(Tx_Dom, [unit, Unit_Count_Atom]),
			atom_number(Unit_Count_Atom, Unit_Count),
			Count_Absolute is abs(Unit_Count),
			(
				Bank_Dr > 0
			->
					Exchanged = vector([coord(Unit_Type, Count_Absolute)])
			;
				(
					Count_Credit is -Count_Absolute,
					Exchanged = vector([coord(Unit_Type, Count_Credit)])
				)
			),
			!
		 )
		 ;
		 (
			% If the user has specified only a unit type, then infer count by exchange rate
			Exchanged = bases([Unit_Type])
		 )
	  ),!
   )
   ;
   (
	  Exchanged = vector([])
   ).





/*
fixme, this get also some irrelevant ones
*/
print_relevant_exchange_rates_comment([], _, _, _).

print_relevant_exchange_rates_comment([Report_Currency], Report_End_Date, Exchange_Rates, Transactions) :-
	findall(
		Exchange_Rates2,
		(
			get_relevant_exchange_rates2([Report_Currency], Exchange_Rates, Transactions, Exchange_Rates2)
			;
			get_relevant_exchange_rates2([Report_Currency], Report_End_Date, Exchange_Rates, Transactions, Exchange_Rates2)
		),
		Relevant_Exchange_Rates
	),
	pretty_term_string(Relevant_Exchange_Rates, Message1c),
	atomic_list_concat([
		'\n<!--',
		'Exchange rates2:\n', Message1c,'\n\n',
		'-->\n\n'], 
	Debug_Message2),
	writeln(Debug_Message2).


				
get_relevant_exchange_rates2([Report_Currency], Exchange_Rates, Transactions, Exchange_Rates2) :-
	% find all days when something happened
	findall(
		Date,
		(
			member(T, Transactions),
			transaction_day(T, Date)
		),
		Dates_Unsorted0
	),
	sort(Dates_Unsorted0, Dates),
	member(Date, Dates),
	%find all currencies used
	findall(
		Currency,
		(
			member(T, Transactions),
			transaction_vector(T, Vector),
			transaction_day(T,Date),
			pacioli:vec_units(Vector, Vector_Units),
			member(Currency, Vector_Units)
		),
		Currencies_Unsorted
	),
	sort(Currencies_Unsorted, Currencies),
	% produce all exchange rates
	findall(
		exchange_rate(Date, Src_Currency, Report_Currency, Exchange_Rate),
		(
			member(Src_Currency, Currencies),
			\+member(Src_Currency, [Report_Currency]),
			exchange_rate(Exchange_Rates, Date, Src_Currency, Report_Currency, Exchange_Rate)
		),
		Exchange_Rates2
	).

get_relevant_exchange_rates2([Report_Currency], Date, Exchange_Rates, Transactions, Exchange_Rates2) :-
	%find all currencies from all transactions, TODO: , find only all currencies appearing in totals of accounts at the report end date
	findall(
		Currency,
		(
			member(T, Transactions),
			transaction_vector(T, Vector),
			member(coord(Currency, _), Vector)
		),
		Currencies_Unsorted
	),
	sort(Currencies_Unsorted, Currencies),
	% produce all exchange rates
	findall(
		exchange_rate(Date, Src_Currency, Report_Currency, Exchange_Rate),
		(
			member(Src_Currency, Currencies),
			\+member(Src_Currency, [Report_Currency]),
			exchange_rate(Exchange_Rates, Date, Src_Currency, Report_Currency, Exchange_Rate)
		),
		Exchange_Rates2
	).
	
	
invert_s_transaction_vector(T0, T1) :-
	T0 = s_transaction(Date, Type_id, Vector, Account_id, Exchanged),
	T1 = s_transaction(Date, Type_id, Vector_Inverted, Account_id, Exchanged),
	vec_inverse(Vector, Vector_Inverted).


	

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
			pricing:infer_unit_cost_from_last_buy_or_sell(Unit2, S_Transactions, Rate),
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
	transaction_account_id(Transaction, Account),
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


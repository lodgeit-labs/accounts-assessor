% ===================================================================
% Project:   LodgeiT
% Module:    statements.pl
% Date:      2019-06-02
% ===================================================================

:- module(statements, [
		extract_s_transaction/3, 
		preprocess_s_transactions/5,
		print_relevant_exchange_rates_comment/4,
		invert_s_transaction_vector/2, 
		fill_in_missing_units/6,
		s_transaction_day/2,
		s_transaction_account_id/2,
		s_transaction_type_of/3,
		s_transaction_exchanged/2,
		s_transaction_vector/2,
		sort_s_transactions/2,
		s_transactions_up_to/3
		]).

/*fixme turn trading into module*/
:- [trading].

:- use_module('pacioli',  [
		vec_inverse/2, 
		vec_add/3, 
		vec_sub/3, 
		number_coord/3,
		make_debit/2,
		make_credit/2,
		value_multiply/3,
		value_divide/3,
		is_debit/1]).
:- use_module('exchange', [
		vec_change_bases/5]).
:- use_module('exchange_rates', [
		exchange_rate/5, 
		is_exchangeable_into_request_bases/4]).
:- use_module('transaction_types', [
		transaction_type_id/2,
		transaction_type_exchanged_account_id/2,
		transaction_type_trading_account_id/2,
		transaction_type_description/2]).
:- use_module('livestock', [
		preprocess_livestock_buy_or_sell/3, 
		process_livestock/14, 
		make_livestock_accounts/2]).
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
:- use_module('utils', [
		pretty_term_string/2, 
		inner_xml/3, 
		write_tag/2, 
		fields/2, 
		field_nothrow/2, 
		numeric_fields/2, 
		throw_string/1,
		coord_is_almost_zero/1]).
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

:- use_module(library(record)).
:- use_module(library(xpath)).

% -------------------------------------------------------------------
% bank statement transaction record, these are in the input xml
:- record
	s_transaction(day, type_id, vector, account_id, exchanged).
% - The absolute day that the transaction happenned
% - The type identifier/action tag of the transaction
% - The amounts that are being moved in this transaction
% - The account that the transaction modifies without using exchange rate conversions
% - Either the units or the amount to which the transaction amount will be converted to
% depending on whether the term is of the form bases(...) or vector(...).

/*
	at this point:
	s_transactions have to be sorted by date from oldest to newest 
	s_transactions have flipped vectors, so they are from our perspective
*/
preprocess_s_transactions(Static_Data, S_Transactions, Transactions_Out, Outstanding_Out, Debug_Info) :-
	preprocess_s_transactions2(Static_Data, S_Transactions, Transactions0, ([],[]), Outstanding_Out, Debug_Info, []),
	flatten(Transactions0, Transactions_Out).

/*
	call preprocess_s_transaction on each item of the S_Transactions list and do some error checking and cleaning up
*/
preprocess_s_transactions2(_, [], [], Outstanding, Outstanding, ['done.'], _).

preprocess_s_transactions2(Static_Data, [S_Transaction|S_Transactions], [Transactions_Out|Transactions_Out_Tail], Outstanding_In, Outstanding_Out, [Debug_Head|Debug_Tail], Debug_So_Far) :-
	dict_vars(Static_Data, [Accounts, Report_Currency, End_Date, Exchange_Rates]),
	pretty_term_string(S_Transaction, S_Transaction_String),
	catch(
		(
			check_that_s_transaction_account_exists(S_Transaction, Accounts),
			catch(
				(
					(preprocess_s_transaction(Static_Data, S_Transaction, Transactions0, Outstanding_In, Outstanding_Mid)
					-> true; (/*gtrace,fail,*/throw_string('internal error'))),
					% filter out unbound vars from the resulting Transactions list, as some rules do not always produce all possible transactions
					flatten(Transactions0, Transactions1),
					exclude(var, Transactions1, Transactions2),
					exclude(has_empty_vector, Transactions2, Transactions_Out),
					pretty_term_string(Transactions_Out, Transactions_String),
					atomic_list_concat([S_Transaction_String, '==>\n', Transactions_String, '\n====\n'], Debug_Head),
					Transactions_Out = [T|_],
					transaction_day(T, Transaction_Date),
					check_trial_balance0(Exchange_Rates, Report_Currency, Transaction_Date, Transactions_Out, End_Date, Debug_So_Far, Debug_Head),
					append(Debug_So_Far, [Debug_Head], Debug_So_Far2)
				),
				not_enough_goods_to_sell,
				(
					atomic_list_concat([not_enough_goods_to_sell, ' when processing ', S_Transaction_String], Debug_Head),
					Outstanding_In = Outstanding_Out,
					Transactions_Out_Tail = [],
					Transactions_Out = [],
					Debug_Tail = []
				)
			)
		),
		string(E_Str),
		(
			%term_string(E, E_Str),
			throw_string([E_Str, ' when processing ', S_Transaction_String])
		)
	),
	(
		var(Debug_Tail) /* debug tail is left free if processing this transaction succeeded ... */
	->
		preprocess_s_transactions2(Static_Data, S_Transactions, Transactions_Out_Tail,  Outstanding_Mid, Outstanding_Out, Debug_Tail, Debug_So_Far2)
	;
		true
	).

check_trial_balance0(Exchange_Rates, Report_Currency, Transaction_Date, Transactions_Out, Report_End_Date, Debug_So_Far, Debug_Head) :-
	catch(
		(
			check_trial_balance(Exchange_Rates, Report_Currency, Transaction_Date, Transactions_Out),
			check_trial_balance(Exchange_Rates, Report_Currency, Report_End_Date, Transactions_Out)
		),
		E, 
		(
			format(user_error, '\n\\n~w\n\n', [Debug_So_Far]),
			format(user_error, '\n\nwhen processing:\n~w', [Debug_Head]),
			pretty_term_string(E, E_Str),
			throw_string([E_Str])
		)
	).

	
% ----------
% This predicate takes a list of statement transaction terms and decomposes it into a list of plain transaction terms.
% ----------	
% This Prolog rule handles the case when only the exchanged units are known (for example GOOG)  and
% hence it is desired for the program to infer the count. 
% We passthrough the output list to the above rule, and just replace the first S_Transaction in the 
% input list with a modified one (NS_Transaction).
preprocess_s_transaction(Static_Data, S_Transaction, Transactions, Outstanding_In, Outstanding_Out) :-
	dict_vars(Static_Data, [Exchange_Rates]),
	s_transaction_exchanged(S_Transaction, bases(Goods_Bases)),
	s_transaction_day(S_Transaction, Transaction_Date), 
	s_transaction_day(NS_Transaction, Transaction_Date),
	s_transaction_type_id(S_Transaction, Type_Id), 
	s_transaction_type_id(NS_Transaction, Type_Id),
	s_transaction_vector(S_Transaction, Vector_Bank), 
	s_transaction_vector(NS_Transaction, Vector_Bank),
	s_transaction_account_id(S_Transaction, Unexchanged_Account_Id), 
	s_transaction_account_id(NS_Transaction, Unexchanged_Account_Id),
	% infer the count by money debit/credit and exchange rate
	vec_change_bases(Exchange_Rates, Transaction_Date, Goods_Bases, Vector_Bank, Vector_Exchanged),
	vec_inverse(Vector_Exchanged, Vector_Exchanged_Inverted),
	s_transaction_exchanged(NS_Transaction, vector(Vector_Exchanged_Inverted)),
	preprocess_s_transaction(Static_Data, NS_Transaction, Transactions, Outstanding_In, Outstanding_Out).


/*
	livestock currenty does it's own thing, using average cost computation and andjustment transactions.
	This means that it does not handle foreign currency bank accounts as we do here.
	At least the aftecting of bank account should be changed to be handled by preprocess_s_transaction,
	but the livestock logic is in need of a serious cleanup, we will probably do that as part of implementing inventory or other pricing methods.
*/
preprocess_s_transaction(Static_Data, S_Transaction, Transactions, Outstanding, Outstanding) :-
	preprocess_livestock_buy_or_sell(Static_Data, S_Transaction, Transactions).


preprocess_s_transaction(Static_Data, S_Transaction, [Ts1, Ts2, Ts3, Ts4], Outstanding_In, Outstanding_Out) :-
	Pricing_Method = lifo,
	dict_vars(Static_Data, [Report_Currency, Transaction_Types, Exchange_Rates]),
	check_s_transaction_action_type(Transaction_Types, S_Transaction),
	s_transaction_exchanged(S_Transaction, vector(Counteraccount_Vector)),
	s_transaction_account_id(S_Transaction, Bank_Account_Name), 
	s_transaction_type_of(Transaction_Types, S_Transaction, Transaction_Type),
	s_transaction_vector(S_Transaction, Vector_Ours),
	s_transaction_day(S_Transaction, Transaction_Date),
	transaction_type(_, Exchanged_Account, Trading_Account_Id, Description) = Transaction_Type,
	(var(Description)->	Description = '?'; true),
	[coord(Bank_Account_Currency, _,_)] = Vector_Ours,
	vec_change_bases(Exchange_Rates, Transaction_Date, Report_Currency, Vector_Ours, Converted_Vector_Ours),
	
	affect_bank_account(Static_Data, Bank_Account_Name, Bank_Account_Currency, Transaction_Date, Vector_Ours, Description, Ts1), 
	(
		Counteraccount_Vector \= []
	->
		(
			is_debit(Counteraccount_Vector)
		->
			make_buy(
				Static_Data, Trading_Account_Id, Pricing_Method, Bank_Account_Currency, Counteraccount_Vector,
				Converted_Vector_Ours, Vector_Ours, Exchanged_Account, Transaction_Date, Description, Outstanding_In, Outstanding_Out, Ts2)
		;		
			make_sell(
				Static_Data, Trading_Account_Id, Pricing_Method, Bank_Account_Currency, Counteraccount_Vector, Vector_Ours, 
				Converted_Vector_Ours,	Exchanged_Account, Transaction_Date, Description,	Outstanding_In, Outstanding_Out, Ts3)
		)
	;
		(
			assertion(Counteraccount_Vector = []),
			record_earning_or_equity_or_loan(Static_Data, Vector_Ours, Exchanged_Account, Transaction_Date, Description, Ts4),
			Outstanding_Out = Outstanding_In
		)
	).

/*
	purchased shares are recorded in an assets account without conversion. The unit is wrapped in a with_cost_per_unit
	term.
	Separately from that, we also change Outstanding with each buy or sell.
*/
make_buy(Static_Data, Trading_Account_Id, Pricing_Method, Bank_Account_Currency, Goods_Vector, 
	Converted_Vector_Ours, Vector_Ours,
	Exchanged_Account, Transaction_Date, Description, 
	Outstanding_In, Outstanding_Out, [Ts1, Ts2]
) :-
	purchased_goods_vector_with_cost(Goods_Vector, Converted_Vector_Ours, Goods_With_Cost_Vector),
	[coord(with_cost_per_unit(Goods_Unit, Unit_Cost), Goods_Count, _)] = Goods_With_Cost_Vector,
	purchased_goods_vector_with_cost(
		Goods_Vector, Vector_Ours, 
		[coord(with_cost_per_unit(Goods_Unit, Unit_Cost_Foreign), Goods_Count, _)]),
	dict_vars(Static_Data, [Accounts]),
	account_by_role(Accounts, Exchanged_Account/Goods_Unit, Exchanged_Account2),
	make_transaction(Transaction_Date, Description, Exchanged_Account2, Goods_With_Cost_Vector, Ts1),
	add_bought_items(
		Pricing_Method, 
		outstanding(Bank_Account_Currency, Goods_Unit, Goods_Count, Unit_Cost, Unit_Cost_Foreign, Transaction_Date),
		Outstanding_In, Outstanding_Out
	),
	(var(Trading_Account_Id) -> true
		; increase_unrealized_gains(Static_Data, Trading_Account_Id, Bank_Account_Currency, Converted_Vector_Ours, Goods_With_Cost_Vector, Transaction_Date, Ts2) 
	).

make_sell(Static_Data, Trading_Account_Id, Pricing_Method, _Bank_Account_Currency, Goods_Vector,
	Vector_Ours, Converted_Vector_Ours,
	Exchanged_Account, Transaction_Date, Description,
	Outstanding_In, Outstanding_Out, [Ts1, Ts2, Ts3]
) :-
	Goods_Vector = [coord(Goods_Unit,_,Goods_Positive)],
	dict_vars(Static_Data, [Accounts]),
	account_by_role(Accounts, Exchanged_Account/Goods_Unit, Exchanged_Account2),
	bank_debit_to_unit_price(Vector_Ours, Goods_Positive, Sale_Unit_Price),
	((find_items_to_sell(Pricing_Method, Goods_Unit, Goods_Positive, Transaction_Date, Sale_Unit_Price, Outstanding_In, Outstanding_Out, Goods_Cost_Values),!)
		;(throw(not_enough_goods_to_sell))),
	maplist(sold_goods_vector_with_cost, Goods_Cost_Values, Goods_With_Cost_Vectors),
	maplist(
		make_transaction(Transaction_Date, Description, Exchanged_Account2), 
		Goods_With_Cost_Vectors, Ts1
	),
	(var(Trading_Account_Id) -> true
		;(						
			reduce_unrealized_gains(Static_Data, Trading_Account_Id, Transaction_Date, Goods_Cost_Values, Ts2),
			increase_realized_gains(Static_Data, Trading_Account_Id, Vector_Ours, Converted_Vector_Ours, Goods_Vector, Transaction_Date, Goods_Cost_Values, Ts3)
		)
	).

bank_debit_to_unit_price(Vector_Ours, Goods_Positive, value(Unit, Number2)) :-
	Vector_Ours = [Coord],
	number_coord(Unit, Number, Coord),
	Number2 is Number / Goods_Positive.

	
/*
	when we bought something, we debited some assets account with the result of 
	purchased_goods_vector_with_cost(Goods_Vector0, Converted_Vector_Ours, Goods_With_Cost_Vector)
	now we need to credit that account with a coord(with_cost_per_unit(..), with the same unit costs
*/
sold_goods_vector_with_cost(Goods_Cost_Value, Goods_With_Cost_Vector) :-
	Goods_Cost_Value = goods(_Bank_Account_Currency, Goods_Unit, Goods_Count, Total_Cost_Value, _),
	value_divide(Total_Cost_Value, Goods_Count, Unit_Cost_Value),
	Goods_With_Cost_Vector = [coord(
		with_cost_per_unit(Goods_Unit, Unit_Cost_Value),
		0,
		Goods_Count
	)].
	
/*	
	Transactions using currency trading accounts can be decomposed into:
	a transaction of the given amount to the unexchanged account (your bank account)
	a transaction of the transformed inverse into the exchanged account (your shares investments account)
	and a transaction of the negative sum of these into the trading cccount. 
	this "currency trading account" is not to be confused with a shares trading account.
*/
affect_bank_account(Static_Data, Bank_Account_Name, Bank_Account_Currency, Transaction_Date, Vector_Ours, Description, [Ts0, Ts3]) :-
	dict_vars(Static_Data, [Accounts, Report_Currency]),
	Bank_Account_Role = ('Banks'/Bank_Account_Name),
	account_by_role(Accounts, Bank_Account_Role, Bank_Account_Id),
	/* record the change on our bank account */
	make_transaction(Transaction_Date, Description, Bank_Account_Id, Vector_Ours, Ts0),
	/* Make a difference transaction to the currency trading account. See https://www.mathstat.dal.ca/~selinger/accounting/tutorial.html . This will track the gain/loss generated by the movement of exchange rate between our asset in foreign currency and our equity/revenue in reporting currency. */
	(
		[Bank_Account_Currency] = Report_Currency
	->
		true
	;
		make_currency_movement_transactions(Static_Data, Bank_Account_Id, Transaction_Date, Vector_Ours, [Description, ' - currency movement adjustment'], Ts3)
	).

record_earning_or_equity_or_loan(Static_Data, Vector_Ours, Exchanged_Account, Transaction_Date, Description, Ts2) :-
	dict_vars(Static_Data, [Report_Currency, Exchange_Rates]),
	/* Make an inverse exchanged transaction to the exchanged account. This can be a revenue, expense or equity account*/
	vec_inverse(Vector_Ours, Vector_Exchanged),
	make_exchanged_transactions(Exchange_Rates, Report_Currency, Exchanged_Account, Transaction_Date, Vector_Exchanged, Description, Ts2).

purchased_goods_vector_with_cost(
	[coord(Goods_Unit_In, Goods_Count, Zero)],
	Cost_Vector, Goods_Vector_With_Cost
) :-
	assertion(Zero =:= 0),
	[coord(Currency, _, Price)] = Cost_Vector,
	Unit_Cost is Price / Goods_Count,
	Goods_Vector_With_Cost = [coord(
		with_cost_per_unit(
			Goods_Unit_In, 
			value(Currency, Unit_Cost)
		),
			Goods_Count, 
			0
	)].	

make_exchanged_transactions(Exchange_Rates, Report_Currency, Account, Date, Vector, Description, Transaction) :-
	vec_change_bases(Exchange_Rates, Date, Report_Currency, Vector, Vector_Exchanged_To_Report),
	make_transaction(Date, Description, Account, Vector_Exchanged_To_Report, Transaction).
	
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
				Currency_Movement_Account, Date, Description, 
				
				Vector_Frozen_After_Start_Date,
				[Report_Currency_Coord],
				
				Transaction1),
			/* the current earnings difference transaction tracks asset value change against opening value */
			vector_without_movement_after(Vector, Start_Date, Vector_Frozen_At_Opening_Date),
			make_difference_transaction(
				Currency_Movement_Account, Start_Date, Description, 
				
				Vector,
				Vector_Frozen_At_Opening_Date,
				
				Transaction2)
		)
	;
		make_difference_transaction(
			Currency_Movement_Account, Date, Description, 
			
			Vector,
			Vector_Exchanged_To_Report_Currency, 
			
			Transaction3
		)
	)
	.

vector_without_movement_after([coord(Unit1,D,C)], Start_Date, [coord(Unit2,D,C)]) :-
	Unit2 = without_movement_after(Unit1, Start_Date).
	
make_difference_transaction(Account, Date, Description, What, Against, Transaction) :-
	vec_sub(What, Against, Diff),
	/* when an asset account goes up, it rises in debit, and the revenue has to rise in credit to add up to 0 */
	vec_inverse(Diff, Diff_Revenue),
	make_transaction2(Date, Description, Account, Diff_Revenue, Transaction),
	transaction_type(Transaction, tracking).
	

without_movement(Report_Currency, Since, [coord(Unit, D, C)], [coord(Unit2, D, C)]) :-
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

check_trial_balance(Exchange_Rates, Report_Currency, Date, Transactions) :-
	transactions_trial_balance(Exchange_Rates, Report_Currency, Date, Transactions, Total),
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

	
% Gets the transaction_type term associated with the given transaction
s_transaction_type_of(Transaction_Types, S_Transaction, Transaction_Type) :-
	% get type id
	s_transaction_type_id(S_Transaction, Type_Id),
	% construct type term with parent variable unbound
	transaction_type_id(Transaction_Type, Type_Id),
	% match it with what's in Transaction_Types
	member(Transaction_Type, Transaction_Types).


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
	Coord = coord(Account_Currency, Bank_Debit, Bank_Credit),
	ST = s_transaction(Date, Desc, [Coord], Account, Exchanged),
	extract_exchanged_value(Tx_Dom, Account_Currency, Bank_Debit, Bank_Credit, Exchanged).

extract_exchanged_value(Tx_Dom, _Account_Currency, Bank_Debit, Bank_Credit, Exchanged) :-
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
				Bank_Debit > 0
			->
				(
					assertion(Bank_Credit =:= 0),
					Exchanged = vector([coord(Unit_Type, Count_Absolute, 0)])
				)
			;
					Exchanged = vector([coord(Unit_Type, 0, Count_Absolute)])
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
			member(coord(Currency, _,_), Vector)
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
	%find all currencies from all transactions, todo, find only all currencies appearing in totals of accounts at the report end date
	findall(
		Currency,
		(
			member(T, Transactions),
			transaction_vector(T, Vector),
			member(coord(Currency, _,_), Vector)
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
			infer_unit_cost_from_last_buy_or_sell(Unit2, S_Transactions, Rate),
			Rate = exchange_rate(Report_End_Date, _, _, _)
		),
		Inferred_Rates
	).
	

check_s_transaction_action_type(Transaction_Types, S_Transaction) :-
	(
		% do we have a tag that corresponds to one of known actions?
		s_transaction_type_of(Transaction_Types, S_Transaction, Transaction_Type)
	->
		true
	;
		(
			s_transaction_type_id(S_Transaction, Type_Id),
			throw_string(['unknown action verb:',Type_Id])
		)
	),
	transaction_type(_Verb, Exchanged_Account, _Trading_Account_Id, _Description) = Transaction_Type,
	(var(Exchanged_Account) -> throw_string('action does not specify exchanged account') ; true).

	

sort_s_transactions(In, Out) :-
	/*
	If a buy and a sale of same thing happens on the same day, we want to process the buy first.
	We first sort by our debit on the bank account. Transactions with zero of our debit are not sales.
	*/
	sort(
	/*
	this is a path inside the structure of the elements of the sorted array (inside the s_transactions):
	3th sub-term is the amount from bank perspective. 
	1st (and hopefully only) item of the vector is the coord,
	3rd item of the coord is bank credit, our debit.
	*/
	[3,1,3], @=<,  In, Mid),
	/*now we can sort by date ascending, and the order of transactions with same date, as sorted above, will be preserved*/
	sort(1, @=<,  Mid, Out).

s_transactions_up_to(End_Date, S_Transactions_In, S_Transactions_Out) :-
	findall(
		T,
		(
			member(T, S_Transactions_In),
			s_transaction_day(T, D),
			D @=< End_Date
		),
		S_Transactions_Out
	).

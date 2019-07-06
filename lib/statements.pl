% ===================================================================
% Project:   LodgeiT
% Module:    statements.pl
% Date:      2019-06-02
% ===================================================================

:- module(statements, [extract_transaction/3, preprocess_s_transactions/4, add_bank_accounts/3, get_relevant_exchange_rates/5, invert_s_transaction_vector/2, find_s_transactions_in_period/4, fill_in_missing_units/6]).
 
:- use_module(pacioli,  [vec_inverse/2, vec_add/3, vec_sub/3, integer_to_coord/3,
		    make_debit/2,
		    make_credit/2]).
:- use_module(exchange, [vec_change_bases/5]).
:- use_module(exchange_rates, [exchange_rate/5, is_exchangeable_into_request_bases/4]).

:- use_module(transaction_types, [
	transaction_type_id/2,
	transaction_type_exchanged_account_id/2,
	transaction_type_trading_account_id/2,
	transaction_type_description/2]).
:- use_module(livestock, [preprocess_livestock_buy_or_sell/3]).
:- use_module(transactions, [
	transaction_day/2,
	transaction_description/2,
	transaction_account_id/2,
	transaction_vector/2]).
:- use_module(utils, [pretty_term_string/2, inner_xml/3, write_tag/2, fields/2, fields_nothrow/2, numeric_fields/2, throw_string/1, value_multiply/3]).
:- use_module(accounts, [account_parent_id/3, account_ancestor_id/3]).
:- use_module(days, [format_date/2, parse_date/2, gregorian_date/2, date_between/3]).
:- use_module(library(record)).
:- use_module(library(xpath)).
:- use_module(pricing, [
	add_bought_items/4, 
	find_items_to_sell/6
]).

% -------------------------------------------------------------------

:- record
	s_transaction(day, type_id, vector, account_id, exchanged).
% - The absolute day that the transaction happenned
% - The type identifier/action tag of the transaction
% - The amounts that are being moved in this transaction
% - The account that the transaction modifies without using exchange rate conversions
% - Either the units or the amount to which the transaction amount will be converted to
% depending on whether the term is of the form bases(...) or vector(...).
/*we may want to introduce st2 that will hold an inverted, that is, ours, vector, as opposed to a vector from the bank's perspective*/

find_s_transactions_in_period(S_Transactions, Opening_Date, Closing_Date, Out) :-
	findall(
		S_Transaction,
		(
			member(S_Transaction, S_Transactions),
			s_transaction_day(S_Transaction, Date),
			date_between(Opening_Date, Closing_Date, Date)
		),
		Out
	).

/*
at this point:
s_transactions have to be sorted by date from oldest to newest 
s_transactions have flipped vectors, so they are from our perspective
*/
preprocess_s_transactions(Static_Data, S_Transactions, Transactions_Out, Debug_Info) :-
	preprocess_s_transactions2(Static_Data, S_Transactions, Transactions0, [], _, Debug_Info, []),
	flatten(Transactions0, Transactions_Out).

preprocess_s_transactions2(_, [], [], Outstanding, Outstanding, ["end."], _).

preprocess_s_transactions2(Static_Data, [S_Transaction|S_Transactions], [Transactions_Out|Transactions_Out_Tail], Outstanding_In, Outstanding_Out, [Debug_Head|Debug_Tail], Debug_So_Far) :-
	Static_Data = (Accounts, Report_Currency, _, Report_End_Date, Exchange_Rates),
	check_that_s_transaction_account_exists(S_Transaction, Accounts),
	pretty_term_string(S_Transaction, S_Transaction_String),
	(
		catch(
			(
			preprocess_s_transaction(Static_Data, S_Transaction, Transactions0, Outstanding_In, Outstanding_Mid)
			),
			string(E),
			throw_string([E, ' when processing ', S_Transaction_String])
		)
		->
		(
			% filter out unbound vars from the resulting Transactions list, as some rules do not always produce all possible transactions
			exclude(var, Transactions0, Transactions1),
			exclude(has_empty_vector, Transactions1, Transactions2),
			flatten(Transactions2, Transactions_Out),
			pretty_term_string(Transactions_Out, Transactions_String),
			atomic_list_concat([S_Transaction_String, '==>\n', Transactions_String, '\n====\n'], Debug_Head),
			Transactions_Out = [T|_],
			transaction_day(T, Transaction_Date),
			catch(
				(
					check_trial_balance(Exchange_Rates, Report_Currency, Transaction_Date, Transactions_Out),
					check_trial_balance(Exchange_Rates, Report_Currency, Report_End_Date, Transactions_Out)
				),
				E,
				(
					format(user_error, '\n\\n~w\n\n', [Debug_So_Far]),
					format(user_error, '\n\nwhen processing:\n~w', [Debug_Head]),
					throw([E])
				)
			)
		)
		;
		(
			%gtrace,
			throw_string(['processing failed:', S_Transaction_String])
		)
	),
	append(Debug_So_Far, [Debug_Head], Debug_So_Far2),
	preprocess_s_transactions2(Static_Data, S_Transactions, Transactions_Out_Tail,  Outstanding_Mid, Outstanding_Out, Debug_Tail, Debug_So_Far2).

	
% This Prolog rule handles the case when only the exchanged units are known (for example GOOG)  and
% hence it is desired for the program to infer the count. 
% We passthrough the output list to the above rule, and just replace the first S_Transaction in the 
% input list with a modified one (NS_Transaction).
preprocess_s_transaction(Static_Data, S_Transaction, Transactions, Outstanding_In, Outstanding_Out) :-
	Static_Data = (_, _, _, _, Exchange_Rates),
	s_transaction_exchanged(S_Transaction, bases(Goods_Bases)),
	s_transaction_day(S_Transaction, Transaction_Day), 
	s_transaction_day(NS_Transaction, Transaction_Day),
	s_transaction_type_id(S_Transaction, Type_Id), 
	s_transaction_type_id(NS_Transaction, Type_Id),
	s_transaction_vector(S_Transaction, Vector_Bank), 
	s_transaction_vector(NS_Transaction, Vector_Bank),
	s_transaction_account_id(S_Transaction, Unexchanged_Account_Id), 
	s_transaction_account_id(NS_Transaction, Unexchanged_Account_Id),
	% infer the count by money debit/credit and exchange rate
	vec_change_bases(Exchange_Rates, Transaction_Day, Goods_Bases, Vector_Bank, Vector_Exchanged),
	vec_inverse(Vector_Exchanged, Vector_Exchanged_Inverted),
	s_transaction_exchanged(NS_Transaction, vector(Vector_Exchanged_Inverted)),
	preprocess_s_transaction(Static_Data, NS_Transaction, Transactions, Outstanding_In, Outstanding_Out).

	
preprocess_s_transaction(Static_Data, S_Transaction, Transactions, Outstanding, Outstanding) :-
	preprocess_livestock_buy_or_sell(Static_Data, S_Transaction, Transactions).

/*	
Transactions using trading accounts can be decomposed into:
	a transaction of the given amount to the unexchanged account (your bank account)
	a transaction of the transformed inverse into the exchanged account (your shares investments account)
	and a transaction of the negative sum of these into the trading cccount. 
This predicate takes a list of statement transaction terms and decomposes it into a list of plain transaction terms, 3 for each input s_transaction.
"Goods" is not a general enough word, but it avoids confusion with other terms used.
*/	

preprocess_s_transaction(Static_Data, S_Transaction, [T0, T1, T2, T4, T5, T6, T7], Outstanding_In, Outstanding_Out) :-
	Static_Data = (Accounts, Report_Currency, Transaction_Types, _, Exchange_Rates),
	Pricing_Method = lifo,
	s_transaction_exchanged(S_Transaction, vector(Vector_Goods0)),
	(
		Vector_Goods0 = []
	->
		vec_inverse(Vector_Ours, Vector_Goods)
	;
		Vector_Goods = Vector_Goods0
	),
	[Goods_Coord] = Vector_Goods,
	integer_to_coord(Goods_Unit, Goods_Integer, Goods_Coord),
	(
		% do we have a tag that corresponds to one of known actions?
		transaction_type_of(Transaction_Types, S_Transaction, Transaction_Type)
	->
		true
	;
		(
			s_transaction_type_id(S_Transaction, Type_Id),
			throw_string(['unknown action verb:',Type_Id])
		)
	),
	s_transaction_account_id(S_Transaction, UnX_Account), 
	s_transaction_vector(S_Transaction, Vector_Ours),
	s_transaction_day(S_Transaction, Transaction_Day), 
	[Our_Coord] = Vector_Ours,
	coord(Currency, Our_Debit, Our_Credit) = Our_Coord,
	transaction_type(_Verb, Exchanged_Account, Trading_Account_Id, Description) = Transaction_Type,
	(var(Description)->	Description = '?'; true),
	(var(Exchanged_Account) -> throw_string('action does not specify exchanged account') ; true),
	(
		(account_ancestor_id(Accounts, Exchanged_Account, 'Equity')
		;account_ancestor_id(Accounts, Exchanged_Account, 'Earnings'))
	->
		Earnings_Account = Exchanged_Account
	;
		Shuffle_Account = Exchanged_Account
	),
	make_transaction(UnX_Account, Transaction_Day, Vector_Ours, Description, T0),
	((var(Shuffle_Account),!)
		;make_transaction(Shuffle_Account, Transaction_Day, Vector_Goods, Description, T1)),
	(
		var(Earnings_Account)
	->
		true
	;
		(
			/* Make an inverse exchanged transaction to the exchanged account.
			this can be a revenue/expense or equity account, in case value is coming in or going out of the company*/
			make_exchanged_transactions(Exchange_Rates, Report_Currency, Earnings_Account, Transaction_Day, Vector_Goods, Description, T2),
			% Make a difference transaction to the currency trading account. See https://www.mathstat.dal.ca/~selinger/accounting/tutorial.html . This will track the gain/loss generated by the movement of exchange rate between our asset in foreign currency and our equity/revenue in reporting currency.
			make_currency_movement_transactions(Exchange_Rates, Report_Currency, Transaction_Day, Vector_Ours, [Description, ' - currency movement adjustment'], T5)
		)
	),
	(
		var(Trading_Account_Id)
	->
		Outstanding_Out = Outstanding_In	
	;
		(
			(
				true
			->
				vec_change_bases(Exchange_Rates, Transaction_Day, Report_Currency, Vector_Ours, Cost_Vector_Converted)
			,
				Cost_Vector_Converted = Vector_Ours
			),
			make_trading_transactions(Static_Data)
		)
	).

make_trading_transactions(Static_Data, Goods_Integer, Cost_Vector) :-
	(
		Goods_Integer >= 0
	->
	(
		[coord(Cost_Unit, _, Our_Credit)] = Cost_Vector,
		Unit_Cost is Our_Credit / Goods_Integer,
		add_bought_items(
			Pricing_Method, 
			outstanding(Goods_Unit, Goods_Integer, value(Cost_Unit, Unit_Cost), Transaction_Day), 
			Outstanding_In, Outstanding_Out
		),
		unrealized_gains_txs(Static_Data, Currency, Cost_Vector_Converted, Vector_Goods, Transaction_Day, Trading_Txs),
		txs_to_transactions(Transaction_Day, Trading_Txs, T4)
	)
		;
			(
				Goods_Positive is -Goods_Integer,
				((find_items_to_sell(Pricing_Method, Goods_Unit, Goods_Positive, Outstanding_In, Outstanding_Out, Goods_Cost_Values),!)
					;throw_string(['not enough goods to sell'])),
					
				/*Cost_Vector = [coord(Purchase_Currency, Purchase_Money, 0)],
				vec_change_bases(Exchange_Rates, Purchase_Date, Report_Currency, Cost_Vector, Cost_At_Report),*/
					
				maplist(unrealized_gains_reduction_txs(Static_Data), Goods_Cost_Values, Txs1),
				txs_to_transactions(Transaction_Day, Txs1, T6),
				Sale_Unit_Price_Amount is Our_Debit / Goods_Positive,
				
				/*
					
Sale = value(Sale_Currency, Sale_Amount),
vec_change_bases(Exchange_Rates, Transaction_Date, Report_Currency, Sale_Vec, Sale_In_Report_Currency),

value(Purchase_Currency, Purchase_Money) = Cost,
Cost_Vector = [coord(Purchase_Currency, 0, Purchase_Money)],
vec_change_bases(Exchange_Rates, Purchase_Date, Report_Currency, Cost_Vector, Cost_In_Report_Currency),

				
*/					
				maplist(
					realized_gains_txs(
						Static_Data, 
						value(Currency, Sale_Unit_Price_Amount),
						Transaction_Day
					), 
					Goods_Cost_Values, Txs2
				),
				txs_to_transactions(Transaction_Day, Txs2, T7)
			)
	).

	
	
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
	
unrealized_gains_txs((_, Report_Currency, _, _, _), Purchase_Currency, Cost_Vector, Goods, Transaction_Day, Txs) :-
	/*	without forex:
	Unrealized_Gains = [
	% Account            DR                                               CR
	('',                         Purchase_Date_Cost,        Goods)
	]*/
	
	Goods_Without_Currency_Movement = [coord(
		without_currency_movement_against_since(Goods_Unit, Purchase_Currency, Report_Currency, Purchase_Date), 
		Goods_Debit, Goods_Credit)
	],
	Goods = [coord(Goods_Unit, Goods_Debit, Goods_Credit)],
	Purchase_Date = Transaction_Day,

	dr_cr_table_to_txs([
	% Account                                                                 DR                                                               CR
	('Unrealized_Gains_Currency_Movement',                Goods_Without_Currency_Movement,        Goods),
	('Unrealized_Gains_Excluding_Forex',	                 Cost_Vector,      	                Goods_Without_Currency_Movement)
	],
	Txs).
	

unrealized_gains_reduction_txs((_, Report_Currency, _, _, _), Purchase_Info, Txs) :-
	Goods_Without_Currency_Movement = [coord(
		without_currency_movement_against_since(Goods_Unit, Purchase_Currency, Report_Currency, Purchase_Date), 
		Goods_Count, 0)
	],
	outstanding(Goods_Unit, Goods_Count, Cost, Purchase_Date) = Purchase_Info,
	Goods = value(Goods_Unit, Goods_Count),
	value(Purchase_Currency, Purchase_Money) = Cost,

	dr_cr_table_to_txs([
	% Account                                                                 DR                                                               CR
	('Unrealized_Gains_Currency_Movement',             Goods    ,                                   Goods_Without_Currency_Movement  ),
	('Unrealized_Gains_Excluding_Forex',					Goods_Without_Currency_Movement    ,      Cost                 )
	],
	Txs),
	Txs= [T0, T1],
	T0.comment = T1.comment,
	T0.comment = 'reduce unrealized gain by outgoing asset and its cost'.
	

realized_gains_txs((_, Report_Currency, _, _,Exchange_Rates), Sale_Unit_Price, Transaction_Date, Purchase_Info, Txs) :-
	Sale_Without_Currency_Movement = [coord(
		without_currency_movement_against_since(Goods_Unit, Purchase_Currency, Report_Currency, Purchase_Date), 
		0, Goods_Count)
	],
	Cost = value(Purchase_Currency, _),
	outstanding(Goods_Unit, Goods_Count, Cost, Purchase_Date) = Purchase_Info,
	
	value_multiply(Sale_Unit_Price, Goods_Count, Sale),

	dr_cr_table_to_txs([
	% Account                                                                 DR                                                               CR
	('Realized_Gains_Currency_Movement',	                Sale_Without_Currency_Movement,           Sale),
	('Realized_Gains_Excluding_Forex',                        Cost,   	                    Sale_Without_Currency_Movement)
	],
	Txs).

	
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
	
gains_account_has_forex_accounts(Gains_Account, Gains_Excluding_Forex, Gains_Currency_Movement) :-
	atom_concat(Gains_Account, '_Excluding_Forex', Gains_Excluding_Forex),
	atom_concat(Gains_Account, '_Currency_Movement', Gains_Currency_Movement).

	% Make an unexchanged transaction to the unexchanged (bank) account
	% the bank account is debited/credited in the currency of the bank account, exchange will happen for report end day

make_transaction(Account, Day, Vector, Description, Transaction) :-
	flatten([Description], Description_Flat),
	atomic_list_concat(Description_Flat, Description_Str),
	transaction_day(Transaction, Day),
	transaction_description(Transaction, Description_Str),
	transaction_vector(Transaction, Vector),
	transaction_account_id(Transaction, Account).

make_exchanged_transactions(Exchange_Rates, Report_Currency, Account, Day, Vector, Description, Transaction) :-
	vec_change_bases(Exchange_Rates, Day, Report_Currency, Vector, Vector_Exchanged_To_Report),
	make_transaction(Account, Day, Vector_Exchanged_To_Report, Description, Transaction).
	
make_currency_movement_transactions(Exchange_Rates, Report_Currency, Day, Vector, Description, Transaction) :-
	vec_change_bases(Exchange_Rates, Day, Report_Currency, Vector, Vector_Exchanged_To_Report),
	make_transaction('Currency_Movement', Day, Vector_Movement, Description, Transaction),
	vec_sub(Vector_Exchanged_To_Report, Vector, Vector_Movement).

transactions_trial_balance(Exchange_Rates, Report_Currency, Day, Transactions, Vector_Converted) :-
	maplist(transaction_vector, Transactions, Vectors_Nested),
	flatten(Vectors_Nested, Vector),
	vec_change_bases(Exchange_Rates, Day, Report_Currency, Vector, Vector_Converted).

check_trial_balance(Exchange_Rates, Report_Currency, Day, Transactions) :-
	transactions_trial_balance(Exchange_Rates, Report_Currency, Day, Transactions, Total),
	(
		Total = []
	->
		true
	;
		(
			pretty_term_string(['total is ', Total, ' on day ', Day], Err_Str),
			throw(Err_Str)
		)
	).

	
% Gets the transaction_type term associated with the given transaction
transaction_type_of(Transaction_Types, S_Transaction, Transaction_Type) :-
	% get type id
	s_transaction_type_id(S_Transaction, Type_Id),
	% construct type term with parent variable unbound
	transaction_type_id(Transaction_Type, Type_Id),
	% match it with what's in Transaction_Types
	member(Transaction_Type, Transaction_Types).


% throw an error if the s_transaction's account is not found in the hierarchy
check_that_s_transaction_account_exists(S_Transaction, Accounts) :-
	s_transaction_account_id(S_Transaction, Account_Name),
	(
		account_parent_id(Accounts, Account_Name, _) 
		->
			true
		;
			throw_string(['account not found in hierarchy:', Account_Name])
	).

	

% yield all transactions from all accounts one by one.
% these are s_transactions, the raw transactions from bank statements. Later each s_transaction will be preprocessed
% into multiple transaction(..) terms.
% fixme dont fail silently
extract_transaction(Dom, Start_Date, Transaction) :-
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
		extract_transaction2(Tx_Dom, Account_Currency, Account_Name, Start_Date, Transaction),
		Error,
		(
			term_string(Error, Str1),
			term_string(Tx_Dom, Str2),
			atomic_list_concat([Str1, Str2], Message),
			throw(Message)
		)),
	true.

extract_transaction2(Tx_Dom, Account_Currency, Account, Start_Date, ST) :-
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
	parse_date(Date_Atom, Absolute_Days),
	Coord = coord(Account_Currency, Bank_Debit, Bank_Credit),
	ST = s_transaction(Absolute_Days, Desc, [Coord], Account, Exchanged),
	extract_exchanged_value(Tx_Dom, Account_Currency, Bank_Debit, Bank_Credit, Exchanged).

extract_exchanged_value(Tx_Dom, _Account_Currency, Bank_Debit, Bank_Credit, Exchanged) :-
   % if unit type and count is specified, unifies Exchanged with a one-item vector with a coord with those values
   % otherwise unifies Exchanged with bases(..) to trigger unit conversion later
   (
      fields_nothrow(Tx_Dom, [unitType, Unit_Type]),
      (
         (
            fields_nothrow(Tx_Dom, [unit, Unit_Count_Atom]),
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


/* fixme: use sort, dont change order */
add_bank_accounts(S_Transactions, Accounts_In, Accounts_Out) :-
	findall(
		Bank_Account_Name,
		(
			
			member(T, S_Transactions),
			s_transaction_account_id(T, Bank_Account_Name)
		),
		Bank_Account_Names),
	sort(Bank_Account_Names, Bank_Account_Names_Unique),
	findall(
		account(Name, 'CashAndCashEquivalents'),
		member(Name, Bank_Account_Names_Unique),
		Bank_Accounts),
	append(Bank_Accounts, Accounts_In, Accounts_Duplicated),
	sort(Accounts_Duplicated, Accounts_Out).


get_relevant_exchange_rates([Report_Currency], Report_End_Day, Exchange_Rates, Transactions, Rates_List) :-
	findall(
		Exchange_Rates2,
		(
			get_relevant_exchange_rates2([Report_Currency], Exchange_Rates, Transactions, Exchange_Rates2)
			;
			get_relevant_exchange_rates2([Report_Currency], Report_End_Day, Exchange_Rates, Transactions, Exchange_Rates2)
		),
		Rates_List
	).
				
get_relevant_exchange_rates2([Report_Currency], Exchange_Rates, Transactions, Exchange_Rates2) :-
	% find all days when something happened
	findall(
		Day,
		(
			member(T, Transactions),
			transaction_day(T, Day)
		),
		Days_Unsorted0
	),
	sort(Days_Unsorted0, Days),
	member(Day, Days),
	%find all currencies used
	findall(
		Currency,
		(
			member(T, Transactions),
			transaction_vector(T, Vector),
			transaction_day(T,Day),
			member(coord(Currency, _,_), Vector)
		),
		Currencies_Unsorted
	),
	sort(Currencies_Unsorted, Currencies),
	% produce all exchange rates
	findall(
		exchange_rate(Day, Src_Currency, Report_Currency, Exchange_Rate),
		(
			member(Src_Currency, Currencies),
			\+member(Src_Currency, [Report_Currency]),
			exchange_rate(Exchange_Rates, Day, Src_Currency, Report_Currency, Exchange_Rate)
		),
		Exchange_Rates2
	).

get_relevant_exchange_rates2([Report_Currency], Day, Exchange_Rates, Transactions, Exchange_Rates2) :-
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
		exchange_rate(Day, Src_Currency, Report_Currency, Exchange_Rate),
		(
			member(Src_Currency, Currencies),
			\+member(Src_Currency, [Report_Currency]),
			exchange_rate(Exchange_Rates, Day, Src_Currency, Report_Currency, Exchange_Rate)
		),
		Exchange_Rates2
	).
	
	
invert_s_transaction_vector(T0, T1) :-
	T0 = s_transaction(Day, Type_id, Vector, Account_id, Exchanged),
	T1 = s_transaction(Day, Type_id, Vector_Inverted, Account_id, Exchanged),
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
	
infer_unit_cost_from_last_buy_or_sell(Unit, [ST|_], Exchange_Rate) :-
	s_transaction_exchanged(ST, vector([coord(Unit, D, C)])),
	s_transaction_vector(ST, [coord(Currency, Cost_D, Cost_C)]),
	(
		D =:= 0
	->
		Rate is Cost_D / C
	;
		Rate is Cost_C / D
	),
	Exchange_Rate = exchange_rate(_,Unit,Currency,Rate),
	!.

infer_unit_cost_from_last_buy_or_sell(Unit, [_|S_Transactions], Rate) :-
	infer_unit_cost_from_last_buy_or_sell(Unit, S_Transactions, Rate).

has_empty_vector(T) :-
	transaction_vector(T, []).


%:- assert(track_currency_movement).







	
% tests	
/*
todo: just check vec_add with this.
:- maplist(transaction_vector, Transactions, [[coord(aAAA, 5, 1), coord(aBBB, 0, 0.0)], [], [coord(aBBB, 7, 7)], [coord(aAAA, 0.0, 4)]]), check_trial_balance(Transactions).
:- maplist(transaction_vector, Transactions, [[coord(aAAA, 5, 1)], [coord(aAAA, 0.0, 4)]]), check_trial_balance(Transactions).
:- maplist(transaction_vector, Transactions, [[coord(AAA, 5, 1), coord(BBB, 0, 0.0)], [], [coord(BBB, 7, 7)], [coord(AAA, 0.0, 4)]]), check_trial_balance(Transactions).
:- maplist(transaction_vector, Transactions, [[coord(AAA, 45, 49), coord(BBB, 0, 0.0)], [], [coord(BBB, -7, -7)], [coord(AAA, 0.0, -4)]]), check_trial_balance(Transactions).
*/


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

	pretty_term_string(Exchange_Day, Exchange_Day_Str),
	pretty_term_string(Report_Currency, Report_Currency_Str),
	pretty_term_string(	Cost_In_Purchase_Currency, Cost_Vector_Str),
	atomic_list_concat(['cost:', Cost_Vector_Str, ' exchanged to ', Report_Currency_Str, ' on ', Exchange_Day_Str], Tx2_Comment2),

*/

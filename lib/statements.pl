% ===================================================================
% Project:   LodgeiT
% Module:    statements.pl
% Date:      2019-06-02
% ===================================================================

:- module(statements, [extract_transaction/3, preprocess_s_transactions/4, add_bank_accounts/3, get_relevant_exchange_rates/5, invert_s_transaction_vector/2, find_s_transactions_in_period/4]).
 
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
:- use_module(accounts, [account_parent_id/3]).
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

s_transactions have to be sorted by date from oldest to newest 

*/
preprocess_s_transactions(Static_Data, S_Transactions, Transactions_Out, Debug_Info) :-
	preprocess_s_transactions2(Static_Data, S_Transactions, Transactions0, [], _, Debug_Info),
	flatten(Transactions0, Transactions_Out).

preprocess_s_transactions2(_, [], [], Outstanding, Outstanding, ["end."]).

preprocess_s_transactions2(Static_Data, [S_Transaction|S_Transactions], [Transactions_Out|Transactions_Out_Tail], Outstanding_In, Outstanding_Out, [Debug_Head|Debug_Tail]) :-
	Static_Data = (Accounts, _, _, _, _),
	check_that_s_transaction_account_exists(S_Transaction, Accounts),
	pretty_term_string(S_Transaction, S_Transaction_String),
	(
		catch(
			(
			preprocess_s_transaction(Static_Data, S_Transaction, Transactions0, Outstanding_In, Outstanding_Mid)
			),
			string(E),
			throw_string([E, ' in ', S_Transaction_String])
		)
		->
		(
			% filter out unbound vars from the resulting Transactions list, as some rules do no always produce all possible transactions
			exclude(var, Transactions0, Transactions1),
			flatten(Transactions1, Transactions_Out),
			pretty_term_string(Transactions_Out, Transactions_String),
			atomic_list_concat([S_Transaction_String, '==>\n', Transactions_String, '\n====\n'], Debug_Head),
			catch(
				check_trial_balance(Transactions_Out),
				E,
				(
					format(user_error, '~w', [Debug_Head]),
					throw([E])
				)
			)
		)
		;
			throw_string(['processing failed:', S_Transaction_String])
	),
	preprocess_s_transactions2(Static_Data, S_Transactions, Transactions_Out_Tail,  Outstanding_Mid, Outstanding_Out, Debug_Tail).

	
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

preprocess_s_transaction(Static_Data, S_Transaction, [UnX_Transaction, X_Transaction, Trading_Transactions], Outstanding_In, Outstanding_Out) :-
	Static_Data = (_, _Report_Currency, Transaction_Types, _, _Exchange_Rates),
	Pricing_Method = lifo,
	s_transaction_exchanged(S_Transaction, vector(Vector_Goods)),
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
	s_transaction_vector(S_Transaction, Vector_Ours),
	s_transaction_day(S_Transaction, Transaction_Day), 
	[Our_Coord] = Vector_Ours,
	[Goods_Coord] = Vector_Goods,
	coord(Currency, Our_Debit, Our_Credit) = Our_Coord ,
	integer_to_coord(Goods_Unit, Goods_Integer, Goods_Coord),
	transaction_type(_, Exchanged_Account_Id, Trading_Account_Id, Description) = Transaction_Type,
	make_unexchanged_transaction(S_Transaction, Description, UnX_Transaction),
	(
		nonvar(Exchanged_Account_Id)
	->
		(
			/* Make an inverse exchanged transaction to the exchanged account.
				this can be a revenue/expense or equity account, in case value is coming in or going out of the company,
				or it can be an assets account, if we are moving values around*/
			transaction_day(X_Transaction, Transaction_Day),
			transaction_description(X_Transaction, Description),
			transaction_vector(X_Transaction, Vector_Goods),
			transaction_account_id(X_Transaction, Exchanged_Account_Id)
		)
	;
		throw_string(['action does not specify exchanged account'])
	),
	(
		nonvar(Trading_Account_Id)
	->
		% Make a difference transaction to the currency trading account. See https://www.mathstat.dal.ca/~selinger/accounting/tutorial.html . This will track the gain/loss generated by the movement of exchange rate between our asset and the reporting currency.
		(
				Goods_Integer >= 0
			->
				(
					Unit_Cost is Our_Credit / Goods_Integer,
					add_bought_items(
						Pricing_Method, 
						outstanding(Goods_Unit, Goods_Integer, value(Currency, Unit_Cost), Transaction_Day), 
						Outstanding_In, Outstanding_Out
					),
					
					unrealized_gains_txs(Static_Data, Vector_Ours, Vector_Goods, Transaction_Day, Trading_Txs),
					maplist(tx_to_transaction(Transaction_Day), Trading_Txs, Trading_Transactions)
				)
			;
				(
					Goods_Positive is -Goods_Integer,
					(
						find_items_to_sell(Pricing_Method, Goods_Unit, Goods_Positive, Outstanding_In, Outstanding_Out, Goods_Cost_Values)
							->
						true
							;
						(
							gtrace,
							throw_string(['not enough goods to sell'])
						)
					),
					
					maplist(unrealized_gains_reduction_txs(Static_Data), Goods_Cost_Values, Txs1_Nested),
					flatten(Txs1_Nested, Txs1),
					maplist(tx_to_transaction(Transaction_Day), Txs1, Trading_Transactions1),
					
					Sale_Unit_Price_Amount is Our_Debit / Goods_Positive,
					maplist(
						realized_gains_txs(
							Static_Data, value(
								Currency, Sale_Unit_Price_Amount
							)
						), 
						Goods_Cost_Values, Txs2_Nested
					),
					flatten(Txs2_Nested, Txs2),
					maplist(tx_to_transaction(Transaction_Day), Txs2, Trading_Transactions2),
					Trading_Transactions = [Trading_Transactions1, Trading_Transactions2]
				)
		)
	;
		(
			Outstanding_Out = Outstanding_In
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
	
unrealized_gains_txs((_, Report_Currency, _, _, _), Cost, Goods, Transaction_Day, Txs) :-
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
	Cost = [coord(Purchase_Currency, _, _)],
	Purchase_Date = Transaction_Day,
	
	dr_cr_table_to_txs([
	% Account                                                                 DR                                                               CR
	('Unrealized_Gains_Currency_Movement',	             Cost,      	                                  Goods_Without_Currency_Movement),
	('Unrealized_Gains_Excluding_Forex',     Goods_Without_Currency_Movement,       Goods)
	],
	Txs).
	

unrealized_gains_reduction_txs((_, Report_Currency, _, _, _), Purchase_Info, Transactions_Out) :-
	Goods_Without_Currency_Movement = [coord(
		without_currency_movement_against_since(Goods_Unit, Purchase_Currency, Report_Currency, Purchase_Date), 
		Goods_Count, 0)
	],
	outstanding(Goods_Unit, Goods_Count, Cost, Purchase_Date) = Purchase_Info,
	Goods = value(Goods_Unit, Goods_Count),
	value(Purchase_Currency, _) = Cost,
	dr_cr_table_to_txs([
	% Account                                                                 DR                                                               CR
	('Unrealized_Gains_Currency_Movement',					Goods_Without_Currency_Movement,           Cost),
	('Unrealized_Gains_Excluding_Forex',        Goods,                                                              Goods_Without_Currency_Movement)
	],
	Transactions_Out).
	


realized_gains_txs((_, Report_Currency, _, _, _), Sale_Unit_Price, Purchase_Info, Txs) :-
	Sale_Without_Currency_Movement = [coord(
		without_currency_movement_against_since(Goods_Unit, Purchase_Currency, Report_Currency, Purchase_Date), 
		0, Goods_Count)
	],
	outstanding(Goods_Unit, Goods_Count, Cost, Purchase_Date) = Purchase_Info,
	value_multiply(Sale_Unit_Price, Goods_Count, Sale),
	value(Purchase_Currency, _) = Cost,
	dr_cr_table_to_txs([
	% Account                                                                 DR                                                               CR
	('Realized_Gains_Currency_Movement',	                Sale_Without_Currency_Movement,           Sale),
	('Realized_Gains_Excluding_Forex',                        Cost,      	                     Sale_Without_Currency_Movement)
	],
	Txs).

	
/*
					
					Unrealized gains:
					Account              DR                            CR
					Forex                Report_Currency_Expense       Sale_Currency_Expense
					Excluding_Forex      Sale_Currency_Expense         Goods
					
					
					
					
					without forex:
					Realized_Gains = [
					% Account              DR                            CR
					''                           Goods                      Revenue
					]
					
					Realized_Gains_With_Forex = [
					% Account                                      DR                                               CR
					('Forex',                    Sale_Currency_Purchase_Date_Revenue,       Sale_Currency_Sale_Date_Revenue),
					('Excluding_Forex',     Sale_Currency_Purchase_Date_Expense,        Sale_Currency_Purchase_Date_Revenue)
					]
			
		
					
					
					
*/
	
/*	
realized_gains_transactions(Static_Data, Transaction_Day, Sale_Unit_Price, Sale_Currency, Purchase_Info, Transactions_Out):-
	Static_Data = (_, Report_Currency, _, _, Exchange_Rates),
	(_, Goods_Count, value(Purchase_Currency, Purchase_Cost), Purchase_Day) = Purchase_Info,
	Cost_In_Purchase_Currency = [coord(Purchase_Currency, Purchase_Cost, 0)],
	
	Sale_Revenue = [coord(Sale_Currency, 0, Revenue_Amount)],
	Revenue_Amount is Sale_Unit_Price * Goods_Count,
	
	vec_change_bases(Exchange_Rates, Purchase_Day, Report_Currency, Sale_Revenue, Sale_Revenue_Converted_To_Report_Currency_At_Purchase_Time),
	vec_change_bases(Exchange_Rates, Purchase_Day, Report_Currency, Cost_In_Purchase_Currency, Purchase_Expense_Converted_To_Report_Currency_At_Purchase_Time),
	
	vec_inverse(Sale_Revenue_Converted_To_Report_Currency_At_Purchase_Time, Sale_Revenue_Converted_To_Report_Currency_At_Purchase_Time_Inverted),
	
	Txs = [
		tx{
			comment: '',
			comment2: '',
			account: Gains_Excluding_Forex,
			vector: [Sale_Revenue_Converted_To_Report_Currency_At_Purchase_Time, Purchase_Expense_Converted_To_Report_Currency_At_Purchase_Time]
		},
		tx{
			comment: '',
			comment2: '',
			account: Gains_Currency_Movement,
			vector: [Sale_Revenue_Converted_To_Report_Currency_At_Purchase_Time_Inverted, Sale_Revenue]
		}],
	
	maplist(tx_to_transaction(Transaction_Day), Txs, Transactions_Out),
	gains_account_has_forex_accounts('Realized_Gains', Gains_Excluding_Forex, Gains_Currency_Movement).
*/
					
/*
we bought the shares with some currency. we can think of gains as having two parts:
	share value against that currency.
	that currency value against report currency.
*/
/*
gains_txs(Static_Data, Cost_In_Purchase_Currency, Goods_Vector, Transaction_Day, Exchange_Day, Gains_Account, Transactions_Out) :-
	Static_Data = (_Accounts, Report_Currency, _Transaction_Types, _Report_End_Day, Exchange_Rates),
	vec_change_bases(Exchange_Rates, Exchange_Day, Report_Currency, Cost_In_Purchase_Currency, Cost_In_Report_Currency),
	append(Cost_In_Purchase_Currency, Goods_Vector, Cost_In_Purchase_Currency_Vs_Goods),
	vec_inverse(Cost_In_Purchase_Currency_Vs_Goods, Cost_In_Purchase_Currency_Vs_Goods__Revenue),
	
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
	vec_sub(Cost_In_Report_Currency, Cost_In_Purchase_Currency, Cost_In_Report_Vs_Purchase_Currency),
	vec_inverse(Cost_In_Report_Vs_Purchase_Currency, Cost_In_Report_Vs_Purchase_Currency_Inverted),

	pretty_term_string(Exchange_Day, Exchange_Day_Str),
	pretty_term_string(Report_Currency, Report_Currency_Str),
	pretty_term_string(	Cost_In_Purchase_Currency, Cost_Vector_Str),
	atomic_list_concat(['cost:', Cost_Vector_Str, ' exchanged to ', Report_Currency_Str, ' on ', Exchange_Day_Str], Tx2_Comment2),

	maplist(tx_to_transaction(Transaction_Day), Txs0, Transactions_Out),
	gains_account_has_forex_accounts(Gains_Account, Gains_Excluding_Forex, Gains_Currency_Movement).
*/


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
	
make_unexchanged_transaction(S_Transaction, Description, UnX_Transaction) :-
	% Make an unexchanged transaction to the unexchanged (bank) account
	% the bank account is debited/credited in the currency of the bank account, exchange will happen for report end day
	s_transaction_day(S_Transaction, Day), 
	transaction_day(UnX_Transaction, Day),
	transaction_description(UnX_Transaction, Description),
	s_transaction_vector(S_Transaction, Vector),
	transaction_vector(UnX_Transaction, Vector),
	s_transaction_account_id(S_Transaction, UnX_Account), 
	transaction_account_id(UnX_Transaction, UnX_Account).



transactions_trial_balance(Transactions, Total) :-
	maplist(transaction_vector, Transactions, Vectors),
	vec_add(Vectors, [], Total).

check_trial_balance(Transactions) :-	
	transactions_trial_balance(Transactions, Total),
	(
		Total = []
	->
		true
	;
		(
			pretty_term_string(['total is ', Total], Err_Str),
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
		debit, Bank_Debit,
		credit, Bank_Credit]),
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

extract_exchanged_value(Tx_Dom, Account_Currency, Bank_Debit, Bank_Credit, Exchanged) :-
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
      Exchanged = bases([Account_Currency])
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


get_relevant_exchange_rates([Report_Currency], Report_End_Day, Exchange_Rates, Transactions, Exchange_Rates2) :-
	% find all days when something happened
	findall(
		Day,
		(
			member(T, Transactions),
			transaction_day(T, Day)
		),
		Days_Unsorted0
	),
	append(Days_Unsorted0, [Report_End_Day], Days_Unsorted1),
	sort(Days_Unsorted1, Days),
	%find all currencies used
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
			member(Day, Days),
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
	


	
	
% tests	

:- maplist(transaction_vector, Transactions, [[coord(aAAA, 5, 1), coord(aBBB, 0, 0.0)], [], [coord(aBBB, 7, 7)], [coord(aAAA, 0.0, 4)]]), check_trial_balance(Transactions).
:- maplist(transaction_vector, Transactions, [[coord(aAAA, 5, 1)], [coord(aAAA, 0.0, 4)]]), check_trial_balance(Transactions).
:- maplist(transaction_vector, Transactions, [[coord(AAA, 5, 1), coord(BBB, 0, 0.0)], [], [coord(BBB, 7, 7)], [coord(AAA, 0.0, 4)]]), check_trial_balance(Transactions).
:- maplist(transaction_vector, Transactions, [[coord(AAA, 45, 49), coord(BBB, 0, 0.0)], [], [coord(BBB, -7, -7)], [coord(AAA, 0.0, -4)]]), check_trial_balance(Transactions).


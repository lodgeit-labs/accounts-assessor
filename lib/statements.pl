% ===================================================================
% Project:   LodgeiT
% Module:    statements.pl
% Date:      2019-06-02
% ===================================================================

:- module(statements, [extract_transaction/4, preprocess_s_transaction_with_debug/8, add_bank_accounts/3]).
 
:- use_module(pacioli,  [vec_inverse/2, vec_sub/3]).
:- use_module(exchange, [vec_change_bases/5]).
:- use_module(exchange_rates, [exchange_rate/5, is_exchangeable_into_request_bases/4]).

:- use_module(transaction_types, [
	transaction_type_id/2,
	transaction_type_exchanged_account_id/2,
	transaction_type_trading_account_id/2,
	transaction_type_description/2]).
:- use_module(livestock, [preprocess_livestock_buy_or_sell/5]).
:- use_module(transactions, [
	transaction_day/2,
	transaction_description/2,
	transaction_account_id/2,
	transaction_vector/2]).
:- use_module(utils, [pretty_term_string/2, inner_xml/3, write_tag/2, fields/2, fields_nothrow/2, numeric_fields/2, throw_string/1]).
:- use_module(accounts, [account_parent_id/3]).
:- use_module(days, [format_date/2, parse_date/2, gregorian_date/2]).
:- use_module(library(record)).

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


/*

s_transactions have to be sorted by date from oldest to newest 

*/
preprocess_s_transactions(Static_Data, Exchange_Rates_In, Exchange_Rates_Out, S_Transactions, Transactions_Out) :-
	Outstanding = [],
	preprocess_s_transactions2(Static_Data, Exchange_Rates_In, Exchange_Rates_Out, S_Transactions, Transactions_Out, Outstanding).

preprocess_s_transactions2(Static_Data, Exchange_Rates_In, Exchange_Rates_Out, [S_Transaction|S_Transactions], [Transactions_Out|Transactions_Out_Tail], Outstanding).
	check_that_s_transaction_account_exists(S_Transaction, Accounts),
	(
		(
			pretty_term_string(S_Transaction, S_Transaction_String),
			preprocess_s_transaction(Accounts, Report_Currency, Transaction_Types, End_Date, Exchange_Rates, S_Transaction, Transactions0, Outstanding, New_Outstanding),
			pretty_term_string(Transactions, Transactions_String),
			atomic_list_concat([S_Transaction_String, '==>\n', Transactions_String, '\n====\n'], Transaction_Transformation_Debug)
		)
		->
			(
				% filter out unbound vars from the resulting Transactions list, as some rules do no always produce all possible transactions
				exclude(var, Transactions0, Transactions1),
				flatten(Transactions1, Transactions_Out),
				check_trial_balance(Transactions_Out)
			)
		;
		(
			% throw error on failure
			term_string(S_Transaction, Str2),
			atomic_list_concat(['processing failed:', Str2], Message),
			throw(Message)
		)
	),
	preprocess_s_transactions2(Static_Data, Exchange_Rates_In, Exchange_Rates_Out, S_Transactions, Transactions_Out_Tail, New_Outstanding).
	
preprocess_s_transaction(Accounts, Report_Currency, Transaction_Types, End_Date, Exchange_Rates, S_Transaction, [UnX_Transaction, X_Transaction, Trading_Transactions|Transactions_Tail], Outstanding, Outstanding) :-
	preprocess_livestock_buy_or_sell(Accounts, Exchange_Rates, Transaction_Types, S_Transaction, Transactions).

/*	
Transactions using trading accounts can be decomposed into:
	a transaction of the given amount to the unexchanged account (your bank account)
	a transaction of the transformed inverse into the exchanged account (your shares investments account)
	and a transaction of the negative sum of these into the trading cccount. 
This predicate takes a list of statement transaction terms and decomposes it into a list of plain transaction terms, 3 for each input s_transaction.
"Goods" is not a general enough word, but it avoids confusion with other terms used.
*/	

preprocess_s_transaction(Accounts, Report_Currency, Transaction_Types, End_Date, Exchange_Rates, [S_Transaction|S_Transactions], [UnX_Transaction, X_Transaction, Trading_Transactions|Transactions_Tail], ], Outstanding_In, Outstanding_Out)	 :-
	(
		% do we have a tag that corresponds to one of known actions?
		transaction_type_of(Transaction_Types, S_Transaction, Transaction_Type)
	->
		true
	;
		throw(string('unknown action verb'))
	),
	s_transaction_vector(S_Transaction, Vector_Bank),
	vec_inverse(Vector_Bank, [Our_Coord]),
	
	s_transaction_exchanged(S_Transaction, vector(Vector_Goods)),
	transaction_type(_, Exchanged_Account_Id, Trading_Account_Id, Description) = Transaction_Type,
	
	make_unexchanged_transaction(S_Transaction, Description, UnX_Transaction),
	
	(
		nonvar(Exchanged_Account_Id)
	->
		(
			/* Make an inverse exchanged transaction to the exchanged account.
				this can be a revenue/expense or equity account, in case value is coming in or going out of the company,
				or it can be an assets account, if we are moving values around*/
			transaction_day(X_Transaction, Day),
			transaction_description(X_Transaction, Description),
			transaction_vector(X_Transaction, Vector_Goods),
			transaction_account_id(X_Transaction, Exchanged_Account_Id)
		)
	;
		throw(string('action does not specify exchanged account'))
	),
	(
		nonvar(Trading_Account_Id)
	->
		% Make a difference transaction to the currency trading account. See https://www.mathstat.dal.ca/~selinger/accounting/tutorial.html . This will track the gain/loss generated by the movement of exchange rate between our asset and the reporting currency.
		(
				Vector_Goods = [coord(Unit_Type, Goods_Count, 0)
			->
				(
					Added = (Unit_Type, Goods_Count, Unit_Cost),
					Unit_Cost is 
					add_bought_items(fifo, Added, Outstanding_In, Outstanding_In, Outstanding_Out),
					gains_txs(Cost, Goods, 'Unrealized_Gains', Trading_Transactions)
				)
			;
			(
				is_shares_sell(ST)
			->
				(
					units_cost(lifo, Unit_Type, Sale_Count, Sale_Cost, Outstanding_In, Outstanding_Out),
					gains_txs(Sale_Cost, Goods, 'Unrealized_Gains', Txs1),
					gains_txs(Cost, Goods, 'Realized_Gains', Txs2),
					Trading_Transactions = [Txs1, Txs2]
				)
			)
		)
	;
		(
			Outstanding_Out = Outstanding_In
		)
	).


% This Prolog rule handles the case when only the exchanged units are known (for example GOOG)  and
% hence it is desired for the program to infer the count. 
% We passthrough the output list to the above rule, and just replace the first S_Transaction in the 
% input list with a modified one (NS_Transaction).
preprocess_s_transaction(Accounts, Request_Bases, Exchange_Rates, Transaction_Types, Report_End_Date, S_Transaction, Transactions) :-
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
	s_transaction_exchanged(NS_Transaction, vector(Vector_Exchanged)),
	preprocess_s_transaction2(Accounts, Request_Bases, Exchange_Rates, Transaction_Types, Report_End_Date, NS_Transaction, Transactions),
	!.


gains_txs(Cost, Goods, Gains_Account) :-
	vec_add(Cost, Goods, Assets_Change)
	is_exchanged_to_currency(Cost, Report_Currency, Cost_At_Report_Currency),
	Txs = [
		tx{
			comment: keeps track of gains obtained by changes in price of shares against at the currency we bought them for
			comment2: Comment2
			account: Gains_Excluding_Forex
			vector:  Assets_Change_At_Cost_Inverse
		}

		tx{
			comment: keeps track of gains obtained by changes in the value of the currency we bought the shares with, against report currency
			comment2: Comment2
			account: Gains_Currency_Movement
			vector:  Cost - Cost_At_Report_Currency
		}],
	gains_account_has_forex_accounts(Gains_Account, Gains_Excluding_Forex, Gains_Currency_Movement).


make_unexchanged_transaction(S_Transaction, Description, UnX_Transaction) :-
	% Make an unexchanged transaction to the unexchanged (bank) account
	% the bank account is debited/credited in the currency of the bank account, exchange will happen for report end day
	s_transaction_day(S_Transaction, Day), 
	transaction_day(UnX_Transaction, Day),
	transaction_description(UnX_Transaction, Description),
	s_transaction_vector(S_Transaction, Vector_Bank),
	vec_inverse(Vector_Bank, Vector_Inverted), % bank statement is from bank perspective
	transaction_vector(UnX_Transaction, Vector_Inverted),
	s_transaction_account_id(S_Transaction, UnX_Account), 
	transaction_account_id(UnX_Transaction, UnX_Account).

	
/*
pricing methods:

for adjusted_cost method, we will add up all the buys costs and divide by number of units outstanding.
for lifo, sales will be reducing/removing buys from the end, for fifo, from the beginning.
*/

units_cost(Method, Type, Sale_Count, Sale_Cost, Outstanding_In, Outstanding_Out) :-
	(Method = lifo; Method = fifo),
	find_sold_items(Type, Sale_Count, Sale_Cost, Outstanding_In, Outstanding_Out).

	
add_bought_items(fifo, Added, Outstanding_In, [Added|Outstanding_In]).
add_bought_items(lifo, Added, Outstanding_In, [Outstanding_In|Added]).


find_sold_items(Type, 0, 0, Outstanding, Outstanding).

find_sold_items(Type, Count, Cost, [(Type, Outstanding_Count, Outstanding_Unit_Cost)|Outstanding_Tail], Outstanding_Out) :-
	Outstanding_Count > Count,
	Cost is Count * Outstanding_Unit_Cost,
	Outstanding_Remaining_Count is Outstanding_Count - Count,
	Outstanding_Out = [Outstanding_Remaining | Outstanding_Tail],
	Outstanding_Remaining = (Type, Outstanding_Remaining_Count, Outstanding_Unit_Cost).

find_sold_items(lifo, Type, Sale_Count, Sale_Cost, [(Type, Outstanding_Count, Outstanding_Unit_Cost)|Outstanding_Tail], Outstanding_Out) :-
	Outstanding_Count <= Sale_Count,
	Outstanding_Out = Outstanding_Tail,
	Remaining_Count is Sale_Count - Outstanding_Count,
	find_sold_items(lifo, Type, Remaining_Count, Remaining_Cost, Outstanding_Tail, Outstanding_Out),	
	Sale_Cost is Outstanding_Count * Outstanding_Unit_Cost + Remaining_Cost.

find_sold_items(lifo, Type, Count, Cost, [(Outstanding_Type,_,_)|Outstanding_Tail], Outstanding_Out) :-
	Outstanding_Type \= Type,
	find_sold_items(lifo, Type, Count, Cost, Outstanding_Tail, Outstanding_Out).
	

	
	
/*
finally, we should update our knowledge of unit costs, based on recent sales and buys

we will only be interested in an exchange rate (price) of shares at report date.
note that we keep exchange rates at two places. 
Currency exchange rates fetched from openexchangerates are asserted into a persistent db.
Exchange_Rates are parsed from the request xml.


Report_Date, Exchange_Rates, , Exchange_Rates2

	% will we be able to exchange this later?
	is_exchangeable_into_currency(Exchange_Rates, End_Date, Goods_Units, Request_Currency)
		->
	true
		;
		(
			% save the cost for report time
		)
*/

	


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
			throw_string(['account not found in hierarchy:', Account_Name]).
	).

	

% yield all transactions from all accounts one by one.
% these are s_transactions, the raw transactions from bank statements. Later each s_transaction will be preprocessed
% into multiple transaction(..) terms.
% fixme dont fail silently
extract_transaction(Dom, Default_Bases, Start_Date, Transaction) :-
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
		extract_transaction2(Tx_Dom, Account_Currency, Default_Bases, Account_Name, Start_Date, Transaction),
		Error,
		(
			term_string(Error, Str1),
			term_string(Tx_Dom, Str2),
			atomic_list_concat([Str1, Str2], Message),
			throw(Message)
		)),
	true.

extract_transaction2(Tx_Dom, Account_Currency, _Default_Bases, Account, Start_Date, ST) :-
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


	

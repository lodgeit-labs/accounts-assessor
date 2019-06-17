% ===================================================================
% Project:   LodgeiT
% Module:    statements.pl
% Date:      2019-06-02
% ===================================================================

:- module(statements, [extract_transaction/4, preprocess_s_transaction_with_debug/8]).
 
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
:- use_module(utils, [pretty_term_string/2, inner_xml/3, write_tag/2, fields/2, fields_nothrow/2, numeric_fields/2]).
:- use_module(accounts, [account_parent_id/3]).
:- use_module(days, [format_date/2, parse_date/2, gregorian_date/2]).
:- use_module(library(record)).

% -------------------------------------------------------------------

:- record s_transaction(day, type_id, vector, account_id, exchanged).
% - The absolute day that the transaction happenned
% - The type identifier/action tag of the transaction
% - The amounts that are being moved in this transaction
% - The account that the transaction modifies without using exchange rate conversions
% - Either the units or the amount to which the transaction amount will be converted to
% depending on whether the term is of the form bases(...) or vector(...).


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
			(
				atomic_list_concat(['account not found in hierarchy:', Account_Name], Msg),
				throw(Msg)
			)
	).


preprocess_s_transaction(Accounts, Bases, Exchange_Rates, Transaction_Types, End_Date, S_Transaction, Transactions) :-
	check_that_s_transaction_account_exists(S_Transaction, Accounts),
	preprocess_s_transaction1(Accounts, Bases, Exchange_Rates, Transaction_Types, End_Date, S_Transaction, Transactions).
	
	
preprocess_s_transaction1(Accounts, Bases, Exchange_Rates, Transaction_Types, End_Date, S_Transaction, Transactions) :-
	(
			preprocess_s_transaction2(Accounts, Bases, Exchange_Rates, Transaction_Types, End_Date,  S_Transaction, Transactions0)
		->
			% filter out unbound vars from the resulting Transactions list, as some rules do no always produce all possible transactions
			exclude(var, Transactions0, Transactions)
		;
		(
			% throw error on failure
			gtrace,
			term_string(S_Transaction, Str2),
			atomic_list_concat(['processing failed:', Str2], Message),
			throw(Message)
		)
	).

	
preprocess_s_transaction2(Accounts, _, Exchange_Rates, Transaction_Types, _End_Date,  S_Transaction, Transactions) :-
	(preprocess_livestock_buy_or_sell(Accounts, Exchange_Rates, Transaction_Types, S_Transaction, Transactions),
	!).

/*	
trading account, non-livestock processing:
Transactions using trading accounts can be decomposed into:
	a transaction of the given amount to the unexchanged account (your bank account)
	a transaction of the transformed inverse into the exchanged account (your shares investments account)
	and a transaction of the negative sum of these into the trading cccount. 

This predicate takes a list of statement transaction terms and decomposes it into a list of plain transaction terms, 3 for each input s_transaction.
This Prolog rule handles the case when the exchanged amount is known, for example 10 GOOG,
and hence no exchange rate calculations need to be done.

"Goods" is not a general enough word, but it avoids confusion with other terms used.
*/

preprocess_s_transaction2(_Accounts, Bases, Exchange_Rates, Transaction_Types, End_Date, S_Transaction,
		[UnX_Transaction, X_Transaction, Trading_Transaction]) :-
	s_transaction_vector(S_Transaction, Vector_Bank),
	s_transaction_exchanged(S_Transaction, vector(Vector_Goods0)),
	[coord(Goods_Units, _, _)] = Vector_Goods0,
	(
		% will we be able to exchange this later?
			is_exchangeable_into_request_bases(Exchange_Rates, End_Date, Goods_Units, Bases)
		->
			Vector_Goods = Vector_Goods0
		;
			% just take the amount paid, and report this "at cost"
			Vector_Goods = Vector_Bank
	),
	(
		% do we have a tag that corresponds to one of known actions?
		transaction_type_of(Transaction_Types, S_Transaction, Transaction_Type)
	->
		true
	;
		% if not, we will affect no other accounts, (the balance sheet won't balance)
		(
			s_transaction_type_id(S_Transaction, Description),
			Transaction_Type = transaction_type(_,_,_,Description)
		)
	),
	transaction_type(_, Exchanged_Account_Id, Trading_Account_Id, Description) = Transaction_Type,

	% Make an unexchanged transaction to the unexchanged (bank) account
	% the bank account is debited/credited in the currency of the bank account, exchange will happen for report end day
	s_transaction_day(S_Transaction, Day), 
	transaction_day(UnX_Transaction, Day),
	transaction_description(UnX_Transaction, Description),
	vec_inverse(Vector_Bank, Vector_Inverted), % bank statement is from bank perspective
	transaction_vector(UnX_Transaction, Vector_Inverted),
	s_transaction_account_id(S_Transaction, UnX_Account), 
	transaction_account_id(UnX_Transaction, UnX_Account),
	
	% Make an inverse exchanged transaction to the exchanged account
	(
		nonvar(Exchanged_Account_Id)
	->
		(
			transaction_day(X_Transaction, Day),
			transaction_description(X_Transaction, Description),
			transaction_vector(X_Transaction, Vector_Goods),
			transaction_account_id(X_Transaction, Exchanged_Account_Id)
		)
	;
		true
	),
	% Make a difference transaction to the trading account
	(
		nonvar(Trading_Account_Id)
	->
		(
			vec_sub(Vector_Bank, Vector_Goods, Trading_Vector),
			transaction_day(Trading_Transaction, Day),
			transaction_description(Trading_Transaction, Description),
			transaction_vector(Trading_Transaction, Trading_Vector),
			transaction_account_id(Trading_Transaction, Trading_Account_Id)
		)
	;
		true
	),
	!.

% This Prolog rule handles the case when only the exchanged units are known (for example GOOG)  and
% hence it is desired for the program to infer the count. 
% We passthrough the output list to the above rule, and just replace the first S_Transaction in the 
% input list with a modified one (NS_Transaction).
preprocess_s_transaction2(Accounts, Request_Bases, Exchange_Rates, Transaction_Types, Report_End_Date, S_Transaction, Transactions) :-
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


% yield all transactions from all accounts one by one.
% these are s_transactions, the raw transactions from bank statements. Later each s_transaction will be preprocessed
% into multiple transaction(..) terms.
% fixme dont fail silently
extract_transaction(Dom, Default_Bases, Start_Date, Transaction) :-
	xpath(Dom, //reports/balanceSheetRequest/bankStatement/accountDetails, Account),
	fields(Account, [
		accountName, Account_Name,
		currency, Account_Currency
		]),
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


preprocess_s_transaction_with_debug(Account_Hierarchy, Bases, Exchange_Rates, Action_Taxonomy, End_Days, S_Transaction, Transactions, Transaction_Transformation_Debug) :-
	pretty_term_string(S_Transaction, S_Transaction_String),
	preprocess_s_transaction(Account_Hierarchy, Bases, Exchange_Rates, Action_Taxonomy, End_Days, S_Transaction, Transactions),
	pretty_term_string(Transactions, Transactions_String),
	atomic_list_concat([S_Transaction_String, '==>\n', Transactions_String, '\n====\n'], Transaction_Transformation_Debug).

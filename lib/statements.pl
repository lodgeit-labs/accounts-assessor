% ===================================================================
% Project:   LodgeiT
% Module:    statements.pl
% Date:      2019-06-02
% ===================================================================

:- module(statements, [
		extract_transaction/3, 
		preprocess_s_transactions/4,
		get_relevant_exchange_rates/5, 
		invert_s_transaction_vector/2, 
		fill_in_missing_units/6,
		s_transaction_day/2,
		s_transaction_account_id/2,
		s_transaction_type_of/3,
		s_transaction_exchanged/2,
		s_transaction_vector/2
		]).

/*fixme turn trading into module*/
:- [trading].

:- use_module('pacioli',  [
		vec_inverse/2, 
		vec_add/3, 
		vec_sub/3, 
		integer_to_coord/3,
		make_debit/2,
		make_credit/2,
		value_multiply/3]).
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
		make_livestock_accounts/2, 
		livestock_counts/5]).
:- use_module('transactions', [
		has_empty_vector/1,
		transaction_day/2,
		transaction_description/2,
		transaction_account_id/2,
		transaction_vector/2]).
:- use_module('utils', [
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
		account_exists/2]).
:- use_module('days', [
		format_date/2, 
		parse_date/2]).
:- use_module('pricing', [
		add_bought_items/4, 
		find_items_to_sell/6]).

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
			%g trace,
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
	This predicate takes a list of statement transaction terms and decomposes it into a list of plain transaction terms.
	"Goods" is not a general enough word, but it avoids confusion with other terms used.
*/	

preprocess_s_transaction(Static_Data, S_Transaction, [Ts0, Ts1, Ts2, Ts3, Ts4, Ts5, Ts6], Outstanding_In, Outstanding_Out) :-

	Static_Data = (Accounts, Report_Currency, Transaction_Types, _, Exchange_Rates),
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
	s_transaction_exchanged(S_Transaction, vector(Goods_Vector0)),
	s_transaction_account_id(S_Transaction, Bank_Account_Name), 
	s_transaction_vector(S_Transaction, Vector_Ours),
	s_transaction_day(S_Transaction, Transaction_Day), 
	transaction_type(_Verb, Exchanged_Account, Trading_Account_Id, Description) = Transaction_Type,
	(var(Exchanged_Account) -> throw_string('action does not specify exchanged account') ; true),
	(var(Description)->	Description = '?'; true),
	(
		Goods_Vector0 = []
	->
		vec_inverse(Vector_Ours, Goods_Vector)
	;
		Goods_Vector = Goods_Vector0
	),
	(
		(account_in_set(Accounts, Exchanged_Account, 'Equity')
		;account_in_set(Accounts, Exchanged_Account, 'Earnings'))
	->
		Earnings_Account = Exchanged_Account
	;
		Shuffle_Account = Exchanged_Account
	),
	/* record the change on our bank account */
	Bank_Account_Role = ('Cash_And_Cash_Equivalents'/Bank_Account_Name),
	account_by_role(Accounts, Bank_Account_Role, Bank_Account_Id),
	make_transaction(Bank_Account_Id, Transaction_Day, Vector_Ours, Description, Ts0),
	(
		nonvar(Shuffle_Account)
	->
		/* record the change in another assets account*/
		make_transaction(Shuffle_Account, Transaction_Day, Goods_Vector, Description, Ts1)
	;
		(
			(
				true
			->
				(
					/* Make an inverse exchanged transaction to the exchanged account.
					this can be a revenue/expense or equity account, in case value is coming in or going out of the company*/
					make_exchanged_transactions(Exchange_Rates, Report_Currency, Earnings_Account, Transaction_Day, Goods_Vector, Description, Ts2),
					% Make a difference transaction to the currency trading account. See https://www.mathstat.dal.ca/~selinger/accounting/tutorial.html . This will track the gain/loss generated by the movement of exchange rate between our asset in foreign currency and our equity/revenue in reporting currency.
					make_currency_movement_transactions(Exchange_Rates, Accounts, Bank_Account_Id, Report_Currency, Transaction_Day, Vector_Ours, [Description, ' - currency movement adjustment'], Ts3)
				)
			;
				make_transaction(Earnings_Account, Transaction_Day, Vector_Ours, Description, Ts2)
			)
		)
	),
	(
		nonvar(Trading_Account_Id)
	->
		(
			(
				true
			->
				vec_change_bases(Exchange_Rates, Transaction_Day, Report_Currency, Vector_Ours, Converted_Vector)
			;
				Converted_Vector = Vector_Ours
			),
			make_currency_movement_transactions(Exchange_Rates, Accounts, Bank_Account_Id, Report_Currency, Transaction_Day, Vector_Ours, [Description, ' - currency movement adjustment'], Ts3),

			Pricing_Method = lifo,
			(
				(Goods_Vector = [coord(_,_,Zero)], Zero =:= 0)
			->
				(
					Vector_Ours = [coord(Purchase_Currency, _,_)],
					make_trading_buy(Static_Data, Trading_Account_Id, Pricing_Method, Purchase_Currency, Converted_Vector, Goods_Vector, Transaction_Day, Outstanding_In, Outstanding_Out, Ts4) 
				)
			;
				(
					Goods_Vector = [coord(Goods_Unit,_,Goods_Positive)],
					((find_items_to_sell(Pricing_Method, Goods_Unit, Goods_Positive, Outstanding_In, Outstanding_Out, Goods_Cost_Values),!)
						;throw_string(['not enough goods to sell'])),
					reduce_unrealized_gains(Static_Data, Trading_Account_Id, Transaction_Day, Goods_Cost_Values, Ts5),
					increase_realized_gains(Static_Data, Trading_Account_Id, Converted_Vector, Goods_Vector, Transaction_Day, Goods_Cost_Values, Ts6)
				)
			)
		)
	;
		Outstanding_Out = Outstanding_In	
	).
	

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
	
make_currency_movement_transactions(Exchange_Rates, Accounts, Bank_Account, Report_Currency, Day, Vector, Description, Transaction) :-
	vec_change_bases(Exchange_Rates, Day, Report_Currency, Vector, Vector_Exchanged_To_Report),
	account_by_role(Accounts, ('Currency_Movement'/Bank_Account), Currency_Movement_Account),
	make_transaction(Currency_Movement_Account, Day, Vector_Movement, Description, Transaction),
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
			maplist(coord_is_almost_zero, Total)
		->
			true
		;
			(
				pretty_term_string(['WARNING: total is ', Total, ' on day ', Day], Err_Str),
				format(user_error, '\n\\n~w\n\n', [Err_Str])/*,
				throw(Err_Str)*/
			)
		)
	).

float_comparison_max_difference(0.00000001).
	
coord_is_almost_zero(coord(_, D, C)) :-
	compare_floats(D, 0),
	compare_floats(C, 0).


compare_floats(A, B) :-
	float_comparison_max_difference(Max),
	D is abs(A - B),
	D =< Max.

	
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
	(
		account_by_role(Accounts, ('Cash_And_Cash_Equivalents'/Account_Name), _) 
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
	




% tests	
/*
fixme: just check vec_add with this.
:- maplist(

		transaction_vector, 
		Transactions, 
		vec_add(
			[
				coord(aAAA, 5, 1), 
				coord(aBBB, 0, 0.0), 
				coord(aBBB, 7, 7)], 
			[coord(aAAA, 0.0, 4)]]
	), 
	check_trial_balance(Transactions).


:- maplist(transaction_vector, Transactions, [[coord(aAAA, 5, 1)], [coord(aAAA, 0.0, 4)]]), check_trial_balance(Transactions).
:- maplist(transaction_vector, Transactions, [[coord(AAA, 5, 1), coord(BBB, 0, 0.0)], [], [coord(BBB, 7, 7)], [coord(AAA, 0.0, 4)]]), check_trial_balance(Transactions).
:- maplist(transaction_vector, Transactions, [[coord(AAA, 45, 49), coord(BBB, 0, 0.0)], [], [coord(BBB, -7, -7)], [coord(AAA, 0.0, -4)]]), check_trial_balance(Transactions).
*/

/*

wip notes...

adjustment transactions for forex :

buy goog for 1 usd
unrealized gain = goog - 1usd
unrealized gain = goog - 1.2 aud:

	goog - goog without usd movement
	goog without usd movement - 1.2 aud


*/

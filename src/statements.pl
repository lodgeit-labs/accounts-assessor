% Predicates for asserting that the fields of given transaction types have particular values

% The identifier of this transaction type, for example Borrow
transaction_type_id(transaction_type(Id, _, _, _), Id).

% The account that will receive the inverse of the transaction amount after exchanging
transaction_type_exchanged_account_id(transaction_type(_, Exchanged_Account_Id, _, _), Exchanged_Account_Id).

% The account that will record the gains and losses on the transaction amount
transaction_type_trading_account_id(transaction_type(_, _, Trading_Account_Id, _), Trading_Account_Id).

% A description of this transaction type
transaction_type_description(transaction_type(_, _, _, Description), Description).


%  term s_transaction(Day, Type_Id, Vector, Unexchanged_Account_Id, Bases)

% Predicates for asserting that the fields of given transactions have particular values

% The absolute day that the transaction happenned
s_transaction_day(s_transaction(Day, _, _, _, _), Day).
% The type identifier of the transaction
s_transaction_type_id(s_transaction(_, Type_Id, _, _, _), Type_Id).
% The amounts that are being moved in this transaction
s_transaction_vector(s_transaction(_, _, Vector, _, _), Vector).
% The account that the transaction modifies without using exchange rate conversions
s_transaction_account_id(s_transaction(_, _, _, Unexchanged_Account_Id, _), Unexchanged_Account_Id).
% Either the units or the amount to which the transaction amount will be converted to
% depending on whether the term is of the form bases(...) or vector(...).
s_transaction_exchanged(s_transaction(_, _, _, _, Bases), Bases).

% Gets the transaction_type associated with the given transaction

transaction_type_of(Transaction_Types, S_Transaction, Transaction_Type) :-
  s_transaction_type_id(S_Transaction, Type_Id),
  transaction_type_id(Transaction_Type, Type_Id),
  member(Transaction_Type, Transaction_Types).

% Transactions using trading accounts can be decomposed into a transaction of the given
% amount to the unexchanged account, a transaction of the transformed inverse into the
% exchanged account, and a transaction of the negative sum of these into the trading
% account. This predicate takes a list of statement transactions (and transactions using trading
% accounts?) and decomposes it into a list of just transactions, 3 for each input s_transaction.

preprocess_s_transactions(_, _, [], []).

% This Prolog rule handles the case when the exchanged amount is known, for example 10 GOOG,
% and hence no exchange rate calculations need to be done.
% preprocess_s_transactions(Exchange_Rates, Transaction_Types, Input, Output).

preprocess_s_transactions(Exchange_Rates, Transaction_Types, [S_Transaction | S_Transactions],
		[UnX_Transaction | [X_Transaction | [Trading_Transaction | PP_Transactions]]]) :-
	transaction_type_of(Transaction_Types, S_Transaction, Transaction_Type),
	
	% Make an unexchanged transaction to the unexchanged account
	s_transaction_day(S_Transaction, Day), transaction_day(UnX_Transaction, Day),
	transaction_type_description(Transaction_Type, Description), transaction_description(UnX_Transaction, Description),
	s_transaction_vector(S_Transaction, Vector),
	vec_inverse(Vector, Vector_Inverted),
	transaction_vector(UnX_Transaction, Vector_Inverted),
	s_transaction_account_id(S_Transaction, UnX_Account), transaction_account_id(UnX_Transaction, UnX_Account),
	
	% Make an inverse exchanged transaction to the exchanged account
	s_transaction_exchanged(S_Transaction, vector(Vector_Transformed)),
	transaction_day(X_Transaction, Day),
	transaction_description(X_Transaction, Description),
	transaction_vector(X_Transaction, Vector_Transformed),
	transaction_type_exchanged_account_id(Transaction_Type, X_Account), transaction_account_id(X_Transaction, X_Account),
	
	% Make a difference transaction to the trading account
	vec_sub(Vector, Vector_Transformed, Trading_Vector),
	transaction_day(Trading_Transaction, Day),
	transaction_description(Trading_Transaction, Description),
	transaction_vector(Trading_Transaction, Trading_Vector),
	transaction_type_trading_account_id(Transaction_Type, Trading_Account), transaction_account_id(Trading_Transaction, Trading_Account),
	
	% Make the list of preprocessed transactions
	preprocess_s_transactions(Exchange_Rates, Transaction_Types, S_Transactions, PP_Transactions), !.

% This Prolog rule handles the case when only the exchanged amount units are known (for example GOOG)  and
% hence it is desired for the program to do an exchange rate conversion. 
% We passthrough the output list to the above rule, and just replace the first transaction in the 
% input list (S_Transaction) with a modified one (NS_Transaction).


preprocess_s_transactions(Exchange_Rates, Transaction_Types, [S_Transaction | S_Transactions], Transaction) :-
	s_transaction_day(S_Transaction, Day), s_transaction_day(NS_Transaction, Day),
  s_transaction_type_id(S_Transaction, Type_Id), s_transaction_type_id(NS_Transaction, Type_Id),
  s_transaction_vector(S_Transaction, Vector), s_transaction_vector(NS_Transaction, Vector),
  s_transaction_account_id(S_Transaction, Unexchanged_Account_Id), s_transaction_account_id(NS_Transaction, Unexchanged_Account_Id),
  s_transaction_exchanged(S_Transaction, bases(Bases)),
  % Do the exchange rate conversion and then proceed using the above rule where the
  % exchanged amount.
	vec_change_bases(Exchange_Rates, Day, Bases, Vector, Vector_Transformed),
  s_transaction_exchanged(NS_Transaction, vector(Vector_Transformed)),
  preprocess_s_transactions(Exchange_Rates, Transaction_Types, [NS_Transaction | S_Transactions], Transaction).


one livestock acount with transactions? vectors with different unit types

defined for year:
	Natural_Increase_value is Natural_increase_count * Natural_increase_value_per_head,
	Opening_and_purchases_and_increase_count is Stock_on_hand_at_beginning_of_year_count + Purchases_count + Natural_increase_count,
	Opening_and_purchases_and_increase_value is Stock_on_hand_at_beginning_of_year_value + Purchases_value + Natural_Increase_value,
	Average_cost is Opening_and_purchases_and_increase_value / Opening_and_purchases_and_increase_count,


Stock_on_hand_at_beginning_of_year_count for day
since beginning of year:
	purchases
	born

livestock event types:
	dayEndCount 
	born        
	loss        
	rations     
	internal:
		bought
		sold

rations:
	debit equity drawings

born/loss as a source event affects:
	livestock count
	"Assets"/"Current Assets"/"Inventory on Hand"/"Inventory at Cost"/"Livestock at Cost","Livestock at average Cost"?

    



livestock-related bank statements:
	buy 
	sell
		fill in tag by unit type
	
	
		affect livestock count
		affect the bank account as usual
		the inverse account:
                    {
                      "name": "Livestock at Average Cost",
                      "code": "1204",
                      "active": false
                    },
                    {

	
actions:
	buy_livestock	"1203"-"Livestock at Cost"



Sales_Account_ID
Cog







% here we just simply count livestock units

livestock_count(Events, UnitType, EndDay, Count) :-
	filter_events(Events, UnitType, EndDay, FilteredEvents),
	livestock_count(FilteredEvents, Count).


livestock_count([E|Events], Count) :-
	livestock_count(Events, CountBefore),
	(
		(
			Events = [],
			(
				E = day_end_count(Count)
			;
				throw("first event has to be endDayCount")
			),
		),!
		;
		(
			E = end_day_count(EndDayCount),
			(
				EndDayCount = Count,!;
				throw("EndDayCount != Count")
			)
		)
	);
	E = born(C);
	E = loss(C);
	E = rations(C);
	Count is CountBefore + C
	
livestock_count([], Count) :-
	throw("no events, initial count missing").






s_transactions ->
	livestock_events
	transactions

livestock_events ->
	transactions

% this is a version of statements.pl where i am adding livestock functionality. work in progress.

/*

<howThisShouldWork>

account taxonomy must include accounts for individual livestock types


a list of livestock units will be defined in the sheet, for example "cows, horses".
FOR CURRENT ITERATION, ASSUME THAT ALL TRANSACTIONS ARE IN THE BANK STATEMENT. I.E. NO OPENING BALANCES.WHY? BECAUSE OPENING BALANCES IN LIVESTOCK WILL REQUIRE A COMPLETE SET OF OPENING BALANCES. I.E. A COMPLETE OPENING BALANCE SHEET. 
	
Natural_increase_cost_per_head has to be input for each livestock type, for example cows $20.

when bank statements are processed: 
	If there is a livestock unit ("cows") set on a bank account transaction:
		count has to be set too ("20"). 
		internally, we tag the transaction with a sell/buy livestock action type. 
		SYSTEM CAN INFER BUY/SELL i.e. A BUY IS A PAYMENT & A SELL IS A DEPOSIT. OF COURSE, THE UNIT TYPE MUST BE DESCRIBED. COW. PIG, ETC. AND THE UNIT TYPE MUST HAVE AN ACCOUNTS TAXONOMICAL RELATIONSHIP
		user should have sell/buy livestock action types in their action taxonomy.
			the "exchanged" account will be one where livestock increase/decrease transactions are internally collected. 
			AT REPORT RUN TIME COMPUTE THE FACTS BY INFERENCE.

		internally, livestock buys and sells are transformed into "livestock buy/sell events" OK.
		other livestock events are taken from the second table: natural increase, loss, rations.
		all livestock event types change the count accordingly.
		livestock events have effects on other accounts beside the livestock count account:
			buy/sell:
				cost is taken from the bank transaction
				BUY - 
					CR BANK (BANK BCE REDUCES) 
					DR Assets_1204_Livestock_at_Cost.
				SELL - 
					DR BANK (BANK BCE INCREASES) 
					CR Assets_1204_Livestock_at_Cost (STOCK ON HAND DECREASES,VALUE HELD DECREASES), 
					CR SALES_OF_LIVESTOCK (REVENUE INCREASES) 
					DR COST_OF_GOODS_LIVESTOCK (EXPENSE ASSOCIATED WITH REVENUE INCREASES). 
					
			natural increase:  NATURAL INCREASE IS AN ABSTRACT VALUE THAT IMPACTS THE LIVESTOCK_AT_MARKET_VALUE AT REPORT RUN TIME. THERE IS NO NEED TO STORE/SAVE THE VALUE IN THE LEDGER. WHEN A COW IS BORN, NO CASH CHANGES HAND. 
				dont: affect Assets_1203_Livestock_at_Cost by Natural_increase_cost_per_head as set by user
				
			loss?
			
			rations: 
				at what cost?
				DR OWNERS_EQUITY -->DRAWINGS. I.E. THE OWNER TAKES SOMETHING OF VALUE. Equity_3145_Drawings_by_Sole_Trader.
				CR COST_OF_GOODS. I.E. DECREASES COST.
          
average cost is defined for date and livestock type as follows:
	stock count and value at beginning of year is taken from beginning of year balance on:
		the livestock count account
		Assets_1203_Livestock_at_Cost, Assets_1204_Livestock_at_Average_Cost
	subsequent transactions until the given date are processed to get purchases count/value and natural increase count/value
	then we calculate:
		Natural_Increase_value is Natural_increase_count * Natural_increase_cost_per_head,
		Opening_and_purchases_and_increase_count is Stock_on_hand_at_beginning_of_year_count + Purchases_count + Natural_increase_count,
		Opening_and_purchases_and_increase_value is Stock_on_hand_at_beginning_of_year_value + Purchases_value + Natural_Increase_value,
		Average_cost is Opening_and_purchases_and_increase_value / Opening_and_purchases_and_increase_count,


</howThisShouldWork>

	
*/

:- ['transaction_types', 'accounts'].


livestock_account_ids('Livestock', 'LivestockAtCost', 'Drawings', 'LivestockRations').
expenses__direct_costs__purchases__account_id('Purchases').

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


% Gets the transaction_type term associated with the given transaction
transaction_type_of(Transaction_Types, S_Transaction, Transaction_Type) :-
	% get type id
	s_transaction_type_id(S_Transaction, Type_Id),
	% construct type term with parent variable unbound
	transaction_type_id(Transaction_Type, Type_Id),
	% match it with what's in Transaction_Types
	member(Transaction_Type, Transaction_Types).

	
	
% preprocess_s_transactions(Exchange_Rates, Transaction_Types, Input, Output).

preprocess_s_transactions(_, _, [], []).

% the case for livestock buy/sell:
% CR BANK (BANK BCE REDUCES) 
% DR Assets_1204_Livestock_at_Cost
%	produce a livestock count transaction 
preprocess_s_transactions(Exchange_Rates, Transaction_Types, [S_Transaction | S_Transactions], [Bank_Transaction, Livestock_Transaction, Assets_Transaction | Transactions]) :-
	S_Transaction = s_transaction(Day, Livestock_Units, Vector, Unexchanged_Account_Id, Bases),
	% bank statements are from the perspective of the bank, their debit is our credit
    vec_inverse(Vector, Vector_Inverted),
	
	% get what unit type was exchanged for the money
	Bases = vector([coord(Livestock_Units, _, _)]),
	account_ancestor_id(Livestock_Units, Livestock_Account),
	livestock_account_ids(Livestock_Account, Assets_1204_Livestock_at_Cost, _, _),
	
	% produce the bank account transaction
	Bank_Transaction = transaction(Day, "livestock buy/sell", Unexchanged_Account_Id, Vector_Inverted),
	% produce a livestock count increase/decrease transaction
	Livestock_Transaction = transaction(Day, "livestock buy/sell", Livestock_Account, Vector),
	% produce an assets transaction
	Assets_Transaction = transaction(Day, "livestock buy/sell", Assets_1204_Livestock_at_Cost, Vector_Inverted),
	preprocess_s_transactions(Exchange_Rates, Transaction_Types, S_Transactions, Transactions),
	!.

	
% trading account, non-livestock processing:
% Transactions using trading accounts can be decomposed into a transaction of the given
% amount to the unexchanged account, a transaction of the transformed inverse into the
% exchanged account, and a transaction of the negative sum of these into the trading
% account. This predicate takes a list of statement transactions (and transactions using trading
% accounts?) and decomposes it into a list of just transactions, 3 for each input s_transaction.
% This Prolog rule handles the case when the exchanged amount is known, for example 10 GOOG,
% and hence no exchange rate calculations need to be done.


preprocess_s_transactions(Exchange_Rates, Transaction_Types, [S_Transaction | S_Transactions],
		[UnX_Transaction | [X_Transaction | [Trading_Transaction | PP_Transactions]]]) :-

	s_transaction_vector(S_Transaction, Vector),
	s_transaction_exchanged(S_Transaction, vector(Vector_Transformed)),

	transaction_type_of(Transaction_Types, S_Transaction, Transaction_Type),
	
	% Make an unexchanged transaction to the unexchanged account
	s_transaction_day(S_Transaction, Day), 
	transaction_day(UnX_Transaction, Day),
	transaction_type_description(Transaction_Type, Description), 
	transaction_description(UnX_Transaction, Description),
	vec_inverse(Vector, Vector_Inverted), %?
	transaction_vector(UnX_Transaction, Vector_Inverted),
	s_transaction_account_id(S_Transaction, UnX_Account), 
	transaction_account_id(UnX_Transaction, UnX_Account),
	
	% Make an inverse exchanged transaction to the exchanged account
	transaction_day(X_Transaction, Day),
	transaction_description(X_Transaction, Description),
	transaction_vector(X_Transaction, Vector_Transformed),
	transaction_type_exchanged_account_id(Transaction_Type, X_Account), 
	transaction_account_id(X_Transaction, X_Account),
	
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
	s_transaction_exchanged(S_Transaction, bases(Bases)),
	s_transaction_day(S_Transaction, Day), 
	s_transaction_day(NS_Transaction, Day),
	s_transaction_type_id(S_Transaction, Type_Id), 
	s_transaction_type_id(NS_Transaction, Type_Id),
	s_transaction_vector(S_Transaction, Vector), 
	s_transaction_vector(NS_Transaction, Vector),
	s_transaction_account_id(S_Transaction, Unexchanged_Account_Id), 
	s_transaction_account_id(NS_Transaction, Unexchanged_Account_Id),
	% Do the exchange rate conversion and then proceed using the above rule where the
	% exchanged amount.
	vec_change_bases(Exchange_Rates, Day, Bases, Vector, Vector_Transformed),
	s_transaction_exchanged(NS_Transaction, vector(Vector_Transformed)),
	preprocess_s_transactions(Exchange_Rates, Transaction_Types, [NS_Transaction | S_Transactions], Transaction).


	
preprocess_livestock_event(Event, Transaction) :-
	Event = born(Type, Day, Count),
	Transaction = transaction(Day, 'born', Livestock_Account, [coord(Type, Count, 0)]),
	livestock_account_ids(Livestock_Account, _, _, _).

preprocess_livestock_event(Event, Transaction) :-
	Event = loss(Type, Day, Count),
	Transaction = transaction(Day, 'loss', Livestock_Account, [coord(Type, 0, Count)]),
	livestock_account_ids(Livestock_Account, _, _, _).

preprocess_livestock_event(Event, []) :-
	Event = rations(_,_,_).
	% will be processed later when all transactions are collected, need average cost		
	
preprocess_rations(Event, [Livestock_Transaction, Equity_Transaction, Cog_Transaction]) :-
	Event = rations(Type, Day, Count),
	Cost = 5,
	Livestock_Transaction = transaction(Day, 'rations', Livestock_Account, [coord(Type, 0, Count)]),
	% DR OWNERS_EQUITY -->DRAWINGS. I.E. THE OWNER TAKES SOMETHING OF VALUE. 
	Equity_Transaction = transaction(Day, "rations", Equity_3145_Drawings_by_Sole_Trader, [coord('AUD', Cost, 0)]),
	%	CR COST_OF_GOODS. I.E. DECREASES COST.
	Cog_Transaction = transaction(Day, "rations", Expenses__Direct_Costs__Livestock_Adjustments__Livestock_Rations, [coord('AUD', 0, Cost)]),
	livestock_account_ids(Livestock_Account, _Assets_Livestock_At_Cost_Account, Equity_3145_Drawings_by_Sole_Trader, Expenses__Direct_Costs__Livestock_Adjustments__Livestock_Rations),
	!.

preprocess_rations(_, []).
	


	
	
% end.
	
/* SCRAPS: */	
	
	
/*
livestock event types:
	dayEndCount 
	born        
	loss        
	rations     
*/
/*
preprocess_livestock_event(Event) :-
	

rations:
	Livestock_Account
	debit Equity_Drawings

born/loss
	Livestock_Account
	Assets_1204_Livestock_at_Average_Cost

		the inverse account:
                    {
                      "name": "Livestock at Cost",
                      "code": "1204",
                      "active": false
                    },
                    {

	
*/


/*
one livestock acount with transactions, vectors with different unit types


s_transactions ->
	livestock_events
	trade transactions

livestock_events ->
	livestock account transactions
	inventory value transactions
	equity transactions
	



Stock_on_hand_at_beginning_of_year_count for day
since beginning of year:
	purchases
	born









% Events is a list specific for one unit type

preprocess_livestock_events([E|Events], Count, TransactionsIn, TransactionsOut) :-
	preprocess_livestock_events(Events, CountBefore, TransactionsIn, TransactionsSoFar),
	(
		(
			Events = [],
			(
				E = count(Count, Cost)
			;
				throw("first event has to be day end count")
			),
			% put first transaction with this unit type into the livestock account
			append(TransactionsSoFar, [
				transaction(Day, 'livestock initial count', Livestock, [coord(Unit, Count, 0)]), 
				transaction(Day, 'livestock initial value', Assets_1204_Livestock_at_Cost, Cost)], 
				TransactionsOut)
			
			
		),!
		;
		(
			E = count(DayEndCount),
			(
				DayEndCount = Count,!;
				throw("DayEndCount != Count")
			),
			TransactionsIn = TransactionsOut
		)
	)
	;
	(
		(
			(E = buy(Count, Cost); E = sell(Count, Cost)) -> 
				T = [transaction(Day, 'livestock bought/sold', Livestock, Count),
					 transaction(Day, 'livestock bought/sold', Assets_1203_Livestock_at_Cost, Cost])
				]
			;
			(E = born(C); E = loss(C); E = rations(C)) ->
				average_cost(Day, TransactionsSoFar or Events?, Cost),
				T = [transaction(Day, 'livestock born/loss/rations', Livestock, C),
					 transaction(Day, 'livestock born/loss/rations', Assets_1204_Livestock_at_Average_Cost, Cost])
				]
		),
		append(TransactionsSoFar, T, TransactionsOut),
		Count is CountBefore + C
	).
	
preprocess_livestock_events([], not_used).




% here we just simply count livestock units

livestock_count(Events, UnitType, EndDay, Count) :-
	filter_events(Events, UnitType, EndDay, FilteredEvents),
	livestock_count(FilteredEvents, Count).

% Events is a list specific for one unit type

livestock_count([E|Events], Count) :-
	livestock_count(Events, CountBefore),
	(
		(
			Events = [],
			(
				E = count(Count)
			;
				throw("first event has to be day end count")
			),
		),!
		;
		(
			E = count(DayEndCount),
			(
				DayEndCount = Count,!;
				throw("DayEndCount != Count")
			)
		)
	)
	;
	(
		(
			E = buy(C);
			E = sell(C);
			E = born(C);
			E = loss(C);
			E = rations(C);
		),
		Count is CountBefore + C
	).
	
livestock_count([], not_used).
*/
/*

Expenses_5107_Opening_Inventory__Inventory_at_Cost__Livestock_at_Cost
*/

/*
we avoid count/opening balance for now:
		"count" has to be the first livestock-related event, by date. OK
			actually i have opted for "day end count", to avoid ambiguity. OK
		it is possible to insert another "day end count" at any point for verification purpose. VERIFICATION MUST BE AGAINST AN EXTERNAL LIVESTOCK CALCULATOR I.E. AS PER THE STAND ALONE CALCULATOR YOU ALREADY BUILT. THIS IS THE CRUX OF THE WHOLE PROJECT - VERIFICATION OF FACTS FROM DIFFERENT PERSPECTIVES.
*/


/*fixme: first let us go through all transactions and tag these as an action such as "livestock_sell", 
then try to use the action taxonomy format with exchange account to define this*/
/*
tag_s_transactions([], []).

tag_s_transactions([S_Transaction | S_Transactions], [Tagged | Taggeds]) :-
	s_transaction_type_id(S_Transaction, Type_Id),
	nonvar(Type_Id),
	Tagged = S_Transaction,
	tag_s_transactions(S_Transactions, Taggeds),!.

tag_s_transactions([S_Transaction | S_Transactions], [Tagged | Taggeds]) :-
	% get what unit type was exchanged for the money
	s_transaction_exchanged(S_Transaction, vector([coord(Unit, _, _)])),
	member(Livestock_Units, Unit),
	account_ancestor_id(Accounts, Unit, Livestock),
	S_Transaction = s_transaction(Day, _Type_Id, Vector, Unexchanged_Account_Id, Bases)
	Tagged			= s_transaction(Day, Type_Id, Vector, Unexchanged_Account_Id, Bases)

	*/
	/*
		internal:
		buy,sell
*/
/*

livestock_s_transaction_to_transaction(S_Transaction, UnX_Transaction) :-
	s_transaction_day(S_Transaction, Day), 
	transaction_day(UnX_Transaction, Day),
	transaction_description(UnX_Transaction, "livestock buy/sell"),
	s_transaction_vector(S_Transaction, Vector),
	transaction_vector(S_Transaction, Vector),
	s_transaction_account_id(S_Transaction, UnX_Account), 
	transaction_account_id(UnX_Transaction, UnX_Account).


	    vec_inverse(Vector, Vector_Inverted),

*/

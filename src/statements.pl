% this is a version of statements.pl where i am adding livestock functionality. work in progress.
% see doc/ledger-livestock

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
				at average cost
				DR OWNERS_EQUITY -->DRAWINGS. I.E. THE OWNER TAKES SOMETHING OF VALUE. Equity_3145_Drawings_by_Sole_Trader.
				CR COST_OF_GOODS. I.E. DECREASES COST.
		
		
		
fixme:		
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
cost_of_goods_livestock_account_id('CostOfGoodsLivestock').


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


	
	
s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, Livestock_Coord, Vector, Vector_Inverted, Unexchanged_Account_Id, MoneyDebit) :-
	S_Transaction = s_transaction(Day, "", Vector, Unexchanged_Account_Id, Bases),
	% todo: exchange Vector to the currency that the report is requested for
	
	% bank statements are from the perspective of the bank, their debit is our credit
	vec_inverse(Vector, Vector_Inverted),
	Vector_Inverted = [coord(_, MoneyDebit, MoneyCredit)],
	
	% get what unit type was exchanged for the money
	Bases = vector([coord(Livestock_Type, Livestock_Count_Input, Livestock_Credit)]),
	assertion(Livestock_Credit == 0),
	Livestock_Count is abs(Livestock_Count_Input),
	
	(MoneyDebit > 0 ->
		(
			assertion(MoneyCredit == 0),
			Livestock_Coord = coord(Livestock_Type, 0, Livestock_Count)
		);
		Livestock_Coord = coord(Livestock_Type, Livestock_Count, 0)
	).


	
	
	
% preprocess_s_transactions(Exchange_Rates, Transaction_Types, Input, Output).

preprocess_s_transactions(_, _, _, [], []).

% the case for livestock buy/sell:
% BUY:
	% CR BANK (BANK BCE REDUCES) 
	% DR Assets_1204_Livestock_at_Cost
% SELL:
	% DR BANK (BANK BCE INCREASES) 
	% CR Assets_1204_Livestock_at_Cost (STOCK ON HAND DECREASES,VALUE HELD DECREASES), 
	% CR SALES_OF_LIVESTOCK (REVENUE INCREASES) 
	% DR COST_OF_GOODS_LIVESTOCK (EXPENSE ASSOCIATED WITH REVENUE INCREASES). 
%	and produce a livestock count transaction 
preprocess_s_transactions(Accounts, Exchange_Rates, Transaction_Types, [S_Transaction | S_Transactions], [Bank_Transaction, Livestock_Transaction, Assets_Transaction | Transactions]) :-
	
	s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, Livestock_Coord, Vector, Vector_Inverted, Unexchanged_Account_Id, MoneyDebit),
	
	livestock_account_ids(Livestock_Account, Assets_1204_Livestock_at_Cost, _, _),
	account_ancestor_id(Accounts, Livestock_Type, Livestock_Account),

	(MoneyDebit > 0 ->
		(
			Description = "livestock sell"
			% sales transactions will be generated in next pass
		)
		;
		(
			Description = "livestock buy"
		)
	),
	
	% produce a livestock count increase/decrease transaction
	Livestock_Transaction = transaction(Day, Description, Livestock_Account, [Livestock_Coord]),
	% produce the bank account transaction
	Bank_Transaction = transaction(Day, Description, Unexchanged_Account_Id, Vector_Inverted),
	% produce an assets transaction
	Assets_Transaction = transaction(Day, Description, Assets_1204_Livestock_at_Cost, Vector	),

	preprocess_s_transactions(Accounts, Exchange_Rates, Transaction_Types, S_Transactions, Transactions),
	!.

	
% trading account, non-livestock processing:
% Transactions using trading accounts can be decomposed into a transaction of the given
% amount to the unexchanged account, a transaction of the transformed inverse into the
% exchanged account, and a transaction of the negative sum of these into the trading
% account. This predicate takes a list of statement transactions (and transactions using trading
% accounts?) and decomposes it into a list of just transactions, 3 for each input s_transaction.
% This Prolog rule handles the case when the exchanged amount is known, for example 10 GOOG,
% and hence no exchange rate calculations need to be done.


preprocess_s_transactions(Accounts, Exchange_Rates, Transaction_Types, [S_Transaction | S_Transactions],
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
	preprocess_s_transactions(Accounts, Exchange_Rates, Transaction_Types, S_Transactions, PP_Transactions), !.

% This Prolog rule handles the case when only the exchanged amount units are known (for example GOOG)  and
% hence it is desired for the program to do an exchange rate conversion. 
% We passthrough the output list to the above rule, and just replace the first transaction in the 
% input list (S_Transaction) with a modified one (NS_Transaction).


preprocess_s_transactions(Accounts, Exchange_Rates, Transaction_Types, [S_Transaction | S_Transactions], Transaction) :-
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
	preprocess_s_transactions(Accounts, Exchange_Rates, Transaction_Types, [NS_Transaction | S_Transactions], Transaction).


	
/*
Births debit inventory (asset) and credit cost of goods section, lowering cost of goods value at a rate ascribed by the tax office $20/head of sheep and/or at market rate ascribed by the farmer. It will be useful to build the reports under both inventory valuation conditions.
*/
preprocess_livestock_event(Event, Transaction) :-
	Event = born(Type, Day, Count),
	Transaction = transaction(Day, 'livestock born', Livestock_Account, [coord(Type, Count, 0)]),
	livestock_account_ids(Livestock_Account, _, _, _).

preprocess_livestock_event(Event, Transaction) :-
	Event = loss(Type, Day, Count),
	Transaction = transaction(Day, 'livestock loss', Livestock_Account, [coord(Type, 0, Count)]),
	livestock_account_ids(Livestock_Account, _, _, _).

preprocess_livestock_event(Event, []) :-
	Event = rations(_,_,_).
	% will be processed later when all transactions are collected, need average cost		
	
	
/*
Rations debit an equity account called drawings of a sole trader or partner, 
debit asset or liability loan account  of a shareholder of a company or beneficiary of a trust.  


Naming conventions of accounts created in end user systems vary and the loans might be current or non current but otherwise the logic should hold perfectly on the taxonomy and logic model. (hence requirement to classify).

A sole trade is his own person so his equity is in his own right, hence reflects directly in equity.

The differences relate to personhood. Trusts & companies have attained some type of personhood while sole traders & partners in partnerships are their own people. Hence the trust or company owes or is owed by the shareholder or beneficiary.
*/
preprocess_rations(Livestock_Type, Cost, Event, Output) :-
	Event = rations(Livestock_Type, Day, Count) ->
	(
		Output = [Livestock_Transaction, Equity_Transaction, Cog_Transaction],
		Livestock_Transaction = transaction(Day, 'rations', Livestock_Account, [coord(Livestock_Type, 0, Count)]),
		% DR OWNERS_EQUITY -->DRAWINGS. I.E. THE OWNER TAKES SOMETHING OF VALUE. 
		Equity_Transaction = transaction(Day, "rations", Equity_3145_Drawings_by_Sole_Trader, [coord('AUD', Cost, 0)]),
		%	CR COST_OF_GOODS. I.E. DECREASES COST.
		Cog_Transaction = transaction(Day, "rations", Expenses__Direct_Costs__Livestock_Adjustments__Livestock_Rations, [coord('AUD', 0, Cost)]),
		livestock_account_ids(Livestock_Account, _Assets_Livestock_At_Cost_Account, Equity_3145_Drawings_by_Sole_Trader, Expenses__Direct_Costs__Livestock_Adjustments__Livestock_Rations)
	);
	Output = [].


preprocess_sales(Livestock_Type, _Average_cost, [S_Transaction | S_Transactions], [Sales_Transactions | Transactions_Tail]) :-
	s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, _Livestock_Coord, Vector, _, _, MoneyDebit),

	(MoneyDebit > 0 ->
		(
			Description = "livestock sell",
			/*(
				coord(_, 0, Livestock_Count) = Livestock_Coord
				% Cost_Of_Goods_Sold is Average_cost * Livestock_Count
			),*/
			Sales_Transactions = [
				transaction(Day, Description, 'SalesOfLivestock', Vector)
				% transaction(Day, Description, 'CostOfGoodsLivestock', [coord('AUD', Cost_Of_Goods_Sold, 0)])
			]
		)
		;
			Sales_Transactions = []
	),
	preprocess_sales(Livestock_Type, _, S_Transactions, Transactions_Tail).
				
preprocess_sales(_, _, [], []).


average_cost(Type, S_Transactions, Livestock_Events, Natural_increase_costs, Exchange_rate) :-
	/*
	all transactions are processed to get purchases count/value and natural increase count/value
	opening balances are ignored for now, and all transactions are used, no date limit.
	*/
	livestock_purchases_cost_and_count(Type, S_Transactions, Purchases_cost, Purchases_count),
	member(natural_increase_cost(Type, Natural_increase_cost_per_head), Natural_increase_costs),
	natural_increase_count(Type, Livestock_Events, Natural_increase_count),
	vec_add([], Purchases_cost, Opening_and_purchases_value),
	vec_add(Opening_and_purchases_value, [coord('AUD', Natural_Increase_value)], Opening_And_Purchases_And_Increase_Value_Vector),

	(Opening_And_Purchases_And_Increase_Value_Vector = []
	-> Opening_And_Purchases_And_Increase_Value_Vector = [coord('AUD', 0, 0)]),
	
	(
		Opening_And_Purchases_And_Increase_Value_Vector = [coord('AUD', 0, Opening_And_Purchases_And_Increase_Value)]
		->
		(
			Natural_Increase_value is Natural_increase_count * Natural_increase_cost_per_head,
			Opening_and_purchases_and_increase_count is Purchases_count + Natural_increase_count,
			(Opening_and_purchases_and_increase_count > 0 ->
					Average_cost is 
						Opening_And_Purchases_And_Increase_Value /  Opening_and_purchases_and_increase_count
				;
					Average_cost = 0),
			Exchange_rate = exchange_rate(_, Type, 'AUD', Average_cost)
		)
		;
		(
			print_term(Opening_And_Purchases_And_Increase_Value_Vector, []),
			throw("fixme")
		)
	).

% natural increase count given livestock type and all livestock events
natural_increase_count(Type, [E | Events], Natural_increase_count) :-
	(E = born(Type, _Day, Count) ->
		C = Count;
		C = 0),
	natural_increase_count(Type, Events, Natural_increase_count_1),
	Natural_increase_count is Natural_increase_count_1 + C.
	
natural_increase_count(_, [], 0).



livestock_purchases_cost_and_count(Type, [ST | S_Transactions], Purchases_cost, Purchases_count) :-
	(
		(
			s_transaction_is_livestock_buy_or_sell(ST, _Day, Type, Livestock_Coord, _, Vector_Ours, _, _),
			Vector_Ours = [coord(_, 0, Cost)]
		)
		->
		(
			Livestock_Coord = coord(Type, Count, 0),
			Cost = Vector_Ours
		)
		;
		(
			Cost = [], Count = 0
		)
	),
	livestock_purchases_cost_and_count(Type, S_Transactions, Purchases_cost_2, Purchases_count_2),
	vec_add(Cost, Purchases_cost_2, Purchases_cost),
	Purchases_count is Purchases_count_2 + Count.

livestock_purchases_cost_and_count(_, [], [], 0).







	

% see also doc/ledger-livestock

/*

<howThisShouldWork>

account taxonomy must include accounts for individual livestock types


a list of livestock units will be defined in the sheet, for example "cows, horses".
FOR CURRENT ITERATION, ASSUME THAT ALL TRANSACTIONS ARE IN THE BANK STATEMENT. I.E. NO OPENING BALANCES.WHY? BECAUSE OPENING BALANCES IN LIVESTOCK WILL REQUIRE A COMPLETE SET OF OPENING BALANCES. I.E. A COMPLETE OPENING BALANCE SHEET. 
	
Natural_Increase_Cost_Per_Head has to be input for each livestock type, for example cows $20.

when bank statements are processed: 
	If there is a livestock unit ("cows") set on a bank account transaction:
		count has to be set to ("20"). 
		
		maybe todo:
			internally, we tag the transaction with a sell/buy livestock action type. 
			user should have sell/buy livestock action types in their action taxonomy.
			the "exchanged" account will be one where livestock increase/decrease transactions are internally collected. 
		
		SYSTEM CAN INFER BUY/SELL i.e. A BUY IS A PAYMENT & A SELL IS A DEPOSIT. OF COURSE, THE UNIT TYPE MUST BE DESCRIBED. COW. PIG, ETC. AND THE UNIT TYPE MUST HAVE AN ACCOUNTS TAXONOMICAL RELATIONSHIP

		
		maybe todo:
			internally, livestock buys and sells are transformed into "livestock buy/sell events" OK.
		
		one excel sheet for bank statement, one for each livestock type: natural increase, loss, rations..
				
		all livestock event types change the count accordingly.
		livestock events have effects on other accounts beside the livestock count account:
			buy/sell:
				cost is taken from the bank transaction

	
				SELL - 
					DR BANK (BANK BCE INCREASES) 
					CR Assets_1204_Livestock_at_Cost (STOCK ON HAND DECREASES,VALUE HELD DECREASES), 
					CR SALES_OF_LIVESTOCK (REVENUE INCREASES) 
					DR COST_OF_GOODS_LIVESTOCK (EXPENSE ASSOCIATED WITH REVENUE INCREASES). 
						by average cost?
					
			natural increase:  NATURAL INCREASE IS AN ABSTRACT VALUE THAT IMPACTS THE LIVESTOCK_AT_MARKET_VALUE AT REPORT RUN TIME. THERE IS NO NEED TO STORE/SAVE THE (monetary) VALUE IN THE LEDGER. WHEN A COW IS BORN, NO CASH CHANGES HAND. 
				dont: affect Assets_1203_Livestock_at_Cost by Natural_Increase_Cost_Per_Head as set by user
				
			loss?
			
	
		
fixme:		
average cost is defined for date and livestock type as follows:
	stock count and value at beginning of year is taken from beginning of year balance on:
		the livestock count account
		Assets_1203_Livestock_at_Cost, Assets_1204_Livestock_at_Average_Cost
	subsequent transactions until the given date are processed to get purchases count/value and natural increase count/value
	then we calculate:
		Natural_Increase_value is Natural_Increase_Count * Natural_Increase_Cost_Per_Head,
		Opening_And_Purchases_And_Increase_Count is Stock_on_hand_at_beginning_of_year_count + Purchases_Count + Natural_Increase_Count,
		Opening_and_purchases_and_increase_value is Stock_on_hand_at_beginning_of_year_value + Purchases_value + Natural_Increase_value,
		Average_Cost is Opening_and_purchases_and_increase_value / Opening_And_Purchases_And_Increase_Count,


</howThisShouldWork>

	
*/


:- module(llivestock, [get_livestock_types/2, process_livestock/9]).
:- use_module(utils, []).



% BUY/SELL:
	% CR/DR BANK (BANK BCE REDUCES) 
    %	and produce a livestock count transaction 
preprocess_livestock_buy_or_sell(Accounts, _Exchange_Rates, _Transaction_Types, S_Transaction, [Bank_Transaction, Livestock_Transaction]) :-
	s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, Livestock_Coord, _Livestock_Count, _Bank_Vector, Our_Vector, Unexchanged_Account_Id, MoneyDebit, _),
	account_ancestor_id(Accounts, Livestock_Type, _Livestock_Account),
	(MoneyDebit > 0 ->
			Description = 'livestock sell'
		;
			Description = 'livestock buy'
	),
	% produce a livestock count increase/decrease transaction
	Livestock_Transaction = transaction(Day, Description, Livestock_Type, [Livestock_Coord]),
	% produce the bank account transaction
	Bank_Transaction = transaction(Day, Description, Unexchanged_Account_Id, Our_Vector).

/*
BUY - 
	DR assets / current assets / inventory on hand / livestock at cost - 	this is our LivestockAtCost or Assets_1204_Livestock_at_Cost.
*/
	
preprocess_buys2(Day, Livestock_Type, Bank_Vector, Buy_Transactions) :-
	% DR expenses / direct costs / purchases - but maybe this should be done at the time of sale
	Buy_Transactions = [
		% transaction(Day, 'livestock buy', 'Purchases', Bank_Vector),
		transaction(Day, 'livestock buy', 'AssetsLivestockAtCost', Bank_Vector),
		transaction(Day, 'livestock buy', Cogs_Account, Bank_Vector)
	],
	cogs_account(Livestock_Type, Cogs_Account).
/*
preprocess_buys2(Day, Livestock_Type, Bank_Vector, Buy_Transactions) :-
	Buy_Transactions = [
		transaction(Day, 'livestock buy', Cogs_Account, Bank_Vector)
		% produce an assets transaction
		transaction(Day, 'livestock buy', 'AssetsLivestockAtCost', Bank_Vector).
		],
	cogs_account(Livestock_Type, Cogs_Account).
*/
	

% SELL:
% CR Assets_1204_Livestock_at_Cost (STOCK ON HAND DECREASES,VALUE HELD DECREASES), 
%	? just keeps decreasing?
% CR SALES_OF_LIVESTOCK (REVENUE INCREASES) 
% DR COST_OF_GOODS_LIVESTOCK (EXPENSE ASSOCIATED WITH REVENUE INCREASES). 
	
preprocess_sales2(Day, Livestock_Type, _Average_Rate, _Livestock_Count, Bank_Vector, Sales_Transactions) :-
	Description = "livestock sell",
	%exchange_rate(_, _, Currency, Average_Cost_Per_Head) = Average_Rate,
	%Average_Cost is Livestock_Count * Average_Cost_Per_Head,
	%Average_Cost_Vector = [coord(Currency, Average_Cost, 0)],
	%vec_inverse(Average_Cost_Vector, Cost),
	vec_inverse(Bank_Vector, Ours_Vector),
	Sales_Transactions = [
		transaction(Day, Description, 'AssetsLivestockAtCost', Ours_Vector),
		transaction(Day, Description, Sales_Account, Bank_Vector)
		%transaction(Day, Description, Cogs_Account, Cost)
	],
	sales_account(Livestock_Type, Sales_Account).
	%cogs_account(Livestock_Type, Cogs_Account).
	

	
/*
Rations debit an equity account called drawings of a sole trader or partner, 
debit asset or liability loan account  of a shareholder of a company or beneficiary of a trust.  

Naming conventions of accounts created in end user systems vary and the loans might be current or non current but otherwise the logic should hold perfectly on the taxonomy and logic model. (hence requirement to classify).

A sole trade is his own person so his equity is in his own right, hence reflects directly in equity.

The differences relate to personhood. Trusts & companies have attained some type of personhood while sole traders & partners in partnerships are their own people. Hence the trust or company owes or is owed by the shareholder or beneficiary.

liabilities / benificiaries
equity / loans to associated persons
equity / drawings by sole trader
equity / partners equity / drawings

at average cost:
	DR OWNERS_EQUITY -->DRAWINGS. I.E. THE OWNER TAKES SOMETHING OF VALUE. 
	CR COST_OF_GOODS. I.E. DECREASES COST.

*/

preprocess_rations2(Day, Cost, Currency, Equity_3145_Drawings_by_Sole_Trader, Output) :- 
	Output = [
		% DR OWNERS_EQUITY -->DRAWINGS. I.E. THE OWNER TAKES SOMETHING OF VALUE. 
		transaction(Day, 'rations', Equity_3145_Drawings_by_Sole_Trader, [coord(Currency, Cost, 0)]),
		%	CR COST_OF_GOODS. I.E. DECREASES COST.
		% expenses / cost of goods / stock adjustment
		% transaction(Day, 'rations', 'ExpensesCogsLivestockAdjustment', [coord(Currency, 0, Cost)])].
		transaction(Day, 'rations', 'RationsRevenue', [coord(Currency, 0, Cost)])].
/*
preprocess_rations2(Day, Cost, Currency, Equity_3145_Drawings_by_Sole_Trader, Output), 
	Output = [
		% DR OWNERS_EQUITY -->DRAWINGS. I.E. THE OWNER TAKES SOMETHING OF VALUE. 
		transaction(Day, 'rations', Equity_3145_Drawings_by_Sole_Trader, [coord(Currency, Cost, 0)]),
		%	CR COST_OF_GOODS. I.E. DECREASES COST.
		transaction(Day, 'rations', 'RationsRevenue', [coord(Currency, 0, Cost)])].
*/


yield_livestock_cogs_transactions(
	Livestock_Type, 
	Opening_Cost, Opening_Count, _Average_Cost,
	(_From_Day, To_Day, Bases, Average_Costs, Input_Transactions, _S_Transactions),
	Cogs_Transactions) :-
		
		balance_by_account(Average_Costs, [], Input_Transactions, Bases,  _Exchange_Day, Livestock_Type, To_Day, Closing_Debit0),
		% balance_by_account does not know obout opening balance, so we add it at average cost to closing balance here for now:
		[exchange_rate(_, _, _, AC)] = Average_Costs,
		Cost is AC * Opening_Count,
		vec_add(Closing_Debit0, [coord('AUD', Cost, 0)], Closing_Debit),
		
		vec_inverse(Closing_Debit, Closing_Credit),
		Cogs_Transactions = [
			% maybe do as one difference transaction
			transaction(To_Day, "livestock closing value for period", 'LivestockClosing', Closing_Credit),
			transaction(To_Day, "livestock opening value for period", 'LivestockOpening', Opening_Cost)
		].

/*
yield_livestock_cogs_transactions(
	Livestock_Type, 
	(Day, Average_Costs, Input_Transactions, S_Transactions),
	Cogs_Transaction) :-
		livestock_purchases_cost_and_count(Livestock_Type, S_Transactions, Purchases_cost, _Purchases_count) ,
		balance_by_account(Average_Costs, [], Input_Transactions, ['AUD'], _Exchange_Day, Livestock_Type, Day, Closing_Cost),
		vec_sub(Purchases_cost, Closing_Cost, Cogs_Credit),
		vec_inverse(Cogs_Credit, Cogs),
		cogs_account(Livestock_Type, CogsAccount),
		Cogs_Transaction = transaction(Day, "livestock COGS for period", CogsAccount, Cogs).
*/
		

/*
Births debit inventory (asset) and credit cost of goods section, lowering cost of goods value at a rate ascribed by the tax office $20/head of sheep and/or at market rate ascribed by the farmer. It will be useful to build the reports under both inventory valuation conditions.
*/

	



/*
[6/3/2019 4:13:59 PM] Jindrich Kolman: ok, so i will just add these values to revenue and expenses once the accounts are totalled

[6/3/2019 4:14:02 PM] ANDREW NOBLE: So do all your transactions via Assets (Stock on Hand), Equity (Owners Drawings), Revenue (Sales), Expenses (COGS)

[6/3/2019 4:15:01 PM] ANDREW NOBLE: You'll know if your accounts are correct because they will equal the Livestock Calculator

[6/3/2019 4:16:25 PM] ANDREW NOBLE: There must be a credit for every debit

[6/3/2019 4:16:36 PM] ANDREW NOBLE: Debit Bank, Credit Sales

[6/3/2019 4:17:01 PM] ANDREW NOBLE: Credit Bank, Debit Cost of Goods Sold ((in case of a purchase)

[6/3/2019 4:19:10 PM] ANDREW NOBLE: Cost of Goods Sold is an expense account that includes various debits & credits from purchases, rations and stock adjustments

[6/3/2019 4:19:53 PM] Jindrich Kolman: so natural increase should be reflected in stock adjustments?

[6/3/2019 4:20:49 PM] ANDREW NOBLE: yes

[6/3/2019 4:21:07 PM] ANDREW NOBLE: and natural deaths too

[6/3/2019 4:21:45 PM] Jindrich Kolman: ok, so not COGS, but an expense like COGS

[6/3/2019 4:21:50 PM] ANDREW NOBLE: Rations are different

[6/3/2019 4:22:26 PM] ANDREW NOBLE: Cost of Good Sold = opening stock +purchases -closing stock.

[6/3/2019 4:23:10 PM] ANDREW NOBLE: natural deaths & births simply impact the value of closing stock via the average cost calc

[6/3/2019 4:23:53 PM] ANDREW NOBLE: COGS = Cost of Goods Sold

[6/3/2019 4:25:20 PM] Jindrich Kolman: well, in your accounts.json, livestock adjustments are expenses/direct costs, not part of 
closing stock

[6/3/2019 4:26:02 PM] Jindrich Kolman: so i am afraid i still dont understand anything

[6/3/2019 4:28:09 PM] ANDREW NOBLE: Rations should be there.

[6/3/2019 4:29:31 PM] ANDREW NOBLE: i.e. Dr Drawings, Cr Rations

[6/3/2019 4:30:53 PM] ANDREW NOBLE: Births & deaths should not be there.

Once inventory value is discovered, simply post the difference to COGS.

So if opening inventory is 10 & closing inventory is 15, then Dr Closing Stock 5 & Credit COGS 5

If instead closing inventory is 7, then Cr Closing Inventory 3 & Dr COGS 3

Sorry ... Closing Inventory & Closing Stock are the same thing.
  ( Expenses / Direct Costs / Closing Inventory / Livestock at (Average) Cost )

just remember that COGS is a composite set of accounts
  
https://www.accountingcoach.com/blog/cost-of-goods-sold-2
Definition of Cost of Goods Sold The cost of goods sold is the cost of the products that a retailer, distributor, or manufacturer has sold. The cost of goods sold is reported on the income statement and should be viewed as an expense of the accounting period. In essence, the cost of goods sold is...

https://docplayer.net/37691180-This-article-sets-out-how-to-enter-livestock-data-into-handiledger.html
HandiLedger Livestock: Data Entry Livestock Data Entry This article sets out how to enter livestock data into HandiLedger. Entering the data in HandiLedger Note: The use of account codes in relation to...
   
   
*/

/*





expenses / direct costs / opening inventory
expenses / direct costs / closing inventory
expenses / direct costs / livestock adjustments
expenses / direct costs / purchases
revenue / trading revenue
assets / inventory on hand




*/
	

	
	
	


/*

another method 1:

buy at cost:
	dr assets / inventory
	cr bank

sell:
	dr expenses cog lifo/fifo price?
	cr assets / inventory
	cr revenue sale price
	cr equity / current earnings (sale price - cog)
	dr assets / cash









assets / inventory
	debited with opening value
	no intermediate txs
	credited with opening value
	(debited with closing value)

(profit and loss)
expenses / direct costs / opening (closing) / inventory at cost / livestock at (average) cost






*/



% WRAPPERS AND UTILITIES:


preprocess_buys(_, _, [], []).

preprocess_buys(Livestock_Type, _Average_cost, [S_Transaction | S_Transactions], [Buy_Transactions | Transactions_Tail]) :-
	s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, _Livestock_Coord, _Livestock_Count, Bank_Vector, _, _, _, MoneyCredit),
	(MoneyCredit > 0 ->
		(
			preprocess_buys2(Day, Livestock_Type, Bank_Vector, Buy_Transactions)
		)
		;
			Buy_Transactions = []
	),
	preprocess_buys(Livestock_Type, _, S_Transactions, Transactions_Tail).


s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, Livestock_Coord, Livestock_Count, Bank_Vector, Our_Vector, Unexchanged_Account_Id, MoneyDebit, MoneyCredit) :-
	S_Transaction = s_transaction(Day, "", Bank_Vector, Unexchanged_Account_Id, Bases),
	% todo: exchange Vector to the currency that the report is requested for
	
	% bank statements are from the perspective of the bank, their debit is our credit
	vec_inverse(Bank_Vector, Our_Vector),
	[coord(_, MoneyDebit, MoneyCredit)] = Our_Vector,
	
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


livestock_account_ids('Livestock', 'LivestockAtCost', 'Drawings', 'LivestockRations').
expenses__direct_costs__purchases__account_id('Purchases').
cost_of_goods_livestock_account_id('CostOfGoodsLivestock').




preprocess_livestock_event(Event, Transaction) :-
	Event = born(Type, Day, Count),
	Transaction = transaction(Day, 'livestock born', Type, [coord(Type, Count, 0)]).
	
preprocess_livestock_event(Event, Transaction) :-
	Event = loss(Type, Day, Count),
	Transaction = transaction(Day, 'livestock loss', Type, [coord(Type, 0, Count)]).
	
preprocess_livestock_event(Event, Transaction) :-
	Event = rations(Type, Day, Count),
	Transaction = transaction(Day, 'livestock rations', Type, [coord(Type, 0, Count)]).
	

	
% natural increase count given livestock type and all livestock events
natural_increase_count(Type, [E | Events], Natural_Increase_Count) :-
	(E = born(Type, _Day, Count) ->
		C = Count;
		C = 0),
	natural_increase_count(Type, Events, Natural_Increase_Count_1),
	Natural_Increase_Count is Natural_Increase_Count_1 + C.
	
natural_increase_count(_, [], 0).



livestock_purchases_cost_and_count(Type, [ST | S_Transactions], Purchases_Cost, Purchases_Count) :-
	(
		(
			s_transaction_is_livestock_buy_or_sell(ST, _Day, Type, Livestock_Coord, _, _, Vector_Ours, _, _, _),
			Vector_Ours = [coord(_, 0, _)]
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
	livestock_purchases_cost_and_count(Type, S_Transactions, Purchases_Cost_2, Purchases_Count_2),
	vec_add(Cost, Purchases_Cost_2, Purchases_Cost),
	Purchases_Count is Purchases_Count_2 + Count.

livestock_purchases_cost_and_count(_, [], [], 0).



/*
The Livestock calculator is an average cost calculator. 
Cost, average cost, market value. 
There may be other ways of measuring value. But any way is simply units held at some time point * defined value. 
Think about what any asset is worth?
Unless you sell it you don't really know
You have to estimate.
*/
average_cost(Type, Opening_Cost0, Opening_Count0, Info, Exchange_Rate) :-
	Info = (_From_Day, _To_Day, S_Transactions, Livestock_Events, Natural_Increase_Costs),
	/*
	for now, we ignore _From_Day (and _To_Day), 
	and use Opening_Cost and Opening_Count as stated in the request.
	*/
	Exchange_Rate = with_info(exchange_rate(_, Type, Currency, Average_Cost), Explanation),
	Explanation = {formula: Formula_String1, computation: Formula_String2},
	
	compile_with_variable_names_preserved((
		Natural_Increase_Value = Natural_Increase_Cost_Per_Head * Natural_Increase_Count,
		Opening_And_Purchases_And_Increase_Value_Exp = Opening_Value + Purchases_Value + Natural_Increase_Value,
		Opening_And_Purchases_And_Increase_Count_Exp = Opening_Count + Purchases_Count + Natural_Increase_Count,
		Average_Cost_Exp = Opening_And_Purchases_And_Increase_Value_Exp //  Opening_And_Purchases_And_Increase_Count_Exp
	),	Names1),
	%	replace_underscores_in_variable_names_with_spaces(Names0, Names1),
    
    term_string(Average_Cost_Exp, Formula_String1, [Names1]),
	%pretty_term_string(Average_Cost_Exp, Formula_String1, [Namings]),

	% now let's fill in the values
	Opening_Cost = Opening_Cost0,
	Opening_Count = Opening_Count0,
	[coord(Currency, Opening_Value, 0)] = Opening_Cost, 
	member(natural_increase_cost(Type, [coord(Currency, Natural_Increase_Cost_Per_Head, 0)]), Natural_Increase_Costs),
	natural_increase_count(Type, Livestock_Events, Natural_Increase_Count),
	livestock_purchases_cost_and_count(Type, S_Transactions, [coord(Currency, 0, Purchases_Value)], Purchases_Count),

	pretty_term_string(Average_Cost_Exp, Formula_String2),
	
	% avoid division by zero and evaluate the formula
	Opening_And_Purchases_And_Increase_Count is Opening_And_Purchases_And_Increase_Count_Exp,
	(Opening_And_Purchases_And_Increase_Count > 0 ->
		Average_Cost is Average_Cost_Exp
	;
		Average_Cost = 0
	).


preprocess_rations(Livestock_Type, Average_Cost, Event, Output) :-
	Event = rations(Livestock_Type, Day, Count) ->
	(
		exchange_rate(_, _, Currency, Average_Cost_Per_Head) = Average_Cost,
		Cost is Average_Cost_Per_Head * Count,
		preprocess_rations2(Day, Cost, Currency, Equity_3145_Drawings_by_Sole_Trader, Output), 
		livestock_account_ids(
			_Livestock_Account,
			_Assets_Livestock_At_Cost_Account, 
			Equity_3145_Drawings_by_Sole_Trader, _Expenses__Direct_Costs__Livestock_Adjustments__Livestock_Rations
		)
	);
	Output = [].

	
preprocess_sales(Livestock_Type, Average_cost, [S_Transaction | S_Transactions], [Sales_Transactions | Transactions_Tail]) :-
	s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, _Livestock_Coord, Livestock_Count, Bank_Vector, _, _, MoneyDebit, _),

	(MoneyDebit > 0 ->
		(
			preprocess_sales2(Day, Livestock_Type, Average_cost, Livestock_Count, Bank_Vector, Sales_Transactions)
		)
		;
			Sales_Transactions = []
	),
	preprocess_sales(Livestock_Type, Average_cost, S_Transactions, Transactions_Tail).
				
preprocess_sales(_, _, [], []).




/*

We want both a stand-alone calculator and include the logic in the ledger system i.e. If there are livestock, allow for inclusion of head held at time x and price y. Births, Rations, Deaths must also be considered via a buy or sell from the bank.


Rations debit an equity account called drawings of a sole trader or partner, debit asset or liability loan account  of a shareholder of a company or beneficiary of a trust.  Naming conventions of accounts created in end user systems vary and the loans might be current or non current but otherwise the logic should hold perfectly on the taxonomy and logic model. (hence requirement to classify).

A sole trade is his own person so his equity is in his own right, hence reflects directly in equity.

The differences relate to personhood. Trusts & companies have attained some type of personhood while sole traders & partners in partnerships are their own people. Hence the trust or company owes or is owed by the shareholder or beneficiary.

Births debit inventory (asset) and credit cost of goods section, lowering cost of goods value at a rate ascribed by the tax office $20/head of sheep and/or at market rate ascribed by the farmer. It will be useful to build the reports under both inventory valuation conditions.

Optimally we should preload the Excel sheet with test data that when pressed, provides a controlled natural language response describing the set of processes the data underwent as a result of the computational rules along with a solution to the problem.

The logic should work in the Ledger solution so long as the reporting taxonomy contains references to births, deaths & rations, purchases, sales and inventory. 


The currency reference should be standalone i.e. it is encoded in the transaction set  on the input and the report frame needs to be referenced with currency on the output.

The taxonomy construct could have been done as Current Liabilities --> Current Loans --> Current Beneficiary Loans.  And the pattern could have been repeated in non current liabilities, current assets & non current assets. This structure is adopted to allow LodgeiT users better visibility over where to classify beneficiary loans to. These structures are social conventions where SEC & US GAAP taxonomies will not have the exact same shape. 

 Optimally we will have lots of useful taxonomy structures in a collection URL endpoint. i.e. Australian Livestock farmer trading through a trust. We must be able to read & use all manner of conformant XBRL taxonomies so we will start by making the attached JSON taxonomy XBRL compliant. Waqas already started the process. 

*/

% finally, other predicates used from process_xml_ledger_request.pl */

get_livestock_types(Livestock_Doms, Livestock_Types) :-
	maplist(extract_livestock_type, Livestock_Doms, Livestock_Types).

extract_livestock_type(Livestock_Dom, Livestock_Type) :-
	inner_xml(Livestock_Dom, type, Livestock_Type).
	
get_average_costs(Livestock_Types, Opening_Costs_And_Counts, Info, Average_Costs) :-
	maplist(get_average_costs2(Opening_Costs_And_Counts, Info), Livestock_Types, Average_Costs).

get_average_costs2(Opening_Costs_And_Counts, Info, Livestock_Type, Rate) :-
	member(opening_cost_and_count(Livestock_Type, Opening_Cost, Opening_Count), Opening_Costs_And_Counts),
	average_cost(Livestock_Type, Opening_Cost, Opening_Count, Info, Rate).
	
livestock_cogs_transactions(Livestock_Types, Opening_Costs_And_Counts, Average_Costs, Info, Transactions_Out) :-
	findall(Txs, 
		(
			member(Livestock_Type, Livestock_Types),
			member(opening_cost_and_count(Livestock_Type, Opening_Cost, Opening_Count), Opening_Costs_And_Counts),	
			member(Average_Cost, Average_Costs),
			Average_Cost = exchange_rate(_, Livestock_Type, _, _),
			yield_livestock_cogs_transactions(
				Livestock_Type, 
				Opening_Cost, Opening_Count,
				Average_Cost,
				Info,
				Txs)
		),
		Transactions_Nested),
	flatten(Transactions_Nested, Transactions_Out).
   
% this logic is dependent on having the average cost value
get_more_livestock_transactions(Livestock_Types, Average_costs, S_Transactions, Livestock_Events, More_Transactions) :-
   maplist(
		yield_more_transactions(Average_costs, S_Transactions, Livestock_Events),
		Livestock_Types, 
		Lists),
	flatten(Lists, More_Transactions).
   
yield_more_transactions(Average_costs, S_Transactions, Livestock_Events, Livestock_Type, [Rations_Transactions, Sales_Transactions, Buys_Transactions]) :-
	member(Average_Cost, Average_costs),
	Average_Cost = exchange_rate(_, Livestock_Type, _, _),
	maplist(preprocess_rations(Livestock_Type, Average_Cost), Livestock_Events, Rations_Transactions),
	preprocess_sales(Livestock_Type, Average_Cost, S_Transactions, Sales_Transactions),
	preprocess_buys(Livestock_Type, Average_Cost, S_Transactions, Buys_Transactions).

extract_natural_increase_costs(Livestock_Doms, Natural_Increase_Costs) :-
	maplist(
		extract_natural_increase_cost,
		Livestock_Doms,
		Natural_Increase_Costs).

extract_natural_increase_cost(Livestock_Dom, natural_increase_cost(Type, [coord('AUD', Cost, 0)])) :-
	fields(Livestock_Dom, ['type', Type]),
	numeric_fields(Livestock_Dom, ['naturalIncreaseValuePerUnit', Cost]).

extract_opening_costs_and_counts(Livestock_Doms, Opening_Costs_And_Counts) :-
	maplist(extract_opening_cost_and_count,	Livestock_Doms, Opening_Costs_And_Counts).

extract_opening_cost_and_count(Livestock_Dom,	Opening_Cost_And_Count) :-
	numeric_fields(Livestock_Dom, [
		'openingCost', Opening_Cost,
		'openingCount', Opening_Count]),
	fields(Livestock_Dom, ['type', Type]),
	Opening_Cost_And_Count = opening_cost_and_count(Type, [coord('AUD', Opening_Cost, 0)], Opening_Count).
	
extract_livestock_events(Livestock_Doms, Events) :-
   maplist(extract_livestock_events2, Livestock_Doms, Events_Nested),
   flatten(Events_Nested, Events).
   
extract_livestock_events2(Data, Events) :-
   inner_xml(Data, type, [Type]),
   findall(Event, xpath(Data, events/(*), Event), Xml_Events),
   maplist(extract_livestock_event(Type), Xml_Events, Events).

extract_livestock_event(Type, Dom, Event) :-
   inner_xml(Dom, date, [Date]),
   parse_date(Date, Days),
   inner_xml(Dom, count, [Count_Atom]),
   atom_number(Count_Atom, Count),
   extract_livestock_event2(Type, Days, Count, Dom, Event).

extract_livestock_event2(Type, Days, Count, element(naturalIncrease,_,_),  born(Type, Days, Count)).
extract_livestock_event2(Type, Days, Count, element(loss,_,_),                     loss(Type, Days, Count)).
extract_livestock_event2(Type, Days, Count, element(rations,_,_),                rations(Type, Days, Count)).



process_livestock(Livestock_Doms, Livestock_Types, Default_Bases, S_Transactions, Transactions1, Transactions_Out, Livestock_Events, Average_Costs, Average_Costs_Explanations) :-
	extract_livestock_events(Livestock_Doms, Livestock_Events),
	extract_natural_increase_costs(Livestock_Doms, Natural_Increase_Costs),
	extract_opening_costs_and_counts(Livestock_Doms, Opening_Costs_And_Counts),

	maplist(preprocess_livestock_event, Livestock_Events, Livestock_Event_Transactions_Nested),
	flatten(Livestock_Event_Transactions_Nested, Livestock_Event_Transactions),
	append(Transactions1, Livestock_Event_Transactions, Transactions2),

	get_average_costs(Livestock_Types, Opening_Costs_And_Counts, (Start_Days, End_Days, S_Transactions, Livestock_Events, Natural_Increase_Costs), Average_Costs_With_Explanations),
	maplist(with_info_value_and_info, Average_Costs_With_Explanations, Average_Costs, Average_Costs_Explanations),
  
	get_more_livestock_transactions(Livestock_Types, Average_Costs, S_Transactions, Livestock_Events, More_Transactions),
	append(Transactions2, More_Transactions, Transactions3),  

	get_livestock_cogs_transactions(Livestock_Types, Opening_Costs_And_Counts, Average_Costs, (Start_Days, End_Days, Default_Bases, Average_Costs, Transactions3, S_Transactions),  Cogs_Transactions),
	append(Transactions3, Cogs_Transactions, Transactions_Out).

/*
extract_livestock_events/2, extract_natural_increase_costs/2, extract_opening_costs_and_counts/2, preprocess_livestock_event/2, get_average_costs/4, get_more_livestock_transactions/5, get_livestock_cogs_transactions/5
*/

% see also doc/ledger-livestock

/*todo:
beginning and ending dates are often ignored

this file needs serious cleanup, one reason to delay that might be that we can end up abstracting this into a general average cost pricing with adjustment transactions method.
*/

:- module(livestock, [
		get_livestock_types/2, process_livestock/14, preprocess_livestock_buy_or_sell/3, make_livestock_accounts/2, livestock_counts/5, extract_livestock_opening_costs_and_counts/2, compute_livestock_by_simple_calculation/22]).
:- use_module(utils, [
		user:goal_expansion/2, inner_xml/3, fields/2, numeric_fields/2, pretty_term_string/2, with_info_value_and_info/3, maplist6/6]).
:- use_module(pacioli, [vec_add/3, vec_inverse/2, vec_reduce/2, vec_sub/3, integer_to_coord/3]).
:- use_module(accounts, [account_ancestor_id/3]).
:- use_module(days, [parse_date/2]).
:- use_module(ledger, [balance_by_account/8]).

/*

<howThisShouldWork>

account taxonomy must include accounts for individual livestock types
a list of livestock units will be defined in the sheet, for example "cows, horses".
Natural_Increase_Cost_Per_Head has to be input for each livestock type, for example cows $20.

FOR CURRENT ITERATION, ASSUME THAT ALL TRANSACTIONS ARE IN THE BANK STATEMENT. I.E. NO OPENING BALANCES.WHY? BECAUSE OPENING BALANCES IN LIVESTOCK WILL REQUIRE A COMPLETE SET OF OPENING BALANCES. I.E. A COMPLETE OPENING BALANCE SHEET. 

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

			natural increase:  NATURAL INCREASE IS AN ABSTRACT VALUE THAT IMPACTS THE LIVESTOCK_AT_MARKET_VALUE AT REPORT RUN TIME. THERE IS NO NEED TO STORE/SAVE THE (monetary) VALUE IN THE LEDGER. WHEN A COW IS BORN, NO CASH CHANGES HAND. 
				dont: affect Assets_1203_Livestock_at_Cost by Natural_Increase_Cost_Per_Head as set by user
		
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

preprocess_livestock_buy_or_sell(Static_Data, S_Transaction, [Bank_Transaction, Livestock_Transaction]) :-
	Static_Data = (Accounts, _, _, _, _),
	% here we don't know Livestock_Type, so s_transaction_is_livestock_buy_or_sell actually yields garbage, that we filter out by existence of appropriate account. Usually we pass it a bounded Livestock_Type.
	s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, Livestock_Coord, _Bank_Vector, Our_Vector, Unexchanged_Account_Id, MoneyDebit, _),
	count_account(Livestock_Type, Count_Account),
	account_ancestor_id(Accounts, Count_Account, _),
	
	(MoneyDebit > 0 ->
			Description = 'livestock sell'
		;
			Description = 'livestock buy'
	),
	
	% produce a livestock count increase/decrease transaction
	Livestock_Transaction = transaction(Day, Description, Count_Account, [Livestock_Coord]),
	% produce the bank account transaction
	Bank_Transaction = transaction(Day, Description, Unexchanged_Account_Id, Our_Vector).

/*
BUY - 
	DR assets / current assets / inventory on hand / livestock at cost - 	this is our LivestockAtCost or Assets_1204_Livestock_at_Cost.
	?
*/
preprocess_buys2(Day, Livestock_Type, Expense_Vector, Buy_Transactions) :-
	% DR expenses / direct costs / purchases
	Buy_Transactions = [
		transaction(Day, 'livestock buy', Cogs_Account, Expense_Vector)
	],
	cogs_account(Livestock_Type, Cogs_Account).
	
preprocess_sales2(Day, Livestock_Type, _Average_Rate, _Livestock_Count, Bank_Vector, Sales_Transactions) :-
	%vec_inverse(Bank_Vector, Ours_Vector),
	Description = "livestock sell",
	
	Sales_Transactions = [
		% CR SALES_OF_LIVESTOCK (REVENUE INCREASES) 
		transaction(Day, Description, Sales_Account, Bank_Vector)
		% CR Assets_1204_Livestock_at_Cost (STOCK ON HAND DECREASES,VALUE HELD DECREASES), 
		% DR COST_OF_GOODS_LIVESTOCK (EXPENSE ASSOCIATED WITH REVENUE INCREASES). 
		% we do this, at average cost, by creating the adjustment transaction
	],
	sales_account(Livestock_Type, Sales_Account)/*,
	cogs_account(Livestock_Type, Cogs_Account)*/.
	
	
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
*/
preprocess_rations2(Livestock_Type, Day, Cost, Currency, Equity_3145_Drawings_by_Sole_Trader, Output) :- 
	Output = [
		% DR OWNERS_EQUITY -->DRAWINGS. I.E. THE OWNER TAKES SOMETHING OF VALUE. 
		transaction(Day, 'rations', Equity_3145_Drawings_by_Sole_Trader, [coord(Currency, Cost, 0)]),
		%	CR COST_OF_GOODS. I.E. DECREASES COST. 	% expenses / cost of goods / stock adjustment
		transaction(Day, 'rations', Cogs_Rations_Account, [coord(Currency, 0, Cost)])],
	cogs_rations_account(Livestock_Type, Cogs_Rations_Account).

	
livestock_counts(Livestock_Types, Transactions, Opening_Costs_And_Counts, To_Day, Counts) :-
	findall(
	Count,
	(
		member(Livestock_Type, Livestock_Types),
		member(Opening_Cost_And_Count, Opening_Costs_And_Counts),
		opening_cost_and_count(Livestock_Type, _, _)  = Opening_Cost_And_Count,
		livestock_count(Livestock_Type, Opening_Cost_And_Count, Transactions, To_Day, Count)
	),
	Counts).

livestock_count(Livestock_Type, Transactions, Opening_Cost_And_Count, To_Day, Count) :-
	opening_cost_and_count(Livestock_Type, _, Opening_Count) = Opening_Cost_And_Count,
	count_account(Livestock_Type, Count_Account),
	balance_by_account([], [], Transactions, [], _, Count_Account, To_Day, Count_Vector),
	vec_add(Count_Vector, [coord(Livestock_Type, Opening_Count, 0)], Count).

livestock_at_average_cost_at_day(Livestock_Type, Transactions, Opening_Cost_And_Count, To_Day, Average_Cost_Exchange_Rate, Cost_Vector) :-
	livestock_count(Livestock_Type, Transactions, Opening_Cost_And_Count, To_Day, Count_Vector),
	exchange_rate(_, _, Dest_Currency, Average_Cost) = Average_Cost_Exchange_Rate,
	[coord(_, Count, _)] = Count_Vector,
	Cost is Average_Cost * Count,
	Cost_Vector = [coord(Dest_Currency, Cost, 0)].
	
yield_livestock_cogs_transactions(
	Livestock_Type, 
	Opening_Cost_And_Count, Average_Cost,
	(_From_Day, To_Day, _Average_Costs, Input_Transactions, _S_Transactions),
	Cogs_Transactions) :-
		livestock_at_average_cost_at_day(Livestock_Type, Input_Transactions, Opening_Cost_And_Count, To_Day, Average_Cost, Closing_Debit),
		opening_cost_and_count(Livestock_Type, Opening_Cost, _) = Opening_Cost_And_Count,
	
		vec_sub(Closing_Debit, Opening_Cost, Adjustment_Debit),
		vec_inverse(Adjustment_Debit, Adjustment_Credit),
		
		Cogs_Transactions = [
			% expense/revenue
			transaction(To_Day, "livestock adjustment", Cogs_Account, Adjustment_Credit),
			% assets
			transaction(To_Day, "livestock adjustment", 'AssetsLivestockAtAverageCost', Adjustment_Debit)
		],
		cogs_account(Livestock_Type, Cogs_Account).


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
	no intermediate txs
	credited with opening value
	debited with closing value

(profit and loss)
expenses / direct costs / opening (closing) / inventory at cost / livestock at (average) cost
*/



preprocess_buys(Livestock_Type, _Average_cost, S_Transaction, Buy_Transactions) :-
		(
			s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, _Livestock_Coord, Bank_Vector, _, _, _, MoneyCredit),
			MoneyCredit > 0
		)
	->
		preprocess_buys2(Day, Livestock_Type, Bank_Vector, Buy_Transactions)
	;
		Buy_Transactions = [].

s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, Livestock_Coord, Bank_Vector, Our_Vector, Unexchanged_Account_Id, Our_Debit, Our_Credit) :-
	S_Transaction = s_transaction(Day, '', Our_Vector, Unexchanged_Account_Id, Exchanged),
	vector([Livestock_Coord]) = Exchanged,
	coord(Livestock_Type, _, _) = Livestock_Coord,
	% member(Livestock_Type, Livestock_Types),
	% bank statements are from the perspective of the bank, their debit is our credit
	vec_inverse(Bank_Vector, Our_Vector),
	[coord(_, Our_Debit, Our_Credit)] = Our_Vector.



livestock_account_ids('Livestock', 'LivestockAtCost', 'Drawings', 'LivestockRations').
expenses__direct_costs__purchases__account_id('Purchases').
cost_of_goods_livestock_account_id('CostOfGoodsLivestock').




preprocess_livestock_event(Event, Transaction) :-
	Event = born(Type, Day, Count),
	count_account(Type, Count_Account),
	Transaction = transaction(Day, 'livestock born', Count_Account, [coord(Type, Count, 0)]).
	
preprocess_livestock_event(Event, Transaction) :-
	Event = loss(Type, Day, Count),
	count_account(Type, Count_Account),
	Transaction = transaction(Day, 'livestock loss', Count_Account, [coord(Type, 0, Count)]).
	
preprocess_livestock_event(Event, Transaction) :-
	Event = rations(Type, Day, Count),
	count_account(Type, Count_Account),
	Transaction = transaction(Day, 'livestock rations', Count_Account, [coord(Type, 0, Count)]).


	
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
			s_transaction_is_livestock_buy_or_sell(ST, _Day, Type, Livestock_Coord, _, Vector_Ours, _, _, _),
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
	/*?
	for now, we ignore _From_Day (and _To_Day), 
	and use Opening_Cost and Opening_Count as stated in the request.
	*/
	Exchange_Rate = with_info(exchange_rate(_, Type, Currency, Average_Cost), Explanation),
	Explanation = {formula: Formula_String1, computation: Formula_String2},
	
	compile_with_variable_names_preserved((
		Natural_Increase_Value = Natural_Increase_Cost_Per_Head * Natural_Increase_Count,
		Opening_And_Purchases_And_Increase_Value_Exp = Opening_Value + Purchases_Value + Natural_Increase_Value,
		Opening_And_Purchases_And_Increase_Count_Exp = Opening_Count + Purchases_Count + Natural_Increase_Count,
		Average_Cost_Exp = Opening_And_Purchases_And_Increase_Value_Exp / Opening_And_Purchases_And_Increase_Count_Exp
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
	livestock_purchases_cost_and_count(Type, S_Transactions, Purchases_Cost, Purchases_Count),

	(
			Purchases_Cost == []
		->
			Purchases_Value = 0
		;
			[coord(Currency, 0, Purchases_Value)] = Purchases_Cost
	),
	
	pretty_term_string(Average_Cost_Exp, Formula_String2),
	
	% avoid division by zero and evaluate the formula
	Opening_And_Purchases_And_Increase_Count is Opening_And_Purchases_And_Increase_Count_Exp,
	(Opening_And_Purchases_And_Increase_Count > 0 ->
		Average_Cost is Average_Cost_Exp
	;
		Average_Cost = 0
	).

vector_single_item([Item], Item).
	
preprocess_rations(Livestock_Type, Average_Cost, Event, Output) :-
	Event = rations(Livestock_Type, Day, Count) ->
	(
		exchange_rate(_, _, Currency, Average_Cost_Per_Head) = Average_Cost,
		Cost is Average_Cost_Per_Head * Count,
		preprocess_rations2(Livestock_Type, Day, Cost, Currency, Equity_3145_Drawings_by_Sole_Trader, Output), 
		livestock_account_ids(
			_Livestock_Account,
			_Assets_Livestock_At_Cost_Account, 
			Equity_3145_Drawings_by_Sole_Trader, _Expenses__Direct_Costs__Livestock_Adjustments__Livestock_Rations
		)
	);
	Output = [].

	
preprocess_sales(Livestock_Type, Average_cost, S_Transaction, Sales_Transactions) :-
		(
			s_transaction_is_livestock_buy_or_sell(S_Transaction, Day, Livestock_Type, Livestock_Coord, Bank_Vector, _, _, MoneyDebit, _),
			MoneyDebit > 0
		)
	->
		(
			coord(_, 0, Livestock_Count) = Livestock_Coord,
			preprocess_sales2(Day, Livestock_Type, Average_cost, Livestock_Count, Bank_Vector, Sales_Transactions)
		)
	;
		Sales_Transactions = [].

/*

We want both a stand-alone calculator and include the logic in the ledger system i.e. If there are livestock, allow for inclusion of head held at time x and price y. Births, Rations, Deaths must also be considered via a buy or sell from the bank.

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
	inner_xml(Livestock_Dom, type, [Livestock_Type]).
	
get_average_costs(Livestock_Types, Opening_Costs_And_Counts, Info, Average_Costs) :-
	maplist(get_average_costs2(Opening_Costs_And_Counts, Info), Livestock_Types, Average_Costs).

get_average_costs2(Opening_Costs_And_Counts, Info, Livestock_Type, Rate) :-
	member(opening_cost_and_count(Livestock_Type, Opening_Cost, Opening_Count), Opening_Costs_And_Counts),
	average_cost(Livestock_Type, Opening_Cost, Opening_Count, Info, Rate).
	
get_livestock_cogs_transactions(Livestock_Types, Opening_Costs_And_Counts, Average_Costs, Info, Transactions_Out) :-
	findall(Txs, 
		(
			member(Livestock_Type, Livestock_Types),
			
			member(Opening_Cost_And_Count, Opening_Costs_And_Counts),	
			opening_cost_and_count(Livestock_Type, _, _) = Opening_Cost_And_Count,
			member(Average_Cost, Average_Costs),
			exchange_rate(_, Livestock_Type, _, _) = Average_Cost,
			
			yield_livestock_cogs_transactions(
				Livestock_Type, 
				Opening_Cost_And_Count,
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
	maplist(preprocess_sales(Livestock_Type, Average_Cost), S_Transactions, Sales_Transactions),
	maplist(preprocess_buys(Livestock_Type, Average_Cost), S_Transactions, Buys_Transactions).

extract_natural_increase_costs(Livestock_Doms, Natural_Increase_Costs) :-
	maplist(
		extract_natural_increase_cost,
		Livestock_Doms,
		Natural_Increase_Costs).

extract_natural_increase_cost(Livestock_Dom, natural_increase_cost(Type, [coord('AUD', Cost, 0)])) :-
	fields(Livestock_Dom, ['type', Type]),
	numeric_fields(Livestock_Dom, ['naturalIncreaseValuePerUnit', Cost]).

extract_livestock_opening_costs_and_counts(Livestock_Doms, Opening_Costs_And_Counts) :-
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



/* we should have probably just put the livestock count accounts under inventory */
yield_livestock_inventory_transaction(Livestock_Type, Opening_Cost_And_Count, Average_Cost_Exchange_Rate, End_Days, Transactions_In, Inventory_Transaction) :-
	Inventory_Transaction = transaction(End_Days, 'livestock closing inventory', 'AssetsLivestockAtCost', Vector),
	livestock_at_average_cost_at_day(Livestock_Type, Transactions_In, Opening_Cost_And_Count, End_Days, Average_Cost_Exchange_Rate, Vector).

get_livestock_inventory_transactions(Livestock_Types, Opening_Costs_And_Counts, Average_Costs, End_Days, Transactions_In, Assets_Transactions) :-
	findall(Inventory_Transaction,
	(
		member(Livestock_Type, Livestock_Types),
		member(Opening_Cost_And_Count, Opening_Costs_And_Counts),	
		opening_cost_and_count(Livestock_Type, _, _) = Opening_Cost_And_Count,
		member(Average_Cost, Average_Costs),
		exchange_rate(_, Livestock_Type, _, _) = Average_Cost,
		yield_livestock_inventory_transaction(Livestock_Type, Opening_Cost_And_Count, Average_Cost, End_Days, Transactions_In, Inventory_Transaction)
	),
	Assets_Transactions).

opening_inventory_transactions(Start_Days, Opening_Costs_And_Counts, Livestock_Type, Opening_Inventory_Transactions) :-
	member(Opening_Cost_And_Count, Opening_Costs_And_Counts),
	opening_cost_and_count(Livestock_Type, Opening_Vector, _) = Opening_Cost_And_Count,
	vec_inverse(Opening_Vector, Opening_Vector_Credit),
	Opening_Inventory_Transactions = [
		transaction(Start_Days, 'livestock opening inventory', 'AssetsLivestockAtCost', Opening_Vector),
		transaction(Start_Days, 'livestock opening inventory', 'CapitalIntroduced', Opening_Vector_Credit)
	].
	
	
process_livestock(Livestock_Doms, Livestock_Types, S_Transactions, Transactions_In, Opening_Costs_And_Counts, Start_Days, End_Days, Exchange_Rates, Accounts, Report_Currency, Transactions_Out, Livestock_Events, Average_Costs, Average_Costs_Explanations) :-
	extract_livestock_events(Livestock_Doms, Livestock_Events),
	extract_natural_increase_costs(Livestock_Doms, Natural_Increase_Costs),

	maplist(opening_inventory_transactions(Start_Days, Opening_Costs_And_Counts), Livestock_Types, Opening_Inventory_Transactions0),
	flatten(Opening_Inventory_Transactions0, Opening_Inventory_Transactions),
	append(Transactions_In, Opening_Inventory_Transactions, Transactions1),

	maplist(preprocess_livestock_event, Livestock_Events, Livestock_Event_Transactions_Nested),
	flatten(Livestock_Event_Transactions_Nested, Livestock_Event_Transactions),
	append(Transactions1, Livestock_Event_Transactions, Transactions2),

	get_average_costs(Livestock_Types, Opening_Costs_And_Counts, (Start_Days, End_Days, S_Transactions, Livestock_Events, Natural_Increase_Costs), Average_Costs_With_Explanations),
	maplist(with_info_value_and_info, Average_Costs_With_Explanations, Average_Costs, Average_Costs_Explanations),
  
	get_more_livestock_transactions(Livestock_Types, Average_Costs, S_Transactions, Livestock_Events, More_Transactions),
	append(Transactions2, More_Transactions, Transactions3),  

	get_livestock_cogs_transactions(Livestock_Types, Opening_Costs_And_Counts, Average_Costs, (Start_Days, End_Days, Average_Costs, Transactions3, S_Transactions),  Cogs_Transactions),
	append(Transactions3, Cogs_Transactions, Transactions_Out),
	
	maplist(do_livestock_cross_check(Livestock_Events, Natural_Increase_Costs, S_Transactions, Transactions_Out, Opening_Costs_And_Counts, Start_Days, End_Days, Exchange_Rates, Accounts, Report_Currency, Average_Costs), Livestock_Types).


	
do_livestock_cross_check(Events, Natural_Increase_Costs, S_Transactions, Transactions, Opening_Costs_And_Counts, _From_Day, To_Day, Exchange_Rates, Accounts, Report_Currency, Average_Costs, Type) :-
	% gather up the inputs
	natural_increase_count(Type, Events, Natural_Increase_Count),
	member(natural_increase_cost(Type, [coord(Currency, Natural_Increase_Cost_Per_Head, 0)]), Natural_Increase_Costs),
	sales_and_buys_count(Type, S_Transactions, Buys_Count, Buys_Value, Sales_Count, Sales_Value),
	events_count(Type, Events, _Borns_Count, Losses_Count, Rations_Count),
	member(Opening_Cost_And_Count, Opening_Costs_And_Counts),
	Opening_Cost_And_Count = opening_cost_and_count(Type, [coord(Currency, Opening_Cost, 0)], Opening_Count),
	
	compute_livestock_by_simple_calculation(
	% input
		Natural_Increase_Count, 
		Natural_Increase_Cost_Per_Head,
		Sales_Count,
		Sales_Value,
		Rations_Count,
		Opening_Count,
		Opening_Cost,
		_,
		Buys_Count, 
		Buys_Value, 
		Losses_Count,
	% output
		Rations_Value,
		Closing_Cost,
		_,
		_,
		_,
		_,
		Natural_Increase_value,
		Average_Cost,
		Revenue,
		Livestock_COGS,
		Gross_Profit_on_Livestock_Trading),
	
	% now check the output
	member(Opening_Cost_And_Count, Opening_Costs_And_Counts),	
	opening_cost_and_count(Type, _, _) = Opening_Cost_And_Count,

	member(Average_Cost_Exchange_Rate, Average_Costs),
	exchange_rate(_, Type, Currency, Average_Cost) = Average_Cost_Exchange_Rate,
	
	cogs_rations_account(Type, Cogs_Rations_Account),
	balance_by_account([], [], Transactions, [], _, Cogs_Rations_Account, To_Day, Cogs_Balance),
	
	(
		Cogs_Balance = [coord(Currency, 0, Rations_Value)]
	->
		true
	;
		(
			Cogs_Balance = [],
			Rations_Value =:= 0
		)
	),
	%needs updating to latest pacioli changes
	livestock_at_average_cost_at_day(Type, Transactions, Opening_Cost_And_Count, To_Day, Average_Cost_Exchange_Rate, [coord(Currency, Closing_Cost, 0)]),
	
	Natural_Increase_value is Natural_Increase_Count * Natural_Increase_Cost_Per_Head,

	balance_by_account(Exchange_Rates, Accounts, Transactions, Report_Currency, To_Day, 'Revenue', To_Day, Revenue_Credit),
	vec_inverse(Revenue_Credit, [Revenue_Coord_Ledger]),
	integer_to_coord(Currency, Revenue, Revenue_Coord),
	
	balance_by_account(Exchange_Rates, Accounts, Transactions, Report_Currency, To_Day, 'CostOfGoodsLivestock', To_Day, [Cogs_Coord_Ledger]),
	integer_to_coord(Currency, Livestock_COGS, Cogs_Coord),
	
	balance_by_account(Exchange_Rates, Accounts, Transactions, Report_Currency, To_Day, 'Earnings', To_Day, Earnings_Credit),
	vec_inverse(Earnings_Credit, [Earnings_Coord_Ledger]),
	integer_to_coord(Currency, Gross_Profit_on_Livestock_Trading, Earnings_Coord),
	
	/*
	fixme, the simple calculator should total these three for all livestock types? if it should support multiple livestock datasets at once at all.
	also, ledger can process other transactions besides livestock, so these totals then wont add up.
	we should figure out how to only do these checks maybe during testing, on some pre-defined files
	*/
	
	compile_with_variable_names_preserved(_ = [
		Revenue_Coord_Ledger, Revenue_Coord,
		Cogs_Coord_Ledger, Cogs_Coord,
		Earnings_Coord_Ledger, Earnings_Coord
	], Namings),
	pretty_term_string(Namings, Namings_Str),
	format(user_error, 'these should match, in absence of non-livestock bank transactions, and with only one livestock type processed: ~w', [Namings_Str]).

compute_livestock_by_simple_calculation(	Natural_increase_count,Natural_increase_value_per_head,Sales_count,Sales_value,Killed_for_rations_or_exchanged_for_goods_count,Stock_on_hand_at_beginning_of_year_count,Stock_on_hand_at_beginning_of_year_value,Stock_on_hand_at_end_of_year_count_input,Purchases_count,Purchases_value,Losses_count,Killed_for_rations_or_exchanged_for_goods_value,Stock_on_hand_at_end_of_year_value,Closing_and_killed_and_sales_minus_losses_count,Closing_and_killed_and_sales_value,Opening_and_purchases_and_increase_count,Opening_and_purchases_value,Natural_Increase_value,Average_cost,Revenue,Livestock_COGS,Gross_Profit_on_Livestock_Trading) :-
	
	Stock_on_hand_at_end_of_year_count is Stock_on_hand_at_beginning_of_year_count + Natural_increase_count + Purchases_count - Killed_for_rations_or_exchanged_for_goods_count - Losses_count - Sales_count,
	(
		(
		(Stock_on_hand_at_end_of_year_count_input = Stock_on_hand_at_end_of_year_count,!)
		;
		Stock_on_hand_at_end_of_year_count_input =:= Stock_on_hand_at_end_of_year_count
		)
	->
		true
	;
		throw("closing count mismatch")
	),
	
	Natural_Increase_value is Natural_increase_count * Natural_increase_value_per_head,
	Opening_and_purchases_and_increase_count is Stock_on_hand_at_beginning_of_year_count + Purchases_count + Natural_increase_count,
	Opening_and_purchases_value is Stock_on_hand_at_beginning_of_year_value + Purchases_value,
	
	Average_cost is (Opening_and_purchases_value + Natural_Increase_value) /  Opening_and_purchases_and_increase_count,
	
	Stock_on_hand_at_end_of_year_value is Average_cost * Stock_on_hand_at_end_of_year_count,
	Killed_for_rations_or_exchanged_for_goods_value is Killed_for_rations_or_exchanged_for_goods_count * Average_cost,
	
	Closing_and_killed_and_sales_minus_losses_count is Sales_count + Killed_for_rations_or_exchanged_for_goods_count + Stock_on_hand_at_end_of_year_count - Losses_count,
	Closing_and_killed_and_sales_value is Sales_value + Killed_for_rations_or_exchanged_for_goods_value + Stock_on_hand_at_end_of_year_value,
	
	Revenue is Sales_value,
	Livestock_COGS is Opening_and_purchases_value - Stock_on_hand_at_end_of_year_value - Killed_for_rations_or_exchanged_for_goods_value,
	Gross_Profit_on_Livestock_Trading is Revenue - Livestock_COGS.

		
sales_and_buys_count(Livestock_Type, S_Transactions, Buys_Count, Buys_Value, Sales_Count, Sales_Value) :-
	maplist6(sales_and_buys_count2(Livestock_Type), S_Transactions, Buys_Count_List, Buys_Value_List, Sales_Count_List, Sales_Value_List),
	sum_list(Buys_Count_List, Buys_Count),
	sum_list(Buys_Value_List, Buys_Value),
	sum_list(Sales_Count_List, Sales_Count),
	sum_list(Sales_Value_List, Sales_Value).
		
sales_and_buys_count2(Livestock_Type, S_Transaction, Buys_Count, Buys_Value, 0, 0) :-
	s_transaction_is_livestock_buy_or_sell(S_Transaction, _Day, Livestock_Type, Livestock_Coord, _, _, _, 0, Buys_Value),
	!,
	coord(Livestock_Type, Buys_Count, 0) = Livestock_Coord.

sales_and_buys_count2(Livestock_Type, S_Transaction, 0, 0, Sales_Count, Sales_Value) :-
	s_transaction_is_livestock_buy_or_sell(S_Transaction, _Day, Livestock_Type, Livestock_Coord, _, _, _, Sales_Value, 0),
	!,
	coord(Livestock_Type, 0, Sales_Count) = Livestock_Coord.

sales_and_buys_count2(_,_,0,0,0,0).


events_count(Type, Events, Borns, Losses, Rations) :-
	maplist(events_count2(Type), Events, Borns_List, Losses_List, Rations_List),
	sum_list(Borns_List, Borns),
	sum_list(Losses_List, Losses),
	sum_list(Rations_List, Rations).

events_count2(Type, Event, Borns, Losses, Rations) :-
	(Event = born(Type, _Day, Borns), Rations=0, Losses=0);
	(Event = loss(Type, _Day, Losses), Rations=0, Borns=0);
	(Event = rations(Type, _Day, Rations), Losses=0, Borns=0).
	

	
make_livestock_accounts(Livestock_Type, Accounts) :-
	Accounts = [Cogs, CogsRations, Sales, Count],
	Cogs  = account(Cogs_Name, 'CostOfGoodsLivestock'),
	Sales = account(Sales_Name, 'SalesOfLivestock'),
	Count = account(Count_Name, 'LivestockCount'),
	CogsRations = account(CogsRations_Name, Cogs_Name),
	cogs_account(Livestock_Type, Cogs_Name),
	sales_account(Livestock_Type, Sales_Name),
	count_account(Livestock_Type, Count_Name),
	cogs_rations_account(Livestock_Type, CogsRations_Name).
	
cogs_account(Livestock_Type, Cogs_Account) :-
	atom_concat(Livestock_Type, 'Cogs', Cogs_Account).

cogs_rations_account(Livestock_Type, Cogs_Rations_Account) :-
	atom_concat(Livestock_Type, 'CogsRations', Cogs_Rations_Account).
	
sales_account(Livestock_Type, Sales_Account) :-
	atom_concat(Livestock_Type, 'Sales', Sales_Account).

count_account(Livestock_Type, Count_Account) :-
	atom_concat(Livestock_Type, 'Count', Count_Account).
	
	

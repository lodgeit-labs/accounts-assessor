

/*livestock_counts(Accounts, Livestock_Types, Transactions, Opening_Costs_And_Counts, To_Day, Counts) :-
	findall(
	Count,
	(
		member(Livestock_Type, Livestock_Types),
		member(Opening_Cost_And_Count, Opening_Costs_And_Counts),
		opening_cost_and_count(Livestock_Type, _, _)  = Opening_Cost_And_Count,
		livestock_count(Accounts, Livestock_Type, Transactions, Opening_Cost_And_Count, To_Day, Count)
	),
	Counts).*/











/*<howThisShouldWork>

account taxonomy must include accounts for individual livestock types
a list of livestock units will be defined in the sheet, for example "cows, horses".
Natural_Increase_Cost_Per_Head has to be input for each livestock type, for example cows $20.

FOR CURRENT ITERATION, ASSUME THAT ALL TRANSACTIONS ARE IN THE BANK STATEMENT. I.E. NO OPENING BALANCES.WHY? BECAUSE OPENING BALANCES IN LIVESTOCK WILL REQUIRE A COMPLETE SET OF OPENING BALANCES. I.E. A COMPLETE OPENING BALANCE SHEET.

when bank statements are processed:
	If there is a livestock unit ("cows") set on a bank account transaction:
		count has to be set to ("20").

		maybe TODO:
			internally, we tag the transaction with a sell/buy livestock action type.
			user should have sell/buy livestock action types in their action taxonomy.
			the "exchanged" account will be one where livestock increase/decrease transactions are internally collected.

		SYSTEM CAN INFER BUY/SELL i.e. A BUY IS A PAYMENT & A SELL IS A DEPOSIT. OF COURSE, THE UNIT TYPE MUST BE DESCRIBED. COW. PIG, ETC. AND THE UNIT TYPE MUST HAVE AN ACCOUNTS TAXONOMICAL RELATIONSHIP

		maybe TODO:
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


/*

We want both a stand-alone calculator and include the logic in the ledger system i.e. If there are livestock, allow for inclusion of head held at time x and price y. Births, Rations, Deaths must also be considered via a buy or sell from the bank.

Births debit inventory (asset) and credit cost of goods section, lowering cost of goods value at a rate ascribed by the tax office $20/head of sheep and/or at market rate ascribed by the farmer. It will be useful to build the reports under both inventory valuation conditions.

Optimally we should preload the Excel sheet with test data that when pressed, provides a controlled natural language response describing the set of processes the data underwent as a result of the computational rules along with a solution to the problem.

The logic should work in the Ledger solution so long as the reporting taxonomy contains references to births, deaths & rations, purchases, sales and inventory.


The currency reference should be standalone i.e. it is encoded in the transaction set  on the input and the report frame needs to be referenced with currency on the output.

The taxonomy construct could have been done as Current Liabilities --> Current Loans --> Current Beneficiary Loans.  And the pattern could have been repeated in non current liabilities, current assets & non current assets. This structure is adopted to allow LodgeiT users better visibility over where to classify beneficiary loans to. These structures are social conventions where SEC & US GAAP taxonomies will not have the exact same shape.

 Optimally we will have lots of useful taxonomy structures in a collection URL endpoint. i.e. Australian Livestock farmer trading through a trust. We must be able to read & use all manner of conformant XBRL taxonomies so we will start by making the attached JSON taxonomy XBRL compliant. Waqas already started the process.
*/



/*
The Livestock calculator is an average cost calculator.
Cost, average cost, market value.
There may be other ways of measuring value. But any way is simply units held at some time point * defined value.
Think about what any asset is worth?
Unless you sell it you don't really know
You have to estimate.
*/

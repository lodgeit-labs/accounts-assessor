/*we may want to introduce this st2 term that will hold an inverted, that is, ours, vector, as opposed to a vector from the bank's perspective*/
st2_vector(ST, Cost)
st2_exchanged(ST, Goods)




%transformation of bank statement transactions (ST's) into transactions (T's):
bank_statement_transaction_to_transactions(ST, Ts) :-
	(livestock_buy_or_sell(ST, Ts),!);
	(share_buy_or_sell(ST, Ts),!);





buy_txs(Cost, Goods):
	gains_txs(Cost, Goods, 'Unrealized_Gains')


sale_txs(Cost, Goods, [Txs1, Txs2]) :-
	
	/* 
	here Goods might be 1 GOOG
	Pricing_Method fifo, lifo, or adjusted_cost
	Sold will be goods_with_purchase_price(1 GOOG, 5 USD)
	*/
	actual_items_sold(Goods, Pricing_Method, goods_with_purchase_price(Goods, Purchase_Price))

	gains_txs(Purchase_Price, Goods, 'Unrealized_Gains', Txs1)
	gains_txs(Cost, Goods, 'Realized_Gains', Txs2)
	
actual_items_sold(Goods, Pricing_Method, Transactions, goods_with_purchase_price(Goods, Purchase_Price))
/*
here we need the amounts and prices of buys and sales of Goods up until time.
if we process STs in a recursive way, we can look at Transactions generated thus far.
Easier might be to keep a separate list of buys and sales.
for adjusted_cost method, we will add up all the buys costs, subtract all the sales costs, and divide by number of units outstanding.
for lifo, sales will be reducing/removing buys from the end, for fifo, from the beginning.
*/

	

filtered_and_flattened(Txs0. Txs1) :-
	...

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


unit_values_with_sale_prices(_Ts, Method, Unit_Values_In, Unit_Values_Out) :-
	Method = none,
	Unit_Values_In = Unit_Values_Out.
	

/*
we will only be interested in an exchange rate (price) of shares at report date.
note that we keep exchange rates at two places. 
Currency exchange rates fetched from openexchangerates are asserted into a persistent db.
Exchange_Rates are parsed from the request xml.


Report_Date, Exchange_Rates, , Exchange_Rates2


	is_exchangeable_into_currency(Exchange_Rates, End_Date, Goods_Units, Request_Currency)
		->
	true
		;
	(
		




	)


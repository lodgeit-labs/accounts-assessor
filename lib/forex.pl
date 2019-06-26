preprocess_s_transactions(Static_Data, Exchange_Rates, 
	[], 
	[]
).

preprocess_s_transactions(Static_Data, 
	Exchange_Rates_In, Exchange_Rates_Out,
	[S_Transaction|S_Transactions], 
	[Transactions_Out|Transactions_Out_Tail]
) :-
	Static_Data = Accounts, Report_Currency, End_Date, Transaction_Types,
	check_that_s_transaction_account_exists(S_Transaction, Accounts),
	preprocess_s_transaction1(
		Static_Data, 
		Exchange_Rates_In, Exchange_Rates_Out,
		S_Transaction, Transactions_Out),
	preprocess_s_transactions(Static_Data, Exchange_Rates_In, Exchange_Rates_Out, S_Transactions, Transactions_Out_Tail).
		->
			% filter out unbound vars from the resulting Transactions list, as some rules do no always produce all possible transactions
			exclude(var, Transactions0, Transactions)
		;
		(
			% throw error on failure
			term_string(S_Transaction, Str2),
			atomic_list_concat(['processing failed:', Str2], Message),
			throw(Message)
		)
	).

	
/*s_transactions have to be sorted by date and we have to begin at the oldest one

preprocess_s_transaction2(Accounts, _, Exchange_Rates, Transaction_Types, _End_Date,  S_Transaction, Transactions) :-
	(preprocess_livestock_buy_or_sell(Accounts, Exchange_Rates, Transaction_Types, S_Transaction, Transactions),
	!).

	
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

	% will we be able to exchange this later?
	is_exchangeable_into_currency(Exchange_Rates, End_Date, Goods_Units, Request_Currency)
		->
	true
		;
		(
			% save the cost for report time
		)


		
		
		
		
		
/*we may want to introduce this st2 term that will hold an inverted, that is, ours, vector, as opposed to a vector from the bank's perspective*/
st2_vector(ST, Cost)
st2_exchanged(ST, Goods)



%transformation of bank statement transactions (ST's) into transactions (T's):
bank_statement_transaction_to_transactions(ST, Ts) :-
	(livestock_buy_or_sell(ST, Ts),!);
	(share_buy_or_sell(ST, Ts),!);



	
	
	
	
buys_and_sells(STransaction, BuysAndSells) :-
	is_shares_buy(STransaction),
	BuysAndSells = buy(Unit, Count, Unit_Cost),
	!.
buys_and_sells(STransaction, BuysAndSells) :-
	is_shares_sell(STransaction),
	BuysAndSells = sell(Unit, Count),
	!.
buys_and_sells(_STransaction, _BuysAndSells).



/*
maplist(buys_and_sells, STransactions, Buys_And_Sells)
*/

actual_items_sold(Goods, Pricing_Method, Transactions, goods_with_purchase_price(Goods, Purchase_Price))
/*
here we need the amounts and prices of buys and sales of Goods up until time.
if we process STs in a recursive way, we can look at Transactions generated thus far.
Easier might be to keep a separate list of buys and sales.
for adjusted_cost method, we will add up all the buys costs, subtract all the sales costs, and divide by number of units outstanding.
for lifo, sales will be reducing/removing buys from the end, for fifo, from the beginning.
*/

inventory_at














			vec_sub(Vector_Bank, Vector_Goods, Trading_Vector),
			transaction_day(Trading_Transaction, Day),
			transaction_description(Trading_Transaction, Description),
			transaction_vector(Trading_Transaction, Trading_Vector),
			transaction_account_id(Trading_Transaction, Trading_Account_Id)


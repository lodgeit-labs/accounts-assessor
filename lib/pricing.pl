:- module(pricing, [
	add_bought_items/4, 
	find_items_to_sell/6
]).

:- use_module(library(record)).

/*
pricing methods:

for adjusted_cost method, we will add up all the buys costs and divide by number of units outstanding.
for lifo, sales will be reducing/removing buys from the end, for fifo, from the beginning.
*/

:- record outstanding(bank_account_currency, goods_unit, goods_count, unit_cost, transaction_date).
/* ST_Currency is the s_transaction currency, which is the bank account's currency, which is the currency that we bought the shares with. Cost is recorded in report currency.
*/

/*
Outstanding variable treads through preprocess_s_transactions keeps track of currenty owned shares/goods and their purchase costs. 
The same information could be extracted, with knowledge of the pricing method, from the transactions generated so far, although that might be inefficient. But due to how requirements evolved, the essentially same information is kept in two places now.
*/

add_bought_items(fifo, Added, Outstanding_In, Outstanding_Out) :- append([Added], Outstanding_In, Outstanding_Out).
add_bought_items(lifo, Added, Outstanding_In, Outstanding_Out) :- append(Outstanding_In, [Added], Outstanding_Out).


find_items_to_sell(Pricing_Method, Type, Sale_Count, Outstanding_In, Outstanding_Out, Cost) :-
	((Pricing_Method = lifo,!);(Pricing_Method = fifo)),
	find_items_to_sell2(Type, Sale_Count, Outstanding_In, Outstanding_Out, Cost).

find_items_to_sell2(Type, Count, [outstanding(_, Outstanding_Type, _, _,_)|Outstanding_Tail], Outstanding_Out, Cost) :-
	Outstanding_Type \= Type,
	find_items_to_sell2(Type, Count, Outstanding_Tail, Outstanding_Out, Cost).

/* find items and return them in Goods, put the rest back into the outstanding list and return that as Outstanding_Out */
find_items_to_sell2(
	/* input */
	Type, Sale_Count, 
	[outstanding(ST_Currency, Type, Outstanding_Count, value(Currency, Outstanding_Unit_Cost), Date)|Outstanding_Tail], 
	/* output */
	Outstanding_Out, Goods) 
:-
	Outstanding_Count >= Sale_Count,
	Outstanding_Remaining_Count is Outstanding_Count - Sale_Count,
	Cost_Int is Sale_Count * Outstanding_Unit_Cost,
	Goods = [outstanding(ST_Currency, Type, Sale_Count, value(Currency, Cost_Int), Date)],
	Outstanding_Out = [Outstanding_Remaining | Outstanding_Tail],
	Outstanding_Remaining = outstanding(ST_Currency, Type, Outstanding_Remaining_Count, value(Currency, Outstanding_Unit_Cost), Date).

/* in this case we will need to recurse, because we did not find enough items */
find_items_to_sell2(
	Type, Sale_Count, 
	[outstanding(ST_Currency, Type, Outstanding_Count, value(Outstanding_Currency, Outstanding_Unit_Cost), Date)|Outstanding_Tail], 
	Outstanding_Out, Goods)
:-
	Outstanding_Count < Sale_Count,
	Remaining_Count is Sale_Count - Outstanding_Count,
	find_items_to_sell2(Type, Remaining_Count, Outstanding_Tail, Outstanding_Out, Remaining_Goods),
	Partial_Cost_Int is Outstanding_Count * Outstanding_Unit_Cost,
	Partial_Goods = [outstanding(ST_Currency, Type, Outstanding_Count, value(Outstanding_Currency, Partial_Cost_Int), Date)],
	append(Partial_Goods, Remaining_Goods, Goods).
	
/*
finally, we should update our knowledge of unit costs, based on recent sales and buys

we will only be interested in an exchange rate (price) of shares at report date.
note that we keep exchange rates at two places. 
Currency exchange rates fetched from openexchangerates are asserted into a persistent db.
Exchange_Rates are parsed from the request xml.
*/

infer_unit_cost_from_last_buy_or_sell(Unit, [ST|_], Exchange_Rate) :-
	s_transaction_exchanged(ST, vector([coord(Unit, D, C)])),
	s_transaction_vector(ST, [coord(Currency, Cost_D, Cost_C)]),
	(
		D =:= 0
	->
		Rate is Cost_D / C
	;
		Rate is Cost_C / D
	),
	Exchange_Rate = exchange_rate(_,Unit,Currency,Rate),
	!.

infer_unit_cost_from_last_buy_or_sell(Unit, [_|S_Transactions], Rate) :-
	infer_unit_cost_from_last_buy_or_sell(Unit, S_Transactions, Rate).



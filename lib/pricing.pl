:- module(pricing, [
	add_bought_items/4, 
	find_items_to_sell/6
]).

/*
pricing methods:

for adjusted_cost method, we will add up all the buys costs and divide by number of units outstanding.
for lifo, sales will be reducing/removing buys from the end, for fifo, from the beginning.
*/


add_bought_items(fifo, Added, Outstanding_In, Outstanding_Out) :- append([Added], Outstanding_In, Outstanding_Out).
add_bought_items(lifo, Added, Outstanding_In, Outstanding_Out) :- append(Outstanding_In, [Added], Outstanding_Out).


find_items_to_sell(Pricing_Method, Type, Sale_Count, Outstanding_In, Outstanding_Out, Cost) :-
	((Pricing_Method = lifo,!);(Pricing_Method = fifo)),
	find_items_to_sell2(Type, Sale_Count, Outstanding_In, Outstanding_Out, Cost).

find_items_to_sell2(Type, Count, [outstanding(_, Outstanding_Type, _, _,_)|Outstanding_Tail], Outstanding_Out, Cost) :-
	Outstanding_Type \= Type,
	find_items_to_sell2(Type, Count, Outstanding_Tail, Outstanding_Out, Cost).

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


Report_Date, Exchange_Rates, , Exchange_Rates2

	% will we be able to exchange this later?
	is_exchangeable_into_currency(Exchange_Rates, End_Date, Goods_Units, Request_Currency)
		->
	true
		;
		(
			% save the cost for report time
		)
*/



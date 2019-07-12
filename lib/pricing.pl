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




test0 :-
	Pricing_Method = lifo,
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('AUD', 5), date(2000, 1, 1)), 
		[], Outstanding_Out),
	find_items_to_sell(Pricing_Method, 'TLS', 2, Outstanding_Out, _Outstanding_Out2, Cost_Of_Goods),
	%print_term(Cost_Of_Goods, []).
	Cost_Of_Goods = [outstanding('CZK', 'TLS', 2, value('AUD',10), date(2000, 1, 1))].
	
test1 :-
	Pricing_Method = lifo,
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('AUD', 5), date(2000, 1, 1)), 
		[], Outstanding_Out),
	\+find_items_to_sell(Pricing_Method, 'TLS', 6, Outstanding_Out, _Outstanding_Out2, _Cost_Of_Goods).

test2 :-
	Pricing_Method = lifo,
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('AUD', 5), date(2000, 1, 1)), 
		[], Outstanding_Out),
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('AUD', 50), date(2000, 1, 2)), 
		Outstanding_Out, Outstanding_Out2),
	find_items_to_sell(Pricing_Method, 'TLS', 6, Outstanding_Out2, _Outstanding_Out3, Cost_Of_Goods),
	%print_term(Cost_Of_Goods, []).
	Cost_Of_Goods = [outstanding('CZK', 'TLS', 5, value('AUD',25), date(2000, 1, 1)), outstanding('CZK', 'TLS', 1, value('AUD',50), date(2000, 1, 2))].
	
test3 :-
	Pricing_Method = lifo,
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('AUD', 5), date(2000, 1, 1)), 
		[], Outstanding),
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('USD', 5), date(2000, 1, 2)), 
		Outstanding, Outstanding2),
	find_items_to_sell(Pricing_Method, 'TLS', 6, Outstanding2, _Outstanding3, Cost_Of_Goods),
	%print_term(Cost_Of_Goods, []).
	Cost_Of_Goods = [outstanding('CZK', 'TLS', 5, value('AUD',25), date(2000, 1, 1)), outstanding('CZK', 'TLS', 1, value('USD',5), date(2000, 1, 2))].
	

	

:- test0.
:- test1.
:- test2.
:- test3.

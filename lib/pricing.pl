:- ensure_loaded(pacioli).

/*
pricing methods:

for adjusted_cost method, we will add up all the buys costs and divide by number of units outstanding.
for lifo, sales will be reducing/removing buys from the end, for fifo, from the beginning.
*/


add_bought_items(fifo, Added, Outstanding_In, Outstanding_Out) :- append([Added], Outstanding_In, Outstanding_Out).
add_bought_items(lifo, Added, Outstanding_In, Outstanding_Out) :- append(Outstanding_In, [Added], Outstanding_Out).


find_items_to_sell(Pricing_Method, Type, Sale_Count, Outstanding_In, Outstanding_Out, Cost) :-
	((Pricing_Method = lifo,!);(Pricing_Method = fifo)),
	find_items_to_sell(Type, Sale_Count, Outstanding_In, Outstanding_Out, Cost).

find_items_to_sell(
	/* input */
	Type, Sale_Count, 
	[(Type, Outstanding_Count, value(Currency, Outstanding_Unit_Cost))|Outstanding_Tail], 
	/* output */
	Outstanding_Out, Cost) 
:-
	Outstanding_Count >= Sale_Count,
	Outstanding_Remaining_Count is Outstanding_Count - Sale_Count,
	Cost_Int is Sale_Count * Outstanding_Unit_Cost,
	Cost = [value(Currency, Cost_Int)],
	Outstanding_Out = [Outstanding_Remaining | Outstanding_Tail],
	Outstanding_Remaining = (Type, Outstanding_Remaining_Count, value(Currency, Outstanding_Unit_Cost)).

find_items_to_sell(
	Type, Sale_Count, 
	[(Type, Outstanding_Count, value(Outstanding_Currency, Outstanding_Unit_Cost))|Outstanding_Tail], 
	Outstanding_Out, Cost)
:-
	Outstanding_Count < Sale_Count,
	Remaining_Count is Sale_Count - Outstanding_Count,
	find_items_to_sell(Type, Remaining_Count, Outstanding_Tail, Outstanding_Out, Remaining_Cost),
	Partial_Cost_Int is Outstanding_Count * Outstanding_Unit_Cost,
	Partial_Cost = [value(Outstanding_Currency, Partial_Cost_Int)],
	vec_add(Partial_Cost, Remaining_Cost, Cost).

find_items_to_sell(Type, Count, [value(Outstanding_Type,_)|Outstanding_Tail], Outstanding_Out, Cost) :-
	Outstanding_Type \= Type,
	find_items_to_sell(Type, Count, Outstanding_Tail, Outstanding_Out, Cost).

	
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



test0 :-
	Pricing_Method = lifo,
	add_bought_items(Pricing_Method, 
		('TLS', 5, value('AUD', 5)), 
		[], Outstanding_Out),
	find_items_to_sell(Pricing_Method, 'TLS', 2, Outstanding_Out, _Outstanding_Out2, Cost_Of_Goods),
	%print_term(Cost_Of_Goods, []).
	Cost_Of_Goods = [value('AUD',10)].
	
test1 :-
	Pricing_Method = lifo,
	add_bought_items(Pricing_Method, 
		('TLS', 5, value('AUD', 5)), 
		[], Outstanding_Out),
	\+find_items_to_sell(Pricing_Method, 'TLS', 6, Outstanding_Out, _Outstanding_Out2, _Cost_Of_Goods).

test2 :-
	Pricing_Method = lifo,
	add_bought_items(Pricing_Method, 
		('TLS', 5, value('AUD', 5)), 
		[], Outstanding_Out),
	add_bought_items(Pricing_Method, 
		('TLS', 5, value('AUD', 50)), 
		Outstanding_Out, Outstanding_Out2),
	find_items_to_sell(Pricing_Method, 'TLS', 6, Outstanding_Out2, _Outstanding_Out3, Cost_Of_Goods),
	%print_term(Cost_Of_Goods, []).
	Cost_Of_Goods = [value('AUD',75)].
	
test3 :-
	Pricing_Method = lifo,
	add_bought_items(Pricing_Method, 
		('TLS', 5, value('AUD', 5)), 
		[], Outstanding),
	add_bought_items(Pricing_Method, 
		('TLS', 5, value('USD', 5)), 
		Outstanding, Outstanding2),
	find_items_to_sell(Pricing_Method, 'TLS', 6, Outstanding2, _Outstanding3, Cost_Of_Goods),
	%print_term(Cost_Of_Goods, []).
	Cost_Of_Goods = [value('AUD',25), value('USD',5)].
	

	

:- test0.
:- test1.
:- test2.
:- test3.
	

%test(Pricing_Method, [('TLS', 5, value('AUD', 5)], 'TLS', 6

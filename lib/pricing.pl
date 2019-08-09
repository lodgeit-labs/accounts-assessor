:- module(pricing, [
	add_bought_items/4, 
	find_items_to_sell/8,
	outstanding_goods_count/2
]).

:- use_module(library(record)).

/*
pricing methods:

for adjusted_cost method, we will add up all the buys costs and divide by number of units outstanding.
for lifo, sales will be reducing/removing buys from the end, for fifo, from the beginning.
*/

:- record outstanding(purchase_currency, goods_unit, goods_count, unit_cost, unit_cost_foreign, purchase_date).
/* ST_Currency is the s_transaction currency, which is the bank account's currency, which is the currency that we bought the shares with. Cost is recorded in report currency.
*/

/*
Outstanding variable treads through preprocess_s_transactions keeps track of currenty owned shares/goods and their purchase costs. 
The same information could be extracted, with knowledge of the pricing method, from the transactions generated so far, although that might be inefficient. But due to how requirements evolved, the essentially same information is kept in two places now.
*/

add_investment(Investments_In, Added, Investments_Out, Investment_Id) :-
	length(Investments_In, Investment_Id),
	Investment = investment(Added, []),
	append(Investments_In, [Investment], Investments_Out).

add_bought_items(fifo, Added, (Outstanding_In, Investments_In), (Outstanding_Out, Investments_Out)) :- 
	add_investment(Investments_In, Added, Investments_Out, Investment_Id),
	append([(Added, Investment_Id)], Outstanding_In, Outstanding_Out)
	%,print_term(add_bought_items(fifo, Added, (Outstanding_In, Investments_In), (Outstanding_Out, Investments_Out)),[])
	.
		
add_bought_items(lifo, Added, (Outstanding_In, Investments_In), (Outstanding_Out, Investments_Out)) :- 
	add_investment(Investments_In, Added, Investments_Out, Investment_Id),
	append(Outstanding_In, [(Added, Investment_Id)], Outstanding_Out)
	%,print_term(add_bought_items(lifo, Added, (Outstanding_In, Investments_In), (Outstanding_Out, Investments_Out)),[])
	.


find_items_to_sell(Pricing_Method, Type, Sale_Count, Sale_Date, Sale_Unit_Price, (Outstanding_In, Investments_In), (Outstanding_Out, Investments_Out), Cost) :-
	/* this logic is same for both pricing methods */
	((Pricing_Method = lifo,!);(Pricing_Method = fifo)),
	find_items_to_sell2(Type, Sale_Count, Sale_Date, Sale_Unit_Price, Outstanding_In, Investments_In, Outstanding_Out, Investments_Out, Cost)
	%,print_term(find_items_to_sell(Pricing_Method, Type, Sale_Count, Sale_Date, Sale_Unit_Price, (Outstanding_In, Investments_In), (Outstanding_Out, Investments_Out), Cost),[])
	.

find_items_to_sell2(Unit, Count, Sale_Date, Sale_Price, [Outstanding_Head|Outstanding_Tail], Investments_In, [Outstanding_Head|Outstanding_Tail2], Investments_Out, Cost) :-
	/* if this outstanding term doesn't contain the requested unit, just go try with the next one (tail) */
	Outstanding_Head = (Outstanding_Head_Outstanding,_),
	outstanding_goods_unit(Outstanding_Head_Outstanding, Goods_Unit),
	Goods_Unit \= Unit,
	find_items_to_sell2(Unit, Count, Sale_Date, Sale_Price, Outstanding_Tail, Investments_In, Outstanding_Tail2, Investments_Out, Cost).

/* find items and return them in Goods, put the rest back into the outstanding list and return that as Outstanding_Out */
find_items_to_sell2(
	/* input */
	Type, Sale_Count, Sale_Date, Sale_Price,
	[
		(
			outstanding(ST_Currency, Type, Outstanding_Count, Unit_Cost, Unit_Cost_Foreign, Date),
			Investment_Id
		)
		|Outstanding_Tail], Investments_In,
	/* output */
	Outstanding_Out, Investments_Out, Goods
) :-
	value(Currency, Outstanding_Unit_Cost) = Unit_Cost,
	/*this 'outstanding' entry contains more items than are requested, good*/
	Outstanding_Count >= Sale_Count,
	Outstanding_Remaining_Count is Outstanding_Count - Sale_Count,
	Total_Cost is Sale_Count * Outstanding_Unit_Cost,
	Goods = [goods(ST_Currency, Type, Sale_Count, value(Currency, Total_Cost), Date)],
	Outstanding_Remaining = outstanding(
		ST_Currency, Type, Outstanding_Remaining_Count, 
		Unit_Cost, Unit_Cost_Foreign,
		Date
	),
	Outstanding_Out = [(Outstanding_Remaining,Investment_Id) | Outstanding_Tail],
	record_sale(Investment_Id, Investments_In, Sale_Date, Sale_Price, Sale_Count, Investments_Out).
	
/* in this case we will need to recurse, because we did not find enough items */
find_items_to_sell2(
	Type, Sale_Count, Sale_Date, Sale_Price, 
	[
		(
			outstanding(
				ST_Currency, Type, Outstanding_Count, 
				value(Outstanding_Currency, Outstanding_Unit_Cost), _,
				Date
			),
			Investment_Id
		)
		|Outstanding_Tail], Investments_In,
	/* output */
	Outstanding_Out, Investments_Out, Goods
) :-
	Outstanding_Count < Sale_Count,
	record_sale(Investment_Id, Investments_In, Sale_Date, Sale_Price, Outstanding_Count, Investments_Mid),
	Remaining_Count is Sale_Count - Outstanding_Count,
	find_items_to_sell2(Type, Remaining_Count, Sale_Date, Sale_Price, Outstanding_Tail, Investments_Mid, Outstanding_Out, Investments_Out, Remaining_Goods),
	Partial_Cost_Int is Outstanding_Count * Outstanding_Unit_Cost,
	Partial_Goods = [
		goods(
			ST_Currency, Type, Outstanding_Count,
			value(Outstanding_Currency, Partial_Cost_Int), 
			Date
		)
	],
	append(Partial_Goods, Remaining_Goods, Goods).

	
record_sale(Investment_Id, Investments_In, Sale_Date, Sale_Price, Sale_Count, Investments_Out) :-
	/* find the associated investment and record the sale:*/
	nth0(Investment_Id, Investments_In, Investment1, Investments_Rest),
	/* Investments_Rest contains all the other items now */
	Investment1 = investment(Info, Sales1),
	Investment2 = investment(Info, Sales2),
	append(Sales1, [Sale], Sales2),
	Sale = sale(Sale_Date, Sale_Price, Sale_Count),
	append(Investments_Rest, [Investment2], Investments_Out).
	
	
	
	
/*
update our knowledge of unit costs, based on recent sales and buys

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



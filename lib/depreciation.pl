% ===================================================================
% Project:   LodgeiT
% Module:    depreciation.pl
% Date:      2019-06-06
% ===================================================================

/*

work in progress 

*/




/*include depreciation_computation here*/

/*
Not a part of the project yet, jsut a standalone demo. Hence the asserts etc.
*/


:- module(depreciation, [asset_disposal/4]).
							
:- use_module(days, [absolute_day/2]).

:- use_module(depreciation_computation, [depreciation_between_two_dates/5]).


:- dynamic transactions/1.



/* Invest_in 1 Unit of Corolla, where Corolla is a Toyota & where Toyota is a Car & where a Car is a Motor Vehicle & 
where a Motor Vehicle is Property Plant & Equipment & Where Property Plant & Equipment is a Non Current Asset.

Now, assume some rate of depreciation that applies to Motor Vehicles. Say 25% per annum diminishing value. 

Requirement -
Given some profitLoss & balanceSheet future date, compute the Written Down Value of the vehicle. i.e.
Cost $100
Year 1 - $75
Year 2 - 75 * 0.27 = 20.25, 75 - 20.25 = 54.75

Provide queries that generate depreciation values between any two dates on a daily basis anywhere 
between the Invest_In date and the Written Down Value Date. */





% Type hierarchy - i guess should be input as a table of pairs, and we dont have anything similar in concept elsewhere in the codebase, 
% i guess. account hierarchy is parsed from a xml tree and represented internally as a list of id,parent_id terms, but thats not useful here i guess,
% except you can copy the account_ancestor_id, but thats an easy one

type(corolla, toyota).
type(toyota, car).
type(car, motor_vehicles).
type(motor_vehicles, property_plant_and_equipment).
type(property_plant_and_equipment, non_current_asset).

depreciation_rate_for_asset(Asset_Hierarchy, Rates, Asset, Year, Rate) :-
	...

% Example hardcoded transactions regarding motor vehicles
/*eventually depreciation should be integrated into ledger, but not now, so, it will be nice if the representation of transactions here will be equivalent to ledger's, but not critical. i dont really know how it will even integrate exactly. possibly in process_s_transaction by intercepting some action types and producing the depreciation transactions? possibly just checking that they already exist in the input? idk
*/
transactions(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(1000, 0))).
transactions(transaction(date(19, 7, 1), buy_car, hirepurchase_car, t_term(0, 1000))).
transactions(transaction(date(20, 4, 1), buy_truck, motor_vehicles, t_term(3000, 0))).
transactions(transaction(date(20, 4, 1), buy_truck, hirepurchase_truck, t_term(0, 3000))).



/* 
ledger integration:
If the temporal cycle of the depreciation calculation is annual, then each depreciation event is: 
Debit Depreciation EXPENSE, 
Credit Accumulated Depreciation (ASSET Subaccount)

So the Asset COST never changes, just the Credits associated with the Accumulated depreciation gets bigger. 
The net effect is that the Net Written Down Value of the asset gets less as time goes by.

Asset Cost less Asset Accumulated Depreciation.

At disposal, the Asset Cost Account is Credited & the Asset less Accumulated depreciation account is debited 
(with the accumulated depreciation) at date of disposal.

Such that both accounts must go to zero.

The difference goes to a profitLoss account along with the proceeds.

If the proceeds is greater than Written Down Value, then there is a profit.

If less, there is a loss. */

% Extend account types to tackle this use case
/* shouldnt need this util ledger integration
account_type(depreciation, expense).
account_type(accumulated_depreciation, asset).
account_type(profit_and_loss, revenue).
*/
%Original transactions when asset was acquired:
%Original transaction to use for disposal:
%transactions(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(1000, 0))).
%The lease plan in the bank is another matter to tackle in another time possibly
%transactions(transaction(date(19, 7, 1), buy_car, hirepurchase_car, t_term(0, 1000))).

/* 
"Buy car event"
Asset_cost (original when acquire)   |						
"Depreciation event"
Depreciation_value  			     |
									 | Depreciation_value 
"Sell car event"									 
								     | Asset Cost 
Depreciation_value	     			 |
					     Asset_price |
							Loss	 | Profit
									 */
/*

depreciation_event(Original_transaction, Date, Method, Depreciation_value):-
	transaction_date(Original_transaction, Invest_in_date),
	depreciation_between_two_dates(Original_transaction, Invest_in_date, Date , Method, Depreciation_value),

	for standalone calculator you'd probably just output the result instead of turning it back into transactions and then parsing it from them again.

	assert(transactions(transaction(Date, car_depreciation, depreciation, t_term(Depreciation_value, 0)))),
	assert(transactions(transaction(Date, car_depreciation, accumulated_depreciation, t_term(0, Depreciation_value)))).

% Create new facts with assert: generate transactions from asset disposal event
asset_disposal(Original_transaction, Date, Asset_price, Depreciation_method) :- 
	transaction_cost(Original_transaction, Asset_cost),
	depreciation_event(Original_transaction, Date, Depreciation_method, Depreciation_value),
	assert(transactions(transaction(Date, sell_car, motor_vehicles, t_term(0, Asset_cost)))),
	assert(transactions(transaction(Date, car_depreciation, accumulated_depreciation, t_term(Depreciation_value, 0)))),
	assert(transactions(transaction(Date, sell_car, bank, t_term(Asset_price, 0)))),

	/* this might need to be broken out into depreciation_computation.pl to support requests where
	sale date is specified, and profit should be returned */

	Profit_and_loss is Asset_price - Asset_cost + Depreciation_value,
	print(Profit_and_loss),
	( Profit_and_loss >= 0 -> assert(transactions(transaction(Date, sell_car, profit_and_loss, t_term(0, Profit_and_loss))));
	assert(transactions(transaction(Date, sell_car, profit_and_loss, t_term(Profit_and_loss, 0))))
	).
*/
%Queries:
%asset_disposal(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(1000, 0)), date(20,7,1), 900,_).

% To check the generated transactions of buy car:
%listing(transactions(transaction(_,buy_car,_,_))).
%Should give:
%transactions(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(1000, 0))).
%transactions(transaction(date(19, 7, 1), buy_car, hirepurchase_car, t_term(0, 1000))).
% To check the generated transactions of car depreciation:
%listing(transactions(transaction(_,car_depreciation,_,_))).
%Should give:
%transactions(transaction(date(20, 7, 1), car_depreciation, depreciation, t_term(200.0, 0))).
%transactions(transaction(date(20, 7, 1), car_depreciation, accumulated_depreciation, t_term(0, 200.0))).
%transactions(transaction(date(20, 7, 1), car_depreciation, accumulated_depreciation, t_term(200.0, 0))).
% To check the generated transactions of sell car:
%listing(transactions(transaction(_,sell_car,_,_))).
%Should give:
%transactions(transaction(date(20, 7, 1), sell_car, motor_vehicles, t_term(0, 1000))).
%transactions(transaction(date(20, 7, 1), sell_car, bank, t_term(900, 0))).
%transactions(transaction(date(20, 7, 1), sell_car, profit_and_loss, t_term(0, 100.0))).

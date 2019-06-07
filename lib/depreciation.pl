% ===================================================================
% Project:   LodgeiT
% Module:    depreciation.pl
% Date:      2019-06-06
% ===================================================================

:- module(depreciation, [depreciation_between_invest_in_date_and_other_date/9,
							depreciation_between_two_dates/5,
							asset_disposal/4]).
							
:- use_module(days, [absolute_day/2]).

% Import transactions.pl and hirepurchase.pl
:- dynamic transactions/1.
% :- [hirepurchase, days].


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


% Predicates for asserting that the fields of given transactions have particular values
% duplicated from transactions.pl with the difference that transaction_date is used instead of transaction_day
% The absolute day that the transaction happenned
transaction_date(transaction(Date, _, _, _), Date).
% A description of the transaction
transaction_description(transaction(_, Description, _, _), Description).
% The account that the transaction modifies
transaction_account(transaction(_, _, Account_Id, _), Account_Id).
% The amounts by which the account is being debited and credited
transaction_vector(transaction(_, _, _, Vector), Vector).
% Extract the cost of the buy from transaction data
transaction_cost(transaction(_, _, _, t_term(Cost, _)), Cost).


day_diff(Date1, Date2, Days) :-
	absolute_day(Date1, Days1),
	absolute_day(Date2, Days2),
	Days is Days2 - Days1.


% Type hierarchy
type(corolla, toyota).
type(toyota, car).
type(car, motor_vehicles).
type(motor_vehicles, property_plant_and_equipment).
type(property_plant_and_equipment, non_current_asset).


% Example hardcoded transactions regarding motor vehicles
transactions(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(1000, 0))).
transactions(transaction(date(19, 7, 1), buy_car, hirepurchase_car, t_term(0, 1000))).
transactions(transaction(date(20, 4, 1), buy_truck, motor_vehicles, t_term(3000, 0))).
transactions(transaction(date(20, 4, 1), buy_truck, hirepurchase_truck, t_term(0, 3000))).


% Depreciation rates for motor vehicles depending on the year: 1, 2... after investing
depreciation_rate(motor_vehicles, _, 0.2).
%depreciation_rate(motor_vehicles, _, 0.27).


% Calculates depreciation on a daily basis between the invest in date and any other date
depreciation_between_invest_in_date_and_other_date(
	Invest_in_value, Initial_value, Method, date(From_year, From_Month, From_day), To_date,
	Account, Depreciation_year, By_day_factor, Total_depreciation_value
	) :-
	day_diff(date(From_year, From_Month, From_day), To_date, Days_difference),
	Days_difference >= 0,
	depreciation_rate(Account, Depreciation_year, Depreciation_rate),
	Depreciation_fixed_value = Invest_in_value * Depreciation_rate,
	(Days_difference =< 365 -> depreciation_by_method(Method, Initial_value, Depreciation_rate, Depreciation_fixed_value, By_day_factor,
		Days_difference, Total_depreciation_value);
	(
	depreciation_by_method(Method, Initial_value, Depreciation_rate, Depreciation_fixed_value, By_day_factor, 365, Depreciation_value),
	Next_depreciation_year is Depreciation_year + 1,
	Next_from_year is From_year + 1,
	Next_initial_value is Initial_value - Depreciation_value,
	depreciation_between_invest_in_date_and_other_date(Invest_in_value, Next_initial_value, Method, date(Next_from_year, From_Month, From_day), To_date, 
		Account, Next_depreciation_year, By_day_factor, Next_depreciation_value),
	Total_depreciation_value is  Depreciation_value + Next_depreciation_value
	)).

% Calculates depreciation between any two dates on a daily basis equal or posterior to the invest in date
depreciation_between_two_dates(Transaction, From_date, To_date, Method, Depreciation_value):-
	day_diff(From_date, To_date, Days_difference),
	Days_difference >= 0,
	written_down_value(Transaction, To_date, Method, To_date_written_down_value),
	written_down_value(Transaction, From_date, Method, From_date_written_down_value),
	Depreciation_value is From_date_written_down_value - To_date_written_down_value.

% Calculates written down value at a certain date equal or posterior to the invest in date using a daily basis
written_down_value(Transaction, Written_down_date, Method, Written_down_value):-
	transaction_cost(Transaction, Cost),
	transaction_date(Transaction, Invest_in_date),
	transaction_account(Transaction, Account),
	depreciation_between_invest_in_date_and_other_date(Cost, Cost, Method, Invest_in_date, Written_down_date, Account, 1, 1/365, Total_depreciation_value),
	Written_down_value is Cost - Total_depreciation_value.


/* There are 2 methods used for depreciation. a. Diminishing Value. What I believe you implemented. i.e. Rate 20% per period, 
Cost 100, then at end of period 1, Written Down Value is 100-20. For Period 2, 20%*80, For Period 3 20%*64 ... of course, 
written down value never gets to zero.

And there is Prime Cost Method. 20% of Cost each period. i.e. 100-20=80. 80-20=60, 60-20=40..... to zero.

And there is another concept to consider. If the asset (say a car) is depreciated to some value at some point in time, 
say $20. And the car is sold for $40, then there is a gain of $20. But if it is sold for $10, then there is a loss of $10. */

depreciation_by_method(Method, Initial_value, Depreciation_rate, Depreciation_fixed_value, By_day_factor, Days, Depreciation_value):-
	Factor is By_day_factor * Days,
	(Method == diminishing_value -> 
		Depreciation_value is Factor * Initial_value * Depreciation_rate
		;
		Depreciation_value is Factor * Depreciation_fixed_value).


/* If the temporal cycle of the depreciation calculation is annual, then each depreciation event is: 
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
account_type(depreciation, expense).
account_type(accumulated_depreciation, asset).
account_type(profit_and_loss, revenue).

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

depreciation_event(Original_transaction, Date, Method, Depreciation_value):-
	transaction_date(Original_transaction, Invest_in_date),
	depreciation_between_two_dates(Original_transaction, Invest_in_date, Date , Method, Depreciation_value),
	assert(transactions(transaction(Date, car_depreciation, depreciation, t_term(Depreciation_value, 0)))),
	assert(transactions(transaction(Date, car_depreciation, accumulated_depreciation, t_term(0, Depreciation_value)))).

% Create new facts with assert: generate transactions from asset disposal event
asset_disposal(Original_transaction, Date, Asset_price, Depreciation_method) :- 
	transaction_cost(Original_transaction, Asset_cost),
	depreciation_event(Original_transaction, Date, Depreciation_method, Depreciation_value),
	assert(transactions(transaction(Date, sell_car, motor_vehicles, t_term(0, Asset_cost)))),
	assert(transactions(transaction(Date, car_depreciation, accumulated_depreciation, t_term(Depreciation_value, 0)))),
	assert(transactions(transaction(Date, sell_car, bank, t_term(Asset_price, 0)))),
	Profit_and_loss is Asset_price - Asset_cost + Depreciation_value,
	print(Profit_and_loss),
	( Profit_and_loss >= 0 -> assert(transactions(transaction(Date, sell_car, profit_and_loss, t_term(0, Profit_and_loss))));
	assert(transactions(transaction(Date, sell_car, profit_and_loss, t_term(Profit_and_loss, 0))))
	).

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

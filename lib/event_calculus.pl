
:- module(event_calculus, [depreciationInInterval/13]).

:- use_module(library(clpfd)).
/*
:- use_module(depreciation_computation, [
    depreciation_rate/6,
    depreciation_value/6]).
*/
%:- dynamic happens/2.

% Define constraint in days, max 10000 days
time(T):- T #>= -1, T #=<100000.

initiated(F,T):- happens(E,T), initiates(E,F,T), time(T).
initiated(F,-1):- initially(F).

terminated(F,T):- happens(E,T), terminates(E,F,T), time(T).

initiatedBefore(F,T1,T):- initiated(F,T1), T1<T, time(T), time(T1).
terminatedBetween(F,T1,T2):- terminated(F,T), T>=T1, T<T2, time(T), time(T1), time(T2).
terminatedAfter(F,T1,T):- terminated(F,T), T>=T1, time(T), time(T1).

holdsAt(F,T):- initiatedBefore(F,T1,T), \+ terminatedBetween(F,T1,T), time(T), time(T1).

holdsAtAsset(Asset,in_pool(Asset,Pool),T):- holdsAt(in_pool(Asset,Pool),T).
holdsAtAsset(Asset,not_in_pool(Asset),T):- holdsAt(not_in_pool(Asset),T).

depreciationInInterval(_,_,_,T2,T2,_,_,_,_,_,[],Final_depreciation_value,Final_depreciation_value).

depreciationInInterval(Asset,Asset_cost,Purchase_date,T1,T2,Begin_value,End_value,Method,Year_from_purchase,Effective_life_years,
    [[Begin_value,H,T1,T,End_value,Depreciation_value,Rate]|RestOfLife],Initial_depreciation_value,Final_depreciation_value):- 
    T1 < T2,
    holdsAtAsset(Asset,H,T1),
    (H == in_pool(Asset,Pool)-> 
        depreciation_rate(Pool, Method, Year_from_purchase, Purchase_date, Effective_life_years, Rate); 
        depreciation_rate(Asset, Method, Year_from_purchase, Purchase_date, Effective_life_years, Rate)),
    terminatedAfter(H,T1,T),
    Days_held is T-T1,
    depreciation_value(Method, Asset_cost, Begin_value, Days_held, Rate, Depreciation_value),
    End_value is Begin_value - Depreciation_value,
    New_T1 is T + 1,
    New_initial_depreciation_value is (Initial_depreciation_value + Depreciation_value),
    depreciationInInterval(Asset,Asset_cost,Purchase_date,New_T1,T2,End_value,_,Method,Year_from_purchase,
        Effective_life_years,RestOfLife,New_initial_depreciation_value,Final_depreciation_value).

depreciationInInterval(Asset,Asset_cost,Purchase_date,T1,T2,Begin_value,End_value,Method,Year_from_purchase,Effective_life_years,
    [[Begin_value,H,T1,T2,End_value,Depreciation_value,Rate]|RestOfLife],Initial_depreciation_value,Final_depreciation_value):- 
    T1 < T2,
    holdsAtAsset(Asset,H,T1),
    (H == in_pool(Asset,Pool)->  
        depreciation_rate(Pool, Method, Year_from_purchase, Purchase_date, Effective_life_years, Rate); 
        depreciation_rate(Asset, Method, Year_from_purchase, Purchase_date, Effective_life_years, Rate)),
    \+ terminatedAfter(H,T1,_),
    Days_held is T2-T1,
    depreciation_value(Method, Asset_cost, Begin_value, Days_held, Rate, Depreciation_value),
    End_value is Begin_value - Depreciation_value,
    New_initial_depreciation_value is (Initial_depreciation_value + Depreciation_value),
    depreciationInInterval(_,_,_,T2,T2,_,_,_,_,_,RestOfLife,New_initial_depreciation_value,Final_depreciation_value).


/*
Note: ‘Days held’ is the number of days you held the asset in the income year, 
(the income year is a full financial year beginning on 1 July and ending on 30 June in Australia)
in which you used it or had it installed ready for use for any purpose. Days held can be 366 for a leap year.*/
depreciation_value(Method, Asset_cost, Asset_base_value, Days_held, Depreciation_rate, Depreciation_value) :- 
	(
	Method == diminishing_value
    -> Depreciation_value is Asset_base_value * (Days_held / 365) * Depreciation_rate
	;
	Depreciation_value is Asset_cost * (Days_held / 365) * Depreciation_rate
	).

% depreciation_rate(Asset/Pool, Method, Year_from_purchase, Purchase_date, Effective_life_years, Rate).
% If depreciation rate is not given, the generic calculation, for an individual Asset, is:
%The income year is a full financial year beginning on 1 July and ending 30 June in Australia
depreciation_rate(Asset, prime_cost,_,_,Effective_life_years, Rate) :-
	\+pool(Asset),
	Rate is 1 / Effective_life_years.
% If you started to hold the asset before 10 May 2006, the formula for the diminishing value method is:
% Base value × (days held ÷ 365) × (150% ÷ asset’s effective life)
depreciation_rate(Asset, diminishing_value,_,Purchase_date,Effective_life_years, Rate) :-
	\+pool(Asset),
    (Purchase_date @>= date(2016,5,10) -> Rate is 2 / Effective_life_years; Rate is 1.5 / Effective_life_years).
% Depreciation for Assets in Pools
% Depreciation rate for General Pool
/*
Small businesses can allocate depreciating assets that cost more than the instant asset write-off threshold of $20,000 
(or cost) or more to their general small business pool to be depreciated at a rate of 15% in the year of allocation and
 30% in other income years on a diminishing value basis, irrespective of the effective life of the asset.
 */
depreciation_rate(general_pool,diminishing_value,1,_,_,0.15).
depreciation_rate(general_pool,diminishing_value,_,_,_,0.3).
% Depreciation rate for Software Pool
depreciation_rate(software_pool,_, 1, _, _,0).
depreciation_rate(software_pool,_, 2, Purchase_date,_,Rate):- (Purchase_date @>= date(2015,7,1) -> Rate is 0.3; Rate is 0.4).
depreciation_rate(software_pool,_, 3, Purchase_date,_,Rate):- (Purchase_date @>= date(2015,7,1) -> Rate is 0.3; Rate is 0.4).
depreciation_rate(software_pool,_, 4, Purchase_date,_,Rate):- (Purchase_date @>= date(2015,7,1) -> Rate is 0.3; Rate is 0.2).
depreciation_rate(software_pool,_, 5, Purchase_date,_,Rate):- (Purchase_date @>= date(2015,7,1) -> Rate is 0.1; Rate is 0).
% Depreciation rate for Low Value Pool
/*
You calculate the depreciation of all the assets in the low-value pool at the annual rate of 37.5%.
If you acquire an asset and allocate it to the pool during an income year, you calculate its deduction at a rate of 18.75% 
(that is, half the pool rate) in that first year. 
This rate applies regardless of at what point during the year you allocate the asset to the pool.
TODO:If asset is transfered to low value pool, then it can't leave the pool afterwards.
Only low value or low cost assets can be allocated to a Low Value Pool
*/
depreciation_rate(low_value_pool,_,1,_,_,0.1875).
depreciation_rate(low_value_pool,_,_,_,_,0.375).

% For debugging
%start:-depreciationInInterval(car123,1000,date(2017,8,1),0,20,800,_,diminishing_value,1,5,Result,0,Total_depreciation).

asset(car123).

pool(general_pool).
pool(low_value_pool).
pool(software_pool).

fluent(in_pool(Asset,Pool)):- pool(Pool),asset(Asset).
fluent(not_in_pool(Asset)):- asset(Asset).

event(transfer_asset_to_pool(Asset, Pool)):- pool(Pool),asset(Asset).
event(remove_asset_from_pool(Asset, Pool)):- pool(Pool),asset(Asset).

initiates(transfer_asset_to_pool(Asset, Pool), in_pool(Asset, Pool),T):- time(T),asset(Asset),pool(Pool).
initiates(remove_asset_from_pool(Asset, Pool), not_in_pool(Asset),T):- time(T),asset(Asset),pool(Pool).

terminates(remove_asset_from_pool(Asset, Pool), in_pool(Asset, Pool),T):- time(T),asset(Asset),pool(Pool).
terminates(transfer_asset_to_pool(Asset, Pool), not_in_pool(Asset),T):- time(T),asset(Asset),pool(Pool).

% Every asset begins not in any pool
initially(not_in_pool(_)).
% Example usage
happens(transfer_asset_to_pool(car123,general_pool),3).
happens(remove_asset_from_pool(car123,general_pool),6).
happens(transfer_asset_to_pool(car123,low_value_pool),10).
happens(remove_asset_from_pool(car123,low_value_pool),15).
happens(transfer_asset_to_pool(car123,general_pool),17).

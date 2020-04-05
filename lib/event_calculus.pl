
:- module(event_calculus, [
		begin_income_year/1,
		days_from_begin_accounting/2,
        depreciationAsset/12,
        depreciation_value/6,
        depreciation_rate/6,
        asset/4,
        assert_asset/4,
        happens/2
    ]).


:- use_module(library(clpfd)).

%:- use_module(days, [day_diff/3,add_days/3]).

/*
:- use_module(depreciation_computation, [
    depreciation_rate/6,
    depreciation_value/6]).
*/

:- dynamic (asset/4).
:- dynamic happens/2.

assert_asset(Asset_id,Asset_cost,Start_date,Effective_life_years) :-
	assertz(asset(Asset_id,Asset_cost,Start_date,Effective_life_years)).

assert_event(Event, Days) :-
	assertz(happens(Event, Days)).

begin_accounting_date(date(1990,1,1)).
begin_income_year(date(_,7,1)).

% Define constraint in days, max 100000 days
time(T):- T #>= -1, T #=< 100000.

initiated(F,T):- happens(E,T), initiates(E,F,T), time(T).
initiated(F,-1):- initially(F).

terminated(F,T):- happens(E,T), terminates(E,F,T), time(T).

initiatedBefore(F,T1,T):- initiated(F,T1), T1<T, time(T), time(T1).
terminatedBetween(F,T1,T2):- terminated(F,T), T>=T1, T<T2, time(T), time(T1), time(T2).
terminatedAfter(F,T1,T):- terminated(F,T), T>=T1, time(T), time(T1).

holdsAt(F,T):- initiatedBefore(F,T1,T), \+ terminatedBetween(F,T1,T), time(T), time(T1).

holdsAtAsset(Asset_id,in_pool(Asset_id,Pool),T):- holdsAt(in_pool(Asset_id,Pool),T).
holdsAtAsset(Asset_id,not_in_pool(Asset_id),T):- holdsAt(not_in_pool(Asset_id),T).

% if the start date is also the end date, final values = initial values
depreciationAsset(
	_Asset_id,
	T2,
	T2,
	End_value,
	End_value,
	_Method,
	_Year_from_start,
	[], % Life
	_While_in_pool,
	_What_pool,
	Final_depreciation_value,
	Final_depreciation_value).

depreciationAsset(
	Asset_id,T1,T2,Begin_value,End_value,Method,Year_from_start,
    [
    	[Begin_value,H,T1,New_T1,End_value,Depreciation_value,Rate]
    	|RestOfLife],
    While_in_pool,What_pool,Initial_depreciation_value,Final_depreciation_value
):-
    T1 < T2,
    (T2 - T1) < 367,
    asset(Asset_id,Asset_cost,Start_date,Effective_life_years),
    holdsAtAsset(Asset_id,H,T1),
    ((H = in_pool(Asset_id,Pool))->
        depreciation_rate(Pool, Method, Year_from_start, Start_date, Effective_life_years, Rate); 
        depreciation_rate(Asset_id, Method, Year_from_start, Start_date, Effective_life_years, Rate)
    ),
    terminatedAfter(H,T1,T),
    New_T1 is T + 1,
    Days_held is New_T1-T1,
    depreciation_value(Method, Asset_cost, Begin_value, Days_held, Rate, Depreciation_value),
    New_end_value is (Begin_value - Depreciation_value),
    (	(While_in_pool, H == in_pool(Asset_id,What_pool); not(While_in_pool))
    ->	New_initial_depreciation_value is (Initial_depreciation_value + Depreciation_value)
    ;	New_initial_depreciation_value is Initial_depreciation_value),
    depreciationAsset(Asset_id,New_T1,T2,New_end_value,End_value,Method,Year_from_start,
        RestOfLife,While_in_pool,What_pool,New_initial_depreciation_value,Final_depreciation_value).

%reduce end value even if not in specified pool, so that when in pool the begin value is correct
depreciationAsset(Asset_id,T1,T2,Begin_value,End_value,Method,Year_from_start,
    [[Begin_value,H,T1,T2,End_value,Depreciation_value,Rate]|RestOfLife],While_in_pool,What_pool,Initial_depreciation_value,Final_depreciation_value):- 
    T1 < T2,
    (T2 - T1) < 367,
    asset(Asset_id,Asset_cost,Start_date,Effective_life_years),
    holdsAtAsset(Asset_id,H,T1),
    (holdsAtAsset(Asset_id,in_pool(Asset_id,Pool),T1)->
        depreciation_rate(Pool, Method, Year_from_start, Start_date, Effective_life_years, Rate); 
        depreciation_rate(Asset_id, Method, Year_from_start, Start_date, Effective_life_years, Rate)),
    not(terminatedBetween(H,T1,T2)),
    Days_held is T2-T1,
    depreciation_value(Method, Asset_cost, Begin_value, Days_held, Rate, Depreciation_value),
    New_end_value is (Begin_value - Depreciation_value),
    ((While_in_pool, H == in_pool(Asset_id,What_pool); not(While_in_pool))
    -> New_initial_depreciation_value is (Initial_depreciation_value + Depreciation_value);
        New_initial_depreciation_value is Initial_depreciation_value),
    depreciationAsset(Asset_id,T2,T2,New_end_value,End_value,_,_,RestOfLife,While_in_pool,What_pool,New_initial_depreciation_value,Final_depreciation_value).

/*
Note: ‘Days held’ is the number of days you held the asset in the income year, 
(the income year is a full financial year beginning on 1 July and ending on 30 June in Australia)
in which you used it or had it installed ready for use for any purpose. Days held can be 366 for a leap year.*/
depreciation_value(Method, Asset_cost, Asset_base_value, Days_held, Depreciation_rate, Depreciation_value) :- 
    Days_held < 367,
	(
	Method == diminishing_value
    -> Depreciation_value is Asset_base_value * (Days_held / 365) * Depreciation_rate
	;
	Depreciation_value is Asset_cost * (Days_held / 365) * Depreciation_rate
	).

% depreciation_rate(Asset/Pool, Method, Year_from_Start, Start_date, Effective_life_years, Rate).
% If depreciation rate is not given, the generic calculation, for an individual Asset, is:
%The income year is a full financial year beginning on 1 July and ending 30 June in Australia

depreciation_rate(Asset, prime_cost,_,_,Effective_life_years, Rate) :-
	not(pool(Asset)),
	Rate is 1 / Effective_life_years.


depreciation_rate(Asset, diminishing_value,_,Start_date,Effective_life_years, Rate) :-
	not(pool(Asset)),
    (	Start_date @< date(2006,5,10)
    	% If you started to hold the asset before 10 May 2006, the formula for the diminishing value method is:
		% Base value × (days held ÷ 365) × (150% ÷ asset’s effective life)
     -> Rate is 1.5 / Effective_life_years
     	% otherwise:
     ;	Rate is 2 / Effective_life_years).
% Depreciation for Assets in Pools
% Depreciation rate for General Pool
/*
Small businesses can allocate depreciating assets that cost more than the instant asset write-off threshold of $20,000 
(or cost) or more to their general small business pool to be depreciated at a rate of 15% in the year of allocation and
 30% in other income years on a diminishing value basis, irrespective of the effective life of the asset.
 */
depreciation_rate(general_pool,diminishing_value,1,_,_,0.15).
depreciation_rate(general_pool,diminishing_value,Year,_,_,0.3):- Year #> 1.

% Depreciation rate for Software Pool
depreciation_rate(software_pool,_, 1, _, _,0).
depreciation_rate(software_pool,_, 2, Start_date,_,Rate):- (Start_date @>= date(2015,7,1) -> Rate is 0.3; Rate is 0.4).
depreciation_rate(software_pool,_, 3, Start_date,_,Rate):- (Start_date @>= date(2015,7,1) -> Rate is 0.3; Rate is 0.4).
depreciation_rate(software_pool,_, 4, Start_date,_,Rate):- (Start_date @>= date(2015,7,1) -> Rate is 0.3; Rate is 0.2).
depreciation_rate(software_pool,_, 5, Start_date,_,Rate):- (Start_date @>= date(2015,7,1) -> Rate is 0.1; Rate is 0).
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
depreciation_rate(low_value_pool,_,Year,_,_,0.375):- Year > 1.
% For debugging
%start:-depreciationInInterval(car123,1000,date(2017,8,1),0,20,800,_,diminishing_value,1,5,Result,0,Total_depreciation).

pool(general_pool).
pool(low_value_pool).
pool(software_pool).

fluent(in_pool(Asset_id,Pool)):- pool(Pool),asset(Asset_id,_,_,_).
fluent(not_in_pool(Asset_id)):- asset(Asset_id,_,_,_).

event(transfer_asset_to_pool(Asset_id, Pool)):- pool(Pool),asset(Asset_id,_,_,_).
event(asset_disposal(Asset_id)):-asset(Asset_id,_,_,_).

% an Asset can only be transferred in the beginning of an income year
initiates(transfer_asset_to_pool(Asset_id, Pool), in_pool(Asset_id, Pool),T):- 
    time(T),
    begin_accounting_date(Begin_accounting_date),
    add_days(Begin_accounting_date,T,Date),
    begin_income_year(Date),
    asset(Asset_id,_,_,_),
    pool(Pool).
initiates(asset_disposal(Asset_id), not_in_pool(Asset_id),T):- time(T),asset(Asset_id,_,_,_).

terminates(asset_disposal(Asset_id), in_pool(Asset_id, Pool),T):- time(T),asset(Asset_id,_,_,_),pool(Pool).
terminates(transfer_asset_to_pool(Asset_id, Pool), not_in_pool(Asset_id),T):- time(T),asset(Asset_id,_,_,_),pool(Pool).

% Every asset begins not in any pool
initially(not_in_pool(_)).
% Example usage
% asset(Asset_id,Asset_cost,Start_date,Effective_life_years)
/*asset(car123,1000,date(2017,5,1),5).
asset(car456,2000,date(2015,3,16),8).*/

days_from_begin_accounting(Date,Days):-
    begin_accounting_date(Begin_accounting_date), 
    day_diff(Begin_accounting_date,Date,Days).

% Transfer car123 to general pool in date(2017,7,1)
% days_from_begin_accounting(date(2017,7,1),Days).
% Days = 10043
%happens(transfer_asset_to_pool(car123,general_pool),10043).
% Transfer car456 to general pool in date(2015,7,1)
% days_from_begin_accounting(date(2015,7,1),Days).
% Days = 9312
%happens(transfer_asset_to_pool(car456,general_pool),9312).
% Remove car123 from general pool in date(2021,6,1) by disposal
% days_from_begin_accounting(date(2021,6,1),Days).
% Days = 11474
%happens(asset_disposal(car123),11474).
% Remove car456 from general pool in date(2020,7,31) by disposal
% days_from_begin_accounting(date(2020,7,31),Days).
% Days = 11169
%happens(asset_disposal(car456),11169).
/*
start:-
    Asset_id = car123,
    T1 = 9982,
    T2 = 10043,
    Begin_value = 1000,
    Method = diminishing_value,
    Year_of_depreciation = 1,
    depreciationAsset(Asset_id,T1,T2,Begin_value,_End_value,Method,Year_of_depreciation,
        Life,false,_,0,_Final_depreciation_value),
    write(Life).
*/
%start:-depreciationAsset(car456,0,9,1000,End_value,prime_cost,1,Life,false,_,0,Final_depreciation_value).
%asset(Asset_id,Asset_cost,Start_date,Effective_life_years).
%asset(Asset_id,Asset_cost,Start_date,Effective_life_years).
%asset(Asset_id,Asset_cost,Start_date,Effective_life_years)

/*asset(car123,1000,date(2017,5,1),5).
asset(car456,2000,date(2015,3,16),8).

happens(transfer_asset_to_pool(car123,general_pool),5).
happens(transfer_asset_to_pool(car456,general_pool),6).
happens(remove_asset_from_pool(car123,general_pool),8).
happens(remove_asset_from_pool(car456,general_pool),10).

start:-depreciationAsset(car456,0,9,1000,End_value,prime_cost,1,Life,false,_,0,Final_depreciation_value).
%findall((Asset_id,Depreciation_value),depreciationAsset(Asset_id,0,9,1000,End_value,prime_cost,1,Life,false,_,0,Depreciation_value),Result).
%findall((Asset_id,Depreciation_value),depreciationAsset(Asset_id,0,9,1000,End_value,prime_cost,1,Life,true,general_pool,0,Depreciation_value),Result).

*/

:- module(depreciation_new, []).

:- use_module(days, [day_diff/3, leap_year/1]).
:- use_module(utils, [throw_string/1]).
/*
Ultimately we need to tie the following logic into the Ledger module.

Accounting depreciation
Increasing balancing adjustment on disposal
Decreasing balancing adjustment on disposal
Capital gain

Also, the accumulated depreciation account must be zeroed at disposal as part of the increasing/decreasing/gain computation.

% A pool of assets is treated like an unique asset when it comes to depreciation

%non-current-asset; fixed asset; low value pool
%"";software pools
%"";low value pool
%"";general pool
*/
ancestor(Ancestor, Descendant):- isa(Descendant, Ancestor).
ancestor(Ancestor, Descendant):- isa(Descendant, Parent), ancestor(Ancestor, Parent).

isa(general_pool, pool).
isa(software_pool, pool).
isa(low_value_pool, pool).
isa(pool, asset).

isa(corolla, toyota).
isa(toyota, car).
isa(car, motor_vehicles).
isa(motor_vehicles, property_plant_and_equipment).
isa(property_plant_and_equipment, non_current_asset).
isa(non_current_asset, asset).

% Calculations for each year
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

% Calculates depreciation on a daily basis between the invest in date and any other date
% recurses for every income year, because depreciation rates may be different
depreciation_between_invest_in_date_and_other_date(
	Invest_in_value, 						% value at time of investment/ Asset Cost
	Initial_value, 							% value at start of year / Asset Base Value
	Method, 								% Diminishing Value / Prime Cost
	date(From_year, From_Month, From_day),	% date of investment/purchase, it should be date of beginning to use the asset
	To_date,								% date for which depreciation should be computed
	Asset,									% Asset or pool (pool is an asset in the account taxonomy)
	Rates,
	Depreciation_year, 						% 1,2,3...
	Effective_life_years,
	Total_depreciation_value
) :-
	day_diff(date(From_year, From_Month, From_day), To_date, Days_difference),
	check_day_difference_validity(Days_difference),
	% Get days From date until end of the current income year, <=365
	(
		From_Month < 7  
		-> 
			day_diff(date(From_year, From_Month, From_day), date(From_year, 7, 1), Days_held),
			Next_from_year is From_year
			;
			day_diff(date(From_year, From_Month, From_day), date(From_year + 1, 7, 1), Days_held),
			Next_from_year is From_year + 1
	),
	depreciation_scheme(Asset, Method, Depreciation_year, date(From_year, From_Month, From_day), Effective_life_years, Depreciation_rate),
	(
		Days_difference =< Days_held
			-> Days_held is Days_difference,
			depreciation_value(Method, Invest_in_value, Initial_value, Days_held, Depreciation_rate, Total_depreciation_value)
	;
		(	
			depreciation_value(Method, Invest_in_value, Initial_value, Days_held, Depreciation_rate, Depreciation_value),
			Next_depreciation_year is Depreciation_year + 1,
			Next_initial_value is Initial_value - Depreciation_value,
			depreciation_between_invest_in_date_and_other_date(
				Invest_in_value, 
				Next_initial_value, 
				Method,
				date(Next_from_year, 7, 1), 
				To_date, 
				Asset,
				Rates, 
				Next_depreciation_year, 
				Effective_life_years, 
				Next_depreciation_value
			),
			Total_depreciation_value is  Depreciation_value + Next_depreciation_value
		)
	).

check_day_difference_validity(Days_difference) :-
	(
	Days_difference >= 0
	->
		true
	;
		throw_string('Request date is earlier than the invest in date.')
	).

%depreciation_method(prime_cost).
%depreciation_method(diminishing_value).
% depreciation_scheme(Asset/Pool, Method, Year_from_purchase, Purchase_date, Effective_life_years, Rate).
% If depreciation rate is not given, the generic calculation, for an individual Asset, is:
%The income year is a full financial year beginning on 1 July and ending 30 June in Australia
depreciation_scheme(Asset, prime_cost,_,_,Effective_life_years, Rate) :- 
	\+ pool(Asset), \+ in_pool(Asset,_), Rate is 1 / Effective_life_years.
% If you started to hold the asset before 10 May 2006, the formula for the diminishing value method is:
% Base value × (days held ÷ 365) × (150% ÷ asset’s effective life)
depreciation_scheme(Asset, diminishing_value,_,Purchase_date,Effective_life_years, Rate) :- 
	\+ pool(Asset), \+ in_pool(Asset,_),
    (Purchase_date @>= date(2016,5,10) -> Rate is 2 / Effective_life_years; Rate is 1.5 / Effective_life_years).
% Depreciation for Assets in Pools
% Depreciation scheme for General Pool
/*
Small businesses can allocate depreciating assets that cost more than the instant asset write-off threshold of $20,000 
(or cost) or more to their general small business pool to be depreciated at a rate of 15% in the year of allocation and
 30% in other income years on a diminishing value basis, irrespective of the effective life of the asset.
 */
depreciation_scheme(general_pool,diminishing_value,1,_,_,0.15).
depreciation_scheme(general_pool,diminishing_value,_,_,_,0.3).
% Depreciation scheme for Software Pool
depreciation_scheme(software_pool,_, 1, _, _,0).
depreciation_scheme(software_pool,_, 2, Purchase_date,_,Rate):- (Purchase_date @>= date(2015,7,1) -> Rate is 0.3; Rate is 0.4).
depreciation_scheme(software_pool,_, 3, Purchase_date,_,Rate):- (Purchase_date @>= date(2015,7,1) -> Rate is 0.3; Rate is 0.4).
depreciation_scheme(software_pool,_, 4, Purchase_date,_,Rate):- (Purchase_date @>= date(2015,7,1) -> Rate is 0.3; Rate is 0.2).
depreciation_scheme(software_pool,_, 5, Purchase_date,_,Rate):- (Purchase_date @>= date(2015,7,1) -> Rate is 0.1; Rate is 0).
% Depreciation scheme for Low Value Pool
/*
You calculate the depreciation of all the assets in the low-value pool at the annual rate of 37.5%.
If you acquire an asset and allocate it to the pool during an income year, you calculate its deduction at a rate of 18.75% 
(that is, half the pool rate) in that first year. 
This rate applies regardless of at what point during the year you allocate the asset to the pool.
TODO:If asset is transfered to low value pool, then it can't leave the pool afterwards.
Only low value or low cost assets can be allocated to a Low Value Pool
*/
depreciation_scheme(low_value_pool,_,1,_,_,0.1875).
depreciation_scheme(low_value_pool,_,_,_,_,0.375).

pool(general_pool).
pool(low_value_pool).
pool(software_pool).

transfer_asset_to_pool(Asset, Pool, [Asset|Pool]).

in_pool(asset(Asset_id,_,_), Pool):- member(Asset_id, Pool).

%transactions(transaction(date(19, 7, 1), buy_car, motor_vehicles, t_term(1000, 0))).
asset_from_transaction(transaction(Date,_,Account,t_term(Cost,0)), asset(Account, Cost, Date)).

asset_cost(asset(_,Cost,_),Cost).
asset_date_of_purchase(asset(_,_,Date),Date).
asset_account(asset(Account,_,_),Account).

low_cost_asset(Asset) :- asset_cost(Asset, Cost), Cost < 1000.

/*
TODO:
low_value_asset(Asset, Current_date):- 
    asset_date_of_purchase(Asset,Purchase_date),
    day_diff(Purchase_date, Current_date, Days_since_purchase),
    Days_since_purchase >=365,
    written_down_value_asset(Asset, Current_date, diminishing_value, Rates, Written_down_value),
    Written_down_value < 1000.
    % to add: , previous deductions used diminishing_value.

written_down_value_asset(Asset, Written_down_date, Method, Rates, Written_down_value):-
	asset_cost(Asset, Cost),
	asset_date_of_purchase(Asset, Invest_in_date),
	asset_account(Asset, Account),
	depreciation_between_invest_in_date_and_other_date(
		Cost, 
		Cost, 
		Method, 
		Invest_in_date, 
		Written_down_date, 
		Account, 
		Rates,
		1,% i guess this is in the sense of first year of ownership
		1/365, 
		Total_depreciation_value
	),
	Written_down_value is Cost - Total_depreciation_value.

*/


:- module(depreciation_computation, [
		written_down_value/6, 
		depreciation_between_two_dates/7, 
		transaction_account/2, 
		transaction_cost/2, 
		transaction_date/2]).


:- use_module(days, [day_diff/3]).
:- use_module(utils, [throw_string/1]).


% Calculates depreciation on a daily basis between the invest in date and any other date
% recurses for every income year, because depreciation rates may be different
depreciation_between_invest_in_date_and_other_date(
		Invest_in_value, 						% value at time of investment/ Asset Cost
		Initial_value, 							% value at start of year / Asset Base Value
		Method, 								% Diminishing Value / Prime Cost
		date(From_year, From_Month, From_day),	% date of investment/purchase, it should be date of beginning to use the asset
		To_date,								% date for which depreciation should be computed
		Account,								% Asset or pool (pool is an asset in the account taxonomy)
		Rates,
		Depreciation_year, 						% 1,2,3...
		Effective_life_years,
		Total_depreciation_value
	) :-
	/*format(user_error, depreciation_between_invest_in_date_and_other_date,[]),*/
	day_diff(date(From_year, From_Month, From_day), To_date, Days_difference),
	check_day_difference_validity(Days_difference),	
	
	% throw exception 
	% if we do not have depreciation rate for the specific year we are looking for or
	% if there is no depreciation rate with unbound variable for depreciation year
	copy_term(Rates, Rates_Copy),
	(	
	%depreciation_rate(Asset/Pool, Method, Year_from_purchase, Purchase_date, Effective_life_years, Rate).
	member(depreciation_rate(Account, Method, Depreciation_year, date(From_year, From_Month, From_day), Effective_life_years, Depreciation_rate), Rates_Copy)
	->
		true
	;
		throw_string('Expected depreciation rate not found.')		
	),
		
	/*format(user_error, "ok..\n", []),*/
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
				Account,
				Rates, 
				Next_depreciation_year, 
				Effective_life_years, 
				Next_depreciation_value
			),
			Total_depreciation_value is  Depreciation_value + Next_depreciation_value
		)
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

% List of available pools
pool(general_pool).
pool(software_pool).
pool(low_value_pool).

% Calculates depreciation between any two dates on a daily basis equal or posterior to the invest in date
depreciation_between_two_dates(Transaction, From_date, To_date, Method, Rates, Effective_life_years, Depreciation_value):-
	day_diff(From_date, To_date, Days_difference),
	check_day_difference_validity(Days_difference),
	written_down_value(Transaction, To_date, Method, Rates, Effective_life_years, To_date_written_down_value),
	written_down_value(Transaction, From_date, Method, Rates,Effective_life_years, From_date_written_down_value),
	Depreciation_value is From_date_written_down_value - To_date_written_down_value.

% Calculates written down value at a certain date equal or posterior to the invest in date using a daily basis
written_down_value(Transaction, Written_down_date, Method, Rates, Effective_life_years, Written_down_value):-
	transaction_cost(Transaction, Cost),
	transaction_date(Transaction, Invest_in_date),
	transaction_account(Transaction, Account),
	depreciation_between_invest_in_date_and_other_date(
		Cost, 
		Cost, 
		Method, 
		Invest_in_date, 
		Written_down_date, 
		Account, 
		Rates,
		1,/* i guess this is in the sense of first year of ownership*/
		Effective_life_years, 
		Total_depreciation_value
	),
	Written_down_value is Cost - Total_depreciation_value.

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

% if days difference is less than zero, it means that the requested date 
% in the input value is earlier than the invest in date.
check_day_difference_validity(Days_difference) :-
	(
	Days_difference >= 0
	->
		true
	;
		throw_string('Request date is earlier than the invest in date.')
	).

% Predicates for asserting that the fields of given transactions have particular values
% duplicated from transactions.pl with the difference that transaction_date is used instead of transaction_day
% ok well transactions.pl transactions now use date too, just havent renamed it yet, so we can probably use it 
% The absolute day that the transaction happenned
% ok well transactions.pl uses dates, not days
% input and output xml should use dates too, so idk, best to convert it to days just inside the computation functions and convert it back after
transaction_date(transaction(Date, _, _, _), Date).
% A description of the transaction
transaction_description(transaction(_, Description, _, _), Description).
% The account that the transaction modifies
transaction_account(transaction(_, _, Account_Id, _), Account_Id).
% The amounts by which the account is being debited and credited
transaction_vector(transaction(_, _, _, Vector), Vector).
% Extract the cost of the buy from transaction data
transaction_cost(transaction(_, _, _, t_term(Cost, _)), Cost).



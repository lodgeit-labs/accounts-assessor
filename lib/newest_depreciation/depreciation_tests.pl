:- use_module(event_calculus,[
        depreciation_value/6,
        depreciation_rate/6,
        depreciationAsset/12,
        asset/4,
        happens/2]).

:- use_module(depreciation_computation,[
    depreciation_between_start_date_and_other_date/11,
    depreciation_pool/6]).

:- begin_tests(depreciation).

test(depreciation_value_prime_cost) :-
    Method = prime_cost,
    Asset_cost = 1000,
    Asset_base_value = 800,
    Days_held = 200,
    Depreciation_rate = 0.2,
    Correct_depreciation_value is Asset_cost * (Days_held / 365) * Depreciation_rate,
    depreciation_value(Method, Asset_cost, Asset_base_value, Days_held, Depreciation_rate, Depreciation_value),
    assertion(Depreciation_value == Correct_depreciation_value).

test(depreciation_value_dimishing_value):-
    Method = diminishing_value,
    Asset_cost = 1000,
    Asset_base_value = 800,
    Days_held = 200,
    Depreciation_rate = 0.2,
    Correct_depreciation_value is Asset_base_value * (Days_held / 365) * Depreciation_rate,
    depreciation_value(Method, Asset_cost, Asset_base_value, Days_held, Depreciation_rate, Depreciation_value),
    assertion(Depreciation_value == Correct_depreciation_value).

test(depreciation_value_prime_cost_fail,fail) :-
    Method = prime_cost,
    Asset_cost = 1000,
    Asset_base_value = 800,
    Days_held = 367,
    Depreciation_rate = 0.2,
    Correct_depreciation_value is Asset_cost * (Days_held / 365) * Depreciation_rate,
    depreciation_value(Method, Asset_cost, Asset_base_value, Days_held, Depreciation_rate, Depreciation_value),
    assertion(Depreciation_value == Correct_depreciation_value).

test(depreciation_value_dimishing_value_fail,fail):-
    Method = diminishing_value,
    Asset_cost = 1000,
    Asset_base_value = 800,
    Days_held = 400,
    Depreciation_rate = 0.2,
    Correct_depreciation_value is Asset_base_value * (Days_held / 365) * Depreciation_rate,
    depreciation_value(Method, Asset_cost, Asset_base_value, Days_held, Depreciation_rate, Depreciation_value),
    assertion(Depreciation_value == Correct_depreciation_value).

test(depreciation_rate_prime_cost) :-
    Method = prime_cost,
    Asset_id = car123,
    Effective_life_years = 5,
    depreciation_rate(Asset_id, Method,_,_,Effective_life_years, Rate),
    assertion(Rate == 0.2).

test(depreciation_rate_prime_cost) :-
    Method = diminishing_value,
    Asset_id = car123,
    Effective_life_years = 5,
    Start_date = date(2017,1,1),
    depreciation_rate(Asset_id, Method,_,Start_date,Effective_life_years, Rate),
    assertion(Rate == 0.4).

/*
% Transfer car123 to general pool in date(2017,6,1)
% days_from_begin_accounting(date(2017,6,1),Days).
% Days = 10013
happens(transfer_asset_to_pool(car123,general_pool),10013).
% Transfer car456 to general pool in date(2015,8,1)
% days_from_begin_accounting(date(2015,8,1),Days).
% Days = 9343
happens(transfer_asset_to_pool(car456,general_pool),9343).
% Remove car123 from general pool in date(2021,6,1) by disposal
% days_from_begin_accounting(date(2021,6,1),Days).
% Days = 11474
happens(remove_asset_from_pool(car123,general_pool),11474).
% Remove car456 from general pool in date(2020,7,31) by disposal
% days_from_begin_accounting(date(2020,7,31),Days).
% Days = 11169
happens(remove_asset_from_pool(car456,general_pool),11169).
*/
test(depreciationAsset_all_life_1):-
    Asset_id = car123,
    T1 = 10000,
    T2 = 10213,
    Begin_value = 1000,
    Method = diminishing_value,
    Year_of_depreciation = 1,
    depreciationAsset(Asset_id,T1,T2,Begin_value,End_value,Method,Year_of_depreciation,Life,false,_,0,Final_depreciation_value),
    assertion(Life == [[1000,not_in_pool(car123),10000,10013,770.7781572527679,14.246575342465754,0.4],
        [985.7534246575342,in_pool(car123,general_pool),10014,10213,770.7781572527679,214.97526740476638,0.4]]),
    assertion(Final_depreciation_value=:=229.22184274723213),
    Correct_end_value is Begin_value - Final_depreciation_value,
    assertion(Correct_end_value =:= End_value).

test(depreciationAsset_all_life_2):-
    Asset_id = car456,
    T1 = 9300,
    T2 = 9500,
    Begin_value = 1000,
    Method = diminishing_value,
    Year_of_depreciation = 1,
    depreciationAsset(Asset_id,T1,T2,Begin_value,End_value,Method,Year_of_depreciation,Life,false,_,0,Final_depreciation_value),
    assertion(Life==[[1000,not_in_pool(car456),9300,9343,899.5441217864516,22.089041095890412,0.1875],
        [977.9109589041096,in_pool(car456,general_pool),9344,9500,899.5441217864516,78.36683711765811,0.1875]]),
    assertion(Final_depreciation_value=:=100.45587821354852),
    Correct_end_value is Begin_value - Final_depreciation_value,
    assertion(round(Correct_end_value) =:= round(End_value)).

test(depreciationAsset_only_in_pool_1):-
    Asset_id = car123,
    T1 = 10000,
    T2 = 10213,
    Begin_value = 1000,
    Method = diminishing_value,
    Year_of_depreciation = 1,
    depreciationAsset(Asset_id,T1,T2,Begin_value,_,Method,Year_of_depreciation,Life,true,general_pool,0,Final_depreciation_value),
    assertion(Life == [[1000,not_in_pool(car123),10000,10013,770.7781572527679,14.246575342465754,0.4],
        [985.7534246575342,in_pool(car123,general_pool),10014,10213,770.7781572527679,214.97526740476638,0.4]]),
    assertion(Final_depreciation_value=:=214.97526740476638).

test(depreciationAsset_only_in_pool_2):-
    Asset_id = car456,
    T1 = 9300,
    T2 = 9500,
    Begin_value = 1000,
    Method = diminishing_value,
    Year_of_depreciation = 1,
    depreciationAsset(Asset_id,T1,T2,Begin_value,_,Method,Year_of_depreciation,Life,true,general_pool,0,Final_depreciation_value),
    assertion(Life==[[1000,not_in_pool(car456),9300,9343,899.5441217864516,22.089041095890412,0.1875],
        [977.9109589041096,in_pool(car456,general_pool),9344,9500,899.5441217864516,78.36683711765811,0.1875]]),
    assertion(Final_depreciation_value=:=78.36683711765811).

test(depreciation_between_start_date_and_other_date_all_life):-
    /* Parameters of predicate
    Initial_value, 							% value at start of year / Asset Base Value
    Method, 								% Diminishing Value / Prime Cost
    date(From_year, From_Month, From_day),  % Start depreciation date
    To_date,								% date for which depreciation should be computed
    Asset_id,								% Asset
    Rates,
    Depreciation_year, 						% 1,2,3...
    While_in_pool,
    What_pool,
    Initial_depreciation_value,
    Total_depreciation_value*/
    /*
    asset: car123, start depreciation date: 2017-5-1, cost: 1000, effective life years defined: 5
    Method: diminishing value
    Transfered to general pool in: 2017-6-1
    Removed from general pool in: 2020-7-31
    1st income year from 2017-5-1 to 2017-6-30
    2017-5-1 to 2017-6-1 depreciated as an individual asset: 31 days
    1000 * 31/365 * 2/5 = 33,97260274
    2017-6-2 to 2017-6-30 depreciated in the general pool: 28 days
    (1000-33,97260274)*28/365*0.15 = 11,115931694
    2nd income year from 2017-7-1 to 2018-6-30:365 days, rate is 0.3 from second year on
    (1000-33,97260274-11,115931694)* 365/365 * 0.3 = 286,47343967
    3rd income year from 2018-7-1 to 2019-6-30:365 days
    (1000-33,97260274-11,115931694-286,47343967)* 365/365 * 0.3 = 200,531407769
    4th income year from 2019-7-1 to 2019-10-2: 93 days(shortened due to the To_date defined)
    (1000-33,97260274-11,115931694-286,47343967-200,531407769) * 93/365 * 0.3 = 35,766012728
    Total depreciation value is 33,97260274 + 11,115931694 + 286,47343967 + 200,531407769 +
    35,766012728 = 567,859394601
    */
    depreciation_between_start_date_and_other_date(1000,diminishing_value,date(2017,6,1),date(2019,10,2),car123,_,1,false,_,0,Total_depreciation_value),
    assertion(Total_depreciation_value == 567,859394601).

test(depreciation_between_start_date_and_other_date_while_in_pool_1):-
    /* Parameters of predicate
    Initial_value, 							% value at start of year / Asset Base Value
    Method, 								% Diminishing Value / Prime Cost
    date(From_year, From_Month, From_day),
    To_date,								% date for which depreciation should be computed
    Asset_id,								% Asset
    Rates,
    Depreciation_year, 						% 1,2,3...
    While_in_pool,
    What_pool,
    Initial_depreciation_value,
    Total_depreciation_value*/
    depreciation_between_start_date_and_other_date(1000,diminishing_value,date(2017,6,1),date(2019,10,2),car123,_,1,true,general_pool,0,Total_depreciation_value),
    assertion(Total_depreciation_value == 790.6679798684376).

test(depreciation_between_start_date_and_other_date_while_in_pool_2):-
    /* Parameters of predicate
    Initial_value, 							% value at start of year / Asset Base Value
    Method, 								% Diminishing Value / Prime Cost
    date(From_year, From_Month, From_day),  % Start date
    To_date,								% date for which depreciation should be computed
    Asset_id,								% Asset
    Rates,
    Depreciation_year, 						% 1,2,3...
    While_in_pool,
    What_pool,
    Initial_depreciation_value,
    Total_depreciation_value*/
    depreciation_between_start_date_and_other_date(2000,diminishing_value,date(2015,3,16),date(2019,10,2),car456,_,1,true,general_pool,0,Total_depreciation_value),
    assertion(Total_depreciation_value == 1235.298708978685).

test(depreciation_pool):-
    depreciation_pool(general_pool,date(2017,1,1),date(2019,2,2),1000,diminishing_value,Total_depreciation),
    % From above the pool should add the depreciation values of each asset for the same period
    Correct_total_depreciation is 1235.298708978685+790.6679798684376,
    assertion(Total_depreciation==Correct_total_depreciation).

:- end_tests(depreciation).
:- run_tests.
:- use_module(event_calculus,[
        depreciation_value/6,
        depreciation_rate/6,
        depreciationAsset/12,
        asset/4,
        happens/2]).

:- use_module(depreciation_computation,[
    depreciation_between_start_date_and_other_date/11,
    depreciation_pool_from_start/4,
    depreciation_pool_between_two_dates/5,
    written_down_value/5,
    depreciation_between_two_dates/5,
    profit_and_loss/5]).

:- begin_tests(depreciation).

test(depreciation_value_prime_cost) :-
    Method = prime_cost,
    Asset_cost = 1000,
    Asset_base_value = 800,
    Days_held = 200,
    Depreciation_rate = 0.2,
    Correct_depreciation_value is Asset_cost * (Days_held / 365) * Depreciation_rate,
    depreciation_value(Method, Asset_cost, Asset_base_value, Days_held, 
        Depreciation_rate, Depreciation_value),
    assertion(Depreciation_value == Correct_depreciation_value).

test(depreciation_value_dimishing_value):-
    Method = diminishing_value,
    Asset_cost = 1000,
    Asset_base_value = 800,
    Days_held = 200,
    Depreciation_rate = 0.2,
    Correct_depreciation_value is Asset_base_value * (Days_held / 365) * Depreciation_rate,
    depreciation_value(Method, Asset_cost, Asset_base_value, Days_held, Depreciation_rate, 
        Depreciation_value),
    assertion(Depreciation_value == Correct_depreciation_value).

test(depreciation_value_prime_cost_fail,fail) :-
    Method = prime_cost,
    Asset_cost = 1000,
    Asset_base_value = 800,
    Days_held = 367,
    Depreciation_rate = 0.2,
    Correct_depreciation_value is Asset_cost * (Days_held / 365) * Depreciation_rate,
    depreciation_value(Method, Asset_cost, Asset_base_value, Days_held, Depreciation_rate, 
        Depreciation_value),
    assertion(Depreciation_value == Correct_depreciation_value).

test(depreciation_value_dimishing_value_fail,fail):-
    Method = diminishing_value,
    Asset_cost = 1000,
    Asset_base_value = 800,
    Days_held = 400,
    Depreciation_rate = 0.2,
    Correct_depreciation_value is Asset_base_value * (Days_held / 365) * Depreciation_rate,
    depreciation_value(Method, Asset_cost, Asset_base_value, Days_held, Depreciation_rate, 
        Depreciation_value),
    assertion(Depreciation_value == Correct_depreciation_value).

test(depreciation_rate_prime_cost) :-
    Method = prime_cost,
    Asset_id = car123,
    Effective_life_years = 5,
    depreciation_rate(Asset_id, Method,_,_,Effective_life_years, Rate),
    assertion(Rate == 0.2).

test(depreciation_rate_diminishing_value) :-
    Method = diminishing_value,
    Asset_id = car123,
    Effective_life_years = 5,
    Start_date = date(2017,1,1),
    depreciation_rate(Asset_id, Method,_,Start_date,Effective_life_years, Rate),
    assertion(Rate == 0.4).

test(depreciation_rate_general_pool) :-
    Asset_id = general_pool,
    Effective_life_years = 5,
    Start_date = date(2017,1,1),
    Year_from_start = 1,
    depreciation_rate(Asset_id, _,Year_from_start,Start_date,Effective_life_years, Rate),
    assertion(Rate == 0.15).

test(depreciation_rate_general_pool_fail, fail) :-
    % It should fail because general_pool can only use diminishing value method
    Asset_id = general_pool,
    Method = prime_cost,
    Effective_life_years = 5,
    Start_date = date(2017,1,1),
    Year_from_start = 1,
    depreciation_rate(Asset_id, Method,Year_from_start,Start_date,Effective_life_years, Rate),
    assertion(Rate == 0.15).

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
    depreciationAsset(Asset_id,T1,T2,Begin_value,End_value,Method,Year_of_depreciation,
        Life,false,_,0,Final_depreciation_value),
    assertion(Life == [[1000,not_in_pool(car123),10000,10014,904.131431788328,15.34246575342466,0.4],
        [984.6575342465753,in_pool(car123,general_pool),10014,10213,904.131431788328,80.52610245824732,0.15]]),
    assertion(Final_depreciation_value=:=95.86856821167198),
    Correct_end_value is Begin_value - Final_depreciation_value,
    assertion(round(Correct_end_value) =:= round(End_value)).

test(depreciationAsset_all_life_2):-
    Asset_id = car456,
    T1 = 9300,
    T2 = 9500,
    Begin_value = 1000,
    Method = diminishing_value,
    Year_of_depreciation = 1,
    depreciationAsset(Asset_id,T1,T2,Begin_value,End_value,Method,Year_of_depreciation,Life,
        false,_,0,Final_depreciation_value),
    assertion(Life==[[1000,not_in_pool(car456),9300,9344,914.7367235879152,22.602739726027398,0.1875],
        [977.3972602739726,in_pool(car456,general_pool),9344,9500,914.7367235879152,62.66053668605742,0.15]]),
    assertion(Final_depreciation_value=:=85.26327641208482),
    Correct_end_value is Begin_value - Final_depreciation_value,
    assertion(round(Correct_end_value) =:= round(End_value)).

test(depreciationAsset_all_life_3):-
    Asset_id = car123,
    T1 = 9982,
    T2 = 10042,
    Begin_value = 1000,
    Method = diminishing_value,
    Year_of_depreciation = 1,
    depreciationAsset(Asset_id,T1,T2,Begin_value,End_value,Method,Year_of_depreciation,
        Life,false,_,0,Final_depreciation_value),
    assertion(Life == [[1000,not_in_pool(car123),9982,10014,953.828185400638,35.06849315068493,0.4],
        [964.931506849315,in_pool(car123,general_pool),10014,10042,953.828185400638,11.103321448677049,0.15]]),
    assertion(Final_depreciation_value=:=46.17181459936198),
    Correct_end_value is Begin_value - Final_depreciation_value,
    assertion(round(Correct_end_value) =:= round(End_value)).

test(depreciationAsset_only_in_pool_1):-
    Asset_id = car123,
    T1 = 10000,
    T2 = 10213,
    Begin_value = 1000,
    Method = diminishing_value,
    Year_of_depreciation = 1,
    depreciationAsset(Asset_id,T1,T2,Begin_value,_,Method,Year_of_depreciation,Life,true,
        general_pool,0,Final_depreciation_value),
    assertion(Life ==  [[1000,not_in_pool(car123),10000,10014,904.131431788328,15.34246575342466,0.4],
        [984.6575342465753,in_pool(car123,general_pool),10014,10213,904.131431788328,80.52610245824732,0.15]]),
    assertion(Final_depreciation_value=:=80.52610245824732).

test(depreciationAsset_only_in_pool_2):-
    Asset_id = car456,
    T1 = 9300,
    T2 = 9500,
    Begin_value = 1000,
    Method = diminishing_value,
    Year_of_depreciation = 1,
    depreciationAsset(Asset_id,T1,T2,Begin_value,_,Method,Year_of_depreciation,Life,true,
        general_pool,0,Final_depreciation_value),
    assertion(Life==[[1000,not_in_pool(car456),9300,9344,914.7367235879152,22.602739726027398,0.1875],
        [977.3972602739726,in_pool(car456,general_pool),9344,9500,914.7367235879152,62.66053668605742,0.15]]),
    assertion(Final_depreciation_value=:=62.66053668605742).

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
    asset: car123, start depreciation date: 2017-5-1, cost: 1000, effective life years defined:
     5
    Method: diminishing value
    Transfered to general pool in: 2017-6-1
    Removed from general pool in: 2020-7-31
    1st income year from 2017-5-1 to 2017-6-30
    2017-5-1 to 2017-6-1 depreciated as an individual asset: 32 days
    1000 * 32/365 * 2/5 = 35,068493151
    2017-6-2 to 2017-7-1 depreciated in the general pool: 29 days
    (1000-35,068493151)*29/365*0.15 = 11,499868643
    2nd income year from 2017-7-1 to 2018-7-1:365 days, rate is 0.3 from second year on
    (1000-35,068493151-11,499868643)* 365/365 * 0.3 = 286,029491462
    3rd income year from 2018-7-1 to 2019-7-1:365 days
    (1000-35,068493151-11,499868643-286,029491462)* 365/365 * 0.3 = 200,220644023
    4th income year from 2019-7-1 to 2019-10-2: 93 days(shortened due to the To_date defined)
    (1000-35,068493151-11,499868643-286,029491462-200,220644023) * 93/365 * 0.3 = 35,710586098
    Total depreciation value is 35,068493151 + 11,499868643+ 286,029491462 + 200,220644023 +
    35,710586098 =568,529083377
    */
    depreciation_between_start_date_and_other_date(1000,diminishing_value,date(2017,5,1),
        date(2019,10,2),car123,_,1,false,_,0,Total_depreciation_value),
    assertion(round(Total_depreciation_value) =:= round(568.529083377)).

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
    depreciation_between_start_date_and_other_date(1000,diminishing_value,date(2017,6,1),
        date(2019,10,2),car123,_,1,true,general_pool,0,Total_depreciation_value),
    assertion(Total_depreciation_value == 552.8422309727339).

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
    depreciation_between_start_date_and_other_date(2000,diminishing_value,date(2015,3,16),
        date(2019,10,2),car456,_,1,true,general_pool,0,Total_depreciation_value),
    assertion(Total_depreciation_value == 1537.5037933680019).


test(depreciation_between_start_date_and_other_date_while_in_pool_3):-
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
    Asset_id = car123,
    asset(Asset_id,Cost,Start_date,_),
    depreciation_between_start_date_and_other_date(Cost,diminishing_value,Start_date,
        date(2019,2,2),Asset_id,_,1,true,general_pool,0,Total_depreciation_value),
    assertion(Total_depreciation_value == 430.8947462923214).

test(depreciation_between_start_date_and_other_date_while_in_pool_4):-
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
    Asset_id = car456,
    asset(Asset_id,Cost,Start_date,_),
    depreciation_between_start_date_and_other_date(Cost,diminishing_value,Start_date,
        date(2019,2,2),Asset_id,_,1,true,general_pool,0,Total_depreciation_value),
    assertion(Total_depreciation_value == 1411.6143525408916).

test(written_down_value_asset_1):-
    Asset_id = car123,
    asset(Asset_id,Cost,Start_date,_),
    Written_down_date = date(2019,2,2),
    Method = diminishing_value,
    depreciation_between_start_date_and_other_date(Cost,diminishing_value,Start_date,
        Written_down_date,car123,_,1,false,_,0,Total_depreciation_value),
    written_down_value(Asset_id, Written_down_date, Method, _, Written_down_value),
    assertion(Written_down_value =:= Cost-Total_depreciation_value).

test(written_down_value_asset_2):-
    Asset_id = car456,
    Written_down_date = date(2019,2,2),
    Method = diminishing_value,
    written_down_value(Asset_id, Written_down_date, Method, _, Written_down_value),
    assertion(Written_down_value == 543.5232751921387).

test(written_down_value_asset_3):-
    Asset_id = car123,
    Written_down_date = date(2017,6,1),
    Method = diminishing_value,
    written_down_value(Asset_id, Written_down_date, Method, _, Written_down_value),
    assertion(Written_down_value == 966.027397260274).

test(written_down_value_asset_4):-
    Asset_id = car456,
    Written_down_date = date(2017,6,1),
    Method = diminishing_value,
    written_down_value(Asset_id, Written_down_date, Method, _, Written_down_value),
    assertion(Written_down_value == 977.3206045515285).

test(written_down_value_asset_5, fail):-
    %It should fail because at this date car456 wasnt purchased yet
    Asset_id = car456,
    Written_down_date = date(2014,6,1),
    Method = diminishing_value,
    written_down_value(Asset_id, Written_down_date, Method, _, Written_down_value),
    assertion(Written_down_value == 977.3206045515285).

test(depreciation_pool_from_start_1):-
    depreciation_pool_from_start(general_pool,date(2019,2,2),diminishing_value,Total_depreciation),
    % From above, the pool should add the depreciation values of each asset for the same period while in pool
    Correct_total_depreciation is 430.8947462923214 + 1411.6143525408916,
    assertion(Total_depreciation == Correct_total_depreciation).

test(depreciation_pool_from_start_2):-
    depreciation_pool_from_start(low_value_pool,date(2019,2,2),diminishing_value,Total_depreciation),
    % Not any asset was placed in the low value pool so it should be zero
    Correct_total_depreciation is 0,
    assertion(Total_depreciation == Correct_total_depreciation).

test(depreciation_pool_from_start_3):-
    depreciation_pool_from_start(general_pool,date(2013,2,2),diminishing_value,Total_depreciation),
    % Not any asset was in the pool before this date so it should be zero
    Correct_total_depreciation is 0,
    assertion(Total_depreciation == Correct_total_depreciation).

test(depreciation_pool_from_start_5):-
    depreciation_pool_from_start(general_pool,date(2020,2,2),diminishing_value,Total_depreciation),
    % From above, the pool should add the depreciation values of each asset for the same period while in pool
    Correct_total_depreciation is 2189.7563691832493,
    assertion(Total_depreciation == Correct_total_depreciation).

test(depreciation_pool_between_two_dates_1):-
    depreciation_pool_between_two_dates(general_pool,date(2019,2,2),date(2020,2,2),diminishing_value,Total_depreciation),
    Correct_total_depreciation is 2189.7563691832493 - (430.8947462923214 + 1411.6143525408916),
    assertion(Total_depreciation == Correct_total_depreciation).

test(depreciation_between_two_dates_1):-
    Asset_id = car456,
    From_date = date(2017,6,1),
    To_date = date(2019,2,2),
    Method = diminishing_value,
    depreciation_between_two_dates(Asset_id, From_date, To_date, Method, Depreciation_value),
    Correct_depreciation_value is 977.3206045515285 - 543.5232751921387,
    assertion(Correct_depreciation_value == Depreciation_value).

test(profit_and_loss_1):-
    Asset_id = car123,
    asset(Asset_id,Asset_cost,Start_date,_),
    Termination_date = date(2019,7,7),
    Termination_value = 500,
    profit_and_loss(Asset_id, Termination_value, Termination_date, _, Profit_and_loss),
    depreciation_between_start_date_and_other_date(Asset_cost,diminishing_value,Start_date,
        Termination_date,Asset_id,_,1,false,_,0,Total_depreciation_value),
    Correct_profit_and_loss is Termination_value - (Asset_cost - Total_depreciation_value),
    assertion(Correct_profit_and_loss == Profit_and_loss).

test(profit_and_loss_2, fail):-
    % It should fail since the asset was placed in a general pool that forces a diminishing value method
    Method = prime_cost,
    Asset_id = car123,
    asset(Asset_id,Asset_cost,Start_date,_),
    Termination_date = date(2019,7,7),
    Termination_value = 500,
    profit_and_loss(Asset_id, Termination_value, Termination_date, Method, Profit_and_loss),
    depreciation_between_start_date_and_other_date(Asset_cost,Method,Start_date,
        Termination_date,Asset_id,_,1,false,_,0,Total_depreciation_value),
    Correct_profit_and_loss is Termination_value - (Asset_cost - Total_depreciation_value),
    assertion(Correct_profit_and_loss == Profit_and_loss).

:- end_tests(depreciation).
:- run_tests.
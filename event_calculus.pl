:- dynamic happens/2.

:- use_module(library(clpfd)).

time(T):- T #>= 0, T #=<10000.

initiated(F,T):- happens(E,T), initiates(E,F,T), time(T).
initiated(F,-1):- initially(F).

terminated(F,T):- happens(E,T), terminates(E,F,T), time(T).

initiatedBefore(F,T1,T) :- initiated(F,T1), T1<T, time(T), time(T1).
terminatedBetween(F,T1,T2) :- terminated(F,T), T>=T1, T<T2, time(T), time(T1), time(T2).

holdsAt(F,T):- initiatedBefore(F,T1,T), \+ terminatedBetween(F,T1,T), time(T), time(T1).

% interval ]...], a fluent holds in a continuous interval
% holdsExactlyBetween(F,T1,T2):- initiated(F,T1), \+ terminatedBetween(F,T1,T2), terminated(F,T2), time(T1), time(T2).

get_intervals_from_begin_end([],[],[]).
get_intervals_from_begin_end([Begin],[],[[Begin,'End']]).
get_intervals_from_begin_end([Begin|RestBegins],[End|RestEnds],[[Begin,End]|RestIntervals]):- 
    get_intervals_from_begin_end(RestBegins,RestEnds,RestIntervals), labeling([up],RestBegins),labeling([up],RestEnds).

getHoldsIntervals(F,HoldsIntervals) :- 
    findall(T,initiated(F,T),Begins),
    findall(T,terminated(F,T),Ends),
    get_intervals_from_begin_end(Begins,Ends,HoldsIntervals).

lifeOfAnAssetInPool(Asset,Pool,HoldsIntervals):- pool(Pool), asset(Asset), getHoldsIntervals(in_pool(Asset,Pool),HoldsIntervals).

lifeOfAnAsset(Asset,PoolIntervals):- 
    asset(Asset), 
    findall([Pool,HoldsIntervals],lifeOfAnAssetInPool(Asset,Pool,HoldsIntervals),PoolIntervals).

asset(car123).

pool(general_pool).
pool(low_value_pool).
pool(software_pool).

fluent(in_pool(Asset,Pool)):- pool(Pool),asset(Asset).

event(transfer_asset_to_pool(Asset, Pool)):- pool(Pool),asset(Asset).
event(remove_asset_from_pool(Asset, Pool)):- pool(Pool),asset(Asset).

initiates(transfer_asset_to_pool(Asset, Pool), in_pool(Asset, Pool),T):- time(T),asset(Asset),pool(Pool).
terminates(remove_asset_from_pool(Asset, Pool), in_pool(Asset, Pool),T):- time(T),asset(Asset),pool(Pool).

% Asset begins not in any pool
initially(\+in_pool(car123,_)).
happens(transfer_asset_to_pool(car123,general_pool),3).
happens(remove_asset_from_pool(car123,general_pool),6).
happens(transfer_asset_to_pool(car123,low_value_pool),10).
happens(remove_asset_from_pool(car123,low_value_pool),15).
happens(transfer_asset_to_pool(car123,general_pool),17).

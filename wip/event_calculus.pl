:- dynamic happens/2.

:- use_module(library(clpfd)).

time(T):- T #>= -1, T #=<10000.

initiated(F,T):- happens(E,T), initiates(E,F,T), time(T).
initiated(F,-1):- initially(F).

terminated(F,T):- happens(E,T), terminates(E,F,T), time(T).

initiatedBefore(F,T1,T):- initiated(F,T1), T1<T, time(T), time(T1).
terminatedBetween(F,T1,T2):- terminated(F,T), T>=T1, T<T2, time(T), time(T1), time(T2).
terminatedAfter(F,T1,T):- terminated(F,T), T>=T1, time(T), time(T1).

holdsAt(F,T):- initiatedBefore(F,T1,T), \+ terminatedBetween(F,T1,T), time(T), time(T1).

holdsAtAsset(Asset,in_pool(Asset,Pool),T):- holdsAt(in_pool(Asset,Pool),T).
holdsAtAsset(Asset,not_in_pool(Asset),T):- holdsAt(not_in_pool(Asset),T).

lifeOfAnAsset(_,T2,T2,[]).

lifeOfAnAsset(Asset,T1,T2,[[H,T1,T]|RestOfLife]):- 
    T1 < T2,
    holdsAtAsset(Asset,H,T1),
    terminatedAfter(H,T1,T),
    New_T1 is T + 1,
    lifeOfAnAsset(Asset,New_T1,T2,RestOfLife).

lifeOfAnAsset(Asset,T1,T2,[[H,T1,T2]|RestOfLife]):- 
    T1 < T2,
    holdsAtAsset(Asset,H,T1),
    \+ terminatedAfter(H,T1,_),
    lifeOfAnAsset(_,T2,T2,RestOfLife).

% For debugging
%start:-lifeOfAnAsset(car123,0,20,Result).

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

% Asset begins not in any pool
initially(not_in_pool(car123)).
happens(transfer_asset_to_pool(car123,general_pool),3).
happens(remove_asset_from_pool(car123,general_pool),6).
happens(transfer_asset_to_pool(car123,low_value_pool),10).
happens(remove_asset_from_pool(car123,low_value_pool),15).
happens(transfer_asset_to_pool(car123,general_pool),17).

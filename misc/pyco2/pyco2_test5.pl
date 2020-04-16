:- use_module(library(clpfd)).

:- ['pyco2_2'].

:- discontiguous p/2.

p([
	maplist(_,nil,nil)
,bc]).

p([
	maplist(Pred,A,B)
		,call(Pred, A_head, B_head)
		,fr(A,A_head, A_tail)
		,fr(B,B_head, B_tail)
		,maplist(Pred,A_tail,B_tail)
]).


p([
	'slice out item by index'(List, Idx, Item, Rest)
		,Idx = 0
		,fr(List, Item, Rest)
	,bc
]).

p([
	'slice out item by index'(List, Idx, Item_at_idx, List_without_item)
		,Idx #> 0
		,New_idx #= Idx - 1
		,fr(List_without_item, Other_Item, List_without_item_rest)
		,'slice out item by index'(List_rest, New_idx, Item_at_idx, List_without_item_rest)
		,fr(List, Other_Item, List_rest)
	,en-[removing,Item_at_idx,at,Idx,from,List,produces,List_without_item]
]).




p([
	last(List, Last_item, List_without_last_item)
		,fr(List, Last_item, nil)
		,List_without_last_item = nil
	,n-bc
]).

p([
	last(List, Last_item, List_without_last_item)
		,fr(List, Other_item, List_rest)
		,dif(List_rest, nil)
		,fr(List_without_last_item, Other_item, List_without_last_item_rest)
		,last(List_rest, Last_item, List_without_last_item_rest)
]).

p([
	'"last" test 1'(List0, Last_item, Rest)
		,fr(List0, 0, List1)
		,fr(List1, 1, List2)
		,fr(List2, 2, List3)
		,fr(List3, 3, List4)
		,fr(List4, 4, nil)
		,last(List0, Last_item, Rest)
]).

p([
	'"last" test 2'(List0, Last_item, Rest)
		,List0 = nil
		,last(List0, Last_item, Rest)
]).
/*
p([
	'"last" test 3'(List0, Last_item, Rest)
		,fr(List0, 0, List1)
		,fr(List1, 1, List2)
		,fr(List2, 2, List3)
		,fr(List3, 3, List4)
		,fr(List4, 4, _)
		,last(List0, Last_item, Rest)
]).

p([
	append(nil, X, X)
	,n-base_case
]).

p([
	append(A,B,C)
		,fr(A, X, At)
		,fr(B, X, Bt)
		,append(At, B, Bt)
	,en-[A,appended,to,B,is,C]
]).

*/

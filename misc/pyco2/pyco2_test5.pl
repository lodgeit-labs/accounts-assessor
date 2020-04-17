:- use_module(library(clpfd)).

:- ['pyco2_2'].

%:- discontiguous p/2.





/*


r(
	exists-('list cell', [first,rest])

).
*/


r(
	fr(L,F,R)
		,first(L, F)
		,rest(L, R)
	,n-'list cell helper'
).







r(	maplist(_,nil,nil)
	,bc
).

r(	maplist(Pred,A,B)
		,pyco_call(Pred, A_head, B_head)
		,fr(A,A_head, A_tail)
		,fr(B,B_head, B_tail)
		,maplist(Pred,A_tail,B_tail)
).







r(	last(List, Last_item, List_without_last_item)
		,fr(List, Last_item, nil)
		,List_without_last_item = nil
	,n-bc
).

r(	last(List, Last_item, List_without_last_item)
		,fr(List, Other_item, List_rest)
		,dif(List_rest, nil)
		,fr(List_without_last_item, Other_item, List_without_last_item_rest)
		,last(List_rest, Last_item, List_without_last_item_rest)
).

r(	'"last" test 1'(List0, Last_item, Rest)
		,fr(List0, 0, List1)
		,fr(List1, 1, List2)
		,fr(List2, 2, List3)
		,fr(List3, 3, List4)
		,fr(List4, 4, nil)
		,last(List0, Last_item, Rest)
).

r(	'"last" test 2'(List0, Last_item, Rest)
		,List0 = nil
		,last(List0, Last_item, Rest)
).

r(	'"last" test 3'(List0, Last_item, Rest)
		,fr(List0, 0, List1)
		,fr(List1, 1, List2)
		,fr(List2, 2, List3)
		,fr(List3, 3, List4)
		,fr(List4, 4, _)
		,last(List0, Last_item, Rest)
).









r(	append(nil, X, X)
	,bc
).

r(	append(A,B,C)
		,fr(A, X, At)
		,fr(B, X, Bt)
		,append(At, B, Bt)
	,en-[A,appended,to,B,is,C]
).








r(	'slice out item by index'(List, Idx, Item, Rest)
		,Idx = 0
		,fr(List, Item, Rest)
	,bc
).

r(	'slice out item by index'(List, Idx, Item_at_idx, List_without_item)
		,Idx #> 0
		,New_idx #= Idx - 1
		,fr(List_without_item, Other_Item, List_without_item_rest)
		,'slice out item by index'(List_rest, New_idx, Item_at_idx, List_without_item_rest)
		,fr(List, Other_Item, List_rest)
	,en-[removing,Item_at_idx,at,Idx,from,List,produces,List_without_item]
).








r(	vec_inverse(V, Vi)
		,fr(V, VH, VT)
		,fr(Vi, ViH, ViT)
		,coord_or_value_inverse(VH,ViH)
		,vec_inverse(VT, ViT)
).

r(	vec_inverse(nil, nil)
	,bc
).

r(	coord_inverse(A, B)
		,coord_unit(A, U)
		,coord_unit(B, U)
		,coord_value(A, V)
		,coord_value(B, Vi)
		,eq(V #= -Vi)
).

r(	value_inverse(A, B)
		,value_unit(A, U)
		,value_unit(B, U)
		,value_value(A, V)
		,value_value(B, Vi)
		,eq(V #= -Vi)
).

r(	coord_or_value_inverse(A, B)
		,coord_inverse(A, B)
).


r(	coord_or_value_inverse(A, B)
		,value_inverse(A, B)
).


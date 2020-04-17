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






).r(

member(Item, List)
		,fr(List, Item, _)

).r(

member(Item, List)
		,fr(List, _, Rest),
		,member(Item, Rest)

).r(








maplist(_,nil,nil)
,bc

).r(

maplist(Pred,A,B)
		,pyco_call(Pred, A_head, B_head)
		,fr(A,A_head, A_tail)
		,fr(B,B_head, B_tail)
		,maplist(Pred,A_tail,B_tail)





).r(


last(List, Last_item, List_without_last_item)
		,fr(List, Last_item, nil)
		,List_without_last_item = nil
	,n-bc

).r(

last(List, Last_item, List_without_last_item)
		,fr(List, Other_item, List_rest)
		,dif(List_rest, nil)
		,fr(List_without_last_item, Other_item, List_without_last_item_rest)
		,last(List_rest, Last_item, List_without_last_item_rest)

).r(

'"last" test 1'(List0, Last_item, Rest)
		,fr(List0, 0, List1)
		,fr(List1, 1, List2)
		,fr(List2, 2, List3)
		,fr(List3, 3, List4)
		,fr(List4, 4, nil)
		,last(List0, Last_item, Rest)

).r(

'"last" test 2'(List0, Last_item, Rest)
		,List0 = nil
		,last(List0, Last_item, Rest)

).r(

'"last" test 3'(List0, Last_item, Rest)
		,fr(List0, 0, List1)
		,fr(List1, 1, List2)
		,fr(List2, 2, List3)
		,fr(List3, 3, List4)
		,fr(List4, 4, _)
		,last(List0, Last_item, Rest)





).r(




append(nil, X, X)
	,bc

).r(

append(A,B,C)
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










r(	exists-coord(unit,value)).
r(	exists-value(unit,value)).


r(	coord_side_value(C, debit, V)
		,coord_unit(C,U)
		,value_unit(V,U)
		,coord_value(C,X)
		,value_value(V,X)

).r(

coord_side_value(C, credit, V)
		,coord_unit(C,U)
		,value_unit(V,U)
		,coord_value(C,X)
		,value_value(V,Y)
		,eq(Y #= -X)

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



).r(


n-"Adds the two given vectors together and reduces coords or values in a vector to a minimal (normal) form."

vec_add(As, Bs, Cs_Reduced)


	,assertion((flatten(As, As), flatten(Bs, Bs)))
	/*
	todo
	"assertion" roughly means that the goal must not fail
	if it fails, exception is thrown
	in prolog, it cuts after first result.
	in pyco we'd probably let the goal leave choicepoints
	dunno..
	*/




	,n-"paste the two vectors togetner"
	,append(As, Bs, As_And_Bs)

	,n-"sort into a map by unit, each item is unit:list of coords"
	,sort_into_assoc(coord_or_value_unit, As_And_Bs, Sorted)

	,n-"each coord carries Unit already, so we dont need keys"
	,assoc_to_values(Sorted, Valueses)


	findall(
		Total,
		(
			member(Values, Valueses),
			semigroup_foldl(coord_merge, Values, [Total])
		),
		Cs_Flat
	),
	vec_reduce_coords(Cs_Flat, Cs_Reduced).

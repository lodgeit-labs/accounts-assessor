
/*
	extract_element_from_list with pattern-matching, preserving variable-to-variable bindings
	this is also called slice in pyco tests.
*/

extract_element_from_list([], _, _, _) :- assertion(false).

extract_element_from_list(List, Index, Element, List_without_element) :-
	extract_element_from_list2(0, List, Index, Element, List_without_element).

extract_element_from_list2(At_index, [F|R], Index, Element, List_without_element) :-
	Index == At_index,
	F = Element,
	Next_index is At_index + 1,
	extract_element_from_list2(Next_index, R, Index, Element, List_without_element).

extract_element_from_list2(At_index, [F|R], Index, Element, [F|WT]) :-
	Index \= At_index,
	Next_index is At_index + 1,
	extract_element_from_list2(Next_index, R, Index, Element, WT).

extract_element_from_list2(_, [], _, _, []).

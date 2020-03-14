chr_fields(list, [
	_{
		key:length,
		type:integer,
		required:true
	},
	_{
		key:element_type,
		/* type should be type but let's not go there right now */
		unique:true /* just because for now we don't have any interpretation of a list with multiple element types */
	},
	_{
		key:first,
		/*can we make this theory work over regular rdf list representation? (i.e. no distinction between lists and list-cells) */
		type:list_cell,
		unique:true
		/*required:false % existence is dependent on length, exists exactly when length is non-zero / list is non-empty */
	},
	_{
		key:last,
		type:list_cell,
		unique:true
		/*required:false % existence is dependent on length, exists exactly when length is non-zero / list is non-empty */
	}
]).

chr_fields(list_cell, [
	_{
		key:value,
		/* type: self.list.element_type */
		unique:true,
		required:true
	},
	/*	% this was causing problems
	_{
		key:list,
		type:list,
		unique:true,
		required:true
	},
	*/
	_{
		key:index,
		type:integer,
		unique:true,
		required:true	
	},
	_{
		key:next,
		type:list_cell,
		unique:true
		/* required: false % exists exactly when this is not the last element */
	},
	_{
		key:previous,
		type:list_cell,
		unique:true
		/* required: false % exists exactly when this is not the first element */
	}
]).



% LIST THEORY

fact(L, a, list)
\
rule
<=>
\+find_fact(allow_first_rule, fired_on, L)
|
debug(chr_list_allow, "CHR: allow first; list=~w~n", [L]),
fact(allow_first_rule, fired_on, L),
allow_list(L, first_exist_rule),
allow_list(L, last_exist_rule),
allow_list(L, first_index_rule),
allow_list(L, last_index_rule),
rule.

/*
fact(L, a, list)
\
rule
<=>
\+find_fact(allow_last_rule, fired_on, L)
|
debug(chr_list_allow, "CHR: allow last; list=~w~n", [L]),
fact(allow_last_rule, fired_on, L),
allow_last(L),
rule.
*/


fact(L, a, list),
fact(Cell, list_in, L)
\
rule
<=>
\+find_fact(allow_cell_rule, fired_on, [L, Cell])
|
debug(chr_list_allow, "CHR: allow allow cell rule; list=~w, cell=~w~n", [L, Cell]),
fact(allow_cell_rule, fired_on, [L, Cell]),
allow_cell(L, Cell, adjacent_items_rule),
allow_cell(L, Cell, element_type_rule),
allow_cell(L, Cell, prev_item_rule),
allow_cell(L, Cell, next_item_rule),
allow_cell(L, Cell, index_bounds_rule),
allow_cell(L, Cell, first_exist_rule),
allow_cell(L, Cell, last_exist_rule), 
rule.












% there is only one cell at any given index
fact(L, a, list),
fact(X, list_in, L),
fact(X, index, I) \
fact(Y, list_in, L),
fact(Y, index, I),
rule
<=> 
debug(chr_list, "CHR: list index uniqueness: list=~w, index=~w, value1=~w, value2=~w: ...~n", [L, I, X, Y]),
add_constraints([
	X = Y
]),
debug(chr_list, "CHR: list index uniqueness: list=~w, index=~w, value1=~w, value2=~w: ... done~n", [L, I, X, Y]),
rule.






% if non-empty then first exists
fact(L, a, list),
fact(Cell, list_in, L)
\
allow_list(L, first_exist_rule),
%allow_cell(L, Cell, first_exist_rule),
rule
<=>
debug(chr_list, "CHR GUARD: if non-empty then first exists: list=~w, cell=~w: ... ~n", [L, Cell]),
\+find_fact(first_exist_rule, fired_on, [L]) %,
/*\+find_fact(L, first, _)*/ % should be handled by uniqueness
|
fact(first_exist_rule, fired_on, [L]),
debug(chr_list, "CHR: if non-empty then first exists: list=~w, cell=~w: ... ~n", [L, Cell]),
add_constraints([
	fact(L, first, _)
]),
debug(chr_list, "CHR: if non-empty then first exists: list=~w, cell=~w: ... done~n", [L, Cell]),
rule.





% if non-empty then last exists
fact(L, a, list),
fact(Cell, list_in, L)
\
allow_list(L, last_exist_rule),
%allow_cell(L, Cell, last_exist_rule),
rule
<=>
debug(chr_list, "CHR GUARD: if non-empty then last exists: list=~w, cell=~w: ... ~n", [L, Cell]),
\+find_fact(last_exist_rule, fired_on, [L]) %,
%\+find_fact(L, last, _)
|
fact(last_exist_rule, fired_on, [L]),
debug(chr_list, "CHR: if non-empty then last exists: list=~w, cell=~w: ... ~n", [L, Cell]),
add_constraints([
	fact(L, last, _)
]),
debug(chr_list, "CHR: if non-empty then last exists: list=~w, cell=~w: ... done~n", [L, Cell]),
rule.




% the first object has index 1
% this isn't fully bidirectional: derive first from list-index?
fact(L, a, list),
fact(L, first, First)
\
allow_list(L, first_index_rule),
rule
<=>
debug(chr_list, "CHR GUARD: if first exists it has list index 1: list=~w, first=~w: ...~n", [L, First]),
\+find_fact(first_index_rule, fired_on, [L])
|
fact(first_index_rule, fired_on, [L]),
debug(chr_list, "CHR: if first exists it has list index 1: list=~w, first=~w: ...~n", [L, First]),
add_constraints([
	fact(First, list_in, L),
	fact(First, index, 1)
]),
debug(chr_list, "CHR: if first exists it has list index 1: list=~w, first=~w: ... done~n", [L, First]),
rule.


% if non-empty, and N is the length of the list, then last exists, is unique, is in the list, and has list index N
% this isn't fully bidirectional: derive length from list-index of last? derive last from length and list-index?
fact(L, a, list),
fact(L, last, Last),
fact(L, length, N)
\
allow_list(L, last_index_rule),
rule
<=> 
debug(chr_list, "CHR GUARD: last index rule: list=~w, last=~w, length=~w: ...~n", [L, Last, N]),
\+find_fact(last_index_rule, fired_on, [L, Last, N])
|
fact(last_index_rule, fired_on, [L, Last, N]),
debug(chr_list, "CHR: last index rule: list=~w, last=~w, length=~w: ...~n", [L, Last, N]),
add_constraints([
	fact(Last, list_in, L),
	fact(Last, index, N)
]),
debug(chr_list, "CHR: last index rule: list=~w, last=~w, length=~w: ... done~n", [L, Last, N]),
rule.






% the list index of any item is between 1 and the length of the list
fact(L, a, list),
fact(X, list_in, L),
fact(X, index, I),
fact(L, length, N)
\
allow_cell(L, X, index_bounds_rule),
rule
<=> 
debug(chr_list, "CHR GUARD: index bounds: list=~w, length=~w, index=~w, value=~w: ...~n", [L, N, I, X]),
\+find_fact(index_bounds_rule, fired_on, [L, X, I, N])
|
fact(index_bounds_rule, fired_on, [L, X, I, N]),
debug(chr_list, "CHR: index bounds: list=~w, length=~w, index=~w, value=~w: ...~n", [L, N, I, X]),
add_constraints([
	I #>= 1,
	I #=< N
]),
debug(chr_list, "CHR: index bounds: list=~w, length=~w, index=~w, value=~w: ... done~n", [L, N, I, X]),
rule.





% if list has an element type, then every element of that list has that type
fact(L, a, list),
fact(L, element_type, T),
fact(Cell, list_in, L),
fact(Cell, value, V)
\
allow_cell(L, Cell, element_type_rule),
rule
<=>
debug(chr_list, "CHR GUARD: element type: list=~w, cell=~w, value=~w, type=~w: ...~n", [L, Cell, V, T]),
\+find_fact(element_type_rule, fired_on, [L, Cell])
|
fact(element_type_rule, fired_on, [L, Cell]),
debug(chr_list, "CHR: element type: list=~w, cell=~w, value=~w, type=~w: ...~n", [L, Cell, V, T]),
add_constraints([
	fact(V, a, T)
]),
debug(chr_list, "CHR: element type: list=~w, cell=~w, value=~w, type=~w: ... done~n", [L, Cell, V, T]),
rule.





% if X is the previous item before Y, then Y is the next item after X, and vice versa.
% the next and previous items of an element are in the same list as that element 
fact(L, a, list),
fact(Cell, list_in, L),
fact(Cell, prev, Prev)
\
allow_cell(L, Cell, prev_item_rule),
rule
<=>
debug(chr_list, "CHR GUARD: prev item rule: list=~w, cell=~w, prev=~w: ...~n", [L, Cell, Prev]),
\+find_fact(prev_item_rule, fired_on, [L, Cell, Prev])
|
fact(prev_item_rule, fired_on, [L, Cell, Prev]),
debug(chr_list, "CHR: prev item rule: list=~w, cell=~w, prev=~w: ...~n", [L, Cell, Prev]),
add_constraints([
	fact(Prev, next, Cell),
	fact(Prev, list_in, L)
]),
debug(chr_list, "CHR: prev item rule: list=~w, cell=~w, prev=~w: ... done~n", [L, Cell, Prev]),
rule.




fact(L, a, list),
fact(Cell, list_in, L),
fact(Cell, next, Next)
\
allow_cell(L, Cell, next_item_rule),
rule
<=>
debug(chr_list, "CHR GUARD: next item rule: list=~w, cell=~w, next=~w: ...~n", [L, Cell, Next]),
\+find_fact(next_item_rule, fired_on, [L, Cell, Next])
|
fact(next_item_rule, fired_on, [L, Cell, Next]),
debug(chr_list, "CHR: next item rule: list=~w, cell=~w, next=~w: ...~n", [L, Cell, Next]),
add_constraints([
	fact(Next, prev, Cell),
	fact(Next, list_in, L),
	fact(Next, a, list_cell)
]),
debug(chr_list, "CHR: next item rule: list=~w, cell=~w, next=~w: ... done~n", [L, Cell, Next]),
rule.




% the next item after the item at list index I has list index I + 1
fact(L, a, list),
fact(Cell, list_in, L),
fact(Cell, index, I),
fact(Cell, next, Next), fact(Next, index, J)
\
allow_cell(L, Cell, adjacent_items_rule),
rule
<=>
debug(chr_list, "CHR GUARD: adjacent items rule: list=~w, cell=~w, next=~w: ...~n", [L, Cell, Next]),
\+find_fact(adjacent_items_rule, fired_on, [L, Cell, Next])
|
fact(adjacent_items_rule, fired_on, [L, Cell, Next]),
debug(chr_list, "CHR: adjacent items rule: list=~w, cell=~w, next=~w: ...~n", [L, Cell, Next]),
add_constraints([
	J #= I + 1
]),
debug(chr_list, "CHR: adjacent items rule: list=~w, cell=~w, next=~w: done~n", [L, Cell, Next]),
rule.

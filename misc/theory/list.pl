:- module(theory_list, []).

:- chr_constraint fact/3, rule/0.

:- multifile chr_fields/2.

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
	_{
		key:list,
		type:list,
		unique:true,
		required:true
	},
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
% there is only one cell at any given index
rule,
	fact(L, a, list),
	fact(X, list_in, L),
	fact(X, list_index, I) \
	fact(Y, list_in, L),
	fact(Y, list_index, I)
	<=> 
	add_constraints([
		X = Y
	]).


% if non-empty then first exists, is unique, is in the list, and has list index 1
rule,
	fact(L, a, list),
	fact(_, list_in, L)
	==> 
	add_constraints([
		fact(L, first, _),
		fact(L, last, _)
	]).

% this isn't fully bidirectional: derive first from list-index?
rule,
	fact(L, a, list),
	fact(L, first, First)
	==>
	add_constraints([
		fact(First, list_in, L),
		fact(First, list_index, 1)
	]).


% if non-empty, and N is the length of the list, then last exists, is unique, is in the list, and has list index N
% this isn't fully bidirectional: derive length from list-index of last? derive last from length and list-index?
rule,
	fact(L, a, list),
	fact(L, last, Last),
	fact(L, length, N)
	==> 
	add_constraints([
		fact(Last, list_in, L),
		fact(Last, list_index, N)
	]).

% the list index of any item is between 1 and the length of the list
rule,
	fact(L, a, list),
	fact(X, list_in, L),
	fact(X, list_index, I),
	fact(L, length, N)
	==> 
	add_constraints([
		I #>= 1,
		I #=< N
	]).

% if list has an element type, then every element of that list has that type
rule,
	fact(L, a, list),
	fact(L, element_type, T),
	fact(Cell, list_in, L),
	fact(Cell, value, V)
	==>
	add_constraints([
		fact(V, a, T)
	]).

% if X is the previous item before Y, then Y is the next item after X, and vice versa.
% the next and previous items of an element are in the same list as that element 
rule, 
	fact(L, a, list),
	fact(Cell, list_in, L),
	fact(Cell, prev, Prev)
	==>
	add_constraints([
		fact(Prev, next, Cell),
		fact(Prev, list_in, L)
	]).
rule,
	fact(L, a, list),
	fact(Cell, list_in, L),
	fact(Cell, next, Next)
	==>
	add_constraints([
		fact(Next, prev, Cell),
		fact(Next, list_in, L)
	]).

% the next item after the item at list index I has list index I + 1
rule,
	fact(L, a, list),
	fact(Cell, list_in, L),
	fact(Cell, list_index, I),
	fact(Cell, next, Next), fact(Next, list_index, J)
	==>
	add_constraints([
		J #= I + 1
	]).

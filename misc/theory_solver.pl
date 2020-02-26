:- use_module(library(chr)).
:- use_module(library(clpq)).
:- use_module(library(clpfd)).
:- use_module(library(interpolate)).

:- op(100, yfx, ':').	% for left-associativity of x:y:z
/*
:- chr_constraint
	fact/3,
	rule/0.
*/
	/*
	start/2,
	clpq/1,
	clpq/0,
	countdown/2,
	next/1,
	old_clpq/1,
	block/0.*/

:- multifile chr_fields/2.

%:- use_module('./solver').
:- use_module('./theory/date').
/*
:- use_module('./theory/object.pl').
:- use_module('./theory/list').
:- use_module('./theory/hp_arrangement').
*/

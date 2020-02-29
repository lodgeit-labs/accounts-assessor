:- use_module(library(chr)).
:- use_module(library(clpq)).
:- use_module(library(clpfd)).
% :- use_module(library(interpolate)). % currently not using due to bugs, but would be nice

:- op(100, yfx, ':').	% for left-associativity of x:y:z
:- chr_constraint
	fact/3,
	rule/0.

%:- use_module('./solver').
:- use_module('./theory/date').
:- use_module('./theory/object').
:- use_module('./theory/list').
:- use_module('./theory/hp_arrangement').

:- use_module('./solver').

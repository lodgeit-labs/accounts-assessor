:- use_module(library(chr)).
:- use_module(library(clpq)).
:- use_module(library(clpfd)).
% :- use_module(library(interpolate)). % currently not using due to bugs, but would be nice

:- op(100, yfx, ':').	% for left-associativity of x:y:z

:- chr_constraint fact/3, rule/0, allow_last/1, allow_first/1, allow_cell/3, allow_list/2.
:- discontiguous chr_fields/2.

:- include('./theory/date.pl').
:- include('./theory/object.pl').
:- include('./theory/list.pl').
:- include('./theory/hp_arrangement.pl').

:- include('./solver.pl').

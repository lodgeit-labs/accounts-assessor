
:- use_module(library(http/json)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_open)).
:- use_module(library(xpath)).
:- use_module(library(rdet)).
:- use_module(library(yall)).
:- use_module(library(xsd/flatten)).
:- use_module(library(semweb/rdf11),except(['{}'/1])).
:- use_module(library(debug)).

:- use_module(library(fnotation)).
:- fnotation_ops($>,<$).
:- op(900,fx,<$).

:- use_module('../determinancy_checker/determinancy_checker_main.pl').

:- multifile user:goal_expansion/2.
:- dynamic user:goal_expansion/2.

:- [compare_xml].
:- [compile_with_variable_names_preserved].
:- [dict_vars].
:- [exceptions].
:- [files].
:- [higher_order].
:- [json].
:- [magic_formula].
:- [numbers].
:- [shell].
:- [string_manipulation].
:- [structured_xml].
:- [structures].
:- [term_output].
:- [xml].

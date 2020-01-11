
:- use_module(library(http/json)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_open)).
:- use_module(library(xpath)).
:- use_module(library(rdet)).
:- use_module(library(yall)).
:- use_module(library(xsd/flatten)).
:- use_module(library(semweb/rdf11),except(['{}'/1])).
:- use_module(library(debug)).

:- multifile user:goal_expansion/2.
:- dynamic user:goal_expansion/2.

:- [compare_xml].
:- [compile_with_variable_names_preserved].
:- [dict_vars].
:- [doc].
:- [exceptions].
:- [files].
:- [higher_order].
:- [magic_formula].
:- [numbers].
:- [request_files].
:- [shell].
:- [string_manipulation].
:- [structured_xml].
:- [structures].
:- [term_output].
:- [xml].

:- module(_, []).

:- asserta(user:file_search_path(library, '../prolog_xbrl_public/xbrl/prolog')).
:- use_module(library(xbrl/utils)).
:- use_module('doc', [doc/3]).


process :-
gtrace,
	doc(Q, rdf:type, l:hp_calculator_query),
	writeq(Q).

:- module(_, [my_rdf_graph/1]).

:- use_module('files', []).

:- use_module(library(semweb/rdf11)).

:- rdf_register_prefix(l, 'https://lodgeit.net.au#').

my_rdf_graph(G) :-
	files:my_request_tmp_dir(G).

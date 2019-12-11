:- module(_, [doc/3, docm/3, doc_add/3]).
:- use_module(doc_core, [doc/3, docm/3, doc_add/3]).
:- use_module('files', []).
:- use_module(library(semweb/rdf11)).

:- rdf_register_prefix(l, 'https://lodgeit.net.au#').
:- rdf_register_prefix(livestock, 'https://lodgeit.net.au/livestock#').

/*
helper predicates
*/

doc_new_theory(T) :-
	doc_new_uri(T),
	doc_add(T, rdf:a, l:theory).

doc_new_uri(Uri) :-
	files:my_request_tmp_dir(D),
	gensym(bn, Uid),
	atomics_to_string([D, '/rdf#', Uid], Uri),
	assertion(\+doc:doc(Uri,_,_)),
	assertion(\+doc:doc(_,_,Uri)).

:- rdf_meta request_has_property(r,r).

request_has_property(P, O) :-
	doc:doc(R, rdf:a, l:request),
	doc:doc(R, P, O).

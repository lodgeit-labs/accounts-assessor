:- module(_, [doc/3, doc_add/3, doc_new_theory/1, doc_new_uri/1]).

:- use_module(library(semweb/rdf11)).


:- rdf_register_prefix(l, 'https://lodgeit.net.au#').
:- rdf_register_prefix(livestock, 'https://lodgeit.net.au/livestock#').

:- rdf_meta doc_add(r,r,r).

doc_add(S,P,O) :-
	files:my_request_tmp_dir(D),
	assertz(doc_data(D,S,P,O)).

:- rdf_meta doc(r,r,r).

doc(S,P,O) :-
	files:my_request_tmp_dir(D),
	doc_data(D,S,P,O).

doc_new_theory(T) :-
	doc_new_uri(T),
	doc_add(T, rdf:a, l:theory).

doc_new_uri(Uri) :-
	files:my_request_tmp_dir(D),
	gensym(bn, Uid),
	atomics_to_string([D, '/rdf#', Uid], Uri),
	assertion(\+doc(T,_,_)),
	assertion(\+doc(_,_,T)).

request_has_property(P, O) :-
	doc(R, rdf:a, l:request),
	doc(R, P, O).

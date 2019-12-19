:- module(_, [doc/3, docm/3, doc_add/3, doc_new_uri/1]).
:- use_module(doc_core, [doc/3, docm/3, doc_add/3]).
:- use_module('files', []).
:- use_module(library(semweb/rdf11)).

:- rdf_register_prefix(l, 'https://lodgeit.net.au/#').
:- rdf_register_prefix(livestock, 'https://lodgeit.net.au/livestock#').

/*
helper predicates
*/

doc_new_theory(T) :-
	doc_new_uri(T),
	doc_add(T, rdf:type, l:theory).

doc_new_uri(Uri) :-
	files:tmp_file_url('response.n3', D),
	gensym(bn, Uid),
	atomic_list_concat([D, '#', Uid], Uri)
	/*,
	% this is maybe too strong because it can bind with variable nodes
	assertion(\+doc:doc(Uri,_,_)),
	assertion(\+doc:doc(_,_,Uri))
	*/.

:- rdf_meta request_has_property(r,r).

request_has_property(P, O) :-
	doc:doc(R, rdf:type, l:request),
	doc:doc(R, P, O).


init :-
	/*	i'm storing some data in the 'doc' rdf-like database, only as an experiment for now.
	livestock and action verbs exclusively, some other data in parallel with passing them around in variables..	*/
	doc_core:doc_clear,
	doc:doc_new_uri(R),
	doc:doc_add(R, rdf:type, l:request).

from_rdf(Rdf_Graph) :-
	findall((X,Y,Z),
		rdf(X,Y,Z,Rdf_Graph),
		Triples),
	maplist(triple_rdf_vs_doc, Triples, Triples2),
	maplist(doc_core:doc_add, Triples2).

triple_rdf_vs_doc((S,P,O), (S,P,O2)) :-
	node_rdf_vs_doc(O,O2).

node_rdf_vs_doc(
	date_time(Y,M,D,0,0,0.0) ^^ 'http://www.w3.org/2001/XMLSchema#dateTime',
	date(Y,M,D)) :- !.

node_rdf_vs_doc(
	String ^^ 'http://www.w3.org/2001/XMLSchema#string',
	String):- string(String), !.

node_rdf_vs_doc(
	Int ^^ 'http://www.w3.org/2001/XMLSchema#integer',
	Int) :- integer(Int),!.

node_rdf_vs_doc(
	Float ^^ 'http://www.w3.org/2001/XMLSchema#decimal',
	Rat) :-
		freeze(Float, float(Float)),
		freeze(Rat, rational(Rat)),
		(	nonvar(Rat)
		->	Float is float(Rat)
		;	Rat is rationalize(Float)),!.

node_rdf_vs_doc(Atom, Atom).


to_rdf(Rdf_Graph) :-
	rdf_create_bnode(Rdf_Graph),
	findall(_,
		(
			docm(X,Y,Z),
			triple_rdf_vs_doc((X2,Y2,Z2),(X,Y,Z)),
			debug(doc, 'to_rdf:~q~n', [(X2,Y2,Z2)]),
			rdf_assert(X2,Y2,Z2,Rdf_Graph)
		),_).


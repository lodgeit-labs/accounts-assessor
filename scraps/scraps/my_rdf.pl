:- module(_, [my_rdf_graph/1, my_rdf/3]).
:- use_module('files', []).
:- use_module(library(semweb/rdf11)).


:- rdf_register_prefix(l, 'https://lodgeit.net.au#').
:- rdf_register_prefix(livestock, 'https://lodgeit.net.au/livestock#').


/* query helpers */
:- rdf_meta my_rdf(r,r,r).
my_rdf(S,P,O) :-
	my_rdf_graph(G),
	my_rdf(S,P,O,G).
my_rdf(S,P,O) :-
	my_rdf_graph(G),
    with_subgraphs(S,P,O,G).
with_subgraphs(S,P,O,G) :-
    rdf(S,P,O,G).
with_subgraphs(S,P,O,G) :-
    rdf(G,l:imports,G2,G),
    rdf(S,P,O,G2).


/* insertion helpers */
:- rdf_meta add(r,r,r,r).
add(S,P,O,G) :-
    O = value(_,_),
    assert_value(S,P,O,G),
    !.
add(S,P,O,G) :-
    rdf_assert(S,P,O,G).


/* add and query value/2 terms. Complex units are tbd */
assert_value(S, P, value(Unit, Amount), G) :-
    new_graph(Bn),
    rdf_assert(Bn, l:has_unit, Unit, Bn),
    rdf_assert(Bn, l:has_value, Amount, Bn),
    rdf_assert(S, P, Bn, G),
    true.
value(S, P, value(Unit, Amount), G) :-
    rdf(S, P, Bn, G),
    rdf(Bn, l:has_unit, Unit, Bn),
    rdf(Bn, l:has_value, Amount, Bn),
    true.


/* bookkeeping */
/* returns a graph that's unique for this request */
my_rdf_graph(G) :-
	files:my_request_tmp_dir(G).
init_request_graph(Dir) :-
	rdf_default_graph(_, Dir),
	my_rdf:check_empty(Dir).
new_graph(H) :-
	rdf_create_bnode(H),
	check_empty(H).
check_empty(G) :-
		findall(_, rdf(_,_,_,G), [])
	->	true
	;	throw(error(this_shouldnt_happen,_)).
dump_all_rdf :-
	%list_debug_topics,
	debug(bs, 'all rdf:', []),
	writeq('XXXXXXXXXXXXXXXXXXXXXX'),nl,
	findall(_,(
		rdf(S,P,O),
		debug(bs, '~k', [(S,P,O)]),
		writeq((S,P,O)),
		nl
	),_),
	debug(bs, '.', []).

/*
todo:sequences
rdf_update,
rdf_seq
*/
/*
%global data of the xbrl-instance-outputting operation
new_graph(H),
rdf_assert(op, format, xbrl),
Max_Detail_Level
*/

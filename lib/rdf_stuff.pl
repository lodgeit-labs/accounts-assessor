/*
note that files.pl sets "default graph" in bump_tmp_directory_id.
*/

:- module(_, [my_rdf_graph/1, my_rdf/3]).

:- use_module('files', []).

:- use_module(library(semweb/rdf11)).

:- rdf_register_prefix(l, 'https://lodgeit.net.au#').

/*
returns a graph that's unique for this request
*/
my_rdf_graph(G) :-
	files:my_request_tmp_dir(G).

/*
for explanation see https://www.swi-prolog.org/pldoc/doc_for?object=section(%27packages/semweb.html%27)#rdf_global_term/2
*/
:- rdf_meta my_rdf(r,r,r).
/*
invoke rdf/4 on request graph
*/
my_rdf(S,P,O) :-
	my_rdf_graph(G),
	rdf(S,P,O,G).

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

new_global_data_handle(H) :-
	rdf_create_bnode(H),
	check_empty(H).

check_empty(G) :-
	(
		findall(_, rdf(_,_,_,G), [])
	->
		throw("oops")
	;
		true
	).

init_request_graph(Dir) :-
	rdf_default_graph(_, Dir),
	rdf_stuff:check_empty(Dir).



/*
	%findall(_,(rdf(S,P,O),writeq((S,P,O)),nl),_)
rdf_update,
rdf_seq
*/

/* 
%global data of the xbrl-instance-outputting operation 
new_global_data_handle(H),
rdf_assert(op, format, xbrl),
Max_Detail_Level
*/

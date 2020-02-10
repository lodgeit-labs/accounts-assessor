:- rdf_register_prefix(code,
'https://rdf.lodgeit.net.au/v1/code#').
:- rdf_register_prefix(l,
'https://rdf.lodgeit.net.au/v1/request#').
:- rdf_register_prefix(livestock,
'https://rdf.lodgeit.net.au/v1/livestock#').
:- rdf_register_prefix(excel,
'https://rdf.lodgeit.net.au/v1/excel#').
:- rdf_register_prefix(depr,
'https://rdf.lodgeit.net.au/v1/calcs/depr#').
:- rdf_register_prefix(ic,
'https://rdf.lodgeit.net.au/v1/calcs/ic#').
:- rdf_register_prefix(hp,
'https://rdf.lodgeit.net.au/v1/calcs/hp#').
:- rdf_register_prefix(depr_ui,
'https://rdf.lodgeit.net.au/v1/calcs/depr/ui#').
:- rdf_register_prefix(ic_ui,
'https://rdf.lodgeit.net.au/v1/calcs/ic/ui#').
:- rdf_register_prefix(hp_ui,
'https://rdf.lodgeit.net.au/v1/calcs/hp/ui#').
:- rdf_register_prefix(transactions,
'https://rdf.lodgeit.net.au/v1/transactions#').
:- rdf_register_prefix(s_transactions,
'https://rdf.lodgeit.net.au/v1/s_transactions#').
/*
@prefix depr_ui: <https://rdf.lodgeit.net.au/v1/calcs/depr/ui#> .
@prefix ic_ui: <https://rdf.lodgeit.net.au/v1/calcs/ic/ui#> .
@prefix hp_ui: <https://rdf.lodgeit.net.au/v1/calcs/hp/ui#> .
*/


/*
	a quad-store implemented with an open list stored in a global thread-local variable
*/

%:- debug(doc).

% https://www.swi-prolog.org/pldoc/man?predicate=rdf_meta/1
:- rdf_meta doc_add(r,r,r).
:- rdf_meta doc_add(r,r,r,r).
:- rdf_meta doc_assert(r,r,r,r).
:- rdf_meta doc(r,r,r).
:- rdf_meta doc(r,r,r,r).
:- rdf_meta docm(r,r,r).
:- rdf_meta docm(r,r,r,r).
:- rdf_meta doc_new_(r,-).
:- rdf_meta request_has_property(r,r).
:- rdf_meta request_add_property(r,r).
:- rdf_meta request_assert_property(r,r,r).
:- rdf_meta doc_value(r,r,r).
:- rdf_meta doc_add_value(r,r,r).


doc_init :-
	doc_init_trace_0,
	doc_clear,
	doc_new_uri(R),
	/* fixme: we create a bnode of type l:request for storing and processing stuff, and excel sends an actual l:request. not sure what we want to do here. Im hesitant to turn the two objects into one. Possibly this should be l:processing or something. */
	doc_add(R, rdf:type, l:request).
/*	rdf_register_prefix(pid, ':'),
	doc_add(pid, rdf:type, l:request),
	doc_add(pid, rdfs:comment, "processing id - the root node for all data pertaining to processing current request. Also looked up by being the only object of type l:request, but i'd outphase that.").
*/

doc_init_trace_0 :-
	Fn = 'doc_trace_0',
	Fnn = loc(file_name, Fn),
	(	absolute_tmp_path(Fnn, loc(absolute_path, Trail_File_Path))
	->	true
	;	Trail_File_Path = 'doc_trace_0'),
	open(Trail_File_Path, write, Trail_Stream, [buffer(line)]),
	b_setval(doc_trail, Trail_Stream).

/*
good thing is i think even with retracts (the backtracking kind), we won't have to worry about prolog reusing variable numbers. anyway, variables are todo
*/

doc_trace0(Term) :-
	b_getval(doc_trail, Stream),
	writeq(Stream, Term),
	writeln(Stream, ',').

dump :-
	findall(_,
		(
			docm(S,P,O),
			debug(doc, 'dump:~q~n', [(S,P,O)])
		),
	_).


/*
┏┳┓┏━┓╺┳┓╻┏━╸╻ ╻╻┏┓╻┏━╸
┃┃┃┃ ┃ ┃┃┃┣╸ ┗┳┛┃┃┗┫┃╺┓
╹ ╹┗━┛╺┻┛╹╹   ╹ ╹╹ ╹┗━┛
*/

doc_clear :-
	doc_trace0(doc_clear),
	b_setval(the_theory,_{}),
	b_setval(the_theory_nonatoms,_),
	doc_set_default_graph(default).

doc_set_default_graph(G) :-
	doc_trace0(doc_set_default_graph(G)),
	b_setval(default_graph, G).

doc_add((S,P,O)) :-
	doc_add(S,P,O).


doc_add(S,P,O) :-
	b_getval(default_graph, G),
	doc_add(S,P,O,G).


atom_or_idk(X,X2) :-
	(	atom(X)
	->	X2 = X
	;	X2 = idk).

get_or_default(T, X, XXX) :-
	(	XXX = T.get(X)
	->	true
	;	XXX = _{}).

doc_add(S,P,O,G) :-
	doc_trace0(doc_add(S,P,O,G)),
	debug(doc, 'add:~q~n', [(S,P,O,G)]),
	add_atoms(S,P,O,G).

doc_add(S,P,O,G) :-
	doc_trace0(clean_pop(doc_add(S,P,O,G))),
	fail.

/*todo b_getval(the_theory_nongrounds,TTT),*/

/*
assumption: only O's are allowed to be non-atoms
*/
add_atoms(S2,P2,O2,G2) :-
	ground(spog(S2,P2,O2,G2)),
	% get the_theory global
	b_getval(the_theory,Ss),
	%, ie a dict from subjects to pred-dicts
	% does it contain the subject?

	(	Ps = Ss.get(S2)
	%	the it's a dict from preds to graphs
	->	true
	;	(
			Ps = _{},
			b_setval(the_theory, Ss.put(S2, Ps))
		)
	),

	(	Gs = Ps.get(P2)
	->	true
	;	(
			Gs = _{},
			b_set_dict(P2, Ss, Ps.put(P2, Gs))
		)
	),

	(	Os = Gs.get(G2)
	->	true
	;	b_set_dict(G2, Ps, Gs.put(G2, _Os))),

	rol_add(O2, Os).



dddd(spog(S,P,O,G), X) :-
	member(O, X.get(S).get(P).get(G)).



doc_assert(S,P,O,G) :-
	doc_add(S,P,O,G).
/*	doc_trace0(doc_assert(S,P,O,G)),
	b_getval(the_theory,X),
	rol_assert(spog(S,P,O,G),X).*/

doc_assert(S,P,O,G) :-
	doc_trace0(clean_pop(doc_assert(S,P,O,G))),
	fail.



/*

┏━┓╻ ╻┏━╸┏━┓╻ ╻╻┏┓╻┏━╸
┃┓┃┃ ┃┣╸ ┣┳┛┗┳┛┃┃┗┫┃╺┓
┗┻┛┗━┛┗━╸╹┗╸ ╹ ╹╹ ╹┗━┛
*/

/*
must have at most one match
*/
doc(S,P,O) :-
	b_getval(default_graph, G),
	doc(S,P,O,G).

/*
must have at most one match
*/
doc(S,P,O,G) :-
	rdf_global_id(S, S2),
	rdf_global_id(P, P2),
	rdf_global_id(O, O2),
	rdf_global_id(G, G2),
	b_getval(the_theory,X),
	debug(doc, 'doc?:~q~n', [(S2,P2,O2,G2)]),
	dddd(spog(S2,P2,O2,G2), X).

/*
can have multiple matches
*/
docm(S,P,O) :-
	b_getval(default_graph, G),
	docm(S,P,O,G).

docm(S,P,O,G) :-
	rdf_global_id(S, S2),
	rdf_global_id(P, P2),
	rdf_global_id(O, O2),
	rdf_global_id(G, G2),
	b_getval(the_theory,X),
	debug(doc, 'docm:~q~n', [(S2,P2,O2,G2)]),
	dddd(spog(S2,P2,O2,G2), X).
/*
member
*/

exists(I) :-
	docm(I, exists, now);
	once((gensym(bn, I),doc_add(I, exists, now))).


has(S,P,O) :-
	(	doc(S,P,O2)
	->	O = O2
	;	doc_add(S,P,O)).

doc_new_uri(Uri) :-
	doc_new_uri(Uri, '').

doc_new_uri(Uri, Postfix) :-
	%tmp_file_url(loc(file_name, 'response.n3'), D),
	gensym('#bnx', Uri0),
	atomic_list_concat([Uri0, '_', Postfix], Uri).
	/*,
	atomic_list_concat([D, '#', Uid], Uri)*/
	/*,
	% this is maybe too strong because it can bind with variable nodes
	assertion(\+doc(Uri,_,_)),
	assertion(\+doc(_,_,Uri))
	*/


/*
?- make,doc_clear, doc_core:exists(First), has(First, num, 1), has(First, field, F1), doc_core:exists(Last), has(Last, num, N2), call_with_depth_limit(has(Last, field, "foo"), 15, Depth).
First = Last, Last = bn11,
F1 = "foo",
N2 = 1,
Depth = 14 ;
First = bn11,
Last = bn12,
Depth = 16.
?-
*/


/*
░░░░░░░░░░░░░█▀▄░█▀█░█░░
░░░░░░░░░░░░░█▀▄░█░█░█░░
░░░░░░░░░░░░░▀░▀░▀▀▀░▀▀▀
	Reasonably Open List.
	T is an open list. Unifying with the tail variable is only possible through rol_add.
*/

/*
 ensure Spog is added as a last element of T, while memberchk would otherwise possibly just unify an existing member with it
*/
rol_add(Spog,T) :-
	(
		current_prolog_flag(doc_checks, true),
		rol_member(Spog,T),
		throw(added_quad_matches_existing_quad)
	)
	;	memberchk(Spog,T).

rol_assert(Spog,T) :-
	rol_member(Spog,T)
	->	true
	;	memberchk(Spog,T).

/*?*/
rol_add_quiet(Spog,T) :-
		rol_member(Spog,T)
	->	true
	; 	memberchk(Spog,T).

/* nondet */
rol_member(SpogA,T) :-
	/* avoid unifying SpogA with the open tail of T */
	member(SpogB, T),
	(	nonvar(SpogB)
	->	SpogA = SpogB
	;	(!,fail)).

	/*match(SpogA, SpogB)).
match((S1,P1,O1,G1),(S2,P2,O2,G2))
	(	S1 = S2
	->	true
	;	rdf_equal(?Resource1, ?Resource2)
	*/

rol_single_match(T,SpogA) :-
	(	current_prolog_flag(doc_checks, true)
	->	copy_term(SpogA,SpogA_Copy)
	;	true),
	rol_member(SpogA,T),
	(	current_prolog_flag(doc_checks, true)
	->
		(
			/* only allow one match */
			findall(x,rol_member(SpogA_Copy,T),Matches),
			length(Matches, Length),
			(	Length > 1
			->	(
					format(string(Msg), 'multiple_matches, use docm: ~q', [SpogA_Copy]),
					%gtrace,
					throw_string(Msg)
				)
			;	true)
		)
	;	true).





/*
░█▀▀░█▀▄░█▀█░█▄█░░░█░▀█▀░█▀█░░░█▀▄░█▀▄░█▀▀
░█▀▀░█▀▄░█░█░█░█░▄▀░░░█░░█░█░░░█▀▄░█░█░█▀▀
░▀░░░▀░▀░▀▀▀░▀░▀░▀░░░░▀░░▀▀▀░░░▀░▀░▀▀░░▀░░
*/

doc_from_rdf(Rdf_Graph) :-
	findall((X,Y,Z),
		rdf(X,Y,Z,Rdf_Graph),
		Triples),
	maplist(triple_rdf_vs_doc, Triples, Triples2),
	maplist(doc_add, Triples2).

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
		/*freeze(Float, float(Float)),
		freeze(Rat, rational(Rat)),*/
		(
			(var(Float),rational(Rat)) /* swipl does something totally insane here with the loc term */
		;
			(var(Rat), float(Float))
		),
		(	nonvar(Rat)
		->	Float is float(Rat)
		;	Rat is rationalize(Float)),!.

node_rdf_vs_doc(Atom, Atom) :- !.

node_rdf_vs_doc(String, Term) :-
	compound(Term), term_string(Term, String),
	!.

triple_rdf_vs_doc((S,P,O), (S,P,O2)) :-
	node_rdf_vs_doc(O,O2).

/* todo vars */



doc_to_rdf(Rdf_Graph) :-
	rdf_create_bnode(Rdf_Graph),
	findall(_,
		(
			docm(X,Y,Z),
			debug(doc, 'to_rdf:~q~n', [(X,Y,Z)]),
			triple_rdf_vs_doc((X2,Y2,Z2),(X,Y,Z)),
			(rdf_assert(X2,Y2,Z2,Rdf_Graph) -> true ; gtrace)
		),_).

add_to_rdf((X,Y,Z,G)) :-
	(
		triple_rdf_vs_doc((X2,Y2,Z2),(X,Y,Z)),
		debug(doc, 'to_rdf:~q~n', [(X2,Y2,Z2,G)]),
		catch(rdf_assert(X2,Y2,Z2,G),E,format(user_error,'~q~n',[E]))
	)
	->	true
	;	throw((X,Y,Z,G)).


/*:- comment(lib:doc_to_rdf_all_graphs, "if necessary, modify to not wipe out whole rdf database and to check that G doesn't already exist */

doc_to_rdf_all_graphs :-
	rdf_retractall(_,_,_,_),
	findall(_,(
			docm(X,Y,Z,G),
			add_to_rdf((X,Y,Z,G))
		),_
	).

save_doc(/*-*/Fn, /*+*/Url) :-
	(	report_file_path(loc(file_name, Fn), Url, loc(absolute_path,Path))
	->	true
	;	Path = Fn),
	Url = loc(absolute_url, Url_Value),
	doc_to_rdf_all_graphs,
	/* we'll possibly want different options for debugging dumps and for result output for excel */
	rdf_save_turtle(Path, [sorted(true), base(Url_Value), canonize_numbers(true), abbreviate_literals(false), prefixes([rdf,rdfs,xsd,l,livestock])]),
	rdf_retractall(_,_,_,/*fixme*/_Rdf_Graph).






/*
░░▄▀░█▀▀░█▀█░█▀█░█░█░█▀▀░█▀█░▀█▀░█▀▀░█▀█░█▀▀░█▀▀░▀▄░
░▀▄░░█░░░█░█░█░█░▀▄▀░█▀▀░█░█░░█░░█▀▀░█░█░█░░░█▀▀░░▄▀
░░░▀░▀▀▀░▀▀▀░▀░▀░░▀░░▀▀▀░▀░▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀▀▀░▀░░
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
*/


doc_new_(Type, Uri) :-
	doc_new_uri(Uri),
	doc_add(Uri, rdf:type, Type).

doc_new_theory(T) :-
	doc_new_uri(T),
	doc_add(T, rdf:type, l:theory).


request_has_property(P, O) :-
	request(R),
	doc(R, P, O).

request_add_property(P, O) :-
	request(R),
	doc_add(R, P, O).


request_assert_property(P, O, G) :-
	request(R),
	doc_assert(R, P, O, G).

request(R) :-
	doc(R, rdf:type, l:request).

add_alert(Type, Msg) :-
	request(R),
	doc_new_uri(Uri),
	doc_add(R, l:alert, Uri),
	doc_add(Uri, l:type, Type),
	doc_add(Uri, l:message, Msg).

assert_alert(Type, Msg) :-
	/*todo*/
	request(R),
	doc_new_uri(Uri),
	doc_add(R, l:alert, Uri),
	doc_add(Uri, l:type, Type),
	doc_add(Uri, l:message, Msg).

get_alert(Type, Msg) :-
	request(R),
	docm(R, l:alert, Uri),
	doc(Uri, l:type, Type),
	doc(Uri, l:message, Msg).

add_comment_stringize(Title, Term) :-
	pretty_term_string(Term, String),
	add_comment_string(Title, String).

add_comment_string(Title, String) :-
	doc_new_uri(Uri),
	doc_add(Uri, title, Title, comments),
	doc_add(Uri, body, String, comments).

doc_list_member(M, L) :-
	doc(L, rdf:first, M).

doc_list_member(M, L) :-
	doc(L, rdf:rest, R),
	doc_list_member(M, R).

doc_list_items(L, Items) :-
	findall(Item, doc_list_member(Item, L), Items).


doc_value(S, P, V) :-
	doc(S, P, O),
	doc(O, rdf:value, V).


doc_add_value(S, P, V) :-
	doc_new_uri(Uri),
	doc_add(S, P, Uri),
	doc_add(Uri, rdf:value, V).

/*
user:goal_expansion(
	vague_props(X, variable_names(Names))
, X) :-
	term_variables(X, Vars),
	maplist(my_variable_naming, Vars, Names).
vague_doc(S,
	compile_with_variable_names_preserved(X, variable_names(Names))),
*/

/*

pondering a syntax for triples..

	R l:ledger_account_opening_balance_total [
		l:coord Opening_Balance;
		l:ledger_account_name Bank_Account_Name];
	  l:ledger_account_opening_balance_part [
	  	l:coord Opening_Balance_Inverted;
		l:ledger_account_name Equity];
	*/
	/*
	R l:ledger_account_opening_balance_total [
		l:coord Opening_Balance;
		l:ledger_account_name Bank_Account_Name];
	  l:ledger_account_opening_balance_part [
	  	l:coord $>coord_inverse(<$, Opening_Balance),
		l:ledger_account_name $>account_by_role('Accounts'/'Equity')];
	*/

dg :-
	dump,gtrace.


gu(Prefixed, Full) :-
	rdf_global_id(Prefixed, Full).





/*
 ┏╸╻ ╻┏┳┓╻     ╺┳╸┏━┓   ╺┳┓┏━┓┏━╸╺┓
╺┫ ┏╋┛┃┃┃┃      ┃ ┃ ┃    ┃┃┃ ┃┃   ┣╸
 ┗╸╹ ╹╹ ╹┗━╸╺━╸ ╹ ┗━┛╺━╸╺┻┛┗━┛┗━╸╺┛
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
*/


/*
represent xml in doc.
*/

request_xml_to_doc(Dom) :-
	xml_to_doc(request_xml, [
		balanceSheetRequest,
		unitValues
	], pid:request_xml, Dom).

xml_to_doc(Prefix, Uris, Root, Dom) :-
	b_setval(xml_to_doc_uris, Uris),
	b_setval(xml_to_doc_uris_prefix, Prefix),
	b_setval(xml_to_doc_uris_used, _),
	xml_to_doc(Root, Dom).

xml_to_doc(Root, Dom) :-
	maplist(xml_to_doc(Root), Dom).

xml_to_doc(Root, X) :-
	atomic(X),
	doc_add(Root, rdf:value, X).

xml_to_doc(Root, element(Name, _Atts, Children)) :-
	b_getval(xml_to_doc_uris, Uris),
	b_getval(xml_to_doc_uris_used, Used),
	b_getval(xml_to_doc_uris_prefix, Prefix),

	(	member(Name, Uris)
	->	(	rol_member(Name, Used)
		->	throw_string('tag with name supposed to be docified as an uri already appeared')
		;	(
				Uri = Prefix:Name,
				rol_add(Name, Used)
			)
		)
	;	doc_new_uri(Uri)),

	doc_add(Root, Name, Uri),
	xml_to_doc(Uri, Children).








/*

╺┳┓┏━╸┏┓ ╻ ╻┏━╸┏━╸┓┏┓╻┏━╸
 ┃┃┣╸ ┣┻┓┃ ┃┃╺┏┃╺┓┃┃┗┫┃╺┓
╺┻┛┗━╸┗━┛┗━┛┗━┛┗━┛╹╹ ╹┗━┛


*/

omg :-
    open(fo, read, Fo),
    read_term(Fo, X,[]),
    open(X,write,Out_Stream),
    writeq(Out_Stream, bananana),
    close(Out_Stream),
    thread_signal(main, doc_dump),
    omg.

:- thread_create(omg, _).

doc_dump :-gtrace,
	once(save_doc('doc.n3', _)).



/*
we could control this with a thread select'ing some unix socket
*/
/*doc_dumping_enabled :-
	current_prolog_flag(doc_dumping_enabled, true).
*/

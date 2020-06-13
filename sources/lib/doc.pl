:- rdf_register_prefix(code,
'https://rdf.lodgeit.net.au/v1/code#').
:- rdf_register_prefix(kb,
'https://rdf.lodgeit.net.au/v1/kb#').
:- rdf_register_prefix(l,
'https://rdf.lodgeit.net.au/v1/request#').
:- rdf_register_prefix(account_taxonomies,
'https://rdf.lodgeit.net.au/v1/account_taxonomies#').
:- rdf_register_prefix(accounts,
'https://rdf.lodgeit.net.au/v1/accounts#').
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
:- rdf_register_prefix(report_entries,
'https://rdf.lodgeit.net.au/v1/report_entries#').
:- rdf_register_prefix(smsf,
'https://rdf.lodgeit.net.au/v1/calcs/smsf#').
:- rdf_register_prefix(smsf_ui,
'https://rdf.lodgeit.net.au/v1/calcs/smsf/ui#').
:- rdf_register_prefix(smsf_distribution,
'https://rdf.lodgeit.net.au/v1/calcs/smsf/distribution#').
:- rdf_register_prefix(smsf_distribution_ui,
'https://rdf.lodgeit.net.au/v1/calcs/smsf/distribution_ui#').
:- rdf_register_prefix(reallocation,
'https://rdf.lodgeit.net.au/v1/calcs/ic/reallocation#').



rdf_equal2(X,Y) :-
	!rdf_global_id(X, X2),
	!rdf_global_id(Y, Y2),
	X2 = Y2.


/*
	a quad-store implemented with an open list stored in a global thread-local variable
*/

%:- debug(doc).

% https://www.swi-prolog.org/pldoc/man?predicate=rdf_meta/1
/* uses goal_expansion, so as soon as you wrap the call in a !, it doesn't work, so we have to do this at runtime too anyway.
maybe this program will even run faster without this?*/
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
:- rdf_meta request_add_property(r,r,r).
:- rdf_meta request_assert_property(r,r,r).
:- rdf_meta request_assert_property(r,r,r,r).
:- rdf_meta doc_value(r,r,r).
:- rdf_meta doc_add_value(r,r,r).
:- rdf_meta doc_add_value(r,r,r,r).


doc_init :-
	doc_init_trace_0,
	doc_clear.

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
	b_setval(the_theory_nonground,[]),
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
	rdf_global_id(S, S2),
	rdf_global_id(P, P2),
	rdf_global_id(O, O2),
	rdf_global_id(G, G2),
	doc_trace0(doc_add(S2,P2,O2,G2)),
	debug(doc, 'add:~q~n', [(S2,P2,O2,G2)]),
	addd(S2,P2,O2,G2).

doc_add(S,P,O,G) :-
	doc_trace0(clean_pop(doc_add(S,P,O,G))),
	fail.

/*todo b_getval(the_theory_nongrounds,TTT),*/

/*
assumption: only O's are allowed to be non-atoms
*/

addd(S2,P2,O2,G2) :-
%	(\+ground(addd(S2,P2,O2,G2)) -> gtrace ; true),
	atom(S2),atom(P2),atom(G2),

	% get the_theory global
	b_getval(the_theory,Ss),
	%, ie a dict from subjects to pred-dicts
	% does it contain the subject?

	(	Ps = Ss.get(S2)
	%	the it's a dict from preds to graphs
	->	Ss2 = Ss
	;	(
			Ps = _{},
			Ss2 = Ss.put(S2, Ps),
			b_setval(the_theory, Ss2)
		)
	),

	(	Gs = Ps.get(P2)
	->	Ps2 = Ps
	;	(
			Gs = _{},
			Ps2 = Ps.put(P2, Gs),
			b_set_dict(S2, Ss2, Ps2)
		)
	),

/*
	(	Os = Gs.get(G2)
	->	(
			append(Os, [O2], Os2),
			Gs2 = Gs.put(G2, Os2),
			b_set_dict(P2, Ps2, Gs2)
		)
	;	(
			Gs2 = Gs.put(G2, [O2]),
			b_set_dict(P2, Ps2, Gs2)
		)
	).
*/

	(	Os = Gs.get(G2)
    ->      true
	;	(
            Os = _New_Rol,
            Gs2 = Gs.put(G2, Os),
            b_set_dict(P2, Ps2, Gs2))),
    rol_add(O2, Os).


addd(S2,P2,O2,G2) :-
	X = spog(S2,P2,O2,G2),
	\+((atom(S2),atom(P2),atom(G2))),
	%format(user_error, 'ng:~q~n', [X]),
	b_getval(the_theory_nonground, Ng),
	append(Ng, [X], Ng2),
	b_setval(the_theory_nonground, Ng2).
	%rol_add(X, $>).

/*
dddd(Spog, X) :-
	Spog = spog(S2,P2,O2,G2),
	(atom(S2);var(S2)),
	(atom(P2);var(P2)),
	(atom(G2);var(G2)),
	member(O2, X.get(S2).get(P2).get(G2)).
*/
dddd(Spog, X) :-
	Spog = spog(S2,P2,O2,G2),
	(atom(S2);var(S2)),
	(atom(P2);var(P2)),
	(atom(G2);var(G2)),
	rol_member(O2, X.get(S2).get(P2).get(G2)).

dddd(Spog, _X) :-
	member(Spog, $>b_getval(the_theory_nonground)).

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

/*
has(S,P,O) :-
	(	doc(S,P,O2)
	->	O = O2
	;	doc_add(S,P,O)).
*/
doc_new_uri(Uri) :-
	doc_new_uri('', Uri).

doc_new_uri(Postfix, Uri) :-
	result(R),
	doc(R, l:has_result_data_uri_base, Result_data_uri_base),
	/* fixme, use something deterministic */
	gensym('#bnx', Uri0),
	atomic_list_concat([Result_data_uri_base, Uri0, '_', Postfix], Uri).


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

node_rdf_vs_doc(
	date_time(Y,M,D,Z0,Z1,Z2) ^^ 'http://www.w3.org/2001/XMLSchema#dateTime',
	date(Y,M,D)) :-
		is_zero_number(Z0),
		is_zero_number(Z1),
		is_zero_number(Z2),!.

node_rdf_vs_doc(
	date_time(Y,L,D,H,M,S) ^^ 'http://www.w3.org/2001/XMLSchema#dateTime',
	date(Y,L,D,H,M,S, 0,'UTC',-)) :- !.

node_rdf_vs_doc(
	String ^^ 'http://www.w3.org/2001/XMLSchema#string',
	String):- string(String), !.

node_rdf_vs_doc(
	Int ^^ 'http://www.w3.org/2001/XMLSchema#integer',
	Int) :- integer(Int),!.

node_rdf_vs_doc(
	X ^^ 'http://www.w3.org/2001/XMLSchema#boolean',
X) :-
	(X == true
	;
	X == false),
	!.

node_rdf_vs_doc(
	Float ^^ 'http://www.w3.org/2001/XMLSchema#decimal',
	Rat) :-
		/*freeze(Float, float(Float)),
		freeze(Rat, rational(Rat)),*/
		(
			(var(Float),rational(Rat)) /* gtrace is totally buffled by this place, but the gist is that for anything else than a rational Rat, this correctly fails and goes on to the next case */
		;
			(var(Rat), float(Float))
		),
		(	nonvar(Rat)
		->	Float is float(Rat)
		;	Rat is rationalize(Float)),!.

node_rdf_vs_doc(Atom, Atom) :- atom(Atom),!.

node_rdf_vs_doc(String, Term) :-
	var(String),
	/*compound(Term), */term_string(Term, String),
	!.

triple_rdf_vs_doc((S,P,O), (S,P,O2)) :-
	catch(
		(	node_rdf_vs_doc(O,O2)
		->	true
		;	throw('conversion from rdf to doc failed')),
		E,
		(
			format(user_error, '~q', [E])
			,gtrace
		)
	).

/* todo vars */



doc_to_rdf(Rdf_Graph) :-
	rdf_create_bnode(Rdf_Graph),
	findall(_,
		(
			docm(X,Y,Z),
			debug(doc, 'to_rdf:~q~n', [(X,Y,Z)]),
			triple_rdf_vs_doc((X2,Y2,Z2),(X,Y,Z)),
			!rdf_assert(X2,Y2,Z2,Rdf_Graph)
		),_).

add_to_rdf((X,Y,Z,G)) :-
	(
		triple_rdf_vs_doc((X2,Y2,Z2),(X,Y,Z)),
		debug(doc, 'to_rdf:~q~n', [(X2,Y2,Z2,G)]),
		catch(rdf_assert(X2,Y2,Z2,G),E,format(user_error,'~q~n while saving triple:~n~q~n',[E, (X,Y,Z,G)]))
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

save_doc_turtle :-
	Fn = 'doc.n3',
	add_report_file(-15,Fn, Fn, Url),
	report_file_path(loc(file_name, Fn), Url, loc(absolute_path,Path)),
	Url = loc(absolute_url, Url_Value),
	rdf_save_turtle(Path, [sorted(true), base(Url_Value), canonize_numbers(true), abbreviate_literals(false), prefixes([rdf,rdfs,xsd,l,livestock])]).

save_doc_trig :-
	Fn = 'doc.trig',
	add_report_file(-15,Fn, Fn, Url),
	report_file_path(loc(file_name, Fn), Url, loc(absolute_path,Path)),
	Url = loc(absolute_url, Url_Value),
	rdf_save_trig(Path, [sorted(true), base(Url_Value), canonize_numbers(true), abbreviate_literals(false), prefixes([rdf,rdfs,xsd,l,livestock])]).

save_doc :-
	doc_to_rdf_all_graphs,
	save_doc_turtle,
	save_doc_trig,
	rdf_retractall(_,_,_,/*fixme*/_Rdf_Graph).

make_rdf_report :-
	Title = 'response.n3',
	doc_to_rdf(Rdf_Graph),
	report_file_path(loc(file_name, Title), Url, loc(absolute_path,Path)),
	add_report_file(-11,Title, Title, Url),
	Url = loc(absolute_url, Url_Value),
	rdf_save_turtle(Path, [graph(Rdf_Graph), sorted(true), base(Url_Value), canonize_numbers(true), abbreviate_literals(false), prefixes([rdf,rdfs,xsd,l,livestock])]).


doc_from_rdf(Rdf_Graph, Replaced_prefix, Replacement_prefix) :-
	findall((X2,Y,Z2),
		(
			rdf(X,Y,Z,Rdf_Graph),
			replace_uri_node_prefix(X, Replaced_prefix, Replacement_prefix, X2),
			replace_uri_node_prefix(Z, Replaced_prefix, Replacement_prefix, Z2)
		),
		Triples),
	maplist(triple_rdf_vs_doc, Triples, Triples2),
	maplist(doc_add, Triples2).

replace_uri_node_prefix(Z, Replaced_prefix, Replacement_prefix, Z2) :-
	(	(
			atom(Z),
			atom_prefix(Z, Replaced_prefix)
		)
	->	!replace_atom_prefix(Z, Replaced_prefix, Replacement_prefix, Z2)
	;	Z = Z2).

replace_atom_prefix(X, Replaced_prefix, Replacement_prefix, X2) :-
	atom_length(Replaced_prefix, L0),
	atom_length(X, L1),
	L2 is L1 - L0,
	sub_atom(X,_,L2,0,S),
	atomic_list_concat([Replacement_prefix, S], X2).


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
	result(R),
	doc(R, P, O).

request_add_property(P, O) :-
	b_getval(default_graph, G),
	request_add_property(P, O, G).

request_add_property(P, O, G) :-
	result(R),
	doc_add(R, P, O, G).

request_assert_property(P, O) :-
	b_getval(default_graph, G),
	request_assert_property(P, O, G).

request_assert_property(P, O, G) :-
	result(R),
	doc_assert(R, P, O, G).

request(R) :-
	doc(R, rdf:type, l:'Request').

 request_data(D) :-
	request(Request),
	doc(Request, l:has_request_data, D).

request_accounts(As) :-
	request_data(D),
	!doc(D, l:has_accounts, As).

result(R) :-
	doc(R, rdf:type, l:'Result').

 add_alert(Type, Msg) :-
	result(R),
	doc_new_uri(alert, Uri),
	doc_add(R, l:alert, Uri),
	doc_add(Uri, l:type, Type),
	doc_add(Uri, l:message, Msg).

assert_alert(Type, Msg) :-
	/*todo*/
	result(R),
	doc_new_uri(alert, Uri),
	doc_add(R, l:alert, Uri),
	doc_add(Uri, l:type, Type),
	doc_add(Uri, l:message, Msg).

get_alert(Type, Msg) :-
	result(R),
	docm(R, l:alert, Uri),
	doc(Uri, l:type, Type),
	doc(Uri, l:message, Msg).

add_comment_stringize(Title, Term) :-
	pretty_term_string(Term, String),
	add_comment_string(Title, String).

add_comment_string(Title, String) :-
	doc_new_uri(comment, Uri),
	doc_add(Uri, title, Title, comments),
	doc_add(Uri, body, String, comments).

doc_list_member(M, L) :-
	doc(L, rdf:first, M).

doc_list_member(M, L) :-
	doc(L, rdf:rest, R),
	doc_list_member(M, R).

doc_list_items(L, Items) :-
	findall(Item, doc_list_member(Item, L), Items).

doc_add_list([H|T], Uri) :-
	doc_new_uri(rdf_list, Uri),
	doc_add(Uri, rdf:first, H),
	doc_add_list(T, Uri2),
	doc_add(Uri, rdf:rest, Uri2).

doc_add_list([], rdf:nil).


doc_value(S, P, V) :-
	b_getval(default_graph, G),
	doc_value(S, P, V, G).

doc_value(S, P, V, G) :-
	doc(S, P, O, G),
	doc(O, rdf:value, V).


doc_add_value(S, P, V) :-
	b_getval(default_graph, G),
	doc_add_value(S, P, V, G).

doc_add_value(S, P, V, G) :-
	doc_new_uri(value, Uri),
	doc_add(S, P, Uri, G),
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
    open(X,append,Out_Stream),
    writeq(Out_Stream, bananana),
    close(Out_Stream),
    thread_signal(main, doc_dump),
    omg.

:- thread_create(omg, _).

doc_dump :-
	once(save_doc).

dg :-
	doc_dump,gtrace.



/*
┏━╸╻ ╻┏━╸┏━╸╻
┣╸ ┏╋┛┃  ┣╸ ┃
┗━╸╹ ╹┗━╸┗━╸┗━╸
*/
sheet_and_cell_string_for_property(Item, Prop, Str) :-
	!doc(Item, Prop, Value),
	!sheet_and_cell_string(Value, Str).

sheet_and_cell_string(Value, Str) :-
	!doc(Value, excel:sheet_name, Sheet_name),
	!doc(Value, excel:col, Col),
	!doc(Value, excel:row, Row),
	!atomics_to_string([Sheet_name, ' ', Col, ':', Row], Str).

read_coord_vector_from_doc_string(Item, Prop, Default_currency, Side, VectorA) :-
	doc_value(Item, Prop, Amount_string),
	(	vector_from_string(Default_currency, Side, Amount_string, VectorA)
	->	true
	;	throw_string(['error reading "amount" in ', $>!sheet_and_cell_string($>doc(Item, Prop))])).

 read_value_from_doc_string(Item, Prop, Default_currency, Value) :-
	doc_value(Item, Prop, Amount_string),
	(	value_from_string(Default_currency, Amount_string, Value)
	->	true
	;	(
			assert(var(Value)),
			throw_string(['error reading "amount" in ', $>!sheet_and_cell_string($>doc(Item, Prop))])
		)
	).




/*
we could control this with a thread select'ing some unix socket
*/
/*doc_dumping_enabled :-
	current_prolog_flag(doc_dumping_enabled, true).
*/





/*

diff from rol_ version. This was maybe even faster, and prolly uses a lot less memory?

@@ -169,12 +169,16 @@ addd(S2,P2,O2,G2) :-
        ),

        (       Os = Gs.get(G2)
-       ->      true
+       ->      (
+                       append(Os, [O2], Os2),
+                       Gs2 = Gs.put(G2, Os2),
+                       b_set_dict(P2, Ps2, Gs2)
+               )
        ;       (
-                       Os = _New_Rol,
-                       Gs2 = Gs.put(G2, Os),
-                       b_set_dict(P2, Ps2, Gs2))),
-       rol_add(O2, Os).
+                       Gs2 = Gs.put(G2, [O2]),
+                       b_set_dict(P2, Ps2, Gs2)
+               )
+       ).

 addd(S2,P2,O2,G2) :-
        \+((ground(spog(S2,P2,O2,G2)),atom(S2),atom(P2),atom(G2))),
@@ -186,7 +190,7 @@ dddd(Spog, X) :-
        (atom(S2);var(S2)),
        (atom(P2);var(P2)),
        (atom(G2);var(G2)),
-       rol_member(O2, X.get(S2).get(P2).get(G2)).
+       member(O2, X.get(S2).get(P2).get(G2)).
*/




/*

version trying to use swipl rdf db, 4x slower than dicts (and with non-backtracking semantics)

can_go_into_rdf_db(spog(S2,P2,O2,G2)) :-
	atom(S2),atom(P2),atom(G2),atomic(O2).

addd(S2,P2,O2,G2) :-
	can_go_into_rdf_db(spog(S2,P2,O2,G2)),
	rdf_assert(S2,P2,O2,G2).

addd(S2,P2,O2,G2) :-
	X = spog(S2,P2,O2,G2),
	\+can_go_into_rdf_db(X),
	rol_add(X, $>b_getval(the_theory_nonground)).

dddd(Spog, _X) :-
	Spog = spog(S2,P2,O2,G2),
	(atom(S2);var(S2)),
	(atom(P2);var(P2)),
	(atom(G2);var(G2)),
	(atomic(O2);var(O2)),
	rdf(S2,P2,O2,G2).
*/







/*

	permanent storage of doc data / request data in a triplestore:


--------

dereferenceable uris.
RDF_URI_BASE =


objects:
	request
	processing


prolog could need access to the request data










		we want hassle-free data exchange between microservices, but speed is a big concern, so probably the store should be in the prolog process. But the process may not be running at this point. So here, we maybe stick this data into rdflib, and pass that along, then possibly invoke a series of commands on prolog, the first inserting the data into it, the second executing the query









*/

/*

what makes sense to rdf-ize?
take, as an example account role. (RoleParent/RoleChild), posibly nested. For all purposes, this is atomic. We don't want to reference any sub-part of it, ever. It's assembled once, and then treated as an atom. If we "export" it into rdf as an uri, then it's also a referenceable identifier.

*/




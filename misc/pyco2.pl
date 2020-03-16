:- use_module(library(clpfd)).
:- op(900,xfx,<=).
:- use_module(library(fnotation)).
:- fnotation_ops($>,<$).
:- op(900,fx,<$).



/*
 for list bnodes, produce nicer term for printing
*/

nicer_term(T, Nicer) :-
%gtrace,
	T =.. [F|Args],
	maplist(nicer_arg, Args, Nicer_args),
	Nicer =.. [F|Nicer_args].

nicer_arg(Bn, Nicer) :-
	assertion(var(Nicer)),
	debug(pyco_nicer, 'nicer ~q?', [Bn]),
	nicer_arg2(Bn, Nicer),
	debug(pyco_nicer, 'nicer ~q => ~q', [Bn, Nicer]).

nicer_arg2(X, X) :-
	\+ nicer_bn(X, _).

nicer_arg2(Bn, Nicer) :-
	nicer_bn(Bn, Nicer).

nicer_bn(Bn, Nicer) :-
	nonvar(Bn),
	\+ \+ Bn = bn(_, 'list cell exists'{first:_,rest:_}),
	nicer_bn2(Bn, Nice_items),
	Bn = bn(Id, _),
	'='(Nice_functor, $>atomic_list_concat([
			list,
			$>term_string(Id)])),
	'=..'(Nicer, [Nice_functor|Nice_items]).

nicer_bn2(Bn, Nice_items) :-
	collect_items(Bn, Items),
	maplist(nicer_arg2, Items, Nice_items).

collect_items(Bn, [F|Rest]) :-
	\+ \+ Bn = bn(_, 'list cell exists'{first:_,rest:_}),
	Bn = bn(_, 'list cell exists'{first:F,rest:R}),
	nonvar(R),
	collect_items(R, Rest).

collect_items(Bn, []) :-
	Bn == nil.


/*
 some testing rules
*/

:- discontiguous pyco0_rule/2.
:- discontiguous pyco0_rule/3.
:- multifile pyco0_rule/2.
:- multifile pyco0_rule/3.


/*

 main logic

*/

find_rule(Query, Desc, Head_items, Body_items, Prep) :-
	(	pyco0_rule(Desc, Head_items <= Body_items, Prep)
	;	(
			pyco0_rule(Desc, Head_items <= Body_items),
			Prep = true)),
	\+ \+member(Query, Head_items).

matching_rule(Level,Eps0, Query, Body_items, Eps1) :-
	find_rule(Query, Desc, Head_items, Body_items, Prep),
	debug(pyco_proof, '(~q)match~q: ~q (~q)', [$>nb_getval(step) ,Level, $>nicer_term(Query), Desc]),
	query_term_ep_terms(Query, Query_ep_terms),
	member(Query, Head_items),
	check_and_update_ep(Eps0, Desc, Query_ep_terms, Eps1),
	debug(pyco_prep, 'call prep: ~q', [Prep]),
	call(Prep).

proof(Level,Eps0,Query) :-
	matching_rule(Level,Eps0,Query, Body_items,Eps1),
	/* Query has been unified with head. */
	Deeper_level is Level + 1,

	nb_getval(step, Step),
	Step_next is Step + 1,
	nb_setval(step, Step_next),

	body_proof(Deeper_level, Eps1, Body_items).

proof(Level,_,Query) :- call_native(Level, Query).

body_proof(_, _, []).

body_proof(Level, Eps1, Body_items) :-
	pick_bi(Body_items, Bi, Body_items_next),
	proof(Level, Eps1, Bi),
	body_proof(Level, Eps1, Body_items_next).

pick_bi(Body_items, Bi, Body_items_next) :-
	'pairs of Index-Num_unbound'(Body_items, Pairs),
	aggregate_all(min(Num_unbound), member(_Index-Num_unbound, Pairs), Min_unbound),
	once(member(Picked_bi_index-Min_unbound, Pairs)),
	extract_element_from_list(Body_items, Picked_bi_index, Bi, Body_items_next).


/*
 ep stuff
*/


check_and_update_ep(Eps0, Desc, Query_ep_terms, Eps1) :-
	ep_list_for_rule(Eps0, Desc, Ep_List),
	debug(pyco_ep, 'seen:', []),
	maplist(print_debug_ep_list_item, Ep_List),
	debug(pyco_ep, 'now: ~q', [Query_ep_terms]),
	ep_ok(Ep_List, Query_ep_terms),
	append(Ep_List, [Query_ep_terms], Ep_List_New),
	Eps1 = Eps0.put(Desc, Ep_List_New).

print_debug_ep_list_item(I) :-
	debug(pyco_ep, '* ~q', [I]).

query_term_ep_terms(Query, Query_ep_terms) :-
	Query =.. [_|Args],
	maplist(arg_ep_table_term, Args, Query_ep_terms).

ep_list_for_rule(Eps0, Desc, X) :-
	(	get_dict(Desc, Eps0, X)
	->	true
	;	X = []).

ep_ok(Ep_List, Query_ep_terms) :-
	%debug(pyco_ep, 'seen:~q', [Ep_List]),
	%debug(pyco_ep, 'now:~q ?', [Query_ep_terms]),
	maplist(ep_ok2(Query_ep_terms), Ep_List).

ep_ok2(Query_ep_terms, Ep_Entry) :-
	length(Query_ep_terms, L0),
	length(Ep_Entry, L1),
	assertion(L0 == L1),
	findall(x,
		(
			between(1, L0, I),
			nth1(I, Ep_Entry, Old_arg),
			nth1(I, Query_ep_terms, New_arg),
			arg_is_productively_different(Old_arg, New_arg)
		),
		Differents),
	(	Differents == []
	->	(
			debug(pyco_proof, 'EP!', []),
			false
		)
	;	true).


arg_ep_table_term(A, var) :-
	var(A).
arg_ep_table_term(A, const(A)) :-
	atomic(A).
arg_ep_table_term(A, bn(Uid_str, Tag)) :-
	nonvar(A),
	A = bn(Uid, Bn),
	is_dict(Bn, Tag),
	term_string(Uid, Uid_str).


%\+arg_is_productively_different(var, var).
arg_is_productively_different(var, const(_)).
arg_is_productively_different(var, bn(_,_)).
arg_is_productively_different(const(_), var).
arg_is_productively_different(const(C0), const(C1)) :- C0 \= C1.
arg_is_productively_different(const(_), bn(_,_)).
arg_is_productively_different(bn(_,_), var).
arg_is_productively_different(bn(_,_), const(_)).
arg_is_productively_different(bn(Uid_old_str,Tag0), bn(Uid_new_str,Tag1)) :-
	assertion(string(Uid_old_str)),
	assertion(string(Uid_new_str)),
	/* for same uids, we fail. */
	/* for differing types, success */
	(	Tag0 \= Tag1
	->	true
	;	came_before(Uid_new_str, Uid_old_str)).


came_before(A, B) :-
	b_getval(bn_log, Bn_log),
	nth0(Ia, Bn_log, bn(A,_)),
	nth0(Ib, Bn_log, bn(B,_)),
	Ia < Ib.

register_bn(bn(Uid, Dict)) :-
	is_dict(Dict, Tag),
	b_getval(bn_log, Bn_log0),
	term_string(Uid, Uid_str),
	Entry = bn(Uid_str, Tag),
	register_bn2(Entry, Bn_log0).

register_bn2(Entry, Bn_log0) :-
	member(Entry, Bn_log0).

register_bn2(Entry, Bn_log0) :-
	\+ member(Entry, Bn_log0),
	append(Bn_log0, [Entry], Bn_log1),
	b_setval(bn_log, Bn_log1),
	debug(pyco_ep, 'bn_log:', []),
	maplist(debug_print_bn_log_item, Bn_log1).

debug_print_bn_log_item(I) :-
	debug(pyco_ep, '* ~q', [I]).


/*
 calling prolog
*/

call_native(Level, Query) :-
	/* this case tries to handle calling native prolog predicates */
	\+find_rule(Query, _, _, _, _),
	catch(
		(
			debug(pyco_proof, '(~q)prolog~q call:~q', [$>nb_getval(step), Level, Query]),
			call(Query),
			debug(pyco_proof, '(~q)prolog~q call succeded:~q', [$>nb_getval(step), Level, Query])
		),
		error(existence_error(procedure,Name/Arity),_),
		% you'd think this would only catch when the Query term clause doesn't exist, but nope, it actually catches any nested exception. Another swipl bug?
		(
			functor(Query, Name, Arity),
			%gtrace,
			fail
		)
	).



/*
 body ordering stuff
*/

number_of_unbound_args(Term, Count) :-
	Term =.. [_|Args],
	aggregate_all(count,
	(
		member(X, Args),
		var(X)
	),
	Count).

'pairs of Index-Num_unbound'(Body_items, Pairs) :-
	length(Body_items, L0),
	L is L0 - 1,
	findall(I-Num_unbound,
		(
			between(0,L,I),
			nth0(I,Body_items,Bi),
			number_of_unbound_args(Bi, Num_unbound)
		),
	Pairs).



/*
	extract_element_from_list with pattern-matching, preserving variable-to-variable bindings
*/

extract_element_from_list([], _, _, _) :- assertion(false).

extract_element_from_list(List, Index, Element, List_without_element) :-
	extract_element_from_list2(0, List, Index, Element, List_without_element).

extract_element_from_list2(At_index, [F|R], Index, Element, List_without_element) :-
	Index == At_index,
	F = Element,
	Next_index is At_index + 1,
	extract_element_from_list2(Next_index, R, Index, Element, List_without_element).

extract_element_from_list2(At_index, [F|R], Index, Element, [F|WT]) :-
	Index \= At_index,
	Next_index is At_index + 1,
	extract_element_from_list2(Next_index, R, Index, Element, WT).

extract_element_from_list2(_, [], _, _, []).




/*
top-level interface
*/



run(Query) :-
	b_setval(bn_log, []),
	nb_setval(step, 0),
	proof(Query).

proof(Query) :-
	proof(0,eps{dummy:[]},Query).



/*
random notes

ep check:
https://www.swi-prolog.org/pldoc/man?section=compare


optimization:

http://irnok.net:3030/help/source/doc/home/prolog/ontology-server/ClioPatria/lib/semweb/rdf_optimise.pl

pyco optimization:
	https://books.google.cz/books?id=oc7cBwAAQBAJ&pg=PA26&lpg=PA26&dq=prolog++variable+address&source=bl&ots=cDxavU-UaU&sig=ACfU3U0y1RnTKfJI58kykhqltp8fBNkXhA&hl=en&sa=X&ved=2ahUKEwiJ6_OWyuPnAhUx-yoKHZScAU4Q6AEwEHoECAkQAQ#v=onepage&q=prolog%20%20variable%20address&f=false

===


?x a response
?request result ?result
?response result ?result

=====

?sts0 prepreprocess ?sts1
?sts1 preprocess ?txs



{?sts0 prepreprocess ?sts1} <=
{
    ?sts0 first ?st0
    ?st0 action_verb "livestock_sell"

    .....

    ?sts0 rest ?stsr
    ?stsr prepreprocess ?sts1r.

two approaches to optimization:
    follow the data:
        ?txs are bound, so call ?sts1 preprocess ?txs first
    ep-yield earlier:
        as soon as we're called with only vars?


*/


/*
multiple heads:

[a,b] :- writeq(xxx).

?- clause([X|XX],Y).
X = a,
XX = [b],
Y = writeq(xxx).


*/

/*
ba((N,A)) :-
	call(N,A).
*/




/*

debug(pyco_ep),Q = test_statement1b(End, All, Capped), run(Q), nicer_term(Q, NQ).




*/

/*
ignore
list_to_u([], nil).
list_to_u([H|T], Cell) :-
	proof(fr(Cell,H,Cell2)),
	list_to_u(T, Cell2).
*/



/*

todo visualizations:
univar pyco outputs for example kbdbgtests_clean_lists_pyco_unify_bnodes_0.n3:
	describes rule bodies and heads in detail.
	Terms just simple non-recursive functor + args, but thats a fine start.
	structure of locals..(memory layout), because pyco traces each bind, expressed by memory adressess. We could probably just not output that and the visualizer would simply not show any binds but still show the proof tree.
	eventually, a script is ran: converter = subprocess.Popen(["./kbdbg2jsonld/frame_n3.py", pyin.kbdbg_file_name, pyin.rules_jsonld_file_name])
	converts the n3 to jsonld, for consumption in the browser app.
	we cant write json-ld from swipl either, so, i'd reuse the script.

	store traces in doc? nah, too much work wrt backtracking
	but we'll store the rules/static info described above, either in doc or directly in rdf db,
	then save as something that the jsonld script can load, and spawn it.

	trace0.js format:
		S() is a call to a function in the browser. This ensures that the js file stays valid syntax even on crash.

*/


%print_item(I) :-
%	format(user_error,'result: ~q~n', [NQ]),

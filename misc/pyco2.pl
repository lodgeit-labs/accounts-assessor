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

collect_items(Bn, []) :-
	Bn == nil.

collect_items(Bn, [F|Rest]) :-
	nonvar(Bn),
	\+ \+ Bn = bn(_, 'list cell exists'{first:_,rest:_}),/*?*/
	Bn = bn(_, 'list cell exists'{first:F,rest:R}),
	collect_items2(R, Rest).

collect_items2(R, Rest) :-
	nonvar(R),
	collect_items(R, Rest).

collect_items2(R, ['|_']) :-
	var(R).


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

run2(Query) :-
	run2_2(Query),
	debug(pyco_proof, '~w final...', [$>trace_prefix(r, -1)]),
	proof(0,eps{},ep_fail,noisy,Query),
	debug(pyco_proof, '~w result.', [$>trace_prefix(r, -1)]).

run2_2(Query) :-
	%(Quiet = noisy -> debug(depth_map, 'map for: ~q', [Query]); true),
	depth_map(Query, Map0), /*nope, this should include bodies,the whole tree*/
	proof(0,eps{},ep_yield,noisy,Query),
	depth_map(Query, Map1),
	run2_3(Query, Map0, Map1).

run2_3(_Query, Map0, Map1) :-
	Map0 = Map1,
	debug(pyco_proof, '~w stabilized.', [$>trace_prefix(r, -1)]).

run2_3(Query, Map0, Map1) :-
	Map0 \= Map1,
	debug(pyco_proof, '~w repeating.', [$>trace_prefix(r, -1)]),
	run2_2(Query),
	debug(pyco_proof, '~w ok...', [$>trace_prefix(r, -1)]).

proof(Level,Eps0,Ep_yield, Quiet,Query) :-
	nb_getval(step, Proof_id),
	term_string(Proof_id, Proof_id_str),
	register_frame(Proof_id_str),
	Deeper_level is Level + 1,
	proof2(Proof_id_str,Deeper_level,Eps0,Ep_yield, Quiet,Query).

proof2(Proof_id_str,Level,Eps0,Ep_yield, Quiet,Query) :-
	matching_rule2(Level, Query, Desc, Body_items, Prep, Query_ep_terms),
	(Quiet = noisy -> debug(pyco_proof, '~w match: ~q (~q)', [$>trace_prefix(Proof_id_str, Level), $>nicer_term(Query), Desc]); true),
	ep_list_for_rule(Eps0, Desc, Ep_List),
	(Quiet = noisy -> ep_debug_print_1(Ep_List, Query_ep_terms); true),
	proof3(Proof_id_str, Eps0, Ep_List, Query_ep_terms, Desc, Prep, Level, Body_items, Ep_yield, Quiet, Query).

proof2(Proof_id_str,Level,_,_,Quiet,Query) :-
	call_native(Proof_id_str,Level, Quiet, Query).

proof3(Proof_id_str, Eps0, Ep_List, Query_ep_terms, Desc, Prep, Level, Body_items, Ep_yield, Quiet, _Query) :-
	ep_ok(Ep_List, Query_ep_terms, Quiet),
	prove_body(Proof_id_str, Ep_yield, Eps0, Ep_List, Query_ep_terms, Desc, Prep, Level, Body_items, Quiet).

proof3(Proof_id_str, _Eps0, Ep_List, Query_ep_terms, Desc, _Prep, Level, _Body_items, Ep_yield, Quiet, Query) :-
	\+ep_ok(Ep_List, Query_ep_terms, Quiet),
	proof4(Proof_id_str, Desc, Level, Ep_yield, Quiet, Query).

proof4(Proof_id_str, Desc, Level, Ep_yield, Quiet, Query) :-
	Ep_yield == ep_yield,
	(Quiet = noisy -> debug(pyco_proof, '~w ep_yield: ~q (~q)', [$>trace_prefix(Proof_id_str, Level), $>nicer_term(Query), Desc]); true).

proof4(Proof_id_str, Desc, Level, Ep_yield, Quiet, Query) :-
	Ep_yield == ep_fail,
	(Quiet = noisy -> debug(pyco_proof, '~w ep fail: ~q (~q)', [$>trace_prefix(Proof_id_str, Level), $>nicer_term(Query), Desc]); true),
	fail.

prove_body(Proof_id_str, Ep_yield, Eps0, Ep_List, Query_ep_terms, Desc, Prep, Level, Body_items, Quiet) :-
	updated_ep_list(Eps0, Ep_List, Proof_id_str, Query_ep_terms, Desc, Eps1),
	call_prep(Prep),
	bump_step,
	body_proof(Proof_id_str, Ep_yield, Level, Eps1, Body_items, Quiet).

body_proof(Proof_id_str, Ep_yield, Level, Eps1, Body_items, Quiet) :-
	body_proof2(Proof_id_str, Ep_yield, Level, Eps1, Body_items, Quiet).

body_proof(Proof_id_str, Ep_yield, Level, Eps1, Body_items, Quiet) :-
	%(Quiet = noisy -> debug(pyco_proof, '~w disproving..', [$>trace_prefix(Proof_id_str, Level)]); true),
	\+body_proof2(Proof_id_str, Ep_yield, Level, Eps1, Body_items, quiet),
	(Quiet = noisy -> debug(pyco_proof, '~w disproved.', [$>trace_prefix(Proof_id_str, Level)]); true),
	false.

body_proof2(_Proof_id_str, Ep_yield, Level, Eps1, Body_items, Quiet) :-
	maplist(proof(Level, Eps1, Ep_yield, Quiet), Body_items).

depth_map(X, v) :-
	var(X).

depth_map(X, Map) :-
	nonvar(X),
	X =.. [_|Args],
	maplist(depth_map, Args, Args2),
	Map =.. [nv|Args2].



/*
 ep stuff
*/

updated_ep_list(Eps0, Ep_List, Proof_id_str, Query_ep_terms, Desc, Eps1) :-
	append(Ep_List, [Proof_id_str-Query_ep_terms], Ep_List_New),
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

ep_ok(Ep_List, Query_ep_terms, Quiet) :-
	%debug(pyco_ep, 'seen:~q', [Ep_List]),
	%debug(pyco_ep, 'now:~q ?', [Query_ep_terms]),
	maplist(ep_ok2(Query_ep_terms, Quiet), Ep_List),
	(Quiet = noisy -> debug(pyco_ep, 'ep_ok:~q', [Query_ep_terms]);true)
	.

ep_ok2(Query_ep_terms, Quiet, Proof_id_str-Ep_Entry) :-
	length(Query_ep_terms, L0),
	length(Ep_Entry, L1),
	assertion(L0 == L1),
	findall(x,
		(
			between(1, L0, I),
			nth1(I, Ep_Entry, Old_arg),
			nth1(I, Query_ep_terms, New_arg),
			arg_is_productively_different(Proof_id_str, Old_arg, New_arg)
		),
		Differents),
	(	Differents == []
	->	(
			(Quiet = noisy -> debug(pyco_proof, 'EP!', []);true),
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


%\+arg_is_productively_different(_, var, var).
arg_is_productively_different(_, var, const(_)).
arg_is_productively_different(_, var, bn(_,_)).
arg_is_productively_different(_, const(_), var).
arg_is_productively_different(_, const(C0), const(C1)) :- C0 \= C1.
arg_is_productively_different(_, const(_), bn(_,_)).
arg_is_productively_different(_, bn(_,_), var).
arg_is_productively_different(_, bn(_,_), const(_)).
arg_is_productively_different(Proof_id_str, bn(Uid_old_str,Tag0), bn(Uid_new_str,Tag1)) :-
	assertion(string(Uid_old_str)),
	assertion(string(Uid_new_str)),
	/* for same uids, we fail. */
	/* for differing types, success */
	(	Tag0 \= Tag1
	->	true
	;	(
			Uid_old_str \= Uid_new_str,
			came_before(bn(Uid_new_str,_), fr(Proof_id_str))
		)).


came_before(A, B) :-
	b_getval(bn_log, Bn_log),

	assertion(nth0(Ib, Bn_log, B)),
	nth0(Ib, Bn_log, B),

	(	nth0(Ia, Bn_log, A)
	->	Ia < Ib
	;	true).

register_bn(bn(Uid, Dict)) :-
	is_dict(Dict, Tag),
	term_string(Uid, Uid_str),
	Entry = bn(Uid_str, Tag),
	register_bn2(Entry).

register_frame(F) :-
	register_bn2(fr(F)).

register_bn2(Entry) :-
	b_getval(bn_log, Bn_log0),
	member(Entry, Bn_log0).

register_bn2(Entry) :-
	b_getval(bn_log, Bn_log0),
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

call_native(Proof_id_str, Level, Quiet, Query) :-
	/* this case tries to handle calling native prolog predicates */
	\+matching_rule2(Level, Query, _,_,_,_),
	(Quiet = noisy -> debug(pyco_proof, '~w prolog call:~q', [$>trace_prefix(Proof_id_str, Level), Query]); true),
	call_native2(Proof_id_str, Level, Quiet, Query).

call_native2(Proof_id_str, Level, Quiet, Query) :-
	call_native3(Query),
	(Quiet = noisy -> debug(pyco_proof, '~w prolog call succeded:~q', [$>trace_prefix(Proof_id_str, Level), Query]); true).

call_native2(Proof_id_str, Level, Quiet, Query) :-
	\+call_native3(Query),
	(Quiet = noisy -> debug(pyco_proof, '~w prolog call failed:~q', [$>trace_prefix(Proof_id_str, Level), Query]); true),
	fail.

call_native3(Query) :-
	catch(
		call(Query),
		error(existence_error(procedure,Name/Arity),_),
		% you'd think this would only catch when the Query term clause doesn't exist, but nope, it actually catches any nested exception. Another swipl bug?
		(
			functor(Query, Name, Arity),
			fail
		)
	).



/*
top-level interface
*/



run(Query) :-
	b_setval(bn_log, []),
	nb_setval(step, 0),
	run2(Query).




bump_step :-
	nb_getval(step, Step),
	Step_next is Step + 1,
	nb_setval(step, Step_next).

call_prep(Prep) :-
	debug(pyco_prep, 'call prep: ~q', [Prep]),
	call(Prep).

ep_debug_print_1(Ep_List, Query_ep_terms) :-
	debug(pyco_ep, 'seen:', []),
	maplist(print_debug_ep_list_item, Ep_List),
	debug(pyco_ep, 'now: ~q', [Query_ep_terms]).

trace_prefix(Proof_id_str, Level, String) :-
	Level2 is Level + 64,
	char_code(Level_char, Level2),
	format(string(String), '~q ~w ~w', [$>nb_getval(step), Level_char, Proof_id_str]).

rule(Desc, Head_items, Body_items, Prep) :-
	(	pyco0_rule(Desc, Head_items <= Body_items, Prep)
	;	(
			pyco0_rule(Desc, Head_items <= Body_items),
			Prep = true)).

matching_rule2(_Level, Query, Desc, Body_items, Prep, Query_ep_terms) :-
	query_term_ep_terms(Query, Query_ep_terms),
	rule(Desc, Head_items, Body_items, Prep),
	member(Query, Head_items).


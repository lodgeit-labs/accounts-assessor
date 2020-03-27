:- use_module(library(clpfd)).
:- op(900,xfx,<=).
:- use_module(library(fnotation)).
:- fnotation_ops($>,<$).
:- op(900,fx,<$).


:- discontiguous pyco0_rule/2.
:- discontiguous pyco0_rule/3.
:- multifile pyco0_rule/2.
:- multifile pyco0_rule/3.




run(Query) :-
	b_setval(bn_log, []),
	nb_setval(step, 0),
	run2(Query).

run2(Query) :-
	% repeat top-level query until depth_map of Proof stops changing.
	run2_repeat(Query, Proof),
	debug(pyco_run, '~w final...', [$>trace_prefix(r, -1)]),
	/* filter out proofs that didn't ground. In these cases, we only got here due to ep_yield'ing.	*/
	run2_final(Query, Proof).

run2_repeat(Query, Proof) :-
	debug(pyco_map, 'map0 for: ~q', [Proof]),
	depth_map(Proof, Map0),
	debug(pyco_map, 'map0 : ~q', [Map0]),
	proof([],0,eps{},ep_yield,noisy,Query,Proof),
	debug(pyco_map, 'map1 for: ~q', [Proof]),
	depth_map(Proof, Map1),
	debug(pyco_map, 'map1 : ~q', [Map1]),
	((	Map0 \= Map1,
		debug(pyco_run, '~w repeating.', [$>trace_prefix(r, -1)]),
		run2_repeat(Query, Proof),
		debug(pyco_run, '~w ok...', [$>trace_prefix(r, -1)])
	)
	;
	(	Map0 = Map1,
		debug(pyco_run, '~w stabilized.', [$>trace_prefix(r, -1)])
	)).

run2_final(Query, Proof) :-
	proof([],0,eps{},ep_fail,noisy,Query,Proof),
	debug(pyco_run, '~w result.', [$>trace_prefix(r, -1)]),
	true.

run2_final(Query, Proof) :-
	\+proof([],0,eps{},ep_fail,quiet,Query,Proof),
	debug(pyco_run, '~w failed.', [$>trace_prefix(r, -1)]),
	fail.

proof(
	/* a unique path in the proof tree */
	Path,
	/* depth, incremented on each 'proof' recursion */
	Level,
	/* current ep list */
	Eps0,
	/* ep_yield or ep_fail */
	Ep_yield,
	/* silence debugging */
	Quiet,
	/* */
	Query,
	/* a tree of body items*/
	Proof
) :-
	nb_getval(step, Proof_id),
	term_string(Proof_id, Proof_id_str),
	Deeper_level is Level + 1,
	proof2(Path, Proof_id_str,Deeper_level,Eps0,Ep_yield,Quiet,Query,Proof).

proof2(Path0, Proof_id_str,Level,Eps0,Ep_yield, Quiet,Query,Proof) :-
	matching_rule2(Level, Query, Desc, Body_items, Prep, Query_ep_terms, Head_item_idx),
	(Quiet = noisy -> debug(pyco_proof, '~w match: ~q (~q)', [$>trace_prefix(Proof_id_str, Level), $>nicer_term(Query), Desc]); true),

	append(Path0, [ri(Desc, Head_item_idx)], Path),
	register_frame(Path),

	ep_list_for_rule(Eps0, Desc, Ep_List),
	(Quiet = noisy -> ep_debug_print_1(Ep_List, Query_ep_terms); true),
	proof3(Path, Proof_id_str, Eps0, Ep_List, Query_ep_terms, Desc, Prep, Level, Body_items, Ep_yield, Quiet, Query, Proof).

proof2(_Path, Proof_id_str,Level,_,_,Quiet,Query, call) :-
	call_native(Proof_id_str,Level, Quiet, Query).

proof3(Path, Proof_id_str, Eps0, Ep_List, Query_ep_terms, Desc, Prep, Level, Body_items, Ep_yield, Quiet, _Query, Proof) :-
	ep_ok(Ep_List, Query_ep_terms, Quiet),
	prove_body(Path, Proof_id_str, Ep_yield, Eps0, Ep_List, Query_ep_terms, Desc, Prep, Level, Body_items, Quiet, Proof).

proof3(Path, Proof_id_str, _Eps0, Ep_List, Query_ep_terms, Desc, _Prep, Level, _Body_items, Ep_yield, Quiet, Query, Proof) :-
	\+ep_ok(Ep_List, Query_ep_terms, Quiet),
	proof_ep_fail(Path, Proof_id_str, Desc, Level, Ep_yield, Quiet, Query, Proof).

proof_ep_fail(_Path, Proof_id_str, Desc, Level, Ep_yield, Quiet, Query, _Unbound_Proof) :-
	Ep_yield == ep_yield,
	(Quiet = noisy -> debug(pyco_proof, '~w ep_yield: ~q (~q)', [$>trace_prefix(Proof_id_str, Level), $>nicer_term(Query), Desc]); true),
	true.

proof_ep_fail(_Path, Proof_id_str, Desc, Level, Ep_yield, Quiet, Query, _Unbound_Proof) :-
	Ep_yield == ep_fail,
	(Quiet = noisy -> debug(pyco_proof, '~w ep_fail: ~q (~q)', [$>trace_prefix(Proof_id_str, Level), $>nicer_term(Query), Desc]); true),
	fail.

prove_body(Path, Proof_id_str, Ep_yield, Eps0, Ep_List, Query_ep_terms, Desc, Prep, Level, Body_items, Quiet, Proof) :-
	updated_ep_list(Eps0, Ep_List, Path, Query_ep_terms, Desc, Eps1),
	call_prep(Prep, Path),
	bump_step,
	body_proof(Path, Proof_id_str, Ep_yield, Level, Eps1, Body_items, Quiet, Proof).

body_proof(Path, Proof_id_str, Ep_yield, Level, Eps1, Body_items, Quiet, Proof) :-
	body_proof2(Path, Proof_id_str, Ep_yield, Level, Eps1, Body_items, Quiet, Proof).

/* this case only serves for debugging */
body_proof(Path, Proof_id_str, Ep_yield, Level, Eps1, Body_items, Quiet, Proof) :-
	%(Quiet = noisy -> debug(pyco_proof, '~w disproving..', [$>trace_prefix(Proof_id_str, Level)]); true),
	\+body_proof2(Path, Proof_id_str, Ep_yield, Level, Eps1, Body_items, quiet, Proof),
	(Quiet = noisy -> debug(pyco_proof, '~w disproved.', [$>trace_prefix(Proof_id_str, Level)]); true),
	false.

body_proof2(Path, Proof_id, Ep_yield, Level, Eps1, Body_items, Quiet, Proof) :-
	/* this repetition might be one way to solve the ep problem, but it leads to many duplicate results */
	%body_proof3(Path, Proof_id, 0, Ep_yield, Level, Eps1, Body_items, Quiet, Proof),
	body_proof3(Path, Proof_id, 0, Ep_yield, Level, Eps1, Body_items, Quiet, Proof).

/* base case */
body_proof3(_Path, _Proof_id_str, _, _Ep_yield, _Level, _Eps1, [], _Quiet, []).

body_proof3(Path, Proof_id_str, Bi_idx, Ep_yield, Level, Eps1, [Body_item|Body_items], Quiet, [ProofH|ProofT]) :-
	ProofH = Body_item-Proof,
	append(Path, [bi(Bi_idx)], Bi_Path),
	proof(Bi_Path, Level, Eps1, Ep_yield, Quiet, Body_item, Proof),
	Bi_idx_next is Bi_idx + 1,
	body_proof3(Path, Proof_id_str, Bi_idx_next, Ep_yield, Level, Eps1, Body_items, Quiet, ProofT).

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

updated_ep_list(Eps0, Ep_List, Path, Query_ep_terms, Desc, Eps1) :-
	append(Ep_List, [Path-Query_ep_terms], Ep_List_New),
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

ep_ok2(Query_ep_terms, Quiet, Path-Ep_Entry) :-
	length(Query_ep_terms, L0),
	length(Ep_Entry, L1),
	assertion(L0 == L1),
	findall(x,
		(
			between(1, L0, I),
			nth1(I, Ep_Entry, Old_arg),
			nth1(I, Query_ep_terms, New_arg),
			arg_is_productively_different(Path, Old_arg, New_arg)
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
arg_is_productively_different(Path, bn(Uid_old_str,Tag0), bn(Uid_new_str,Tag1)) :-
	assertion(string(Uid_old_str)),
	assertion(string(Uid_new_str)),
	/* for same uids, we fail. */
	/* for differing types, success */
	(	Tag0 \= Tag1
	->	true
	;	(
			Uid_old_str \= Uid_new_str,
			came_before(bn(Uid_new_str,_), fr(Path))
		)).


came_before(A, B) :-
	b_getval(bn_log, Bn_log),
	%debug(pyco_proof, 'came_before:~q', [nth0(Ib, Bn_log, B)]),
	assertion(nth0(Ib, Bn_log, B)),
	nth0(Ib, Bn_log, B),

	(	nth0(Ia, Bn_log, A)
	->	Ia < Ib
	;	true).



mkbn(Bn, Dict, _Path) :-
	%gtrace,
(
	/* avoid creating new bnode if we are already called with one. this eases tracking them for ep check purposes */
(	nonvar(Bn),
	Bn = bn(_, Dict)
)
;
(
	var(Bn),
	Bn = bn(_, Dict),
	register_bn(Bn)
)).

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
	\+matching_rule2(Level, Query, _,_,_,_,_),
	(Quiet = noisy -> debug(pyco_proof, '~w prolog call:~q', [$>trace_prefix(Proof_id_str, Level), Query]); true),
	call_native2(Proof_id_str, Level, Quiet, Query).

call_native2(Proof_id_str, Level, Quiet, Query) :-
	call_native3(Query),
	(Quiet = noisy -> debug(pyco_proof, '~w prolog call succeeded:~q', [$>trace_prefix(Proof_id_str, Level), Query]); true),
	true.

call_native2(Proof_id_str, Level, Quiet, Query) :-
	\+call_native3(Query),
	(Quiet = noisy -> debug(pyco_proof, '~w prolog call failed:~q', [$>trace_prefix(Proof_id_str, Level), Query]); true),
	fail.

call_native3(Query) :-
	% you'd think this would only catch when the Query term clause doesn't exist, but nope, it actually catches any nested exception. Another swipl bug?
	functor(Query, Name, Arity),
	catch(
		call(Query),
		error(existence_error(procedure,Name/Arity),_),
		fail
	).

bump_step :-
	nb_getval(step, Step),
	Step_next is Step + 1,
	nb_setval(step, Step_next).

call_prep(true, _Path).

call_prep(Prep, Path) :-
	Prep \= true,
	debug(pyco_prep, 'call prep: ~q', [Prep]),
	call(Prep, Path).

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

matching_rule2(_Level, Query, Desc, Body_items, Prep, Query_ep_terms, Head_item_idx) :-
	query_term_ep_terms(Query, Query_ep_terms),
	rule(Desc, Head_items, Body_items, Prep),
	nth0(Head_item_idx, Head_items, Query).
	%member(Query, Head_items).



/*
 for list bnodes, produce nicer term for printing
*/

nicer_term(T, Nicer) :-
	(	nicer_term2(T, Nicer)
	->	true
	;	throw(err)).

nicer_term2(T, Nicer) :-
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

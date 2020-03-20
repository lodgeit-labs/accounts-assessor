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


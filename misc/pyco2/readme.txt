# introduction
this is a sucessor to https://github.com/koo5/AutoNomic-pyco
While pyco only achieved a limited form of order invariance with 'EP_YIELD's only in rules producing existentials, this version 'ep_yield's anywhere, and repeats the whole query for as long as the proof tree is growing. It is perhaps an iterative deepening search.

Another difference in semantics from pyco is currently lack of "second_chance" logic, and missing "prune_duplicate_results" option.

This version is implemented in (swi)prolog, so we can experiment with integrating CLP, and we can call native clauses.

Integration with the "doc" system is tbd, as are many other things.



# random notes


## possibly useful for ep check:

https://www.swi-prolog.org/pldoc/man?section=compare


## optimization:

http://irnok.net:3030/help/source/doc/home/prolog/ontology-server/ClioPatria/lib/semweb/rdf_optimise.pl

https://books.google.cz/books?id=oc7cBwAAQBAJ&pg=PA26&lpg=PA26&dq=prolog++variable+address&source=bl&ots=cDxavU-UaU&sig=ACfU3U0y1RnTKfJI58kykhqltp8fBNkXhA&hl=en&sa=X&ved=2ahUKEwiJ6_OWyuPnAhUx-yoKHZScAU4Q6AEwEHoECAkQAQ#v=onepage&q=prolog%20%20variable%20address&f=false

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




## syntax, notation

you can have multiple heads in a prolog clause. This would be one way to write pyco rules "natively"

[a,b] :- writeq(xxx).

?- clause([X|XX],Y).
X = a,
XX = [b],
Y = writeq(xxx).





## debugging, visualizations:
univar pyco outputs, for example, kbdbgtests_clean_lists_pyco_unify_bnodes_0.n3:
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



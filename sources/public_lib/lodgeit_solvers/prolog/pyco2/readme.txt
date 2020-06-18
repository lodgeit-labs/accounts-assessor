# introduction
this is a sucessor to https://github.com/koo5/AutoNomic-pyco
While pyco only achieved a limited form of order invariance with 'EP_YIELD's only in rules producing existentials, this version 'ep_yield's anywhere, and repeats the whole query for as long as the proof tree is growing. It is perhaps an iterative deepening search.

Another difference in semantics from pyco is currently lack of "second_chance" logic, and missing "prune_duplicate_results" option.

This version is implemented in (swi)prolog, so we can experiment with integrating CLP, and we can call native clauses.

Integration with the "doc" system is tbd, as are many other things.


# running it

```
reset;echo -e "\e[3J";   swipl -O -s pyco2_test2.pl -g "test(q3(_,_)),halt" 2>&1 | tee x  
cat x | grep "result:"
```

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


### pre-evaluation, inlining:


take a call to fr(L,F,R), the definition of fr/3 is:
`
	fr(L,F,R)
		,first(L, F)
		,rest(L, R)
`
we can pre-compile the definition into something like:
`
	fr(_{first:F,rest:R},F,R)
`
, and further inline that into the calling place.
This would need to be revised if we change bnode representation/semantics into something like:
`
(
	Bn = _{first:F,rest:R}
;
	(
		first(Bn, F)
		,rest(Bn, R)
	)
)
`
there is a kindof generalized way that pre-evaluation can be done, which i think we touched on in univar,
let's say you have the declaration fr(L,F,R), and also have two pre-asserted rdf lists in your kb:
`
first(list1, x).
rest(list1, nil).

first(list2, x).
rest(list2, list2_2).
first(list2_2, y).
rest(list2_2, nil).
`
you don't know if your program will ever call fr(Unbound_var1, Unbound_var2, Unbound_var3), but if you have the cpu time up-front, you can still pre-evaluate the predicate as if it was called with all vars unbound. You replace the origial declaration with:
`
fr(_{first:F,rest:R},F,R).
fr(list1, x, nil).
fr(list2, x, list2_2).
fr(list2_2, y, nil).
`
not sure if simply running the query and collecting the results would work for more complex cases, ie recursion, ep-yields, or if some interpretation is needed.





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



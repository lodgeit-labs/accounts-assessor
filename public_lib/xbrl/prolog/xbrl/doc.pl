/*
see also: http://mndrix.github.io/julian/constraints.html
todo try with clpfd here.

24.01.20 18:36:40<stoopkid_> chr_hp branch; misc/chr_hp.pl
24.01.20 18:40:37<stoopkid_> still kinda slow
24.01.20 18:41:47<stoopkid_> wrt date/time theory, i'm noticing that it's somewhat different from lists theory in the sense that, we want most of the relations in the lists theory to actually be in the graph to represent the structure of the list, but we don't want to ex.. generate all calendars for all time
24.01.20 18:46:47<stoopkid_> i'm also wondering if it makes sense to model stuff like differing month-lengths using the same logic as time-varying exchange rates for currencies
24.01.20 18:47:37<stoopkid_> but it's kind of weird, because in the case of currencies, you have a well-defined measurement of time, and exchange rates between currencies vary as time progresses
24.01.20 18:48:21<stoopkid_> but in this case, you don't yet have a well-defined measurement of time, because it's what we're trying to define, but would still need a notion of exchange rates between units of time varying... as time progresses
24.01.20 18:56:45<stoopkid_> we also have at least 3 different kinds of things to deal with; instants, time-intervals, and durations
24.01.20 18:57:23<stoopkid_> time-interval is a specific period of time like ex.. Jan 2020; duration is an abstract amount of time like "1 month"
24.01.20 19:00:18<stoopkid_> durations are what gets used in the dimensional system, so we can add/subtract arbitrary durations together to get a new duration (and we can have negative durations)
24.01.20 19:01:59<stoopkid_> you can also add a duration to an instant and get a new instant, ex.. opening_date (instant) + period (duration) = closing_date (instant)
24.01.20 19:03:14<stoopkid_> you can also add a duration to an interval and get a new interval, ex.. Jan 2020 + 1 year = Jan 2021
24.01.20 19:04:14<stoopkid_> these operations aren't always well-defined though, in terms of pure dimensional analysis
24.01.20 19:04:25<stoopkid_> ex.. Jan 31 + 1 month = ?
24.01.20 19:09:05<stoopkid_> it seems that whenever you're adding a duration in some units to a time-like value (instant,duration,interval) which uses more precise units, and there's a varying exchange rate between these two units, then the arithmetic breaks
24.01.20 19:13:45<stoopkid_> despite all the complications, i don't think we can simply reject being able to use time-values in dimensional arithmetic like this
24.01.20 19:14:59<stoopkid_> i.e. people do use and expect to be able to use these operations at least in the cases where they're well-defined
24.01.20 21:57:05<stoopkid_> alright gonna avoid the dimensional approach to date/time stuff for now
24.01.20 21:57:30<stoopkid_> we can do some workarounds in the mean time
24.01.20 21:59:07<stoopkid_> probably ready to start hooking it up to the UI now
24.01.20 22:01:52<stoopkid_> or, not now, bout to have dinner with the family, but that'll be the next thing i dig into
24.01.20 23:52:01<stoopkid_> http://mndrix.github.io/julian/constraints.html
25.01.20 01:25:28<editable-log-koo>yeah i shortly lookd at this the other day
25.01.20 01:26:28<editable-log-koo>also i tried to naively clpq-ize days.pl, but 1) there are some div operations 2) it ended up being too slow or infilooping or something
25.01.20 01:27:35<editable-log-koo>now i just spent like 2 hours exploring https://sewiki.iai.uni-bonn.de/research/pdt/docs/start
25.01.20 01:27:43<editable-log-koo>mostly a waste of time it seems..
25.01.20 01:57:31<stoopkid_> yea the div operations really ruin the prospect of using clpq but clpfd still seems viable, at least it looks like there's been some moderate success w/ julian
25.01.20 01:58:25<stoopkid_> it's all integer problems anyway so i guess this is to be expected, though it didn't occur to me until i actually sat down w/ it and ran into the div issues
25.01.20 02:55:38<editable-log-koo>ok i guess we could keep dates handled with clpfd isolated from the rest of the system handled with clpq, at least for ledger
25.01.20 02:56:22<editable-log-koo>the use for clp in dates in ledger would be minimal i guess, the most i can imagine is putting smaller then / bigger than constraints on tx dates
25.01.20 02:56:44<editable-log-koo>have you experimented with simulating clpq with clpfd?
25.01.20 05:41:29<stoopkid_> not yet but would probably be a good thing to look into soon
25.01.20 05:42:39<stoopkid_> i don't think we necessarily need to isolate clpfd and clpq, they don't seem to interfere w/ each other like chr does
25.01.20 05:44:49<editable-log-koo>oh
25.01.20 05:45:17<editable-log-koo>so, you can put clpq and clpfd constraints on one variable simultaneously?
25.01.20 05:45:32<editable-log-koo>didnt we run into probles with that?
25.01.20 05:46:28<stoopkid_> we ran into problems w/ putting chr and clpq constraints on one variable simultaneously, but w/ clpfd and clpq all we ran into so far was that they don't communicate between each other
25.01.20 05:46:59<stoopkid_> i could imagine there could be similar problems as w/ mixing chr and clpq, but i haven't run into any yet
25.01.20 05:47:44<stoopkid_> i'd imagine the clp authors at least made a bit more effort to make the various clp packages at least play a bit nicer w/ each other, even if they don't really communicate
25.01.20 05:49:32<stoopkid_> it might be better to isolate them all pre-emptively, not sure
25.01.20 05:50:28<editable-log-koo>hmm so chr and clpq break?
25.01.20 05:50:36<stoopkid_> yea, badly
25.01.20 05:50:45<stoopkid_> but fixably (so far)
25.01.20 05:53:04<stoopkid_> w/ clpq, unification triggers the clpq code to run, and until that code finishes running, the clpq seems to be in an inconsistent state
25.01.20 05:53:11<stoopkid_> but chr's unification trigger runs first
25.01.20 05:53:52<stoopkid_> and so more chr rules can fire, and if ends up running more clpq code while it's in this inconsistent state, it fails
25.01.20 05:54:05<editable-log-koo>ah that might be a swipl peculiarity iirc that it first does the actual unification and only runs the hooks after
25.01.20 05:55:02<stoopkid_> otoh when we were experimenting w/ clpfd and clpq, the results were pretty promising, we only needed some slight tweaks to make them start working together and weren't running into any issues like this
25.01.20 05:55:24<editable-log-koo>what tweaks?
25.01.20 05:55:47<editable-log-koo>wellllll we really should write this down
25.01.20 05:56:46<editable-log-koo>nvm i'll just copy&paste the chat
25.01.20 05:57:01<stoopkid_> well, not tweaks to the packages directly just a wrapper that would go through the clpfd variables and try the possibilities
25.01.20 05:57:21<editable-log-koo>do we still have that code?
25.01.20 05:57:42<stoopkid_> somewhere
25.01.20 05:58:04<editable-log-koo>yeah i remember that labelling stuff now
25.01.20 06:00:56<editable-log-koo>clp_test_xxx.pl, clp_nonlinear.pl
25.01.20 06:09:29<stoopkid_> took me a minute to remember how clp_nonlinear works but yea that's it
25.01.20 06:11:12<stoopkid_> tries each possibility of the integer var against the clpq constraints, if it fails to satisfy the clpq constraints, add a clpfd constraint that says it can't be that possibility
25.01.20 06:11:47<stoopkid_> and the constraints don't survive the findall, so it has to be outside the loop
25.01.20 06:16:50<stoopkid_> my latest commit on chr_hp branch has some basic date/time stuff w/ clpfd btw, but i'm not sure whether it's worth examining yet
25.01.20 06:17:32<stoopkid_> as far as date/time logic goes, it's kinda crap, as far as inferencing stuff goes, it's just more of the same
25.01.20 06:18:23<editable-log-koo>then i guess i'll pass, lol
25.01.20 06:19:01<stoopkid_> just enough to demonstrate that we can get away w/ using this inferencing approach for date/time stuff w/o having a comprehensive system like the dimensional analysis for it, if we really have to
25.01.20 06:22:00<stoopkid_> i gotta say though, i'm somewhat disappointed w/ this inferencing approach so far
25.01.20 06:22:42<stoopkid_> i expected that at this stage it would already be nicer than just doing regular prolog, at least to write the code, even if it were slow
25.01.20 06:23:36<stoopkid_> and not even counting the extra stuff you have to write when doing it in chr
25.01.20 06:27:32<stoopkid_> i still think it'll get there, i was just hoping that it this point the system would be self-justifying but i can't say that it is yet
25.01.20 06:30:26<stoopkid_> like, we definitely have gained in terms of declarativeness and bidirectionality, but it seems like in exchange we've gained clunkiness, lost all built-in abstractions, and can only access regular prolog by threading it into the chr execution path
25.01.20 06:31:58<stoopkid_> and it definitely doesn't help that every time i add some more stuff to the hp model i add a couple seconds to the run-time
25.01.20 06:46:03<editable-log-koo>well, one small example i was pondering the other night is: exchange rate specified in request xml can come without Dst. If thats the case, Dst should come from <defaultCurrency>. If that's missing, we should attempt to infer Dst from the fact that the given unit only appears in transactions on one bank account, with a known currency
25.01.20 06:46:29<editable-log-koo>i came to the conclusion that the biggest deal is order (non)-invariance
25.01.20 06:47:37<editable-log-koo>read dst from xml, var(dst) -> read dst from defaultCurrency, var(dst) -> infer dst from transactions
25.01.20 06:50:15<editable-log-koo>but as order-invariant rules, in whatever implementation, it's basically dst = first and only element of first element of list of dst candidates, dst candidates = result of ordering of unordered dst candidates list, unordered dst candidates list = list of all dst candadates, xml a dst candadite, xml priority 100, ..
25.01.20 06:51:42<editable-log-koo>it goes on and on
25.01.20 06:56:04<stoopkid_> "read dst from xml, var(dst) -> read dst from defaultCurrency, var(dst) -> infer dst from transactions" this at least you can do on RHS of chr rules
25.01.20 06:57:08<stoopkid_> RHS of chr rules is just completely arbitrary prolog query, executing in-order
25.01.20 07:01:56<stoopkid_> i'm also noticing that the "long-distance interactions" thanks to bidirectionality is kind of a double-edge sword
25.01.20 07:02:20<stoopkid_> so when things are working good, you propagate information all over the system
25.01.20 07:02:29<stoopkid_> when things aren't working so good, you propagate bugs all over the system
25.01.20 07:04:11<stoopkid_> or similarly, when the solver works, everything works, when the solver fails, everything's broken
25.01.20 07:13:15<editable-log-koo>wrt long-distance interactions, where we took off, in pyco, as far as i could tell, was that order-independence was working, but we weren't making any use of it, and i wasnt sure how we'd go about it
25.01.20 07:13:31<editable-log-koo>i wonder if the method could be to simply follow the data
25.01.20 07:15:08<editable-log-koo>basically, you are in a rule with a bunch of body items, which one should you explore first? probably the one who's arguments are all ground, or most ground, for some way of measuring that
25.01.20 07:16:56<editable-log-koo>maybe starting off with this and if necessary coupling it with some domain-specific heuristics, since we have a well-known domain here,..
25.01.20 07:50:45<editable-log-koo>well, idk, where i've been at is just poking at our prolog code, seeing if i can make things more declarative here and there, theres definitely a lot of obstacles even if i'd figure out how to make swipl tabling act like pyco ep check
25.01.20 07:52:39<editable-log-koo>and then im still mulling over native prolog terms vs triples and graphs vs non-graphs and tracking proofs and presenting things
25.01.20 09:22:53*** Quit: stoopkid_ (uid137696@gateway/web/irccloud.com/x-wcounvqcguvyplwj) left #serious-business: Quit: Connection closed for inactivity
25.01.20 15:59:50*** Join: stoopkid_ (uid137696@gateway/web/irccloud.com/x-hnripbrehhyizmej, (unauthenticated): stoopkid)
25.01.20 19:50:18<editable-log-koo>so, i'm thinking,step 1, use something like your xml -> doc code to generically represent the whole request xml in doc
25.01.20 19:54:58<editable-log-koo>then, extract_exchange_rate asserts a new exchange rate object into doc, following the rule that everything has to have an uri, so, literals get wrapped in a value, but probably not in a lumped fashion like [:unit xxx; :value "xxx"], but [:unit [:value xxx]; :value [:value "xxx"]]? idk
25.01.20 19:57:31<editable-log-koo>then, the exchange rate has the :bnxxx :dst [something] triples, and that's exactly where we'd made use of graphs to attach metadata
25.01.20 19:58:40<editable-log-koo>:bnxxx :dst :bndst :g1. g1 :proof something
25.01.20 20:00:33<editable-log-koo>:bndst can have an :origin property, but the reason that this particular :bndst is the :dst of the :bnxxx belongs outside the default graph
25.01.20 20:01:02<editable-log-koo>graphs get hierarchically included into each other with :includes or whatever
25.01.20 20:04:36<editable-log-koo>this is transparent when querying, ie, plain doc /3 and /4 should invoke some rules when called
25.01.20 20:07:40<editable-log-koo>back on the application level, what i'm not sure about yet is any kinds of generic proof traces we may want to do or present
25.01.20 20:10:06<editable-log-koo>but what we know is the formula explainer would reference the exchange rate in some way, and we know that investment report would link to it from its table
25.01.20 20:12:53<editable-log-koo>ah, also, what i'm going to do is stream all changes to doc into a file, so you can have like kwrite tmp/last/doc opened and just refresh it when you need or refreshing automatically and when you're gtracing you can follow it
25.01.20 20:13:55<editable-log-koo>probably should try to set it up so that all our global variables use the doc framework or that all global variables are traced somehow
25.01.20 20:14:10<editable-log-koo>with attr hook we can trace unifications
25.01.20 20:14:39<editable-log-koo>not sure yet wrt prolog terms in doc
25.01.20 20:15:45<editable-log-koo>things that arent rdf sould probably be stringized on serialization
25.01.20 20:20:07<editable-log-koo>anyway, final results report will include doc.n3, and then im not sure what should happen, i think the standard is to use http content negotiation, like, user GETs tmp/xxxx/doc.n3 requesting application/n3, server sends the file, but user GETs tmp/xxxx/doc.n3 requesting html, server sends a redirect to a vue app, the app sees the fragment in the url ..
25.01.20 20:21:19<editable-log-koo>this way we can reference the final doc data from whatever simple generated html, but once you're in the vue app, you can explore
25.01.20 20:22:07<editable-log-koo>or we can look into pengines, should do something similar
25.01.20 20:51:27<editable-log-koo>anything i'm missing?
25.01.20 20:53:11<editable-log-koo>as on the fwd chaining schemes, at the very least we could use chase on smaller testcases to prove that it comes up with same results as pyco-like inference
25.01.20 20:53:58<editable-log-koo>and chr could be used to develop custom constraint solvers, so, no work wasted i'd think, whatever we end up doing
*/







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

/*@prefix depr_ui: <https://rdf.lodgeit.net.au/v1/calcs/depr/ui#> .
@prefix ic_ui: <https://rdf.lodgeit.net.au/v1/calcs/ic/ui#> .
@prefix hp_ui: <https://rdf.lodgeit.net.au/v1/calcs/hp/ui#> .*/



/*
a quad-store implemented with an open list stored in a global thread-local variable
*/

%:- debug(doc).

dump :-
	findall(_,
		(
			docm(S,P,O),
			debug(doc, 'dump:~q~n', [(S,P,O)])
		),
	_).

doc_init :-
	doc_clear,
	rdf_register_prefix(pid, ':'),
	doc_add(pid, rdf:type, l:request),
	doc_add(pid, rdfs:comment, "processing id - the root node for all data pertaining to processing current request. Also looked up by being the only object of type l:request, but i'd outphase that.").

init_doc_trail :-
	absolute_tmp_path(loc(file_name, 'doc_trail.txt'), loc(absolute_path, Trail_File_Path)),
	open(Trail_File_Path, write, Trail_Stream, [buffer(line)]),
	b_setval(doc_trail, Trail_Stream).

doc_clear :-
	b_setval(the_theory,_X),
	doc_set_default_graph(default).

doc_set_default_graph(G) :-
	b_setval(default_graph, G).

doc_add((S,P,O)) :-
	doc_add(S,P,O).

:- rdf_meta doc_add(r,r,r).

doc_add(S,P,O) :-
	b_getval(default_graph, G),
	doc_add(S,P,O,G).

:- rdf_meta doc_add(r,r,r,r).

doc_add(S,P,O,G) :-
	debug(doc, 'add:~q~n', [(S,P,O)]),
	b_getval(the_theory,X),
	/* hook dump_doc2 to unification of every variable (recurse for complex terms) */


	rol_add((S,P,O,G), X),
	dump_doc2.

doc_assert(S,P,O,G) :-
	b_getval(the_theory,X),
	rol_assert((S,P,O,G), X).

:- rdf_meta doc(r,r,r).
/*
must have at most one match
*/
doc(S,P,O) :-
	b_getval(default_graph, G),
	doc(S,P,O,G).

:- rdf_meta doc(r,r,r,r).
/*
must have at most one match
*/
doc(S,P,O,G) :-
	b_getval(the_theory,X),
	debug(doc, 'doc?:~q~n', [(S,P,O,G)]),
	rol_single_match((S,P,O,G), X).

:- rdf_meta docm(r,r,r).
/*
can have multiple matches
*/
docm(S,P,O) :-
	b_getval(default_graph, G),
	docm(S,P,O,G).

:- rdf_meta docm(r,r,r,r).
docm(S,P,O,G) :-
	b_getval(the_theory,X),
	debug(doc, 'docm:~q~n', [(S,P,O,G)]),
	rol_member((S,P,O,G), X).
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




/*:- comment(code:doc, "livestock and action verbs are in doc exclusively, some other data in parallel with passing them around in variables..").*/

/*
helper predicates
*/

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
a thin layer above ROL
*/

rol_single_match(SpogA, T) :-
	/* only allow one match */
	findall(x,rol_member(SpogA, T),Matches),
	length(Matches, Length),
	(	Length > 1
	->	(
			format(string(Msg), 'multiple_matches, use docm: ~q', [SpogA]),
			%gtrace,
			throw_string(Msg)
		)
	;	rol_member(SpogA, T)).


/*
Reasonably Open List.
T is an open list. Unifying with the tail variable is only possible through rol_add.
*/

rol_add(Spog, T) :-
	/* ensure Spog is added as a last element of T, while memberchk would otherwise possibly just unify an existing member with it */
		rol_member(Spog, T)
	->	throw(added_quad_matches_existing_quad)
	;	memberchk(Spog,T).

rol_assert(Spog, T) :-
	rol_member(Spog, T)
	->	true
	;	memberchk(Spog,T).


rol_add_quiet(Spog, T) :-
		rol_member(Spog, T)
	->	true
	; 	memberchk(Spog,T).

/* nondet */
rol_member(SpogA, T) :-
	/* avoid unifying SpogA with the open tail of T */
	member(SpogB, T),
	(
		var(SpogB)
	->	(!,fail)
	;	SpogA = SpogB).

	/*match(SpogA, SpogB)).
match((S1,P1,O1,G1),(S2,P2,O2,G2))
	(	S1 = S2
	->	true
	;	rdf_equal(?Resource1, ?Resource2)
*/


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

triple_rdf_vs_doc((S,P,O), (S,P,O2)) :-
	node_rdf_vs_doc(O,O2).

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
		freeze(Float, float(Float)),
		freeze(Rat, rational(Rat)),
		(	nonvar(Rat)
		->	Float is float(Rat)
		;	Rat is rationalize(Float)),!.

/* todo vars */

node_rdf_vs_doc(Atom, Atom)/* :- gtrace, writeq(Atom)*/.


doc_to_rdf(Rdf_Graph) :-
	rdf_create_bnode(Rdf_Graph),
	findall(_,
		(
			docm(X,Y,Z),
			triple_rdf_vs_doc((X2,Y2,Z2),(X,Y,Z)),
			debug(doc, 'to_rdf:~q~n', [(X2,Y2,Z2)]),
			rdf_assert(X2,Y2,Z2,Rdf_Graph)
		),_).

/*:- comment(lib:doc_to_rdf_all_graphs, "if necessary, modify to not wipe out whole rdf database and to check that G doesn't already exist */

doc_to_rdf_all_graphs :-
	rdf_retractall(_,_,_,_),
	foreach(
		docm(X,Y,Z,G),
		(
			triple_rdf_vs_doc((X2,Y2,Z2),(X,Y,Z)),
			rdf_assert(X2,Y2,Z2,G)
		)
	).

save_doc(/*-*/Fn, /*+*/Url) :-
	report_file_path(loc(file_name, Fn), Url, loc(absolute_path,Path)),
	Url = loc(absolute_url, Url_Value),
	doc_to_rdf_all_graphs,
	/* we'll possibly want different options for debugging dumps and for result output for excel */
	rdf_save_turtle(Path, [sorted(true), base(Url_Value), canonize_numbers(true), abbreviate_literals(false), prefixes([rdf,rdfs,xsd,l,livestock])]),
	rdf_retractall(_,_,_,Rdf_Graph).

dump_doc2 :-
	(	doc_dumping_enabled
	->	save_doc('doc.n3', _)
	;	true).


/*
we could control this with a thread select'ing some unix socket
*/
doc_dumping_enabled :-
	current_prolog_flag(doc_dumping_enabled, true).



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

doc_new_theory(T) :-
	doc_new_uri(T),
	doc_add(T, rdf:type, l:theory).


:- rdf_meta request_has_property(r,r).

request_has_property(P, O) :-
	request(R),
	doc(R, P, O).

:- rdf_meta request_add_property(r,r).

request_add_property(P, O) :-
	request(R),
	doc_add(R, P, O).

:- rdf_meta request_assert_property(r,r,r).

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

:- rdf_meta doc_value(r,r,r).

doc_value(S, P, V) :-
	doc(S, P, O),
	doc(O, rdf:value, V).

:- rdf_meta doc_add_value(r,r,r).

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


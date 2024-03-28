/*
	Vec: [a rdf:value]
	Sum: [a rdf:value]
*/
 vec_sum_with_proof(Vec, Sum) :-
 	/* Vec is a prolog list of of [rdf:value, Lit]'s */
	maplist([Uri, Lit]>>(doc(Uri, rdf:value, Lit)), Vec, Vec_Lits),
	vec_sum(Vec_Lits, Sum_Lit),
	doc_new_(l:vec, Sum),
	doc_add(Sum, rdf:value, Sum_Lit),
	maplist(doc_add(Sum, l:part), Vec).



 doc_new_vec_with_source(Vec, Source, Vec_Uri) :-
	!doc_new_(l:vec, Vec_Uri),
	!doc_add(Vec_Uri, rdf:value, Vec),
	!doc_add(Vec_Uri, l:source, $>gu(Source)).



 link(Uri, Link) :-
	/*
		the link, as well as Rdf_explorer_base, will keep changing. This is a problem for endpoint_tests.
		Not just for the html, for the report json as well. The json is a kind of data, or a basis of, that we'll want to return to provide to party apps, for example, and we may want to return the whole thing, even with these "volatile" parts. If we limited ourselves to tree-based data, we'd want to:
			break out the volatile part as a separate entity. Ie, report entry title is a list of items, the third item has "volatile":true. The json comparison service could ignore it based on that. Same situation in rdf:
		The volatility isnt a property of any triple, it's a property of the value. In n3: entry title ("date(xxx)", "invest_in", [a volatile_item; value "<a href..."]). Idk, not very elegant.
		So, probably, whichever way we use to store the data and to mark the volatility, we should then generate two sets of files from it: one without the markings (for external services),
		and one either:
			1) without the data volatile bits altogether,
			2) or with the markings, to be processed by endpoint_tests in a special way, ie, objects with "volatile":true replaced with "(volatile value removed)".
			option 1 seems less headache wrt plaintext diffs.
	*/
	result(Result),
	doc(Result, l:rdf_explorer_base, Rdf_explorer_base),
	atomics_to_string([Rdf_explorer_base, '<', Uri, '>&focused-graph=', $>result_data_uri_base, 'default'], Uri2),
	Link = a(href=Uri2, [small("⍰")]).

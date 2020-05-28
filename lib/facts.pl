add_fact_by_account_role(Bs, x(Role, Aspects)) :-
	report_entry_vec_by_role(Bs, Role, Vec),
	make_fact(Vec, Aspects, _).


make_fact(Vec, Aspects, Uri) :-
	doc_new_uri(report_entry, Uri),
	doc_add(Uri, rdf:type, l:fact),
	doc_add(Uri, l:vec, Vec),
	doc_add(Uri, l:aspects, Aspects).

add_fact_by_account_role(Bs, Aspects) :-
	!member(account_role - Role, Aspects),
	report_entry_vec_by_role(Bs, Role, Vec),
	make_fact(Vec, Aspects, _).


make_fact(Vec, Aspects, Uri) :-
	doc_new_uri(report_entry, Uri),
	doc_add(Uri, rdf:type, l:fact),
	doc_add(Uri, l:vec, Vec),
	doc_add(Uri, l:aspects, Aspects).

facts_by_aspects(Aspects) :-
	findall(
		Uri,
		(
			doc(Uri, rdf:type, l:fact),
			doc(Uri, l:aspects, Aspects2),
			maplist(find_aspect, Aspects2, Aspects)
		),
		Aspects).

find_aspect(Hay, Needle) :-
	member(Needle, Hay).


add_sum_report_entry(Bs, Roles, New_fact_aspects) :-
	!maplist(report_entry_value_by_role(Bs), Roles, Vecs),
	!vec_sum(Vecs, Sum),
	!make_fact(Vec, New_fact_aspects, _).

report_entry_vec_by_role(Bs, Role, Vec) :-
	!abrlt(Role, Account),
	!accounts_report_entry_by_account_id(Bs, Account, Entry),
	!report_entry_total_vec(Entry, Vec).



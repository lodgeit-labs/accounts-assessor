
%:- record entry(account_id, balance, child_sheet_entries, transactions_count, misc).

 make_report_entry(Name, Children, Uri) :-
	doc_new_uri(report_entry, Uri),
	doc_add(Uri, rdf:type, l:report_entry),
	doc_add(Uri, report_entries:name, Name),
	doc_add(Uri, report_entries:children, Children).

 set_report_entry_total_vec(Uri, Balance) :-
 	t(Uri,l:report_entry),
	!doc_add(Uri, report_entries:total_vec, Balance).

 set_report_entry_transaction_count(Uri, Transaction_Count) :-
 	t(Uri,l:report_entry),
	!doc_add(Uri, report_entries:transaction_count, Transaction_Count).

 set_report_entry_normal_side(Uri, X) :-
 	t(Uri,l:report_entry),
	!doc_add(Uri, report_entries:normal_side, X).

 set_report_entry_gl_account(Uri, X) :-
 	t(Uri,l:report_entry),
	!doc_add(Uri, report_entries:gl_account, X).

 add_report_entry_misc(Entry, Column, Desc, Type) :-
 	t(Entry,l:report_entry),
	doc_new_uri(report_entry_misc_data, D1),
	doc_add(Entry, report_entries:misc, D1),
	doc_add(D1, report_entries:column, Column),
	doc_add(D1, report_entries:value, Desc),
	doc_add(D1, report_entries:misc_type, $>rdf_global_id(report_entries:Type)).

 report_entry_gl_account(Entry, X) :-
 	t(Entry,l:report_entry),
	doc(Entry, report_entries:gl_account, X).

 report_entry_name(Entry, Name) :-
 	t(Entry,l:report_entry),
	doc(Entry, report_entries:name, Name).

 report_entry_total_vec(Entry, X) :-
 	t(Entry,l:report_entry),
	doc(Entry, report_entries:total_vec, X).

 report_entry_children(Entry, X) :-
 	t(Entry,l:report_entry),
	doc(Entry, report_entries:children, X).

 report_entry_normal_side(Entry, X) :-
 	t(Entry,l:report_entry),
	(	doc(Entry, report_entries:normal_side, X)
	->	true
	;	X = kb:debit).

 report_entry_transaction_count(Entry, X) :-
 	t(Entry,l:report_entry),
	doc(Entry, report_entries:transaction_count, X).

 entry_normal_side_values(Entry, Values_List) :-
 	t(Entry,l:report_entry),
	!report_entry_total_vec(Entry, Balance),
	!report_entry_gl_account(Entry, Account),
	!vector_of_coords_to_vector_of_values_by_account_normal_side(Account, Balance, Values_List).



/*
operations on lists of entries
*/


 report_entry_vec_by_role(Entries, Role, Vec) :-
	assertion(is_list(Entries)),
	!abrlt(Role, Account),
	!accounts_report_entry_by_account_uri(Entries, Account, Entry),
	!report_entry_total_vec(Entry, Vec).

 report_entry_normal_side_values__order2(Entries, Values_List, Account_uri) :-
 	report_entry_normal_side_values(Entries, Account_uri, Values_List).

 report_entry_normal_side_values(Entries, Account_uri, Values_List) :-
 	assertion(is_list(Entries)),
	accounts_report_entry_by_account_uri(Entries, Account_uri, Entry),
	entry_normal_side_values(Entry, Values_List).

 accounts_report_entry_by_account_role_nothrow(_Sd, Report, Role, Entry) :-
	account_by_role(Role, Id),
	accounts_report_entry_by_account_uri(Report, Id, Entry).


 accounts_report_entry_by_account_uri(Report, Id, Entry) :-
	find_thing_in_tree(
			   Report,
			   ([Entry1]>>(report_entry_gl_account(Entry1, Id))),
			   ([Entry2, Child]>>(report_entry_children(Entry2, Children), member(Child, Children))),
			   Entry).


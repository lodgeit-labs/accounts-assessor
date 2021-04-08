
%:- record entry(account_id, balance, child_sheet_entries, transactions_count, misc).

 make_report_entry(Name, Children, Uri) :-
	doc_new_uri(report_entry, Uri),
	doc_add(Uri, rdf:type, l:report_entry),
	doc_add(Uri, report_entries:name, Name),
	doc_add(Uri, report_entries:children, Children).

 set_report_entry_total_vec(Uri, Balance) :-
	!doc_add(Uri, report_entries:total_vec, Balance).

 set_report_entry_transaction_count(Uri, Transaction_Count) :-
	!doc_add(Uri, report_entries:transaction_count, Transaction_Count).

 set_report_entry_normal_side(Uri, X) :-
	!doc_add(Uri, report_entries:normal_side, X).

 set_report_entry_gl_account(Uri, X) :-
	!doc_add(Uri, report_entries:gl_account, X).

 add_report_entry_misc(Entry, Column, Desc, Type) :-
	doc_new_uri(report_entry_misc_data, D1),
	doc_add(Entry, report_entries:misc, D1),
	doc_add(D1, report_entries:column, Column),
	doc_add(D1, report_entries:value, Desc),
	doc_add(D1, report_entries:misc_type, $>rdf_global_id(report_entries:Type)).

 report_entry_gl_account(Uri, X) :-
	doc(Uri, report_entries:gl_account, X).

 report_entry_name(Entry, Name) :-
	doc(Entry, report_entries:name, Name).

 report_entry_total_vec(Entry, X) :-
	doc(Entry, report_entries:total_vec, X).

 report_entry_children(Entry, X) :-
	doc(Entry, report_entries:children, X).

 report_entry_normal_side(Entry, X) :-
	(	doc(Entry, report_entries:normal_side, X)
	->	true
	;	X = kb:debit).

 report_entry_transaction_count(Entry, X) :-
	doc(Entry, report_entries:transaction_count, X).

 report_entry_vec_by_role(Bs, Role, Vec) :-
	!abrlt(Role, Account),
	!accounts_report_entry_by_account_uri(Bs, Account, Entry),
	!report_entry_total_vec(Entry, Vec).


 report_entry_normal_side_values(Report, Account_uri, Values_List) :-
	accounts_report_entry_by_account_uri(Report, Account_uri, Entry),
	entry_normal_side_values(Entry, Values_List).

 report_entry_normal_side_values__order2(Report, Values_List, Account_uri) :-
 	report_entry_normal_side_values(Report, Account_uri, Values_List).

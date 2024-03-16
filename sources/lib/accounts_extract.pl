
/*
extract account tree specified in request xml
the accountHierarchy tag can appear multiple times, all the results will be added together.
*/

 'extract GL accounts' :-
	!doc_add($>(!result), l:has_accounts, $>(!doc_new_uri(account_hierarchy))),
	make_root_account,
	extract_accounts2.

 extract_accounts2 :-
	!report_details(Details),
	!doc_value(Details, ic_ui:account_taxonomies, T),
	!doc_list_items(T, Taxonomies),
	maplist(!load_account_hierarchy,Taxonomies).

 load_account_hierarchy(Taxonomy0) :-
	doc_value(Taxonomy0, account_taxonomies:url, Taxonomy),
	(	default_account_hierarchy(Taxonomy, Url)
	->	true
	;	atom_string(Url, Taxonomy)
	),
	%;	Url = Taxonomy),
	load_accountHierarchy_element(Url, AccountHierarchy),
	extract_accounts_from_accountHierarchy_element(AccountHierarchy).

 default_account_hierarchy(Taxonomy, Filename) :-
 		rdf_current_prefix(account_taxonomies, At),
 		atom_concat(At, Filename, Taxonomy).

 absolutize_account_hierarchy_path(Url_Or_Path, Url_Or_Path2) :-
	(	is_url(Url_Or_Path)
	->	Url_Or_Path2 = Url_Or_Path
	;	(	http_safe_file(Url_Or_Path, []),
			atomics_to_string(['default_account_hierarchies/',Url_Or_Path, '.xml'],Url_Or_Path1),
			catch(
				absolute_file_name(my_static(Url_Or_Path1), Url_Or_Path2, [ access(read) ]),
				error(existence_error(source_sink,_),_),
				throw_string(['pre-defined account hierarchy file not found:',Url_Or_Path1])
			)
		)
	).

 load_accountHierarchy_element(Url_Or_Path, AccountHierarchy_Elements) :-
	absolutize_account_hierarchy_path(Url_Or_Path, Url_Or_Path2),
	load_accountHierarchy_element2(Url_Or_Path2, AccountHierarchy_Elements).

 load_accountHierarchy_element2(Url_Or_Path, AccountHierarchy_Elements) :-
	(	(	xml_from_path_or_url(Url_Or_Path, AccountHierarchy_Elements),
			xpath(AccountHierarchy_Elements, //accountHierarchy, _)
		)
		->	true
		;	arelle(taxonomy, Url_Or_Path, AccountHierarchy_Elements))
	.

 arelle(taxonomy, Taxonomy_URL, Dom) :-
	/* get xml text */
	services_post_result('arelle_extract', _{'taxonomy_locator':Taxonomy_URL}, Result),
	_{xml_text: Xml_text} :< Result,

	absolute_tmp_path(loc(file_name,'account_hierarchy_from_taxonomy.xml'), Filepath),
	write_file(Filepath, Xml_text),

	xml_from_path(Filepath, Dom).



/*
┏━┓┏━╸┏━╸┏━┓╻ ╻┏┓╻╺┳╸╻ ╻╻┏━╸┏━┓┏━┓┏━┓┏━╸╻ ╻╻ ╻
┣━┫┃  ┃  ┃ ┃┃ ┃┃┗┫ ┃ ┣━┫┃┣╸ ┣┳┛┣━┫┣┳┛┃  ┣━┫┗┳┛
╹ ╹┗━╸┗━╸┗━┛┗━┛╹ ╹ ╹ ╹ ╹╹┗━╸╹┗╸╹ ╹╹┗╸┗━╸╹ ╹ ╹
extract accounts from accountHierarchy xml element
*/

 extract_accounts_from_accountHierarchy_element([element(_,_,Children)]) :-
	maplist(extract_accounts_subtree(no_parent_element), Children).

 extract_accounts_subtree(Parent, E) :-
	add_account(E, Parent, Uri),
	E = element(_,_,Children),
	maplist(extract_accounts_subtree(Uri), Children).

 add_account(E, Parent0, Uri) :-
	E = element(Elem_name, Attrs, _),
	(	memberchk((name = Id), Attrs)
	->	true
	;	Id = Elem_name),
	(	memberchk((parent_role = Parent_role_atom), Attrs)
	->	(	Parent0 \= no_parent_element
		->	throw_string(['problem with account "', Id, '" XML: In a nested account element, parent must not be specified. Found:', Parent_role_atom])
		;	(
				role_string_to_term(Parent_role_atom, Parent_role),
				(	account_by_role(Parent_role, Parent)
				->	true
				;	throw_string(['parent account not found by role:', Parent_role_atom]))
			)
		)
	;	(	Parent0 == no_parent_element
		->	throw_string([Id, ': parent role not specified'])
		;	Parent = Parent0)
	),

	% look up details uri from rdf
	(	/*(	request_data(D),
			doc_value(D, ic_ui:account_details, Details),
			doc_list_member(Detail, Details),
			doc(Detail, l:id, Id)
		)*/
		false
	->	true
	;	Detail = _),

	/* try to get role from xml or rdf */
	(	memberchk((role = Role_atom), Attrs)
	->	true
	;	/* try to get role from rdf */
		(	nonvar(Detail),
			doc(Detail, l:role, Role_atom))
		->	true
		;	true
	),

	(	nonvar(Role_atom)
	->	role_string_to_term(Role_atom, Role)
	;	true),

	(	extract_normal_side_uri_from_attrs(Attrs, Side)
	->	true
	;	(	extract_normal_side_uri_from_account_detail_rdf(Detail, Side)
		->	true
		;	true)),

	make_account_with_optional_role(Id, Parent, /*Detail_Level*/0, Role, Uri),

	(	nonvar(Side)
	->	doc_add(Uri, accounts:normal_side, Side, accounts)
	;	true),

 	(	memberchk(subcategorize_by_smsf_member = true, Attrs)
	->	doc_add(Uri, accounts:subcategorize_by_smsf_member, true, accounts)
	;	true),

 	(	memberchk(subcategorize_by_investment = true, Attrs)
	->	doc_add(Uri, accounts:subcategorize_by_investment, true, accounts)
	;	true),

 	(	memberchk(subcategorize_by_bank = true, Attrs)
	->	doc_add(Uri, accounts:subcategorize_by_bank, true, accounts)
	;	true),

 	(	memberchk(smsf_taxability = Taxability0, Attrs)
	->	(	atom_string(Taxability, Taxability0),
			doc_add(Uri, accounts:smsf_taxability, Taxability, accounts)
		)
	;	true),

 	(	memberchk(smsf_phase = Phase0, Attrs)
	->	(	atom_string(Phase, Phase0),
			doc_add(Uri, accounts:smsf_phase, Phase, accounts)
		)
	;	true),

 	(	memberchk(is_smsf_equity_opening_balance = Iob0, Attrs)
	->	(	atom_string(Iob, Iob0),
			doc_add(Uri, accounts:is_smsf_equity_opening_balance, Iob, accounts)
		)
	;	true),

	true.





 role_string_to_term(Role_string, rl(Role)) :-
	split_string(Role_string, '!', '', Role_string_list),
	maplist(atom_string, Role_atom_list, Role_string_list),
	path_list_to_term(Role_atom_list, Role).


/*
 path_list_to_term([H,T], H/T) :-
	!.

 path_list_to_term([H|TH/TT], Role) :-
	path_list_to_term(TH/TT, Role2),
	Role =.. ['/',H,Role2],
	!.
*/



 path_term_to_list(Term, List) :-
    path_term_to_list2(Term, List0),
    reverse(List0, List).

 path_term_to_list2(Bulk/Atom, [Atom|Tail]) :-
    dif(Tail, []),
	!,
    (atomic(Atom)->true;throw(zzz)),
    path_term_to_list2(Bulk, Tail).

 path_term_to_list2(Bulk, [Bulk]) :-
	atomic(Bulk),
    !.

 path_list_to_term(List, Term) :-
    reverse(List, List2),
    path_term_to_list2(Term, List2).



 extract_normal_side_uri_from_attrs(Attrs, Side) :-
	(	memberchk((normal_side = Side_atom), Attrs)
	->	(	Side_atom = debit
		->	Side = kb:debit
		;	(	Side_atom = credit
			->	Side = kb:credit
			;	throw_string(['unexpected account normal side in accounts xml:', Side_atom])))).

 extract_normal_side_uri_from_account_detail_rdf(Detail, Side) :-
	nonvar(Detail),
	doc(Detail, accounts:normal_side, Side).




/*
	% NOTE: we have to load an entire xbrl taxonomy file just to determine that it's not a simple XML hierarchy
	would be even more simplified if we differentiated between <accounts> and <taxonomy> tags
	so that we're not trying to dispatch by inferring the file contents

	<taxonomy> tag:
		we'll probably end up extracting more info from the taxonomies later anyway
		should only be one taxonomy tag
		because: should only be one main taxonomy file that does the linking to other taxonomy files (if any)
			(until we have some use-case for "supporting multiple taxonomies" ?)
		arelle doesn't care whether you send it a filepath or URL

	<accounts> tag:
		now only two cases:
			1) DOM = element(_,_,_)
			2) [Atom] = DOM
				then just generic "load_file(Atom, Contents), extract_simple_account_hierarchy(Contents, Account_Hierarchy)"
*/


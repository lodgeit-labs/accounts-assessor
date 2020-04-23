/*
	% NOTE: we have to load an entire taxonomy file just to determine that it's not a simple XML hierarchy
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

/*
extract account tree specified in request xml
the accountHierarchy tag can appear multiple times, all the results will be added together.
*/

extract_accounts(Request_DOM) :-
	gtrace,
	make_account2(root, 0, root/root, _),
	extract_account_hierarchy_from_request_dom(Request_DOM),
	propagate_accounts_side.


extract_account_hierarchy_from_request_dom(Request_DOM) :-
	findall(E, xpath(Request_DOM, //reports/balanceSheetRequest/accountHierarchy, E), Es),
	(	Es = []
	->	extract_account_hierarchy_from_accountHierarchy_element(element(accountHierarchy, [], ['default_account_hierarchy.xml']))
	;	maplist(extract_account_hierarchy_from_accountHierarchy_element, Es).

extract_account_hierarchy_from_accountHierarchy_element(E) :-
	E = element(_,_,Children),
	(
		(
			Children = [Atom],
			atom(Atom)
		)
	->	extract_accountHierarchy_elements_from_referenced_file($>trim_atom(Atom), AccountHierarchy_Elements),
	;	AccountHierarchy_Elements = Children),
	extract_account_terms_from_accountHierarchy_elements(AccountHierarchy_Elements).

extract_accountHierarchy_elements_from_referenced_file(Trimmed, AccountHierarchy_Elements),
	(	is_url(Trimmed)
	->	Url_Or_Path = Trimmed
	;	(	http_safe_file(Trimmed, []),
			absolute_file_name(my_static(Trimmed), Url_Or_Path, [ access(read) ])
		)
	),
	(
		(
			xml_from_path_or_url(Url_Or_Path, AccountHierarchy_Elements),
			xpath(AccountHierarchy_Elements, //accountHierarchy, _)
		)
		->	true
		;	arelle(taxonomy, Url_Or_Path, AccountHierarchy_Elements)
	).

arelle(taxonomy, Taxonomy_URL, AccountHierarchy_Elements) :-
	internal_services_rpc(
		cmd{'method':'arelle_extract','params':p{'taxonomy_locator':Taxonomy_URL}},
		Result),
	absolute_tmp_path(loc(file_name,'account_hierarchy_from_taxonomy.xml'), Fn),
	write_file(Fn, Result),
	call_with_string_read_stream(Result, load_extracted_account_hierarchy_xml(AccountHierarchy_Elements)).

load_extracted_account_hierarchy_xml(/*-*/AccountHierarchy_Elements, /*+*/Stream) :-
	load_structure(Stream, AccountHierarchy_Elements, [dialect(xml),space(remove)]).



/*
at this point, we have a Dom
*/

extract_account_terms_from_accountHierarchy_elements(Accounts_Elements) :-
	maplist(extract_account_terms_from_accountHierarchy_element, Accounts_Elements).


extract_account_terms_from_accountHierarchy_element(element(_,_,Children)) :-
	maplist(extract_account2, no_parent_element, Children).


extract_account_from_toplevel_element(E) :-
	E = element(Id,Attrs,Children),
	memberchk((parent_role_parent = Parent_role_parent), Attrs),
	memberchk((parent_role_child = Parent_role_child), Attrs),
	account_by_role(Parent_role_parent/Parent_role_child, Parent),
	add_account(Id, Parent, Parent2),
	maplist(exract_account_subtree(Parent2), Children).

exract_account_subtree(Parent, E) :-
	add_account(E, Parent, Uri),
	E = element(_,_,Children),
	maplist(exract_account_subtree(Uri), Children).

add_account(E, Parent, Result) :-
	E = element(Id,Attrs,Children),

	(	(	request_data(D),
			doc_value(D, ic_ui:account_details, Details)
			doc_list_member(Detail, Details),
			doc(Detail, l:id, Id)
		)
	->	true
	;	/*Detail = _*/),

	/* try to get role from xml */
	(	(	memberchk((role_parent = Role_parent), Attrs),
			memberchk((role_child = Role_child), Attrs))
	->	true
			/* try to get role from rdf */
	;	(	nonvar(Detail),
			doc(Detail, l:role_parent, Role_parent_str),
			atom_string(Role_parent, Role_parent_str),
			doc(Detail, l:role_child, Role_child_str),
			atom_string(Role_child, Role_child_str))
		->	true
		;	(
				Role_parent = 'Accounts',
				Role_child = Id
			)
	),

	(	extract_normal_side_uri_from_attrs(Attrs, Side)
	->	true
	;	(	extract_normal_side_uri_from_account_detail_rdf(Detail, Side)
		->	true
		;	true)),

	make_account(Id, Parent, /*Detail_Level*/0, Role_parent/Role_child, Uri),

	(	nonvar(Side)
	->	doc_add(Uri, accounts:side, Side, accounts)
	;	true).


extract_normal_side_uri_from_attrs(Attrs, Side)
	(	memberchk((normal_side = Side_atom), Attrs)
	->	(	Side_atom = debit
		->	Side = kb:debit
		;	(	Side_atom = credit
			->	Side = kb:credit
			;	throw_string(['unexpected account normal side in accounts xml:', Side_atom])))).

extract_normal_side_uri_from_account_detail_rdf(Detail, Side) :-
	nonvar(Detail),
	doc(Detail, l:normal_side, Side).


propagate_accounts_side :-
	account_by_role_throw(root/root, Root),
	account_direct_children(Root, Sub_roots),
	maplist(propagate_accounts_side0(Sub_roots)).

propagate_accounts_side0(Sub_root) :-
	account_direct_children(Sub_root, Top_level_accounts),
	maplist(propagate_accounts_side2(_, Top_level_accounts)).

propagate_accounts_side2(Parent_side, Account) :-
	ensure_account_has_normal_side(Parent_side, Account),
	account_side(Account, Side)
	account_direct_children(Account, Children),
	maplist(propagate_accounts_side2(Side, Children)).

ensure_account_has_normal_side(_, Account) :-
	account_side(Account, _),!.

ensure_account_has_normal_side(Parent_side, Account) :-
	doc_add(Account, accounts:normal_side, Parent_side, accounts),!.

ensure_account_has_normal_side(_, Account) :-
	throw_string(["couldn't determine account normal side"]).


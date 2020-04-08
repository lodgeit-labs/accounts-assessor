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
extract_account_hierarchy_from_request_dom(Request_DOM, Account_Hierarchy) :-
	make_account2(root, 0, root/root, _),
	findall(E, xpath(Request_DOM, //reports/balanceSheetRequest/accountHierarchy, E), Es),
	(	Es = []
	->	extract_account_hierarchy_from_accountHierarchy_element(element(accountHierarchy, [], ['default_account_hierarchy.xml']))
	;	extract_account_hierarchy_from_accountHierarchy_elements(Es)).

extract_account_hierarchy_from_accountHierarchy_elements(DOMs, Account_Hierarchy) :-
	maplist(extract_account_hierarchy_from_accountHierarchy_element, DOMs, Accounts),
	flatten(Accounts, Account_Hierarchy).

extract_account_hierarchy_from_accountHierarchy_element(E, Accounts) :-
	E = element(_,_,Children),
	(
		(
			Children = [Atom],
			atom(Atom)
		)
	->	extract_accountHierarchy_elements_from_referenced_file($>trim_atom(Atom), AccountHierarchy_Elements),
	;	AccountHierarchy_Elements = Children),
	extract_account_terms_from_accountHierarchy_elements(AccountHierarchy_Elements, Accounts).

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

extract_account_terms_from_accountHierarchy_elements(Accounts_Elements, Accounts) :-
	maplist(extract_account_terms_from_accountHierarchy_element, Accounts_Elements, Accounts).

% extract accounts given accountHierarchy element
extract_account_terms_from_accountHierarchy_element(element(_,_,Children)) :-
	maplist(extract_account2, no_parent_element, Children).

extract_account_from_toplevel_element(E) :-
	E = element(Id,Attrs,_),
	memberchk((parent_role_parent = Parent_role_parent), Attrs),
	memberchk((parent_role_child = Parent_role_child), Attrs),
	account_by_role(Parent_role_parent/Parent_role_child, Parent),


	optionally_extract_normal_side(Url, Attrs)


extract_account2(Parent_Element, Child) :-
	Parent_Element = no_parent_element,
	Child = element(Id,Attrs,_),
	memberchk((,Attrs),
	gtrace,
	make_account(Id, $>account_by_role(root/root), Detail_Level, Role, Uri),


		(
			/* TODO: extract role, if specified */
			Role = ('Accounts' / Child_Name),
			Link = account(Child_Name, Parent_Name, Role, 0)
		).

yield_links(element(_,_,Children), Link) :-
		(
			% recurse on the child
			yield_links(Child, Link)
		)
	.




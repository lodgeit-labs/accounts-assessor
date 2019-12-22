
/*
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
	findall(DOM, xpath(Request_DOM, //reports/balanceSheetRequest/accountHierarchy, DOM), DOMs),
	(	DOMs = []
	->	extract_account_hierarchy_from_accountHierarchy_element(element(accountHierarchy, [], ['default_account_hierarchy.xml']), Account_Hierarchy0)
	;	extract_account_hierarchy_from_accountHierarchy_elements(DOMs, Account_Hierarchy0)),
	flatten(Account_Hierarchy0, Account_Hierarchy1),
	sort(Account_Hierarchy1, Account_Hierarchy).

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
	->	(
			trim_atom(Atom, Trimmed),
			(	is_url(Trimmed)
			->	Url_Or_Path = Trimmed
			;	(	http_safe_file(Trimmed, []),
					absolute_file_name(my_static(Trimmed), Url_Or_Path, [ access(read) ])
				)),
			(
				(
					xml_from_path_or_url(Url_Or_Path, AccountHierarchy_Elements),
					xpath(AccountHierarchy_Elements, //accountHierarchy, _)
				)
				->	true
				;	arelle(taxonomy, Url_Or_Path, AccountHierarchy_Elements)
			)
		)
	;
		AccountHierarchy_Elements = Children
	),
	extract_account_terms_from_accountHierarchy_elements(AccountHierarchy_Elements, Accounts).

arelle(taxonomy, Taxonomy_URL, AccountHierarchy_Elements) :-
	setup_call_cleanup(
		% should be activating the venv here
		process_create('../python/venv/bin/python3',['../python/src/account_hierarchy.py',Taxonomy_URL],[stdout(pipe(Out))]),
		(
			load_structure(Out, AccountHierarchy_Elements, [dialect(xml),space(remove)]),
			absolute_tmp_path('account_hierarchy_from_taxonomy.xml', FN),
			xml_write_file(FN, AccountHierarchy_Elements, [])
		),
		close(Out)
	).

extract_account_terms_from_accountHierarchy_elements(Accounts_Elements, Accounts) :-
	maplist(extract_account_terms_from_accountHierarchy_element, Accounts_Elements, Accounts).

% Load Account Hierarchy terms given root account element
extract_account_terms_from_accountHierarchy_element(Account_Element, Account_Hierarchy) :-
	findall(Link, yield_links(Account_Element, Link), Account_Hierarchy).

% extracts and yields all accounts one by one
yield_links(element(Parent_Name,_,Children), Link) :-
	member(Child, Children),
	Child = element(Child_Name,_,_),
	(
		(
			/* TODO: extract role, if specified */
			Role = ('Accounts' / Child_Name),
			Link = account(Child_Name, Parent_Name, Role, 0)
		)
		;
		(
			% recurse on the child
			yield_links(Child, Link)
		)
	).


/*server_public_url(Server_Url),
atomic_list_concat([Server_Url, '/taxonomy/basic.xsd'],Taxonomy_URL),
format(user_error, 'loading default taxonomy from ~w\n', [Taxonomy_URL]),
extract_account_hierarchy_from_taxonomy(Taxonomy_URL,Dom)*/

% NOTE: we have to load an entire taxonomy file just to determine that it's not a simple XML hierarchy

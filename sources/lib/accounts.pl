/*
wiki/specifying_account_hierarchies
*/


:- use_module(library(http/http_client)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_open)).

 make_account_with_optional_role(Id, Parent, Detail_Level, Role, Uri) :-
	assertion(Role = rl(_)),
	make_account3(Id, Detail_Level, Uri),
	(	nonvar(Role)
	->	doc_add(Uri, accounts:role, Role, accounts)
	;	true),
	doc_add(Uri, accounts:parent, Parent, accounts).

 make_account(Id, Parent, Detail_Level, Role, Uri) :-
	make_account2(Id, Detail_Level, Role, Uri),
	doc_add(Uri, accounts:parent, Parent, accounts).

 make_account2(Id, Detail_Level, Role, Uri) :-
	assertion(Role = rl(_)),
	make_account3(Id, Detail_Level, Uri),
	doc_add(Uri, accounts:role, Role, accounts).

 make_account3(Id, Detail_Level, Uri) :-
	doc_new_uri($>atomic_list_concat(['accounts_', Id]), Uri),
	doc_add(Uri, rdf:type, l:account, accounts),
	doc_add(Uri, accounts:name, Id, accounts),
	doc_add(Uri, accounts:detail_level, Detail_Level, accounts),
	result_accounts(As),
	!doc_add(As, l:has_account, Uri),
	true.



 account_name(Uri, X) :-
	doc(Uri, accounts:name, X, accounts).
 account_parent(Uri, X) :-
	doc(Uri, accounts:parent, X, accounts).
 account_role(Uri, X) :-
	assertion(X = rl(_)),
	doc(Uri, accounts:role, X, accounts),
	assertion(X = rl(_)).
 account_detail_level(Uri, X) :-
	/* 0 for normal xbrl facts, 1 for points in xbrl dimensions */
	doc(Uri, accounts:detail_level, X, accounts).
 account_normal_side(Uri, X) :-
	doc(Uri, accounts:normal_side, X, accounts).



/*
 acc(Role, Account) :-
	(	Role = name(Name)
	->	account_by_ui(Name, Account)
	;	abrlt(Role, Account).
*/
 abrlt(Role, Account) :-

	!(	is_valid_role(Role)
	->	true
	;
		%true
		format(user_error, '~q.~n', [is_valid_role(Role)])
	),

	account_by_role_throw(rl(Role), Account).


/*
find account by a user-entered name
*/
 account_by_ui(X0, Uri) :-
 	trim_atom(X0, X),
 	assertion(atom(X)),
	findall(Uri, account_name(Uri, X), Uris),
	(	Uris = []
	->	throw_string(['account not found: "', X, '"'])
	;	(	Uris = [Uri]
		->	true
		;	(throw_string(['multiple accounts with same name found: "', X, '"'])))).

 all_accounts(Accounts) :-
	result_accounts(As),
	findall(A, docm(As, l:has_account, A), Accounts).

 account_exists(Account) :-
	all_accounts(Accounts),
	member(Account, Accounts).

 account_by_name_exists(Name) :-
	result_accounts(As),
	once(
		(
			doc(As, l:has_account, A),
			account_name(A, Name)
		)
	).

% Relates an account to an ancestral account or itself
%:- table account_in_set/3.
 account_in_set(Account, Account).

 account_in_set(Account, Root_Account) :-
	account_parent(Child_Account, Root_Account),
	account_in_set(Account, Child_Account).

 account_direct_children(Parent, Children) :-
	findall(Child, (account_parent(Child, Parent)), Children).

 account_descendants(Account, Descendants) :-
	findall(X, (account_descendant(Account, X)), Descendants).

 account_descendant(Account, Descendant) :-
	account_parent(Descendant, Account).

 account_descendant(Account, Descendant) :-
	account_parent(Descendant0, Account),
	account_descendant(Descendant0, Descendant).

 is_leaf_account(Account) :-
	\+does_account_have_children(Account).

 does_account_have_children(Account) :-
	account_parent(_Child_Account, Account),
	!.

/* throws an exception if no account is found */
 account_by_role_throw(Role, Account) :-
	assertion(Role = rl(_)),
	findall(Account, account_role(Account, Role), Accounts),
	(	Accounts \= []
	->	member(Account, Accounts)
	;	(
			Role = rl(Role2),
			term_string(Role2, Role_Str),
			(	nonvar(Account)
			->	format(string(Err), 'unknown account by role ~w that would match expected account ~q.~n', [Role_Str, Account])
			;	format(string(Err), 'unknown account by role: ~w.~n', [Role_Str])),
			Hint = "Please review the chart of accounts.",
			throw_string([Err,Hint]),
			throw_string_with_html([Err,Hint],div([Err,a([href='general_ledger_viewer/gl.html'],[Hint])]))
		)
	).

 account_by_role(Role, Account) :-
	assertion(Role = rl(_)),
	account_role(Account, Role).


 account_by_role_has_descendants(Role, Descendants) :-
	abrlt(Role, Account),
	account_descendants(Account,Descendants).


/*
check that each account has a parent. Together with checking that each generated transaction has a valid account,
this should ensure that all transactions get reflected in the account tree somewhere
*/
 check_account_parent(Account) :-
	(	account_parent(Account, Parent)
	->	(	account_name(Parent,_)
		->	true
		;	throw_string(['account "', $>account_name(Account), '"\'s parent "', Parent, '" is not an account?.'])
		)
	;	(
			get_root_account(Root),
			(	Root = Account
			->	true
			;	throw_string(['account "', $>account_name(Account), '" has no parent.']))
		)
	).

 check_accounts_parent :-
	all_accounts(Accounts),
	maplist(check_account_parent,Accounts).


/* just writes file, doesnt create report entry here */
 write_accounts_json_report :-
	maplist(account_to_dict, $>all_accounts, Dicts),
	write_tmp_json_file(loc(file_name,'accounts.json'), Dicts).

 account_to_dict(Uri, Dict) :-
	Dict = account{
		id: Uri,
		name: Name,
		parent: Parent,
		role: Role,
		detail_level: Detail_level,
		normal_side: Normal_side
	},

	!account_name(Uri, Name),

	(	account_parent(Uri, Parent)
	->	true
	;	Parent = @null),

	(	account_role(Uri, rl(Role0))
	->	role_bang_string(Role0, Role)
	;	Role = @null),

	!account_detail_level(Uri, Detail_level),

	(	account_normal_side(Uri, Normal_side)
	->	true
	;	Normal_side = @null)
	.

 role_bang_string(Role0, Text) :-
	!role_bang_string_helper(Role0, Role),
	once(c(!'use grammar to generate text'(out_account_specifier(role(Role)), Text))).

 role_bang_string_helper(Role0, Role) :-
%gtrace,
%Role0 = 'Financial_Investments'/'Investments'/'BetaShares Australian Equities Strong Bear Hedge Fund',
	maplist(([R0, fixed(R0)]>>true), $>path_term_to_list(Role0), Role)/*,
	writeq(Role0),nl,
	writeq(Role),nl*/.

%wrap_in_fixed(X

 check_accounts_roles :-
	findall(Role, account_role(_, Role), Roles),
	(	ground(Roles)
	->	true
	;	throw_string(error)),
	dif(I, J),
	findall(_, (
		account_role(I, Ri),
		account_role(J, Rj),
		(	Ri = Rj
		->	(
				(account_name(Ri, I_id)->true;throw_string(error)),
				(account_name(Rj, J_id)->true;throw_string(error)),
				throw_string(['Multiple accounts with same role found. role: "', Ri, '", first account: "', I_id, '", second account: "', J_id, '".'])
			)
		;	true)
	),_).


 ensure_account_exists(Suggested_parent, Suggested_id, Detail_level, Role, Account) :-
 	assertion(number(Detail_level)),
	(	account_by_role(Role, Account)
	->	(	true/*doc(Account, accounts:overrides_autogenerated_account, true, accounts)*/
		->	true
		;	(
				account_name(Account, Name),
				throw_string(['attempted to create account ', Name, ' with role ', Role, ', another account with this role already exists. Add overrides_autogenerated_account="true" if this is intentional'])
			)
		)
	;	(
			(	nonvar(Suggested_id)
			->	assertion(atom(Suggested_id))
			;	(
					Role = rl(Role2),
					path_list_to_term(Role_list, Role2),
					last(Role_list, Child_Role_Raw),
					replace_nonalphanum_chars_with_underscore(Child_Role_Raw, Child_Role_Safe),
					capitalize_atom(Child_Role_Safe, Child_Role_Capitalized),
					!account_name(Suggested_parent, Suggested_parent_id),
					atomic_list_concat([Suggested_parent_id, '', Child_Role_Capitalized], Suggested_id)
				)
			),
			account_free_name(Suggested_id, Free_Id),
			c(make_account(Free_Id, Suggested_parent, Detail_level, Role, Account)),
			doc_add(Account, l:autogenerated, true, accounts)
		)
	).

/*
	find an unused account name.
	if an account with this name found, append _2 and try again.
*/
 account_free_name(Id, Free_Id) :-
		account_by_name_exists(Id)
	->	account_free_name($>atomic_list_concat([Id, '_2']), Free_Id)
	;	Free_Id = Id.




/*
┏━┓┏━┓┏━┓┏━┓┏━┓┏━╸┏━┓╺┳╸┏━╸   ┏━┓┏━╸┏━╸┏━┓╻ ╻┏┓╻╺┳╸┏━┓   ┏━┓╻╺┳┓┏━╸
┣━┛┣┳┛┃ ┃┣━┛┣━┫┃╺┓┣━┫ ┃ ┣╸    ┣━┫┃  ┃  ┃ ┃┃ ┃┃┗┫ ┃ ┗━┓   ┗━┓┃ ┃┃┣╸
╹  ╹┗╸┗━┛╹  ╹ ╹┗━┛╹ ╹ ╹ ┗━╸╺━╸╹ ╹┗━╸┗━╸┗━┛┗━┛╹ ╹ ╹ ┗━┛╺━╸┗━┛╹╺┻┛┗━╸
*/

 propagate_accounts_side :-
	get_root_account(Root),
	account_direct_children(Root, Sub_roots),
	maplist(propagate_accounts_side2(_),Sub_roots).

 propagate_accounts_side2(Parent_side, Account) :-
	ensure_account_has_normal_side(Parent_side, Account),
	account_normal_side(Account, Side),
	account_direct_children(Account, Children),
	maplist(propagate_accounts_side2(Side), Children).

 ensure_account_has_normal_side(_, Account) :-
	account_normal_side(Account, _),!.

 ensure_account_has_normal_side(Parent_side, Account) :-
	nonvar(Parent_side),
	doc_add(Account, accounts:normal_side, Parent_side, accounts),!.

 ensure_account_has_normal_side(_, Account) :-
	account_name(Account, Id),
	throw_string(["couldn't determine account normal side for ", Id]).




/*

todo fuzzy account name comparison/matching, unit name comparison/matching:
account_by_ui(Str)

unit_by_ui(Str, Atom) :-
	i suppose gather up all mentions of units in input
	so let's say:

	we call 'ensure system accounts exist'. Some accounts existence is based on mentions of units in Unit_categorization sheet. These accounts' names or roles dont directly contain a string, but a reference object:
		[a ic_ui:account_input_string; value "account1"]

	then we call extract_smsf_distribution, and it has a bunch of parameters (or binds a bunch of variables in request properties, ie, kind of an implicit Static_data). Llet's say it produces gl transactions with transaction_account with those references too. In the process is looks up accounts by role.

	...

*/

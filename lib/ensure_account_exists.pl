ensure_roles_tree_exists(Parent, Roles_And_Detail_Levels) :-
	ensure_roles_tree_exists2(Roles_And_Detail_Levels, Parent).


ensure_roles_tree_exists2(
	Parent_Id,
	[Roles_And_Detail_Levels|Roles_Tail]
) :-
	(Child_Roles, Detail_Level) = Roles_And_Detail_Levels,
	findall(
		(Parent_Id/Child_Role),
		member(Child_Role, Child_Roles),
		Roles
	),
	maplist(ensure_account_exists(Accounts_In, Parent_Id, Detail_Level), Roles, System_Accounts),
	findall(
		System_Account_Id,
		(
			member(System_Account, System_Accounts),
			account_id(System_Account, System_Account_Id)
		),
		System_Account_Ids
	),
	maplist(ensure_roles_tree_exists2(Roles_Tail), System_Account_Ids).

ensure_roles_tree_exists2([], _).



ensure_account_exists(Parent_Id, Detail_Level, Role, Account) :-

	(
		(
			account_by_role(Role, Account),!)
		)
	;
		(
			Role = (_/Child_Role_Raw),
			replace_nonalphanum_chars_with_underscore(Child_Role_Raw, Child_Role_Safe),
			capitalize_atom(Child_Role_Safe, Child_Role_Capitalized),
			atomic_list_concat([Parent_Id, '', Child_Role_Capitalized], Id),
			free_id(Id, Free_Id),
			doc_add(
			account_role(Account, Role),
			account_parent(Account, Parent_Id),
			account_id(Account, Free_Id),
			account_detail_level(Account, Detail_Level)
		)
	).

/*
	generate a unique id if needed.
	if an account with id Id is found, append _2 and try again,
	otherwise bind Free_Id to Id.
*/
free_account_id(Id, Free_Id) :-
		account_exists(Accounts, Id)
	->	free_id(Accounts, $>atomic_list_concat([Id, '_2']), Free_Id)
	;	Free_Id = Id.



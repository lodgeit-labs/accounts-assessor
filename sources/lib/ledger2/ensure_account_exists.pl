/*
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
*/


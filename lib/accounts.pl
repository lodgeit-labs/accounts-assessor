
/*
https://github.com/LodgeiT/labs-accounts-assessor/wiki/specifying_account_hierarchies
*/

/*
roles: If a trading account Financial_Investments already contains
an account with id Financial_Investments_realized, either it has to have a role Financial_Investments/realized,
or is not recognized as such, and a new one with proper role is proposed. This allows us to abstract away from ids,
because Financial_Investments_realized might already be an id of another user account.
*/

/*
accountHierarchy is not an account. The root account has id 'root' and role 'root'/'root'.
logic does not seem to ever need to care about the structure of the tree, only about identifying appropriate accounts
so what i see we need is a user interface and a simple xml schema to express associations between accounts and their roles in the system.
the roles can have unique names, and later URIs, in the whole set of programs.
 <account id="xxxx" role="Financial_Investments/Realized_Gains">...

mostly it is a matter of creating a user interface to specify these associations

the program can also create sub-accounts from the specified account at runtime as needed, for example for livestock types
each account hierarchy can come with a default set of associations
*/

:- use_module(library(http/http_client)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_open)).

make_account(Id, Parent, Detail_Level, Role, Uri) :-
	make_account2(Id, Detail_Level, Role, Uri),
	doc_add(Uri, accounts:parent, Parent, accounts).

make_account2(Id, Detail_Level, Role, Uri) :-
	doc_new_uri(Uri, $>atomic_list_concat(['accounts_', Id])),
	doc_add(Uri, rdf:type, l:account, accounts),
	doc_add(Uri, accounts:id, Id, accounts),
	doc_add(Uri, accounts:role, Role, accounts),
	doc_add(Uri, accounts:detail_level, Detail_Level, accounts),
	true.



account_id(Uri, X) :-
	doc(Uri, accounts:id, X, accounts).
account_parent(Uri, X) :-
	doc(Uri, accounts:parent, X, accounts).
account_role(Uri, X) :-
	doc(Uri, accounts:role, X, accounts).
account_detail_level(Uri, X) :-
	/* 0 for normal xbrl facts, 1 for points in xbrl dimensions */
	doc(Uri, accounts:detail_level, X, accounts).
account_normal_side(Uri, X) :-
	doc(Uri, accounts:normal_side, X, accounts).

/*
account_normal_side(Uri, X) :-
	(	doc(Uri, accounts:normal_side, X, accounts)
	->	true
	;	once(
			(
				account_ancestor(Uri, A),
				account_normal_side(A, X)
			))).
*/
all_accounts(Accounts) :-
	findall(A, account_id(A, _), Accounts).

account_exists(Id) :-
	once(account_by_id(Id)).

% Relates an account to an ancestral account or itself
%:- table account_in_set/3.
account_in_set(Account, Account).

account_in_set(Account, Root_Account) :-
	account_parent(Child_Account, Root_Account),
	account_in_set(Account, Child_Account).

account_direct_children(Parent, Children) :-
	findall(Child, account_parent(Child, Parent), Children).

/* throws an exception if no account is found */
account_by_role_throw(Role, Account) :-
	findall(Account, account_role(Account, Role), Accounts),
	(	Accounts \= []
	->	member(Account, Accounts)
	;	(
			term_string(Role, Role_Str),
			format(user_error, '~q~n', [Account]),
			format(atom(Err), 'unknown account by role: ~w', [Role_Str]),
			throw_string(Err)
		)
	).

account_by_role(Role, Account) :-
	account_role(Account, Role).

/*
check that each account has a parent. Together with checking that each generated transaction has a valid account,
this should ensure that all transactions get reflected in the account tree somewhere
*/
check_account_parent(Account) :-
	account_id(Account, Id),
	(	Id == 'root'
	->	true
	;	(
			account_parent(Account, Parent),
			(	account_exists(Parent)
			->	true
			;	throw_string(['account "', Id, '" parent "', Parent, '" missing.']))
		)
	).

write_accounts_json_report :-
	maplist(account_to_dict, $>all_accounts, Dicts),
	write_tmp_json_file(loc(file_name,'accounts.json'), Dicts).

account_to_dict(Uri, Dict) :-
	Dict = account{
		id: Id,
		parent: Parent,
		role: Role,
		detail_level: Detail_level,
		normal_side: Normal_side
	},
	account_id(Uri, Id),
	account_parent(Uri, Parent),
	account_role(Uri, Role),
	account_detail_level(Uri, Detail_level),
	account_normal_side(Uri, Normal_side).



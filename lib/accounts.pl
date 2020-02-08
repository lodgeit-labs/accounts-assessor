:- use_module(library(http/http_client)).
:- use_module(library(record)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_open)).

:- record account(id, parent, role, detail_level).


/*
from what i understand, both account names and account numbers can change
at least the logic does not seem to ever need to care about the structure of the tree, only about identifying appropriate accounts
so what i see we need is a user interface and a simple xml schema to express associations between accounts and their roles in the system
the roles can have unique names, and later URLs, in the whole set of programs
.
<role name="Livestock sales revenue" account="4321">
or rather <account id="xxxx" role="Financial_Investments/Realized_Gains">...

mostly it is a matter of creating a user interface to specify these associations
the program can also create sub-accounts from the specified account in runtime as needed, for example for livestock types
then each account hierarchy can come with a default set of associations*/

account_exists(Accounts, Id) :-
	account_id(Account, Id),
	memberchk(Account, Accounts).
	
account_detail_level(Accounts, Id, Detail_Level) :-
	account_term_by_id(Accounts, Id, Account),
	account_detail_level(Account, Detail_Level).
	
% Relates an account to an ancestral account or itself
account_in_set(Accounts, Account_Id, Root_Account_Id) :-
    	Account_Id = Root_Account_Id
	;
	(
		account_id(Child_Account, Child_Id),
		account_parent(Child_Account, Root_Account_Id),
		member(Child_Account, Accounts),
		account_in_set(Accounts, Account_Id, Child_Id)
	).

account_child_parent(Accounts, Child_Id, Parent_Id) :-
	(
		nonvar(Child_Id),
		account_term_by_id(Accounts, Child_Id, Child),
		account_parent(Child, Parent_Id)
	)
	;
	(
		nonvar(Parent_Id),
		account_id(Child, Child_Id),
		account_parent(Child, Parent_Id),
		member(Child, Accounts)
	).

account_direct_children(Accounts, Parent, Children) :-
	findall(
		Child,
		account_child_parent(Accounts, Child, Parent),
		Children
	).
	
account_by_role_nothrow(Accounts, Role, Account_Id) :-
	account_role(Account, Role),
	account_id(Account, Account_Id),
	member(Account, Accounts).

account_by_role(Accounts, Role, Account_Id) :-
	/* TODO: shouldn't cut after first result, otherwise we unnecessarily break order invariance in calling code. */
	(
		account_by_role_nothrow(Accounts, Role, Account_Id)
	->
		true
	;
		(
			pretty_term_string(Accounts, Accounts_Str),
			term_string(Role, Role_Str),
			gtrace,
			format(atom(Err), 'account not found in hierarchy: ~w\n known accounts : ~w \n', [Role_Str, Accounts_Str]),
			format(user_error, Err, []),
			throw_string(Err)
		)
	).

account_by_role(Role, Account_Id) :-
	doc(T, rdf:type, l:request),
	doc(T, l:accounts, Accounts),
	account_by_role(Accounts, Role, Account_Id).


account_term_by_role(Accounts, Role, Account) :-
	member(Account, Accounts),
	account_role(Account, Role).
	
account_term_by_id(Accounts, Id, Account) :-
	account_id(Account, Id),
	member(Account, Accounts).

account_role_by_id(Accounts, Id, Role) :-
	account_term_by_id(Accounts, Id, Account),
	account_role(Account, Role).


/* @Bob fixme, we should be getting this info from the taxonomy */
account_normal_side(Account_Hierarchy, Name, credit) :-
	member(Credit_Side_Account_Id, ['Liabilities', 'Equity', 'Revenue']),
	once(account_in_set(Account_Hierarchy, Name, Credit_Side_Account_Id)),
	!.
account_normal_side(Account_Hierarchy, Name, debit) :-
	member(Credit_Side_Account_Id, ['Expenses']),
	once(account_in_set(Account_Hierarchy, Name, Credit_Side_Account_Id)),
	!.
account_normal_side(Account_Hierarchy, Name, credit) :-
	member(Credit_Side_Account_Id, ['Earnings', 'NetIncomeLoss']),
	once(account_in_set(Account_Hierarchy, Name, Credit_Side_Account_Id)),
	!.
account_normal_side(_, _, debit).


sub_accounts_upto_level(Accounts, Parent, Level, Sub_Accounts) :-
	sub_accounts_upto_level2(Accounts, [Parent], Level, [], Sub_Accounts).

sub_accounts_upto_level2(_, _, 0, Results, Results).
sub_accounts_upto_level2(_, [], _, Results, Results).

sub_accounts_upto_level2(Accounts, [Parent|Parents], Level, In, Out) :-
	Level > 0,
	New_Level is Level - 1,
	account_direct_children(Accounts, Parent, Children),
	append(In, Children, Mid),
	sub_accounts_upto_level2(Accounts, Children, New_Level, Mid, Mid2),
	sub_accounts_upto_level2(Accounts, Parents, Level, Mid2, Out).

	
child_accounts(Accounts, Parent_Account, Child_Accounts) :-
	sub_accounts_upto_level(Accounts, Parent_Account, 1, Child_Accounts).


/*
check that each account has a parent. Together with checking that each generated transaction has a valid account,
this should ensure that the account balances we are getting with the new taxonomy is correct*/
check_account_parent(Accounts, Account) :-
	account_id(Account, Id),
	(	Id == 'accountHierarchy'
	->	true
	;	(
			account_parent(Account, Parent),
			(
				Parent == 'accountHierarchy'
			->
				true
			;
				(
					account_exists(Accounts, Parent)
				->
					true
				;
					throw_string(['account "', Id, '" parent "', Parent, '" missing.'])
				)
			)
		)
	).

write_accounts_json_report(Accounts) :-	
	maplist(account_to_dict, Accounts, Dicts),
	write_tmp_json_file(loc(file_name,'accounts.json'), Dicts).

account_to_dict(Account, Dict) :-
	Dict = _{
		id: Id,
		parent: Parent,
		role: Role,
		detail_level: Detail_Level
	},
	Account = account(Id, Parent, Role, Detail_Level).

	

account_children(Sd, Account, Children) :-
	findall(Ch, account_child_parent(Sd.accounts, Ch, Account), Children).

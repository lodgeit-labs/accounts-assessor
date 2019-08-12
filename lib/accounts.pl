% ===================================================================
% Project:   LodgeiT
% Module:    accounts.pl
% Date:      2019-06-02
% ===================================================================

:- module(accounts, [
		/*The public api.*/
		/*The rest of the codebase should never deal with account terms directly, only handle them by id or role, so i am leaving out the "_id" where possible. 
		All these predicates take and return id's or roles, and require that Accounts is passed to them as first argument*/
		account_in_set/3, 
		account_by_role/3, 
		account_by_role_nothrow/3, 
		account_child_parent/3,
		account_exists/2,
		account_role_by_id/3,
		account_detail_level/3,
		account_normal_side/3,
		sub_accounts_upto_level/4,
		child_accounts/3,
		/*extract account tree specified in request xml*/
		extract_account_hierarchy/2, 
		check_account_parent/2,

		/*The private api.*/
		/*accessors of account term fields*/
		account_id/2,
		account_role/2,
		account_parent/2, 
		account_detail_level/2,
		/*you don't need this*/
		account_term_by_role/3]).

:- use_module(library(http/http_client)).
:- use_module(library(record)).
:- use_module(library(xpath)).
:- use_module('utils', [inner_xml/3, trim_atom/2,pretty_term_string/2, throw_string/1]).
:- use_module('../lib/files', [server_public_url/1, my_tmp_file_name/2	,store_xml_document/2
]).


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
	member(Account, Accounts).
	
account_detail_level(Accounts, Id, Detail_Level) :-
	account_term_by_id(Accounts, Id, Account),
	account_detail_level(Account, Detail_Level).
	
% Relates an account to an ancestral account or itself
account_in_set(Accounts, Account_Id, Root_Account_Id) :-
	Account_Id = Root_Account_Id;
	(
		member(Child_Account, Accounts),
		account_id(Child_Account, Child_Id),
		account_parent(Child_Account, Root_Account_Id),
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
		member(Child, Accounts),
		account_id(Child, Child_Id),
		account_parent(Child, Parent_Id)
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
	(
		account_by_role_nothrow(Accounts, Role, Account_Id)
	->
		true
	;
		(
			pretty_term_string(Accounts, Accounts_Str),
			term_string(Role, Role_Str),
			gtrace,
			format(atom(Err), 'accounts: ~w \naccount not found in hierarchy: ~w\n', [Accounts_Str,  Role_Str]),
			format(user_error, Err, []),
			throw_string(Err)
		)
	).

account_term_by_role(Accounts, Role, Account) :-
	member(Account, Accounts),
	account_role(Account, Role).
	
account_term_by_id(Accounts, Id, Account) :-
	account_id(Account, Id),
	member(Account, Accounts).

account_role_by_id(Accounts, Id, Role) :-
	account_term_by_id(Accounts, Id, Account),
	account_role(Account, Role).

	
extract_account_hierarchy(Request_Dom, Account_Hierarchy) :-
	(
			xpath(Request_Dom, //reports/balanceSheetRequest/accountHierarchy, Account_Hierarchy_Dom)
		->
			true
		;
		(
			(
				inner_xml(Request_Dom, //reports/balanceSheetRequest/accountHierarchyUrl, [Account_Hierarchy_Url0])
			->
				(
					trim_atom(Account_Hierarchy_Url0, Account_Hierarchy_Url),
					fetch_account_hierarchy_from_url(Account_Hierarchy_Url, Dom)
				)
			;
				(
					false,
					xpath(Request_Dom, //reports/'link:schemaRef', element(_,Attributes,_)),
					member('xlink:href'=Taxonomy_URL,Attributes),
					extract_account_hierarchy_from_taxonomy(Taxonomy_URL,Dom)
				)
				-> 
					true
				;
				(
					/*server_public_url(Server_Url),
					atomic_list_concat([Server_Url, '/taxonomy/basic.xsd'],Taxonomy_URL),
					format(user_error, 'loading default taxonomy from ~w\n', [Taxonomy_URL]),
					extract_account_hierarchy_from_taxonomy(Taxonomy_URL,Dom)
					*/
					%("loading default account hierarchy"),
					absolute_file_name(my_static('default_account_hierarchy.xml'), Default_Account_Hierarchy_File, [ access(read) ]),
					load_xml(Default_Account_Hierarchy_File, Dom, [])
					
				)
			)
		),
		xpath(Dom, //accountHierarchy, Account_Hierarchy_Dom)
	),
	extract_account_hierarchy2(Account_Hierarchy_Dom, Account_Hierarchy).
         
fetch_account_hierarchy_from_url(Account_Hierarchy_Url, Account_Hierarchy_Dom) :-
   /*fixme: throw something more descriptive here and produce a human-level error message at output*/
   http_get(Account_Hierarchy_Url, Account_Hierarchy_Xml_Text, []),
   /*fixme: load xml directly from xml text, storing should be optional*/
   % load_structure(Account_Hierarchy_Xml_Text, Account_Hierarchy_Dom,[dialect(xml)]).
   my_tmp_file_name('fetched_account_hierarchy.xml', Fetched_File),
   store_xml_document(Fetched_File, Account_Hierarchy_Xml_Text),
   load_xml(Fetched_File, Account_Hierarchy_Dom, []).

extract_account_hierarchy_from_taxonomy(Taxonomy_URL, Account_Hierarchy_DOM) :-
	setup_call_cleanup(
		% might want to do better than hardcoding the path to the script
		process_create(path(python3),['../xbrl/account_hierarchy/src/main.py',Taxonomy_URL],[stdout(pipe(Out))]),
		(
			load_structure(Out,Account_Hierarchy_DOM,[dialect(xml)]),
			my_tmp_file_name('account_hierarchy_from_taxonomy.xml', FN),
			open(FN, write, Stream),
			xml_write(Stream, Account_Hierarchy_DOM, [])
		),
		close(Out)
	).	

% ------------------------------------------------------------------
% extract_account_hierarchy2/2
%
% Load Account Hierarchy terms from Dom
% ------------------------------------------------------------------

extract_account_hierarchy2(Account_Hierarchy_Dom, Account_Hierarchy) :-
   %findall(Account, xpath(Account_Hierarchy_Dom, *, Account), Accounts),
   findall(Link, yield_accounts(Account_Hierarchy_Dom, Link), Account_Hierarchy0),
   sort(Account_Hierarchy0, Account_Hierarchy).

 
% extracts and yields all accounts one by one
yield_accounts(element(Parent_Name,_,Children), Link) :-
	member(Child, Children), 
	Child = element(Child_Name,_,_),
	(
		(
			/* todo: extract role, if specified */
			Role = ('Accounts' / Child_Name),
			Link = account(Child_Name, Parent_Name, Role, 0)
		)
		;
		(
			% recurse on the child
			yield_accounts(Child, Link)
		)
	).

account_normal_side(Account_Hierarchy, Name, credit) :-
	member(Credit_Side_Account_Id, ['Liabilities', 'Equity', 'Revenue']),
	once(account_in_set(Account_Hierarchy, Name, Credit_Side_Account_Id)),
	!.
account_normal_side(Account_Hierarchy, Name, debit) :-
	member(Credit_Side_Account_Id, ['Expenses']),
	once(account_in_set(Account_Hierarchy, Name, Credit_Side_Account_Id)),
	!.
account_normal_side(Account_Hierarchy, Name, credit) :-
	member(Credit_Side_Account_Id, ['Earnings']),
	once(account_in_set(Account_Hierarchy, Name, Credit_Side_Account_Id)),
	!.
account_normal_side(_, _, debit).


sub_accounts_upto_level(Accounts, Parent, Level, Sub_Accounts) :-
	sub_accounts_upto_level2(Accounts, [Parent], Level, [], Sub_Accounts).

sub_accounts_upto_level2(Accounts, [Parent|Parents], Level, In, Out) :-
	(
		Level > 0
	->
		(
			New_Level is Level - 1,
			account_direct_children(Accounts, Parent, Children),
			append(In, Children, Mid),
			sub_accounts_upto_level2(Accounts, Children, New_Level, Mid, Mid2),
			sub_accounts_upto_level2(Accounts, Parents, Level, Mid2, Out)
		)
	;
		In = Out
	).
	
sub_accounts_upto_level2(_, [], _, Results, Results).

child_accounts(Accounts, Parent_Account, Child_Accounts) :-
	sub_accounts_upto_level(Accounts, Parent_Account, 1, Child_Accounts).


check_account_parent(Accounts, Account) :-
	account_id(Account, Id),
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
	).

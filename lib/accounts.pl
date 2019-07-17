% ===================================================================
% Project:   LodgeiT
% Module:    accounts.pl
% Date:      2019-06-02
% ===================================================================

:- module(accounts, [
		extract_account_hierarchy/2, 
		account_in_set/3, 
		account_by_role/3, 
		account_by_id/3, 
		account_parent/2, 
		account_role/2,
		account_id/2,
		account_detail_level/2,
		account_exists/2]).

:- use_module(library(http/http_client)).
:- use_module(library(record)).
:- use_module(library(xpath)).
:- use_module('utils', [inner_xml/3, trim_atom/2]).
:- use_module('../lib/files', []).


/*
currently we have just a proof-of-concept level of referencing accounts, simply by names

what i understand is that both account names and account numbers can change
at least the logic does not seem to ever need to care about the structure of the tree, only about identifying appropriate accounts
so what i see we need is a user interface and a simple xml schema to express associations between accounts and their roles in the system
the roles can have unique names, and later URLs, in the whole set of programs
.
<role name="Livestock sales revenue" account="4321">
mostly it is a matter of creating a user interface to specify these associations
the program can also create sub-accounts from the specified account in runtime as needed, for example for livestock types
then each account hierarchy can come with a default set of associations
first we should settle on a way to identify accounts and specify the hierarchy for the prolog side
i suppose using the accounts.json format is the way to go
right now we identify just by names and load just from the simple xml */


:- record account(id, parent, role, detail_level).


account_exists(Accounts, Id) :-
	account_id(Account, Id),
	member(Account, Accounts).
	

% Relates an account to an ancestral account or itself
account_in_set(Accounts, Account_Id, Root_Account_Id) :-
	Account_Id = Root_Account_Id;
	(
		member(Child_Account, Accounts),
		account_id(Child_Account, Child_Id),
		account_parent(Child_Account, Root_Account_Id),
		account_in_set(Accounts, Account_Id, Child_Id)
	).


account_by_role(Accounts, Role, Account) :-
	member(Account, Accounts),
	account_role(Account, Role).

account_by_id(Accounts, Id, Account) :-
	member(Account, Accounts),
	account_id(Account, Id).


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
					%("loading default account hierarchy"),
					absolute_file_name(my_static('account_hierarchy.xml'), Default_Account_Hierarchy_File, [ access(read) ]),
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
   my_tmp_file_name('fetched_account_hierarchy.xml', Fetched_File),
   store_xml_document(Fetched_File, Account_Hierarchy_Xml_Text),
   load_xml(Fetched_File, Account_Hierarchy_Dom, []).
  
% ------------------------------------------------------------------
% extract_account_hierarchy2/2
%
% Load Account Hierarchy terms from Dom
% ------------------------------------------------------------------

extract_account_hierarchy2(Account_Hierarchy_Dom, Account_Hierarchy) :-   
   findall(Account, xpath(Account_Hierarchy_Dom, *, Account), Accounts),
   findall(Link, (member(Top_Level_Account, Accounts), yield_accounts(Top_Level_Account, Link)), Account_Hierarchy).

 
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


movement_unit_account(Accounts, Movement_Account, Unit) :-
	member(Account, Accounts),
	account_role(Account, Movement_Account/Unit).
	
gains_movement_account(Accounts, Gains_Account, Movement) :-
	member(Account, Accounts),
	account_role(Account, Gains_Account/Movement).

trading_gains_account(Accounts, Trading_Account, Realized_Or_Unrealized) :-
	member(Account, Accounts),
	account_role(Account, Trading_Account/Realized_Or_Unrealized).



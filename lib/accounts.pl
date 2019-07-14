% ===================================================================
% Project:   LodgeiT
% Module:    accounts.pl
% Date:      2019-06-02
% ===================================================================

:- module(accounts, [account_parent_id/3, account_in_subset/3, account_ids/9, extract_account_hierarchy/2]).

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


:- record account(id, parent, role).


account_exists(Accounts, Id) :-
	account_id(Account, Id),
	member(Account, Accounts).
	

% Relates an account to an ancestral account or itself

account_in_subset(Accounts, Account_Id, Ancestor_Id) :-
	Account_Id = Ancestor_Id;
	(account_parent(Accounts, Ancestor_Child_Id, Ancestor_Id),
	account_in_subset(Accounts, Account_Id, Ancestor_Child_Id)).


account_by_role(Accounts, Role, Account) :-
	member(Account, Accounts),
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
   store_xml_document('tmp/account_hierarchy.xml', Account_Hierarchy_Xml_Text),
   load_xml('tmp/account_hierarchy.xml', Account_Hierarchy_Dom, []).
  
% ------------------------------------------------------------------
% extract_account_hierarchy2/2
%
% Load Account Hierarchy terms from Dom
% ------------------------------------------------------------------

extract_account_hierarchy2(Account_Hierarchy_Dom, Account_Hierarchy) :-   
   findall(Account, xpath(Account_Hierarchy_Dom, *, Account), Accounts),
   findall(Link, (member(Top_Level_Account, Accounts), yield_accounts(Top_Level_Account, Link)), Account_Hierarchy).

 
% yields all child-parent pairs describing the account hierarchy
yield_accounts(element(Parent_Name,_,Children), Link) :-
	member(Child, Children), 
	Child = element(Child_Name,_,_),
	(
		(
			(
				member(Child_Name, ['Assets', 'Equity', 'Liabilities', 'Earnings', 'Current_Earnings', 'Retained_Earnings', 'Revenue', 'Expenses']),
				Role = ('Accounts' / Child_Name),
				!
			)
			;
				Role = ''
		),
		Link = account(Child_Name, Parent_Name, Role)
	)
	;
	(
		% recurse on the child
		yield_accounts(Child, Link)
	).



/*   
   finding and making accounts
*/ 
 
bank_account_names(S_Transactions, Names) :-
	findall(
		Bank_Account_Name,
		(
			member(T, S_Transactions),
			s_transaction_account_id(T, Bank_Account_Name)
		),
		Names0
	),
	sort(Names0, Names).

/*
given all s_transactions, produce all bank accounts we need to add.
bank accounts have role Accounts/(Name)
we will only eventually add this account if an account with same role doesn't already exist
*/

make_bank_account(Name, Account) :-
	account_id(Account, Name),
	account_parent(Account, 'Cash_And_Cash_Equivalents'),
	account_role(Account, ('Accounts'/Name)).

make_bank_accounts(S_Transactions, New_Accounts) :-
	bank_account_names(S_Transactions, Bank_Account_Names),
	maplist(make_bank_account, Bank_Account_Names, New_Accounts).

traded_units(S_Transactions, Transaction_Types, Units_Out) :-
	findall(
		Unit,
		(
			member(T, S_Transactions),
			transaction_type_of(Transaction_Types, S_Transaction, Transaction_Type)
			Transaction_Type = transaction_type(_, _, Trading_Account_Id, _),
			transaction_vector(T, [coord(Unit,_,_)])
		),
		Units
	),
	sort(Units,Units_Out).

trading_account_ids(Transaction_Types, Ids) :-
	findall(
		Trading_Account_Id,
		(
			member(T, Transaction_Types),
			T = transaction_type(_, _, Trading_Account_Id, _)
		),
		Ids0
	),
	sort(Ids0,Ids).



ensure_gains_accounts_exist(Accounts_In, S_Transactions, Transaction_Types, Gains_Accounts) :-
	/* trading accounts are expected to be in user input. */
	trading_account_ids(Transaction_Types, Trading_Account_Ids),
	/* each unit gets its own sub-account in each category */
	traded_units(S_Transactions, Transaction_Types, Units),
	/* create realized and unrealized gains accounts for each trading account*/
	maplist(roles_tree(Accounts_In, [[realized, unrealized], [without_currency_movement, only_currency_movement], Units], Trading_Account_Ids, Gains_Accounts).


roles_tree(Accounts_In, [Roles|Roles_Tail], Parent_Id, Accounts_Out) :-
	maplist(ensure_account_exists(Accounts_In, Parent_Id), Roles, Child_Accounts)),
	maplist(roles_tree(Accounts_Mid, Parent_Id, Roles_Tail, Child_Accounts, Grandchild_Accounts),
	flatten([Child_Accounts, Grandchild_Accounts], Accounts_Out).

ensure_account_exists(Accounts_In, Parent_Id, Child_Role, Account) :-
	Role = (Parent_Id/Child_Role),
	(
		(account_by_role(Accounts, Role, Account),!)
	;
		(
			account_role(Account, Role),
			account_parent(Account, Parent_Id),
			account_id(Account, Free_Id),
			atomic_list_concat([Parent_Id, '_', Child_Role], Id),
			free_id(Id, Free_Id)
		)
	).
	

add_movement_account(Accounts_In, Gains_Account, With_Or_Without, Account) :-
	Role = (Gains_Account/With_Or_Without),
	(
		(account_by_role(Accounts, Role, Account),!)
	;
		(
			account_role(Account, Role),
			account_parent(Account, Trading_Account_Id),
			account_id(Account, Free_Id),
			free_id(Id, Free_Id)
		)
	).

add_gains_account(Accounts, Realized_Or_Unrealized, Trading_Account_Id, Account) :-
	Role = (Trading_Account_Id/Realized_Or_Unrealized),
	(
		(account_by_role(Accounts, Role, Account),!)
		;
		(
			account_role(Account, Role),
			account_parent(Account, Trading_Account_Id),
			account_id(Account, Free_Id),
			free_id(Id, Free_Id)
		)
	).
	
			

investment_accounts(S_Transactions, Transaction_Types, Accounts_In, New_Accounts) :-
	trading_accounts(S_Transactions, Transaction_Type, Trading_Accounts),
	traded_units(S_Transactions, Transaction_Type, Units)
	findall(
		Accounts,
		(
			member(Trading_Account, Trading_Accounts),
			Trading_Account_Role 
			
			Accounts = [Realized, Unrealized],
			
			Role0 = ('Accounts'/Trading_Account),
			account_id(Account, Name),
			account_parent(Account, Parent),
			account_role(Account, New_Account_Role),
			account_by_role(Accounts, ('Accounts'/'Cash_And_Cash_Equivalents'), Parent)			
		),
		Gains_Accounts
	),
	flatten(Used_Accounts_Nested, Used_Accounts),
	findall(
		Account,
		(
			member(Account, Used_Accounts),
			\+member(Account, Accounts_In)
		),
		New_Accounts
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


/* 
	if an account with id Id is found, append _2 and try again,
	otherwise bind Free_Id to Id.
*/
free_id(Accounts, Id, Free_Id) :-
		account_by_id(Accounts, Id)
	->
		(
			atomic_list_concat([Id, '_2'], Next_Id),
			free_id(Accounts, Next_Id, Free_Id)
		)
	;
		Free_Id = Id
	).


add_trading_accounts(Accounts_In, Accounts_Out) :-
	add_gains_accounts(Transaction_Types, Accounts_In, Accounts2),
	add_movement_accounts(Transaction_Types, Accounts2, Accounts3),
	
	
	

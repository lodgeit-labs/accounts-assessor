% ===================================================================
% Project:   LodgeiT
% Module:    accounts.pl
% Date:      2019-06-02
% ===================================================================

:- module(accounts, [account_parent_id/3, account_ancestor_id/3, account_ids/9, extract_account_hierarchy/2, cogs_account/2, sales_account/2]).

:- use_module(library(http/http_client)).
:- use_module('utils', [inner_xml/3]).

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
right now we identify just by names and load just from the simple xml i showed you
i would make these changes incrementally as needed, as usage scenarios are identified, rather than over-enginner it up-front
*/


% --------------------------------------------------------------------
% Predicates for asserting that the fields of given accounts have particular values

% The ID of the given account
account_id(account(Account_Id, _), Account_Id).
% The ID of the parent of the given account
account_parent_id(account(_, Account_Parent_Id), Account_Parent_Id).
% Relates an account id to a parent account id
account_parent_id(Accounts, Account_Id, Parent_Id) :-
	account_parent_id(Account, Parent_Id),
	account_id(Account, Account_Id),
	member(Account, Accounts).
	

% Relates an account to an ancestral account
% or itself, so this should rather be called subset or somesuch

account_ancestor_id(Accounts, Account_Id, Ancestor_Id) :-
	Account_Id = Ancestor_Id;
	(account_parent_id(Accounts, Ancestor_Child_Id, Ancestor_Id),
	account_ancestor_id(Accounts, Account_Id, Ancestor_Child_Id)).

% Gets the ids for the assets, equity, liabilities, earnings, retained earnings, current
% earnings, revenue, and expenses accounts. 
account_ids(_Accounts,
      'Assets', 'Equity', 'Liabilities', 'Earnings', 'RetainedEarnings', 'CurrentEarningsLosses', 'Revenue', 'Expenses').

cogs_account(Livestock_Type, CogsAccount) :-
	atom_concat(Livestock_Type, 'Cogs', CogsAccount).

sales_account(Livestock_Type, SalesAccount) :-
	atom_concat(Livestock_Type, 'Sales', SalesAccount).

extract_account_hierarchy(Request_Dom, Account_Hierarchy) :-
   (
      (
         inner_xml(Request_Dom, //reports/balanceSheetRequest/accountHierarchyUrl, [Account_Hierarchy_Url]), 
         fetch_account_hierarchy_from_url(Account_Hierarchy_Url, Account_Hierarchy_Dom), !
      )
      ;
         load_xml('./taxonomy/account_hierarchy.xml', Account_Hierarchy_Dom, [])
   ),
   extract_account_hierarchy2(Account_Hierarchy_Dom, Account_Hierarchy).

fetch_account_hierarchy_from_url(Account_Hierarchy_Url, Account_Hierarchy_Dom) :-
   http_get(Account_Hierarchy_Url, Account_Hierarchy_Xml_Text, []),
   store_xml_document('tmp/account_hierarchy.xml', Account_Hierarchy_Xml_Text),
   load_xml('tmp/account_hierarchy.xml', Account_Hierarchy_Dom, []).
  
% ------------------------------------------------------------------
% extract_account_hierarchy2/2
%
% Load Account Hierarchy terms from Dom
% ------------------------------------------------------------------

extract_account_hierarchy2(Account_Hierarchy_Dom, Account_Hierarchy) :-   
   % fixme when input format is agreed on
   findall(Account, xpath(Account_Hierarchy_Dom, //accounts, Account), Accounts),
   findall(Link, (member(Top_Level_Account, Accounts), accounts_link(Top_Level_Account, Link)), Account_Hierarchy).

 
% yields all child-parent pairs describing the account hierarchy
accounts_link(element(Parent_Name,_,Children), Link) :-
   member(Child, Children), 
   Child = element(Child_Name,_,_),
   (
      % yield an account(Child, Parent) term for this child
      Link = account(Child_Name, Parent_Name)
      ;
      % recurse on the child
      accounts_link(Child, Link)
   ).

   
   
   

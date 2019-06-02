% ===================================================================
% Project:   LodgeiT
% Module:    accounts.pl
% Date:      2019-06-02
% ===================================================================

:- module(accounts, [account_parent_id/3, account_ids/9]).


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


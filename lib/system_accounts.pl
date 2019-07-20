:- module(system_accounts, [generate_system_accounts/3, trading_account_ids/2]).

:- use_module('accounts', [
		account_term_by_role/3, 
		account_exists/2,
		account_role/2, 
		account_id/2, 
		account_parent/2,
		account_detail_level/2]).
:- use_module('livestock', [
		make_livestock_accounts/2]).
:- use_module('statements', [
		s_transaction_account_id/2,
		s_transaction_type_of/3,
		s_transaction_vector/2,
		s_transaction_exchanged/2]).
:- use_module('utils', [
		without_nonalphanum_chars/2]).
/*	
Take the output of find_or_add_required_accounts and filter out existing accounts by role. 
Change id's to unique if needed.
We could present this as a proposal to the user to add these accounts. But here we will do it immediately.
*/
generate_system_accounts(Info, Accounts_In, Accounts_Out) :-
	find_or_add_required_accounts(Info, Accounts_In, Accounts_With_Generated_Accounts),
	findall(
		Account,
		(
			member(Account, Accounts_With_Generated_Accounts),
			account_id(Account, Account_Id),
			account_id(Possibly_Already_Existing_Account, Account_Id),
			\+member(Possibly_Already_Existing_Account, Accounts_In)
		),
		Accounts_Out
	).

	
find_or_add_required_accounts((S_Transactions, Livestock_Types, Transaction_Types), Accounts_In, Accounts_Out) :-
	make_bank_accounts(Accounts_In, S_Transactions, Bank_Accounts),
	make_currency_movement_accounts(Accounts_In, Bank_Accounts, Currency_Movement_Accounts),
	maplist(make_livestock_accounts, Livestock_Types, Livestock_Accounts),
	ensure_gains_accounts_exist(Accounts_In, S_Transactions, Transaction_Types, Gains_Accounts),
	flatten([Bank_Accounts, Currency_Movement_Accounts, Livestock_Accounts, Gains_Accounts], Accounts_Out).

	

/* all bank account names required by all S_Transactions */ 
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

ensure_bank_account_exists(Accounts_In, Name, Account) :-
	ensure_account_exists(Accounts_In, 'Cash_And_Cash_Equivalents', 0, ('Cash_And_Cash_Equivalents'/Name), Account).
	
/*
given all s_transactions, produce all bank accounts we need to add.
bank accounts have role Accounts/(Name)
we will only eventually add this account if an account with same role doesn't already exist
*/
make_bank_accounts(Accounts_In, S_Transactions, New_Accounts) :-
	bank_account_names(S_Transactions, Bank_Account_Names),
	maplist(
		ensure_bank_account_exists(Accounts_In),
		Bank_Account_Names, 
		New_Accounts
	).

	
make_currency_movement_accounts(Accounts_In, Bank_Accounts, Currency_Movement_Accounts) :-
	maplist(make_currency_movement_account(Accounts_In), Bank_Accounts, Currency_Movement_Accounts).

make_currency_movement_account(Accounts_In, Bank_Account, Currency_Movement_Account) :-
	account_id(Bank_Account, Bank_Account_Id),
	ensure_account_exists(Accounts_In, 'Currency_Movement', 0, ('Currency_Movement'/Bank_Account_Id), Currency_Movement_Account).
	
	
/*
return all units that appear in s_transactions with an action type that specifies a trading account
*/
traded_units(S_Transactions, Transaction_Types, Units_Out) :-
	findall(
		Unit,
		yield_traded_units(Transaction_Types, S_Transactions, Unit),
		Units
	),
	sort(Units, Units_Out).

yield_traded_units(Transaction_Types, S_Transactions, Unit) :-
	member(S_Transaction, S_Transactions),
	s_transaction_type_of(Transaction_Types, S_Transaction, Transaction_Type),
	Transaction_Type = transaction_type(_, _, _Trading_Account_Id, _),
	(
		s_transaction_exchanged(S_Transaction, vector([coord(Unit,_,_)]))
		;
		s_transaction_exchanged(S_Transaction, bases(Unit))
	).
		
	
trading_account_ids(Transaction_Types, Ids) :-
	findall(
		Trading_Account_Id,
		(
			member(T, Transaction_Types),
			T = transaction_type(_, _, Trading_Account_Id, _),
			nonvar(Trading_Account_Id)
		),
		Ids0
	),
	sort(Ids0, Ids).
/*
ensure_accounts_exist should produce a list of account terms that must exist for the system to work. This will include both accounts found 
in user input account hierarchy and generated ones. The reason that it also returns the found ones is that that makes it easier to traverse
the tree and add missing accounts recursively. It should generate naive ids - not checked for uniqueness with user input.

i am introducing the concept of a role of an account. If a trading account Financial_Investments already contains 
an account with id Financial_Investments_realized, either it has to have a role Financial_Investments/realized,
or is not recognized as such, and a new one with proper role is proposed. This allows us to abstract away from ids,
because Financial_Investments_realized might already be an id of another user account.
*/

ensure_gains_accounts_exist(Accounts_In, S_Transactions, Transaction_Types, Accounts_Out) :-
	/* trading accounts are expected to be in user input. */
	trading_account_ids(Transaction_Types, Trading_Account_Ids),
	/* each unit gets its own sub-account in each category */
	traded_units(S_Transactions, Transaction_Types, Units),
	/* create realized and unrealized gains accounts for each trading account*/
	maplist(
		roles_tree(
			Accounts_In, 
			[
				([realized, unrealized], 0), 
				([without_currency_movement, only_currency_movement], 0),
				(Units, 1)
			]
		), 
		Trading_Account_Ids, 
		All_Accounts),
	flatten(All_Accounts, All_Accounts2),
	sort(All_Accounts2, All_Accounts3),%fixme
	subtract(All_Accounts3, Accounts_In, Accounts_Out).


roles_tree(
	Accounts_In, 
	[Roles_And_Detail_Levels|Roles_Tail], 
	Parent_Id, 
	Accounts_Out
) :-
	(Child_Roles, Detail_Level) = Roles_And_Detail_Levels, 
	findall(
		(Parent_Id/Child_Role),
		member(Child_Role, Child_Roles),
		Roles
	),
	maplist(ensure_account_exists(Accounts_In, Parent_Id, Detail_Level), Roles, System_Accounts),
	flatten([Accounts_In, System_Accounts], Accounts_Mid),
	findall(
		System_Account_Id,
		(
			member(System_Account, System_Accounts),
			account_id(System_Account, System_Account_Id)
		),
		System_Account_Ids
	),			
	maplist(
		roles_tree(
			Accounts_Mid, 
			Roles_Tail
		),
		System_Account_Ids, 
		Grandchild_Accounts
	),
	flatten([Accounts_Mid, Grandchild_Accounts], Accounts_Out).

roles_tree(_, [], _, []).
	
ensure_account_exists(Accounts_In, Parent_Id, Detail_Level, Role, Account) :-
	Role = (_/Child_Role_Raw),
	(
		(account_term_by_role(Accounts_In, Role, Account),!)
	;
		(
			without_nonalphanum_chars(Child_Role_Raw, Child_Role_Safe),
			atomic_list_concat([Parent_Id, '_', Child_Role_Safe], Id),
			free_id(Accounts_In, Id, Free_Id),
			account_role(Account, Role),
			account_parent(Account, Parent_Id),
			account_id(Account, Free_Id),
			account_detail_level(Account, Detail_Level)
		)
	).
			
/* 
	if an account with id Id is found, append _2 and try again,
	otherwise bind Free_Id to Id.
*/
free_id(Accounts, Id, Free_Id) :-
		account_exists(Accounts, Id)
	->
		(
			atomic_list_concat([Id, '_2'], Next_Id),
			free_id(Accounts, Next_Id, Free_Id)
		)
	;
		Free_Id = Id.


/*

	retrieving bank accounts from doc

*/

bank_account(Account) :-
	request_has_property(l:bank_account, Account).

bank_accounts(Accounts) :-
	findall(Account, bank_account(Account), Accounts).

bank_account_name(Name) :-
	bank_account(Account),
	doc(Account, l:name, Name).

bank_account_names(Names) :-
	findall(Name, bank_account_name(Name), Names0),
	sort(Names0, Names).

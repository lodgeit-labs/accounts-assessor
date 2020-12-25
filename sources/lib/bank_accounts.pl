
/*
╻   ┏┓ ┏━┓┏┓╻╻┏    ┏━┓┏━╸┏━╸┏━┓╻ ╻┏┓╻╺┳╸
┃  ╹┣┻┓┣━┫┃┗┫┣┻┓   ┣━┫┃  ┃  ┃ ┃┃ ┃┃┗┫ ┃
┗━╸╹┗━┛╹ ╹╹ ╹╹ ╹╺━╸╹ ╹┗━╸┗━╸┗━┛┗━┛╹ ╹ ╹
l:bank_account doc properties were asserted when reading request xml
*/

bank_account(Account) :-
	result_has_property(l:bank_account, Account).

bank_account_name(Name) :-
	bank_account(Account),
	doc(Account, l:name, Name).

bank_account_names(Names) :-
	findall(Name, bank_account_name(Name), Names0),
	sort(Names0, Names).

/* all bank account names required by all S_Transactions */
/*bank_account_names(S_Transactions, Names) :-
	findall(
		Bank_Account_Name,
		(
			member(T, S_Transactions),
			s_transaction_account(T, Bank_Account_Name)
		),
		Names0
	),
	sort(Names0, Names).
*/

bank_accounts(Accounts) :-
	findall(Account, bank_account(Account), Accounts).


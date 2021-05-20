
/*
╻   ┏┓ ┏━┓┏┓╻╻┏    ┏━┓┏━╸┏━╸┏━┓╻ ╻┏┓╻╺┳╸
┃  ╹┣┻┓┣━┫┃┗┫┣┻┓   ┣━┫┃  ┃  ┃ ┃┃ ┃┃┗┫ ┃
┗━╸╹┗━┛╹ ╹╹ ╹╹ ╹╺━╸╹ ╹┗━╸┗━╸┗━┛┗━┛╹ ╹ ╹
l:bank_account doc properties were asserted when reading request xml
*/

 bank_account(Account) :-
	result_property(l:bank_account, Account).

 bank_account_name(Name) :-
	bank_account(Account),
	doc(Account, l:name, Name).

 bank_account_names(Names) :-
	findall(Name, bank_account_name(Name), Names0),
	sort(Names0, Names).

 bank_accounts(Accounts) :-
	findall(Account, bank_account(Account), Accounts).


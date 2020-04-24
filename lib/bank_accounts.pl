
/*
╻   ┏┓ ┏━┓┏┓╻╻┏    ┏━┓┏━╸┏━╸┏━┓╻ ╻┏┓╻╺┳╸
┃  ╹┣┻┓┣━┫┃┗┫┣┻┓   ┣━┫┃  ┃  ┃ ┃┃ ┃┃┗┫ ┃
┗━╸╹┗━┛╹ ╹╹ ╹╹ ╹╺━╸╹ ╹┗━╸┗━╸┗━┛┗━┛╹ ╹ ╹
l:bank_account doc properties were asserted when reading request xml
*/

bank_account(Account) :-
	request_has_property(l:bank_account, Account).

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

/*
┏┓ ┏━┓┏┓╻╻┏    ┏━╸╻     ┏━┓┏━╸┏━╸┏━┓╻ ╻┏┓╻╺┳╸┏━┓
┣┻┓┣━┫┃┗┫┣┻┓   ┃╺┓┃     ┣━┫┃  ┃  ┃ ┃┃ ┃┃┗┫ ┃ ┗━┓
┗━┛╹ ╹╹ ╹╹ ╹╺━╸┗━┛┗━╸╺━╸╹ ╹┗━╸┗━╸┗━┛┗━┛╹ ╹ ╹ ┗━┛
asset GL accounts corresponding to bank accounts
*/

ensure_bank_gl_accounts_exist :-
	bank_account_names(Bank_Account_Names),
	maplist(ensure_bank_gl_account_exists, Bank_Account_Names, Bank_Gl_Account),
	maplist(ensure_currency_movement_account_exists, Bank_Gl_Account).

ensure_bank_gl_account_exists(Name, Account) :-
	ensure_account_exists('Banks', _, 1, ('Banks'/Name), Account).

ensure_currency_movement_account_exists(Bank_Gl_Account) :-
	account_role(Bank_Gl_Account, (_/Bank_name)),
	ensure_account_exists('CurrencyMovement', _, 0, ('CurrencyMovement'/Bank_name), _).

bank_gl_accounts(Bank_Accounts) :-
	findall(A, account_by_role(A, ('Banks'/_Bank_Account_Name)), Bank_Accounts).

bank_gl_account_currency_movement_account(Bank_Gl_Account, Currency_Movement_Account) :-
	account_role(Bank_Gl_Account, (_/Bank_name)),
	account_by_role(('CurrencyMovement'/Bank_name), Currency_Movement_Account).


 extract_s_transactions0(Dom, S_Transactions) :-
 	assertion(Dom = [element(_,_,_)]),
	!extract_bank_accounts(Dom),
	!generate_bank_opening_balances_sts(Bank_Lump_STs),
	!handle_additional_files(S_Transactions0),
	!extract_s_transactions(Dom, S_Transactions1),
	!flatten([Bank_Lump_STs, S_Transactions0, S_Transactions1], S_Transactions2),
	!sort_s_transactions(S_Transactions2, S_Transactions).

extract_bank_accounts(Dom) :-
	findall(Account, xpath(Dom, //reports/balanceSheetRequest/bankStatement/accountDetails, Account), Bank_accounts),
	maplist(!extract_bank_account, Bank_accounts).

extract_bank_account(Account) :-
	!fields(Account, [
		accountName, Account_Name,
		currency, Account_Currency]),
	!numeric_fields(Account, [
		openingBalance, (Opening_Balance_Number, 0)]),
	Opening_Balance = coord(Account_Currency, Opening_Balance_Number),
	!doc_new_uri(bank_account, Uri),
	!request_add_property(l:bank_account, Uri),
	!doc_add(Uri, l:name, Account_Name),
	(	Opening_Balance_Number \= 0
	->	!doc_add_value(Uri, l:opening_balance, Opening_Balance)
	;	true).

generate_bank_opening_balances_sts(Txs) :-
	result(R),
	findall(Bank_Account, docm(R, l:bank_account, Bank_Account), Bank_Accounts),
	maplist(!generate_bank_opening_balances_sts2, Bank_Accounts, Txs0),
	exclude(var, Txs0, Txs).

generate_bank_opening_balances_sts2(Bank_Account, Tx) :-
	(	doc_value(Bank_Account, l:opening_balance, Opening_Balance)
	->	(
			!request_has_property(l:start_date, Start_Date),
			!add_days(Start_Date, -1, Opening_Date),
			!doc(Bank_Account, l:name, Bank_Account_Name),
			!doc_add_s_transaction(
				Opening_Date,
				'Bank_Opening_Balance',
				[Opening_Balance],
				Bank_Account_Name,
				vector([]),
				misc{desc2:'Bank_Opening_Balance'},
				Tx)
		)
	).

generate_bank_opening_balances_sts2(Bank_Account, _Tx) :-
	\+doc_value(Bank_Account, l:opening_balance, _Opening_Balance).

/*
┏┓ ┏━┓┏┓╻╻┏    ┏━┓┏━╸┏━╸┏━┓╻ ╻┏┓╻╺┳╸   ┏━╸╻ ╻╻┏━┓╺┳╸┏━╸┏┓╻┏━╸┏━╸
┣┻┓┣━┫┃┗┫┣┻┓   ┣━┫┃  ┃  ┃ ┃┃ ┃┃┗┫ ┃    ┣╸ ┏╋┛┃┗━┓ ┃ ┣╸ ┃┗┫┃  ┣╸
┗━┛╹ ╹╹ ╹╹ ╹   ╹ ╹┗━╸┗━╸┗━┛┗━┛╹ ╹ ╹    ┗━╸╹ ╹╹┗━┛ ╹ ┗━╸╹ ╹┗━╸┗━╸
*/

'extract bank accounts' :-
	request_data(D),
	format(user_error, '~q~n', [D]),
 	(	doc(D, ic:bank_statement, Accounts)
 	->	(
 			doc_list_items(Accounts, I),
 			maplist(!cf('extract bank account'), I)
 		)
	;	true
	).

'extract bank account'(Acc) :-
	push_format('extract bank account from: ~w', [$>sheet_and_cell_string(Acc)]),
	!doc_new_uri(bank_account, Uri),
	!result_add_property(l:bank_account, Uri),

	atom_string(Account_Currency, $>rpv(Acc, bs:account_currency)),
	assertion(atom(Account_Currency)),
	!doc_add(Uri, l:currency, Account_Currency),

	rpv(Acc, bs:items, Raw_items_list0),
	doc_list_items(Raw_items_list0, Raw_items0),
	length(Raw_items0, L),
	(	L < 1
	->	throw_string('bank statement must specify opening balance')
	;	true),
	[First_row|Raw_items1] = Raw_items0,
	check_first_row(First_row),
	%gtrace,
	!doc_add(Uri, l:raw_items, Raw_items1),

	rpv(First_row, bs:bank_balance, Opening_balance_number),
	(is_numeric(Opening_balance_number)->true;throw_string('opening balance: number expected')),
	Opening_balance = coord(Account_Currency, Opening_balance_number),
	!doc_add_value(Uri, l:opening_balance, Opening_balance),

	atom_string(Account_Name, $>rpv(Acc, bs:account_name)),
	(atom(Account_Name)->true;throw_string('account_name: atom expected')),
	!doc_add(Uri, l:name, Account_Name),
	pop_context.

check_first_row(First_row) :-
	(	(
			doc(First_row, bs:transaction_description, Row_0_verb)
		)
	->	(
			!doc(Row_0_verb, rdf:value, Row_0_verb_value),
			(	Row_0_verb_value = "This is Opening Balance"
				->	true
				;	(	!sheet_and_cell_string(Row_0_verb, Cell_str),
						throw_format('expected "This is Opening Balance" in ~w', [Cell_str])
					)
			)
		)
	;	true).



/*
┏━┓┏━┓┏━╸┏┓╻╻┏┓╻┏━╸   ┏┓ ┏━┓╻  ┏━┓┏┓╻┏━╸┏━╸┏━┓
┃ ┃┣━┛┣╸ ┃┗┫┃┃┗┫┃╺┓   ┣┻┓┣━┫┃  ┣━┫┃┗┫┃  ┣╸ ┗━┓
┗━┛╹  ┗━╸╹ ╹╹╹ ╹┗━┛   ┗━┛╹ ╹┗━╸╹ ╹╹ ╹┗━╸┗━╸┗━┛
(extracted separately)
*/
generate_bank_opening_balances_sts(Txs) :-
	result(R),
	findall(Bank_Account, docm(R, l:bank_account, Bank_Account), Bank_Accounts),
	maplist(!generate_bank_opening_balances_sts2, Bank_Accounts, Txs0),
	exclude(var, Txs0, Txs).

generate_bank_opening_balances_sts2(Bank_Account, Tx) :-
	(	doc_value(Bank_Account, l:opening_balance, Opening_Balance)
	->	(
			!result_has_property(l:start_date, Start_Date),
			!add_days(Start_Date, -1, Opening_Date),
			!doc(Bank_Account, l:name, Bank_Account_Name),
			!c(doc_add_s_transaction(
				Opening_Date,
				'Bank_Opening_Balance',
				[Opening_Balance],
				bank_account_name(Bank_Account_Name),
				vector([]),
				misc{desc2:'Bank_Opening_Balance'},
				Tx))
		)
	).

generate_bank_opening_balances_sts2(Bank_Account, _Tx) :-
	\+doc_value(Bank_Account, l:opening_balance, _Opening_Balance).

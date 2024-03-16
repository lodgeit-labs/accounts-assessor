/*
┏┓ ┏━┓┏┓╻╻┏    ┏━┓┏━╸┏━╸┏━┓╻ ╻┏┓╻╺┳╸   ┏━╸╻ ╻╻┏━┓╺┳╸┏━╸┏┓╻┏━╸┏━╸
┣┻┓┣━┫┃┗┫┣┻┓   ┣━┫┃  ┃  ┃ ┃┃ ┃┃┗┫ ┃    ┣╸ ┏╋┛┃┗━┓ ┃ ┣╸ ┃┗┫┃  ┣╸
┗━┛╹ ╹╹ ╹╹ ╹   ╹ ╹┗━╸┗━╸┗━┛┗━┛╹ ╹ ╹    ┗━╸╹ ╹╹┗━┛ ╹ ┗━╸╹ ╹┗━╸┗━╸
*/

 'extract bank accounts' :-
 	maplist('extract bank accounts 2', [ic_ui:bank_statement_sheet, ic:bank_statement]).


 'extract bank accounts 2'(Type) :-
 	*get_sheets_data(Type, Bs),
 	!maplist(!cf('extract bank statement'(Type)), Bs).


 'extract bank statement'(Type, Acc) :-
 	push_format('extract bank statement from: ~w', [$>sheet_and_cell_string(Acc)]),
	!doc_new_uri(bank_account, Uri),
	!result_add_property(l:bank_account, Uri),

	atom_string(Account_Currency, $>rpv(Acc, bs:account_currency)),
	assertion(atom(Account_Currency)),
	ct(currency(Account_Currency)),
	!doc_add(Uri, l:currency, Account_Currency),
	!doc_add(Uri, l:source, Acc),
	!doc_add(Uri, l:source_type, Type),

	rpv(Acc, bs:items, Raw_items_list0),
	doc_list_items(Raw_items_list0, Raw_items0),

	(	Type == ic_ui:bank_statement_sheet
	->	(
			length(Raw_items0, L),
			(	L < 1
			->	throw_string('bank statement must specify opening balance')
			;	true),
			[First_row|Raw_items1] = Raw_items0,
			check_first_row(First_row)
		)
	;	Raw_items1 = Raw_items0)
	,

	!doc_add(Uri, l:raw_items, Raw_items1),

	(	(	Type == ic_ui:bank_statement_sheet
		->	opv(First_row, bs:bank_balance, Opening_balance_number)
		;	opv(Acc, bs:opening_balance, Opening_balance_number))
	->	(	is_numeric(Opening_balance_number)
		->	true
		;	throw_string('opening balance: number expected'))
	;	Opening_balance_number = 0),

	(	{Opening_balance_number = 0}
	->	true
	;	(
			result_property(l:report_currency, Report_currency),
			(	[Account_Currency] = Report_currency
			->	true
			;	throw_string('opening balance cannot be specified for account in foreign currency, the account must start at zero'))
		)
	),
	Opening_balance = coord(Account_Currency, Opening_balance_number),
	!doc_add_value(Uri, l:opening_balance, Opening_balance),

	atom_string(Account_Name, $>rpv(Acc, bs:account_name)),
	!doc_add(Uri, l:name, Account_Name),
	pop_context.



 check_first_row(First_row) :-
	(	(
			doc(First_row, bs:transaction_description, Row_0_verb)
		)
	->	(
			!doc(Row_0_verb, rdf:value, Row_0_verb_value0),
			trim_string(Row_0_verb_value0, Row_0_verb_value),
			(	member(Row_0_verb_value, ["This is Opening Balance", "Opening Balance", "Bank_Opening_Balance"])
			->	true
			;	(	!sheet_and_cell_string(Row_0_verb, Cell_str),
					throw_format('expected "This is Opening Balance" in ~w', [Cell_str])
				)
			)
		)
	;	true
	).



/*
┏━┓┏━┓┏━╸┏┓╻╻┏┓╻┏━╸   ┏┓ ┏━┓╻  ┏━┓┏┓╻┏━╸┏━╸┏━┓
┃ ┃┣━┛┣╸ ┃┗┫┃┃┗┫┃╺┓   ┣┻┓┣━┫┃  ┣━┫┃┗┫┃  ┣╸ ┗━┓
┗━┛╹  ┗━╸╹ ╹╹╹ ╹┗━┛   ┗━┛╹ ╹┗━╸╹ ╹╹ ╹┗━╸┗━╸┗━┛
(extracted separately)
*/
 generate_bank_opening_balances_sts(Txs) :-
	result(R),
	findall(Bank_Account, *doc(R, l:bank_account, Bank_Account), Bank_Accounts),
	maplist(!generate_bank_opening_balances_sts2, Bank_Accounts, Txs0),
	exclude(var, Txs0, Txs).

 generate_bank_opening_balances_sts2(Bank_Account, Tx) :-
	(	(
			doc_value(Bank_Account, l:opening_balance, Opening_Balance),
			\+coord_is_almost_zero(Opening_Balance)
		)
	->	(
			!doc(Bank_Account, l:name, Bank_Account_Name),
			!c(doc_add_s_transaction(
				date(1,1,1),
				%Opening_Date,
				'Bank_Opening_Balance',
				[Opening_Balance],
				bank_account_name(Bank_Account_Name),
				vector([]),
				misc{desc2:'Bank_Opening_Balance'},
				Tx))
		)
	;	true
	).
/*
 generate_bank_opening_balances_sts2(Bank_Account, _Tx) :-
	\+doc_value(Bank_Account, l:opening_balance, _Opening_Balance).
*/




/*
┏━┓╺┳┓┏━╸
┣┳┛ ┃┃┣╸
╹┗╸╺┻┛╹
*/

'extract bank statement transactions'(S_Transactions) :-
	%format(user_error, '~q~n', ['extract bank statement transactions'(S_Transactions)]),

	findall(
		Acc,
		(
			bank_account(Acc),
			once(doc(Acc, l:raw_items, _))
		),
		Accts
	),
	maplist('extract bank statement transactions2', Accts, S_Transactions0),
	!flatten(S_Transactions0, S_Transactions2),
	maplist(!invert_s_transaction_vector, S_Transactions2, S_Transactions).

 'extract bank statement transactions2'(Acc, S_Transactions1) :-
	push_format('extract bank statement transactions from: ~w', [$>sheet_and_cell_string($>doc(Acc, l:source))]),
	!doc(Acc, l:currency, Account_Currency),
	!doc(Acc, l:name, Account_Name),
	!doc(Acc, l:raw_items, Items),
	!doc(Acc, l:source_type, Source_Type),
	!maplist('extract bank statement transaction'(Source_Type, Account_Currency, Account_Name), Items, S_Transactions0),
 	exclude(var, S_Transactions0, S_Transactions1),
	cf('bank statement transactions are ordered by date'(Acc, S_Transactions1)),
	pop_format.


 'bank statement transactions are ordered by date'(Acc, Sts) :-
 	'bank statement transactions are ordered by date2'(Acc, '', Sts).


 'bank statement transactions are ordered by date2'(_, _, []).

 'bank statement transactions are ordered by date2'(Acc, Last, [T1|Sts]) :-
 	s_transaction_day(T1, Day),
 	(	Last @=< Day
 	->	'bank statement transactions are ordered by date2'(Acc, Last, Sts)
 	;	(
			add_alert(
				'WARNING',
				$>format(
					string(<$),
					'transactions are not in date order in ~w',
					[$>sheet_and_cell_string($>doc(Acc, l:source))]
				),
				Alert
			),
			doc_add(Acc, l:has_alert, Alert)
		)
	).


 /* accept empty row */
 'extract bank statement transaction'(Source_Type, _, _, Item, _) :-
 	e(Source_Type, ic_ui:bank_statement_sheet),
	\+doc_value(Item, bs:transaction_description, _),
	\+read_date(Item, bs:bank_transaction_date, _),
	\+doc_value(Item,bs:units_count,_),
	\+doc_value(Item,bs:units_type,_),
	\+doc_value(Item,bs:transaction_description2,_),
	\+doc_value(Item,bs:debit,_),
	\+doc_value(Item,bs:credit,_),
	!.

'extract bank statement transaction'(_Source_Type, Account_Currency, Account_Name, Item, S_Transaction) :-
	push_format('extract bank statement transaction from: ~w', [$>sheet_and_cell_string(Item)]),
	atom_string(Action_verb_name, $>rpv(Item, bs:transaction_description)),
	!read_date(Item, bs:bank_transaction_date, Date),

	(doc_value(Item,bs:units_count,Units_count) -> true ; Units_count = nil(nil) ),

	(	doc_value(Item,bs:units_type,Units_type0)
	->	atom_string(Units_type, Units_type0)
	;	Units_type = nil(nil)),

	(doc_value(Item,bs:transaction_description2,Description2) -> true ; Description2='' ),

	( doc_value(Item,bs:debit,Bank_Debit) -> true ; Bank_Debit = 0 ),
	( doc_value(Item,bs:credit,Bank_Credit) -> true ; Bank_Credit = 0 ),
	Dr is rationalize(Bank_Debit - Bank_Credit),

	Coord = coord(Account_Currency, Dr),
	(	Dr < 0
	->	Money_side = kb:debit
	;	Money_side = kb:credit),

	!extract_exchanged_value2(Money_side, Units_type, Units_count, Exchanged),

	!doc_add_s_transaction(
		Date,
		Action_verb_name,
		[Coord],
		bank_account_name(Account_Name),
		Exchanged,
		misc{desc2:Description2},
		S_Transaction
	),
	!doc_add(S_Transaction, l:source, Item),
	pop_context.





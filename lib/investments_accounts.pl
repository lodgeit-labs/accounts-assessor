
/*
return all units that appear in s_transactions with an action type that specifies a trading account
*/
 traded_units(S_Transactions, Traded_Units) :-
	findall(Unit,traded_units2(S_Transactions, Unit),Units),
	sort(Units, Traded_Units).

 traded_units2(S_Transactions, Unit) :-
	member(S_Transaction, S_Transactions),
	s_transaction_exchanged(S_Transaction, E),
	(
		E = vector([coord(Unit,_)])
	;
		E = bases(Unit)
	).

 traded_units2(_, Unit) :-
 	%gtrace,
	request_data(D),
 	doc_value(D, ic:unit_types, Categorizations_table),
	doc_list_items(Categorizations_table, Categorizations),
	member(Categorization, Categorizations),
	doc_value(Categorization, ic:unit_type_name, Unit).

/*
	this gets names of "exchanged accounts", as specified in action verbs. Accounts are created based on that name, but the name may need to be adjusted. So don't use this to look accounts up, instead:
	findall(Account, abrlt('FinancialInvestments'/Name, Account), Accounts).
*/

financialInvestments_accounts_ui_names(Names) :-
	findall(
		A,
		(
			action_verb(Action_Verb),
			doc(Action_Verb, l:has_trading_account, _),
			(doc(Action_Verb, l:has_counteraccount, A)->true;throw('action verb has trading_account but no counteraccount'))
		),
		Ids0
	),
	sort(Ids0, Names).

investmentIncome_accounts(Names) :-
	findall(
		A,
		(
			action_verb(Action_Verb),
			doc(Action_Verb, l:has_trading_account, A)
		),
		Ids0
	),
	sort(Ids0, Names).



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

financialInvestments_accounts(Accounts) :-
	findall(
		A,
		(
			action_verb(Action_Verb),
			doc(Action_Verb, l:has_trading_account, _),
			doc(Action_Verb, l:has_exchanged_account, A)
		),
		Ids0
	),
	sort(Ids0, Ids),
	maplist(account_by_ui,Ids, Accounts).

investmentIncome_account_ids(Accounts) :-
	findall(
		A,
		(
			action_verb(Action_Verb),
			doc(Action_Verb, l:has_trading_account, A)
		),
		Ids0
	),
	sort(Ids0, Ids),
	maplist(account_by_ui,Ids, Accounts).


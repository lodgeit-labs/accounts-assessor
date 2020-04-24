
ensure_financial_investments_accounts_exist(Traded_Units) :-
	ensure_roles_tree_exists('FinancialInvestments', [(Traded_Units, 1)]).

ensure_investment_income_accounts_exist(Traded_Units) :-
	/* trading accounts are expected to be in user input. */
	trading_account_ids(Trading_Account_Ids),
	/* each unit gets its own sub-account in each category */
	/* create realized and unrealized gains accounts for each trading account*/
	maplist(
		ensure_roles_tree_exists(
			Trading_Account_Ids,
			[
				([realized, unrealized], 0),
				([withoutCurrencyMovement, onlyCurrencyMovement], 0),
				(Traded_Units, 1)
			]
		)).

/*
return all units that appear in s_transactions with an action type that specifies a trading account
*/
traded_units(S_Transactions, Traded_Units) :-
	findall(Unit,yield_traded_units(S_Transactions, Unit),Units),
	sort(Units, Traded_Units).

yield_traded_units(S_Transactions, Unit) :-
	member(S_Transaction, S_Transactions),
	s_transaction_exchanged(S_Transaction, E),
	(
		E = vector([coord(Unit,_)])
	;
		E = bases(Unit)
	).

trading_account_ids(Ids) :-
	findall(
		A,
		(
			action_verb(Action_Verb),
			doc(Action_Verb, l:has_trading_account, A)
		),
		Ids0
	),
	sort(Ids0, Ids).


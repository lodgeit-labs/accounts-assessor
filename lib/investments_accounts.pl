/*
┏━╸╻┏┓╻┏━┓┏┓╻┏━╸╻┏━┓╻  ╻┏┓╻╻ ╻┏━╸┏━┓╺┳╸┏┳┓┏━╸┏┓╻╺┳╸┏━┓
┣╸ ┃┃┗┫┣━┫┃┗┫┃  ┃┣━┫┃  ┃┃┗┫┃┏┛┣╸ ┗━┓ ┃ ┃┃┃┣╸ ┃┗┫ ┃ ┗━┓
╹  ╹╹ ╹╹ ╹╹ ╹┗━╸╹╹ ╹┗━╸╹╹ ╹┗┛ ┗━╸┗━┛ ╹ ╹ ╹┗━╸╹ ╹ ╹ ┗━┛
*/

ensure_financial_investments_accounts_exist(Traded_Units) :-
	account_by_role('Accounts'/'FinancialInvestments', FinancialInvestments),
	maplist(ensure_FinancialInvestments_Unit(FinancialInvestments), Traded_Units).

ensure_FinancialInvestments_Unit(FinancialInvestments, Traded_Unit) :-
	ensure_account_exists(FinancialInvestments, _, 1, 'FinancialInvestments'/Traded_Unit, _).

/* or alternatively: */
/*
ensure_financial_investments_accounts_exist(Traded_Units) :-
	ensure_roles_tree_exists('FinancialInvestments', [(Traded_Units, 1)]).
*/

/*
╻┏┓╻╻ ╻┏━╸┏━┓╺┳╸┏┳┓┏━╸┏┓╻╺┳╸╻┏┓╻┏━╸┏━┓┏┳┓┏━╸
┃┃┗┫┃┏┛┣╸ ┗━┓ ┃ ┃┃┃┣╸ ┃┗┫ ┃ ┃┃┗┫┃  ┃ ┃┃┃┃┣╸
╹╹ ╹┗┛ ┗━╸┗━┛ ╹ ╹ ╹┗━╸╹ ╹ ╹ ╹╹ ╹┗━╸┗━┛╹ ╹┗━╸
*/
/*experimentally naming predicates just "pxx" here for readability*/

'ensure InvestmentIncome accounts exist' :-
	trading_account_ids(Trading_Accounts),
	maplist(p10, Trading_Accounts).
p10(Trading_Account) :-
	maplist(p20(Trading_Account), [realized,unrealized]).
p20(Trading_Account, R) :-
	account_id(Trading_Account, Trading_Account_Id),
	ensure_account_exists(Trading_Account, _, 0, 'TradingAccounts'/Trading_Account_Id/R, Realization_account),
	maplist(p30(Trading_Account_Id, R, Realization_account), [withoutCurrencyMovement, onlyCurrencyMovement]).
p30(Trading_Account_Id, R, Realization_account, Cm) :-
	ensure_account_exists(Realization_account, _, 0, 'TradingAccounts'/Trading_Account_Id/R/Cm, Cm_account),
	traded_units(Traded_Units),
	maplist(p40(Trading_Account_Id,R,Cm,Cm_account), Traded_Units).
p40(Trading_Account_Id,R,Cm,Cm_account, Traded_Unit) :-
	ensure_account_exists(Cm_account, _, 1, 'TradingAccounts'/Trading_Account_Id/R/Cm/Traded_Unit, _).
/*
alternatively:
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
*/
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

trading_accounts(Accounts) :-
	findall(
		A,
		(
			action_verb(Action_Verb),
			doc(Action_Verb, l:has_trading_account, A)
		),
		Ids0
	),
	sort(Ids0, Ids),
	maplist(account_by_id(Ids, Accounts).


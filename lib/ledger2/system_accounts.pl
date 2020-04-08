ensure_bank_gl_account_exists(Name, Account) :-
	ensure_account_exists('Banks', 1, ('Banks'/Name), Account).

bank_gl_accounts(Bank_Accounts) :-
	findall(A, account_by_role(A, ('Banks'/_Bank_Account_Name)), Bank_Accounts).
	
ensure_currency_movement_account_exists(Bank_Gl_Account, Currency_Movement_Account) :-
	account_role(Bank_Gl_Account, (_/Role_Child)),
	ensure_account_exists('CurrencyMovement', 0, ('CurrencyMovement'/Role_Child), Currency_Movement_Account).

bank_gl_account_currency_movement_account(Bank_Gl_Account, Currency_Movement_Account) :-
	account_role(Bank_Gl_Account, (_/Bank_Child_Role)),
	account_by_role(('CurrencyMovement'/Bank_Child_Role), Currency_Movement_Account).

ensure_financial_investments_accounts_exist(S_Transactions) :-
	traded_units(S_Transactions, Units),
	ensure_roles_tree_exists('FinancialInvestments', [(Units, 1)]).

ensure_investment_income_accounts_exist(Accounts_In, S_Transactions, Accounts_Out) :-
	/* trading accounts are expected to be in user input. */
	trading_account_ids(Trading_Account_Ids),
	/* each unit gets its own sub-account in each category */
	traded_units(S_Transactions, Units),
	/* create realized and unrealized gains accounts for each trading account*/
	maplist(
		ensure_roles_tree_exists(
			Trading_Account_Ids,
			[
				([realized, unrealized], 0), 
				([withoutCurrencyMovement, onlyCurrencyMovement], 0),
				(Units, 1)
			]
		)),
	flatten(All_Accounts, All_Accounts2),
	sort(All_Accounts2, All_Accounts3),%fixme
	subtract(All_Accounts3, Accounts_In, Accounts_Out).



ensure_system_accounts_exists(S_Transactions) :-
	ensure_bank_gl_accounts_exist,
	ensure_livestock_accounts_exist,
	traded_units(S_Transactions, Traded_Units),
	ensure_financial_investments_accounts_exist(Traded_Units),
	'ensure InvestmentIncome accounts exist'(Traded_Units).



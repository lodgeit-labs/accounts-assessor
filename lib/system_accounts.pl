ensure_system_accounts_exists(S_Transactions) :-
	ensure_bank_gl_accounts_exist,
	ensure_livestock_accounts_exist,
	traded_units(S_Transactions, Traded_Units),
	ensure_financial_investments_accounts_exist(Traded_Units),
	'ensure InvestmentIncome accounts exist'(Traded_Units).

check_accounts_roles :-
	findall(Role, account_role(_, Role), Roles),
	(	ground(Roles)
	->	true
	;	throw_string(error)),
	(	sort(Roles, Roles)
	->	true
		/*todo better message */
	;	throw_string(['multiple accounts with same role found'])).


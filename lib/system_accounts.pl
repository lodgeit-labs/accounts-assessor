/*
╻┏━┓   ╻ ╻┏━┓╻  ╻╺┳┓   ┏━┓┏━┓╻  ┏━╸
┃┗━┓   ┃┏┛┣━┫┃  ┃ ┃┃   ┣┳┛┃ ┃┃  ┣╸
╹┗━┛╺━╸┗┛ ╹ ╹┗━╸╹╺┻┛╺━╸╹┗╸┗━┛┗━╸┗━╸
*/

% could be also called from make_account or account_set_role. the goal is that all code paths that construct roles will go through this.
% probably the semantics should be such that it can be skipped for optimization.
is_valid_role('TradingAccounts'/Trading_Account_Id/Realized_Or_Unrealized/Currency_Movement_Aspect/Traded_Unit) :-
	atom(Trading_Account_Id),
	member(Realized_Or_Unrealized, [realized, unrealized]),
	member(Currency_Movement_Aspect, [onlyCurrencyMovement, withoutCurrencyMovement]),
	atom(Traded_Unit).


/*
┏┳┓╻┏━┓┏━╸
┃┃┃┃┗━┓┃
╹ ╹╹┗━┛┗━╸
*/


abrlt(Role, Account) :-
	is_valid_role(Role),
	account_by_role_throw(Role, Account).

ensure_system_accounts_exist(S_Transactions) :-
	ensure_bank_gl_accounts_exist,
	ensure_livestock_accounts_exist,
	traded_units(S_Transactions, Traded_Units),
	ensure_financial_investments_accounts_exist(Traded_Units),
	'ensure InvestmentIncome accounts exist'(Traded_Units).

make_root_account :-
	make_account2(root, 0, rl(root), Root),
	format(user_error, 'root account:~q\n', [Root]).

get_root_account(Root) :-
	account_by_role_throw(rl(root), Root).

/*
┏┓ ┏━┓┏┓╻╻┏    ┏━╸╻     ┏━┓┏━╸┏━╸┏━┓╻ ╻┏┓╻╺┳╸┏━┓
┣┻┓┣━┫┃┗┫┣┻┓   ┃╺┓┃     ┣━┫┃  ┃  ┃ ┃┃ ┃┃┗┫ ┃ ┗━┓
┗━┛╹ ╹╹ ╹╹ ╹╺━╸┗━┛┗━╸╺━╸╹ ╹┗━╸┗━╸┗━┛┗━┛╹ ╹ ╹ ┗━┛
asset GL accounts corresponding to bank accounts
*/

ensure_bank_gl_accounts_exist :-
	bank_account_names(Bank_Account_Names),
	maplist(ensure_bank_gl_account_exists, Bank_Account_Names, Bank_Gl_Account),
	maplist(ensure_currency_movement_account_exists, Bank_Gl_Account).

ensure_bank_gl_account_exists(Name, Account) :-
	ensure_account_exists($>account_by_role_throw(rl('Banks')), _, 1, rl('Banks'/Name), Account).

ensure_currency_movement_account_exists(Bank_Gl_Account) :-
	/* get Bank_name from role. It would probably be cleaner to get it from the same source where we get it when creating the bank gl accounts */
	account_role(Bank_Gl_Account, rl(_/Bank_name)),
	ensure_account_exists($>account_by_role_throw(rl('CurrencyMovement')), _, 0, rl('CurrencyMovement'/Bank_name), _).

bank_gl_accounts(Bank_Accounts) :-
	findall(A, account_by_role(A, rl('Banks'/_Bank_Account_Name)), Bank_Accounts).

bank_gl_account_currency_movement_account(Bank_Gl_Account, Currency_Movement_Account) :-
	account_role(Bank_Gl_Account, rl(_/Bank_name)),
	account_by_role_throw(rl('CurrencyMovement'/Bank_name), Currency_Movement_Account).

bank_gl_account_by_bank_name(Account_Name, Uri) :-
	account_by_role_throw(rl('Banks'/Account_Name), Uri).

/*
╻  ╻╻ ╻┏━╸┏━┓╺┳╸┏━┓┏━╸╻┏    ┏━┓┏━╸┏━╸┏━┓╻ ╻┏┓╻╺┳╸┏━┓
┃  ┃┃┏┛┣╸ ┗━┓ ┃ ┃ ┃┃  ┣┻┓   ┣━┫┃  ┃  ┃ ┃┃ ┃┃┗┫ ┃ ┗━┓
┗━╸╹┗┛ ┗━╸┗━┛ ╹ ┗━┛┗━╸╹ ╹╺━╸╹ ╹┗━╸┗━╸┗━┛┗━┛╹ ╹ ╹ ┗━┛
create livestock-specific accounts that are missing in user account hierarchy.
*/

%:- comment(code:ensure_livestock_accounts_exist, code_topics:account_creation, "livestock accounts are created up-front.").

ensure_livestock_accounts_exist :-
	livestock_units(Units),
	maplist(ensure_livestock_accounts_exist2, Units).

ensure_livestock_accounts_exist2(Livestock_Type) :-
	cogs_account_id(Livestock_Type, Cogs_Name),
	sales_account_id(Livestock_Type, Sales_Name),
	count_account_id(Livestock_Type, Count_Name),
	cogs_rations_account_id(Livestock_Type, CogsRations_Name),

	account_by_role_throw(rl('CostOfGoodsLivestock'), CostOfGoodsLivestock),
	account_by_role_throw(rl('SalesOfLivestock'), SalesOfLivestock),
	account_by_role_throw(rl('LivestockCount'), LivestockCount),

	ensure_account_exists(CostOfGoodsLivestock, Cogs_Name, 0, rl('CostOfGoodsLivestock'/Livestock_Type), Cogs_uri),
	ensure_account_exists(SalesOfLivestock, Sales_Name, 0, rl('SalesOfLivestock'/Livestock_Type), _),
	ensure_account_exists(LivestockCount, Count_Name, 0, rl('LivestockCount'/Livestock_Type), _),
	ensure_account_exists(Cogs_uri, CogsRations_Name, 0, rl('CostOfGoodsLivestock'/Livestock_Type/'Rations'), _).

cogs_account_id(Livestock_Type, Cogs_Account) :-
	atom_concat(Livestock_Type, 'Cogs', Cogs_Account).

cogs_rations_account_id(Livestock_Type, Cogs_Rations_Account) :-
	atom_concat(Livestock_Type, 'CogsRations', Cogs_Rations_Account).

sales_account_id(Livestock_Type, Sales_Account) :-
	atom_concat(Livestock_Type, 'Sales', Sales_Account).

count_account_id(Livestock_Type, Count_Account) :-
	atom_concat(Livestock_Type, 'Count', Count_Account).

livestock_count_account(Livestock_Type, Count_Account) :-
	account_by_role_throw(rl('LivestockCount'/Livestock_Type), Count_Account).

livestock_sales_account(Livestock_Type, Sales_Account) :-
	account_by_role_throw(rl('SalesOfLivestock'/Livestock_Type), Sales_Account).

livestock_cogs_rations_account(Livestock_Type, Cogs_Rations_Account) :-
	account_by_role_throw(rl('CostOfGoodsLivestock'/Livestock_Type/'Rations'), Cogs_Rations_Account).

livestock_cogs_account(Livestock_Type, Cogs_Account) :-
	account_by_role_throw(rl('CostOfGoodsLivestock'/Livestock_Type), Cogs_Account).

/*
┏━╸╻┏┓╻┏━┓┏┓╻┏━╸╻┏━┓╻  ╻┏┓╻╻ ╻┏━╸┏━┓╺┳╸┏┳┓┏━╸┏┓╻╺┳╸┏━┓
┣╸ ┃┃┗┫┣━┫┃┗┫┃  ┃┣━┫┃  ┃┃┗┫┃┏┛┣╸ ┗━┓ ┃ ┃┃┃┣╸ ┃┗┫ ┃ ┗━┓
╹  ╹╹ ╹╹ ╹╹ ╹┗━╸╹╹ ╹┗━╸╹╹ ╹┗┛ ┗━╸┗━┛ ╹ ╹ ╹┗━╸╹ ╹ ╹ ┗━┛
in Assets
*/

ensure_financial_investments_accounts_exist(Traded_Units) :-
	financialInvestments_accounts(FinancialInvestments_accounts),
	maplist(ensure_financial_investments_accounts_exist2(Traded_Units), FinancialInvestments_accounts).

ensure_financial_investments_accounts_exist2(Traded_Units, FinancialInvestments_account) :-
	account_id(FinancialInvestments_account, Id),
	Role0 = rl('FinancialInvestments'/Id),
	account_by_role_throw(Role0, FinancialInvestments),
	maplist(ensure_FinancialInvestments_Unit(Role0, FinancialInvestments), Traded_Units).

ensure_FinancialInvestments_Unit(rl(Role0), FinancialInvestments, Traded_Unit) :-
	ensure_account_exists(FinancialInvestments, _, 1, rl(Role0/Traded_Unit), _).

financial_investments_account(Exchanged_Account_Uri,Goods_Unit,Exchanged_Account2) :-
	account_id(Exchanged_Account_Uri, Exchanged_Account_Id),
	/*note:we form role from id, so the id should be unique in this context. eg, if there are two different accounts with id "Investments", this will break. The alternative is to use full uri, or to introduce account codes, or similar. This problem goes all the way to the excel UI, where action verbs have fields for accounts. Id's are used, and we expect them to be unique, but account names in big hierarchies aren't unique. So how would a user specify an account unambiguously? Either specify the unique code directly, or the ui has to have a sheet with the mapping, or there has to be a menu item that makes a request to the endpoint to load taxonomies and return back some rdf with the mapping. */
	account_by_role_throw(rl('FinancialInvestments'/Exchanged_Account_Id/Goods_Unit), Exchanged_Account2).


/*
╻┏┓╻╻ ╻┏━╸┏━┓╺┳╸┏┳┓┏━╸┏┓╻╺┳╸╻┏┓╻┏━╸┏━┓┏┳┓┏━╸
┃┃┗┫┃┏┛┣╸ ┗━┓ ┃ ┃┃┃┣╸ ┃┗┫ ┃ ┃┃┗┫┃  ┃ ┃┃┃┃┣╸
╹╹ ╹┗┛ ┗━╸┗━┛ ╹ ╹ ╹┗━╸╹ ╹ ╹ ╹╹ ╹┗━╸┗━┛╹ ╹┗━╸
*/
/*experimentally naming predicates just "pxx" here for readability*/

'ensure InvestmentIncome accounts exist'(Traded_Units) :-
	investmentIncome_account_ids(Trading_Accounts),
	maplist(p10(Traded_Units), Trading_Accounts).
p10(Traded_Units, Trading_Account) :-
	maplist(p20(Traded_Units,Trading_Account), [realized,unrealized]).
p20(Traded_Units,Trading_Account, R) :-
	account_id(Trading_Account, Trading_Account_Id),
	ensure_account_exists(Trading_Account, _, 0, rl('TradingAccounts'/Trading_Account_Id/R), Realization_account),
	maplist(p30(Traded_Units, Trading_Account_Id, R, Realization_account), [withoutCurrencyMovement, onlyCurrencyMovement]).
p30(Traded_Units,Trading_Account_Id, R, Realization_account, Cm) :-
	ensure_account_exists(Realization_account, _, 0, rl('TradingAccounts'/Trading_Account_Id/R/Cm), Cm_account),
	maplist(p40(Trading_Account_Id,R,Cm,Cm_account), Traded_Units).
p40(Trading_Account_Id,R,Cm,Cm_account, Traded_Unit) :-
	ensure_account_exists(Cm_account, _, 1, rl('TradingAccounts'/Trading_Account_Id/R/Cm/Traded_Unit), _).

trading_sub_account(_Sd, (Movement_Account, Unit_Accounts)) :-
	investmentIncome_account_ids(Trading_Accounts),
	member(Trading_Account, Trading_Accounts),
	account_id(Trading_Account, Trading_Account_Id),
	account_by_role_throw(rl('TradingAccounts'/Trading_Account_Id/_/_), Movement_Account),
	account_direct_children(Movement_Account, Unit_Accounts).

gains_accounts(
	/*input*/ Trading_Account_Id, Realized_Or_Unrealized, Traded_Unit,
	/*output*/ Currency_Movement_Account, Excluding_Forex_Account
) :-
	abrlt('TradingAccounts'/Trading_Account_Id/Realized_Or_Unrealized/onlyCurrencyMovement/Traded_Unit, Currency_Movement_Account),
	abrlt('TradingAccounts'/Trading_Account_Id/Realized_Or_Unrealized/withoutCurrencyMovement/Traded_Unit, Excluding_Forex_Account).



/*

rl__TradingAccounts__Trading_Account_Id__Realized_Or_Unrealized__onlyCurrencyMovement__Traded_Unit(Trading_Account_Id/Realized_Or_Unrealized/withoutCurrencyMovement/Traded_Unit)

---or:

$>rc('TradingAccounts'/Trading_Account_Id/Realized_Or_Unrealized/withoutCurrencyMovement/Traded_Unit)
because:
rc(X,X) :- role(X).
and:
role('TradingAccounts'/Trading_Account_Id/Realized_Or_Unrealized/withoutCurrencyMovement/Traded_Unit).
or:
 :-
 	member(Realized_Or_Unrealized, [...]),
	if we segregate account lookup from creation, then during lookup only, we can have stricter checks:
	trading_account_id(Trading_Account_Id),

in pyco2, we would not separate lookup and creation.

*/

/*
╻┏━┓   ╻ ╻┏━┓╻  ╻╺┳┓   ┏━┓┏━┓╻  ┏━╸
┃┗━┓   ┃┏┛┣━┫┃  ┃ ┃┃   ┣┳┛┃ ┃┃  ┣╸
╹┗━┛╺━╸┗┛ ╹ ╹┗━╸╹╺┻┛╺━╸╹┗╸┗━┛┗━╸┗━╸
*/

% could be also called from make_account or account_set_role. the goal is that all code paths that construct roles will go through this.
% probably the semantics should be such that it can be skipped for optimization.


is_valid_role('Banks').
is_valid_role('Banks'/Id) :- freeze(Id, atom(Id)).

is_valid_role('TradingAccounts'/Trading_Account_Id) :-
	freeze(Trading_Account_Id, atom(Trading_Account_Id)).
is_valid_role('TradingAccounts'/_1387496/unrealized).
is_valid_role('TradingAccounts'/_1387572/realized).
is_valid_role('TradingAccounts'/_1387080/realized/withoutCurrencyMovement).
is_valid_role('TradingAccounts'/_1387168/realized/onlyCurrencyMovement).
is_valid_role('TradingAccounts'/_1387256/unrealized/withoutCurrencyMovement).
is_valid_role('TradingAccounts'/_1387344/unrealized/onlyCurrencyMovement).
is_valid_role('TradingAccounts'/Trading_Account_Id/Realized_Or_Unrealized/Currency_Movement_Aspect/Traded_Unit) :-
	freeze(Id, atom(Trading_Account_Id)),
	member(Realized_Or_Unrealized, [realized, unrealized]),
	member(Currency_Movement_Aspect, [onlyCurrencyMovement, withoutCurrencyMovement]),
	freeze(Id, atom(Traded_Unit)).

is_valid_role('ComprehensiveIncome').
is_valid_role('HistoricalEarnings').
is_valid_role('CurrentEarnings').
is_valid_role('NetAssets').
is_valid_role('Equity').
is_valid_role('CurrencyMovement').
is_valid_role('CurrencyMovement'/Id) :- freeze(Id, atom(Id)).
is_valid_role('CashAndCashEquivalents').
is_valid_role('FinancialInvestments'/Id) :- freeze(Id, atom(Id)).

/*
┏┳┓╻┏━┓┏━╸
┃┃┃┃┗━┓┃
╹ ╹╹┗━┛┗━╸
*/


 abrlt(Role, Account) :-

	%!is_valid_role(Role),

	!(	is_valid_role(Role)
	->	true
	;	(writeq(is_valid_role(Role)), write('.'), nl)),

	account_by_role_throw(rl(Role), Account).

 ensure_system_accounts_exist(S_Transactions) :-
	!ensure_bank_gl_accounts_exist,
	!subcategorize_by_bank,
	!ensure_livestock_accounts_exist,
	!traded_units(S_Transactions, Traded_units),
	!ensure_financial_investments_accounts_exist(Traded_units),
	!subcategorize_by_investment(Traded_units),
	!'ensure InvestmentIncome accounts exist'(Traded_units),
	!ensure_smsf_equity_tree,
	!subcategorize_by_smsf_members.

 make_root_account :-
	make_account2(root, 0, rl(root), _Root),
	%format(user_error, 'root account:~q\n', [Root])
	true.

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
	ensure_account_exists($>abrlt('Banks'), _, 1, rl('Banks'/Name), Account).

 ensure_currency_movement_account_exists(Bank_Gl_Account) :-
	/* get Bank_name from role. It would probably be cleaner to get it from the same source where we get it when creating the bank gl accounts */
	account_role(Bank_Gl_Account, rl(_/Bank_name)),
	ensure_account_exists($>abrlt('CurrencyMovement'), _, 0, rl('CurrencyMovement'/Bank_name), _).

 bank_gl_accounts(Bank_Accounts) :-
	findall(A, account_by_role(A, rl('Banks'/_Bank_Account_Name)), Bank_Accounts).

 bank_gl_account_currency_movement_account(Bank_Gl_Account, Currency_Movement_Account) :-
	account_role(Bank_Gl_Account, rl(_/Bank_name)),
	abrlt('CurrencyMovement'/Bank_name, Currency_Movement_Account).

 bank_gl_account_by_bank_name(Account_Name, Uri) :-
	account_by_role_throw(rl('Banks'/Account_Name), Uri).

%----

subcategorize_by_bank :-
 	findall(A, doc(A, accounts:subcategorize_by_bank, true, accounts), As),
 	maplist(subcategorize_by_bank3, As).

subcategorize_by_bank3(A) :-
	bank_account_names(Bank_Account_Names),
	maplist(subcategorize_by_bank6(A), Bank_Account_Names).

subcategorize_by_bank6(A, Bank_Account_Name) :-
	account_name(A, Name),
	ensure_account_exists(A, _, 1, rl(Name/Bank_Account_Name), _).


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
	financialInvestments_accounts_ui_names(Names),
	maplist(ensure_financial_investments_accounts_exist2(Traded_Units), Names).

 ensure_financial_investments_accounts_exist2(Traded_Units, Id) :-
	Role0 = 'FinancialInvestments'/Id,
	abrlt(Role0, FinancialInvestments),
	maplist(ensure_FinancialInvestments_Unit(Role0, FinancialInvestments), Traded_Units).

 ensure_FinancialInvestments_Unit(Role0, FinancialInvestments, Traded_Unit) :-
 	Rl = rl(Role0/Traded_Unit),
 	%format(user_error, 'ensure_FinancialInvestments_Unit: ~q\n', [Rl]),
	ensure_account_exists(FinancialInvestments, _, 1, Rl, _).

 financial_investments_account(Exchanged_Account_Uri,Goods_Unit,Exchanged_Account2) :-
	account_name(Exchanged_Account_Uri, Exchanged_Account_Id),
	account_by_role_throw(rl('FinancialInvestments'/Exchanged_Account_Id/Goods_Unit), Exchanged_Account2).

	/*note:we form role from id, so the id should be unique in this context. eg, if there are two different accounts with id "Investments", this will break. The alternative is to use full uri, or to introduce account codes, or similar. This problem goes all the way to the excel UI, where action verbs have fields for accounts. Id's are used, and we expect them to be unique, but account names in big hierarchies aren't unique. So how would a user specify an account unambiguously? Either specify the unique code directly, or the ui has to have a sheet with the mapping, or there has to be a menu item that makes a request to the endpoint to load taxonomies and return back some rdf with the mapping. */

%-----

 subcategorize_by_investment(Traded_units) :-
 	findall(A, doc(A, accounts:subcategorize_by_investment, true, accounts), As),
 	maplist(subcategorize_by_investment3(Traded_units), As).
 subcategorize_by_investment3(Traded_units, A) :-
 	account_name(A, Role_prefix),
	maplist(subcategorize_by_investment6(A, Role_prefix, Traded_units).
 subcategorize_by_investment6(A, Role_prefix, Unit) :-
 	account_name(A, A_name),
 	Role = rl(Role_prefix/A_name/Unit),
 	(
		(
			request_data(D),
			doc_value(D, ic:unit_types, Categorizations_table),
			doc_list_items(Categorizations_table, Categorizations),
			member(Categorization, Categorizations),
			doc(Categorization, ic:unit_type_name, Unit),
			doc(Categorization, ic:unit_type_category, Category)
		)
		->	(
				ensure_account_by_parent_and_name_exists(A, Category, L1),
				(	doc(Categorization, ic:unit_type_subcategory, Subategory)
				->	ensure_account_by_parent_and_name_exists(L1, Sub, Parent)
				;	Parent = L1)
			)
		;	Parent = A
	),
	ensure_account_by_parent_and_name_exists(Parent, Unit, rl(A/Unit), Unit_account).

 ensure_account_by_parent_and_name_exists(Parent, Name, Role, Uri) :-
	ensure_account_by_parent_and_name_exists(Parent, Name, Uri),
	doc_add(Uri, accounts:role, Role, accounts).

ensure_account_by_parent_and_name_exists(Parent, Name, Uri) :-
	(
		account_name(Uri, Name),
		account_parent(Uri, Parent)
	)
	->	true
	;	make_account_with_optional_role(Name, Parent, 1, _Role, Uri).

%------


/*
╻┏┓╻╻ ╻┏━╸┏━┓╺┳╸┏┳┓┏━╸┏┓╻╺┳╸╻┏┓╻┏━╸┏━┓┏┳┓┏━╸
┃┃┗┫┃┏┛┣╸ ┗━┓ ┃ ┃┃┃┣╸ ┃┗┫ ┃ ┃┃┗┫┃  ┃ ┃┃┃┃┣╸
╹╹ ╹┗┛ ┗━╸┗━┛ ╹ ╹ ╹┗━╸╹ ╹ ╹ ╹╹ ╹┗━╸┗━┛╹ ╹┗━╸
*/
/*experimentally naming predicates just "pxx" here for readability*/

 'ensure InvestmentIncome accounts exist'(Traded_Units) :-
 	(	Traded_Units = []
 	->	true
 	;	(
			!investmentIncome_accounts(Uis),
			maplist(p10(Traded_Units), Uis)
		)).
p10(Traded_Units, Uis) :-
	maplist(p20(Traded_Units,Uis), [realized,unrealized]).
p20(Traded_Units,Trading_Account_Id, R) :-
	abrlt('TradingAccounts'/Trading_Account_Id, Trading_Account),
	ensure_account_exists(Trading_Account, _, 0, rl('TradingAccounts'/Trading_Account_Id/R), Realization_account),
	maplist(p30(Traded_Units, Trading_Account_Id, R, Realization_account), [withoutCurrencyMovement, onlyCurrencyMovement]).
p30(Traded_Units,Trading_Account_Id, R, Realization_account, Cm) :-
	ensure_account_exists(Realization_account, _, 0, rl('TradingAccounts'/Trading_Account_Id/R/Cm), Cm_account),
	maplist(p40(Trading_Account_Id,R,Cm,Cm_account), Traded_Units).
p40(Trading_Account_Id,R,Cm,Cm_account, Traded_Unit) :-
	ensure_account_exists(Cm_account, _, 1, rl('TradingAccounts'/Trading_Account_Id/R/Cm/Traded_Unit), _).

 trading_sub_account((Movement_Account, Unit_Accounts)) :-
	account_by_role_throw(rl('TradingAccounts'/_/_/_), Movement_Account),
	account_direct_children(Movement_Account, Unit_Accounts).

 gains_accounts(
	/*input*/ Trading_Account, Realized_Or_Unrealized, Traded_Unit,
	/*output*/ Currency_Movement_Account, Excluding_Forex_Account
) :-
	account_role(Trading_Account, rl('TradingAccounts'/Id)),
	abrlt('TradingAccounts'/Id/Realized_Or_Unrealized/onlyCurrencyMovement/Traded_Unit, Currency_Movement_Account),
	abrlt('TradingAccounts'/Id/Realized_Or_Unrealized/withoutCurrencyMovement/Traded_Unit, Excluding_Forex_Account).



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



/*
┏━┓┏┳┓┏━┓┏━╸
┗━┓┃┃┃┗━┓┣╸
┗━┛╹ ╹┗━┛╹
*/

ensure_smsf_equity_tree :-
	(	account_by_role(smsf_equity, Equity)
	->	ensure_smsf_equity_tree3(Equity)
	;	true).

ensure_smsf_equity_tree3(Root) :-
	% find leaf accounts
	findall(A,
		(
			account_in_set(A, Root),
			\+account_parent(_. A)
		),
		As
	),
	maplist(ensure_smsf_equity_tree6, As).

ensure_smsf_equity_tree6(A) :-
	smsf_members_throw(Members),
	maplist(ensure_smsf_equity_tree6(A), Members).

ensure_smsf_equity_tree6(A, Member) :-
	account_name(A, Account),
	doc(Member, smsf:member_name, Member),
	ensure_account_exists(A, _, 1, (smsf_equity/Account/Member), _).


%-----

 subcategorize_by_smsf_members :-
 	findall(A, doc(A, accounts:subcategorize_by_smsf_member, true, accounts), As),
 	maplist(subcategorize_by_smsf_members3, As).

 subcategorize_by_smsf_members3(A) :-
	smsf_members_throw(Members),
	maplist(subcategorize_by_smsf_member(A), Members).

 subcategorize_by_smsf_member(A, Member) :-
	account_name(A, Account),
	doc(Member, smsf:member_name, Member),
	ensure_account_exists(A, _, 1, (Account/Member), _).

%------



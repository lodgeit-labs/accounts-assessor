/*note:we form roles from ids, so the id should be unique in this context. eg, if there are two different accounts with id "Investments", this will break. The alternative is to use full uri, or to introduce account codes, or similar. This problem goes all the way to the excel UI, where action verbs have fields for accounts. Id's are used, and we expect them to be unique, but account names in big hierarchies aren't unique. So how would a user specify an account unambiguously? Either specify the unique code directly, or the ui has to have a sheet with the mapping, or there has to be a menu item that makes a request to the endpoint to load taxonomies and return back some rdf with the mapping. */


/*
╻┏━┓   ╻ ╻┏━┓╻  ╻╺┳┓   ┏━┓┏━┓╻  ┏━╸
┃┗━┓   ┃┏┛┣━┫┃  ┃ ┃┃   ┣┳┛┃ ┃┃  ┣╸
╹┗━┛╺━╸┗┛ ╹ ╹┗━╸╹╺┻┛╺━╸╹┗╸┗━┛┗━╸┗━╸
*/

% could be also called from make_account or account_set_role. the goal is that all code paths that construct roles will go through this.
% probably the semantics should be such that it can be skipped for optimization.
% in the end, we have roles that are constructed from account names, so any atom is a valid role. This hinders checking.


is_valid_role('Banks') :- !.
is_valid_role('Banks'/Id) :- !,freeze(Id, atom(Id)).

is_valid_role('Trading_Accounts'/Trading_Account_Id) :- !,
	freeze(Trading_Account_Id, atom(Trading_Account_Id)).
is_valid_role('Trading_Accounts'/_1387496/unrealized) :- !.
is_valid_role('Trading_Accounts'/_1387572/realized) :- !.
is_valid_role('Trading_Accounts'/_1387080/realized/withoutCurrencyMovement) :- !.
is_valid_role('Trading_Accounts'/_1387168/realized/onlyCurrencyMovement) :- !.
is_valid_role('Trading_Accounts'/_1387256/unrealized/withoutCurrencyMovement) :- !.
is_valid_role('Trading_Accounts'/_1387344/unrealized/onlyCurrencyMovement) :- !.
is_valid_role('Trading_Accounts'/Trading_Account_Id/Realized_Or_Unrealized/Currency_Movement_Aspect/Traded_Unit) :-
	!,
	freeze(Id, atom(Trading_Account_Id)),
	member(Realized_Or_Unrealized, [realized, unrealized]),
	member(Currency_Movement_Aspect, [onlyCurrencyMovement, withoutCurrencyMovement]),
	freeze(Id, atom(Traded_Unit)).

is_valid_role('Comprehensive_Income') :- !.
is_valid_role('Historical_Earnings') :- !.
is_valid_role('Current_Earnings') :- !.
is_valid_role('Net_Assets') :- !.
is_valid_role('Equity') :- !.
is_valid_role('Currency_Movement') :- !.
is_valid_role('Currency_Movement'/Id) :- !, freeze(Id, atom(Id)).
is_valid_role('Cash_and_Cash_Equivalents') :- !.
is_valid_role('Financial_Investments'/Id) :- !, freeze(Id, atom(Id)).

/*
┏┳┓╻┏━┓┏━╸
┃┃┃┃┗━┓┃
╹ ╹╹┗━┛┗━╸
*/

/*
 acc(Role, Account) :-
	(	Role = name(Name)
	->	account_by_ui(Name, Account)
	;	abrlt(Role, Account).
*/
 abrlt(Role, Account) :-

	%!is_valid_role(Role),

	!(	is_valid_role(Role)
	->	true
	;	true/*format(user_error, '~q.~n', [is_valid_role(Role)])*/),

	account_by_role_throw(rl(Role), Account).

 'ensure system accounts exist'(S_Transactions) :-
	!cf(ensure_bank_gl_accounts_exist),
	!cf(subcategorize_by_bank),
	!cf(ensure_livestock_accounts_exist),
	!cf(traded_units(S_Transactions, Traded_units)),
	!cf(ensure_financial_investments_accounts_exist(Traded_units)),
	!cf(subcategorize_by_investment(Traded_units)),
	!cf(subcategorize_distribution_received),
	!cf('ensure Investment_Income accounts exist'(Traded_units)),
	!cf(ensure_smsf_equity_tree),
	!cf(subcategorize_by_smsf_members).

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
	ensure_account_exists($>abrlt('Currency_Movement'), _, 0, rl('Currency_Movement'/Bank_name), _).

 bank_gl_accounts(Bank_Accounts) :-
	findall(A, account_by_role(A, rl('Banks'/_Bank_Account_Name)), Bank_Accounts).

 bank_gl_account_currency_movement_account(Bank_Gl_Account, Currency_Movement_Account) :-
	account_role(Bank_Gl_Account, rl(_/Bank_name)),
	abrlt('Currency_Movement'/Bank_name, Currency_Movement_Account).

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

	account_by_role_throw(rl('Cost_of_Goods_Livestock'), Cost_of_Goods_Livestock),
	account_by_role_throw(rl('Sales_of_Livestock'), Sales_of_Livestock),
	account_by_role_throw(rl('Livestock_Count'), Livestock_Count),

	ensure_account_exists(Cost_of_Goods_Livestock, Cogs_Name, 0, rl('Cost_of_Goods_Livestock'/Livestock_Type), Cogs_uri),
	ensure_account_exists(Sales_of_Livestock, Sales_Name, 0, rl('Sales_of_Livestock'/Livestock_Type), _),
	ensure_account_exists(Livestock_Count, Count_Name, 0, rl('Livestock_Count'/Livestock_Type), _),
	ensure_account_exists(Cogs_uri, CogsRations_Name, 0, rl('Cost_of_Goods_Livestock'/Livestock_Type/'Rations'), _).

 cogs_account_id(Livestock_Type, Cogs_Account) :-
	atom_concat(Livestock_Type, 'Cogs', Cogs_Account).

 cogs_rations_account_id(Livestock_Type, Cogs_Rations_Account) :-
	atom_concat(Livestock_Type, 'CogsRations', Cogs_Rations_Account).

 sales_account_id(Livestock_Type, Sales_Account) :-
	atom_concat(Livestock_Type, 'Sales', Sales_Account).

 count_account_id(Livestock_Type, Count_Account) :-
	atom_concat(Livestock_Type, 'Count', Count_Account).

 livestock_count_account(Livestock_Type, Count_Account) :-
	account_by_role_throw(rl('Livestock_Count'/Livestock_Type), Count_Account).

 livestock_sales_account(Livestock_Type, Sales_Account) :-
	account_by_role_throw(rl('Sales_of_Livestock'/Livestock_Type), Sales_Account).

 livestock_cogs_rations_account(Livestock_Type, Cogs_Rations_Account) :-
	account_by_role_throw(rl('Cost_of_Goods_Livestock'/Livestock_Type/'Rations'), Cogs_Rations_Account).

 livestock_cogs_account(Livestock_Type, Cogs_Account) :-
	account_by_role_throw(rl('Cost_of_Goods_Livestock'/Livestock_Type), Cogs_Account).

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
	Role0 = 'Financial_Investments'/Id,
	!abrlt(Role0, Financial_Investments),
	!maplist(ensure_FinancialInvestments_Unit(Financial_Investments), Traded_Units).

 ensure_FinancialInvestments_Unit(Financial_Investments, Unit) :-
 	account_name(Financial_Investments, Name),
 	subcategorize_by_investment6(Financial_Investments, 'Financial_Investments'/Name, Unit).

%-----

 subcategorize_by_investment(Traded_units) :-
 	findall(A, doc(A, accounts:subcategorize_by_investment, true, accounts), As),
 	maplist(subcategorize_by_investment3(Traded_units), As).
 subcategorize_by_investment3(Traded_units, A) :-
 	account_name(A, Role_prefix),
	maplist(subcategorize_by_investment6(A, Role_prefix), Traded_units).
 subcategorize_by_investment6(A, Role_prefix, Unit) :-
 	Role = rl(Role_prefix/Unit),
 	(
		(
			request_data(D),
			doc_value(D, ic:unit_types, Categorizations_table),
			doc_list_items(Categorizations_table, Categorizations),
			member(Categorization, Categorizations),
			doc_value(Categorization, ic:unit_type_name, Unit_str),
			atom_string(Unit, Unit_str),
			doc_value(Categorization, ic:unit_type_category, Category_str),
			atom_string(Category, Category_str)
		)
		->	(
				ensure_account_by_parent_and_name_exists(A, Category, L1),
				(	doc_value(Categorization, ic:unit_type_subcategory, Subcategory_str)
				->	(
						atom_string(Subcategory, Subcategory_str),
						ensure_account_by_parent_and_name_exists(L1, Subcategory, Parent)
					)
				;	Parent = L1)
			)
		;	Parent = A
	),
	ensure_account_by_parent_and_name_exists(Parent, Unit, Role, _).

 ensure_account_by_parent_and_name_exists(Parent, Name, Role, Uri) :-
	ensure_account_by_parent_and_name_exists(Parent, Name, Uri),
	doc_add(Uri, accounts:role, Role, accounts).

 ensure_account_by_parent_and_name_exists(Parent, Name, Uri) :-
	(
		account_name(Uri, Name),
		account_parent(Uri, Parent)
	)
	->	true
	;	c(make_account_with_optional_role(Name, Parent, 1, _Role, Uri)).

%------

subcategorize_distribution_received :-
	findall(A, account_role(A, rl('Distribution_Revenue'/_)), As),
	maplist(subcategorize_distribution_received2, As).

subcategorize_distribution_received2(A) :-
	maplist(subcategorize_distribution_received4(A), [
		'Distribution_Cash',
		'Resolved_Accrual',
		'Foreign_Credit',
		'Franking_Credit',
		'TFN/ABN_Withholding_Tax'
	]).

subcategorize_distribution_received4(A, Subcategorization) :-
	account_role(A, rl('Distribution_Revenue'/Unit)),
	ensure_account_exists(A, Subcategorization, 1, rl('Distribution_Revenue'/Unit/Subcategorization), _).

%------

 financial_investments_account(Exchanged_Account_Uri,Goods_Unit,Exchanged_Account2) :-
	!account_name(Exchanged_Account_Uri, Exchanged_Account_Id),
	Rl = rl('Financial_Investments'/Exchanged_Account_Id/Goods_Unit),
 	push_context($>format(string(<$), 'find child account of ~q for unit ~q', [Exchanged_Account_Id, Goods_Unit])),
	account_by_role_throw(Rl, Exchanged_Account2),
	pop_context.

/*
╻┏┓╻╻ ╻┏━╸┏━┓╺┳╸┏┳┓┏━╸┏┓╻╺┳╸╻┏┓╻┏━╸┏━┓┏┳┓┏━╸
┃┃┗┫┃┏┛┣╸ ┗━┓ ┃ ┃┃┃┣╸ ┃┗┫ ┃ ┃┃┗┫┃  ┃ ┃┃┃┃┣╸
╹╹ ╹┗┛ ┗━╸┗━┛ ╹ ╹ ╹┗━╸╹ ╹ ╹ ╹╹ ╹┗━╸┗━┛╹ ╹┗━╸
*/
/*experimentally naming predicates just "pxx" here for readability*/

 'ensure Investment_Income accounts exist'(Traded_Units) :-
 	(	Traded_Units = []
 	->	true
 	;	(
			!cf(investmentIncome_accounts(Uis)),
			maplist(p10(Traded_Units), Uis)
		)).
p10(Traded_Units, Uis) :-
	maplist(p20(Traded_Units,Uis), [realized,unrealized]).
p20(Traded_Units,Trading_Account_Id, R) :-
	abrlt('Trading_Accounts'/Trading_Account_Id, Trading_Account),
	ensure_account_exists(Trading_Account, _, 0, rl('Trading_Accounts'/Trading_Account_Id/R), Realization_account),
	maplist(p30(Traded_Units, Trading_Account_Id, R, Realization_account), [withoutCurrencyMovement, onlyCurrencyMovement]).
p30(Traded_Units,Trading_Account_Id, R, Realization_account, Cm) :-
	ensure_account_exists(Realization_account, _, 0, rl('Trading_Accounts'/Trading_Account_Id/R/Cm), Cm_account),
	maplist(p40(Trading_Account_Id,R,Cm,Cm_account), Traded_Units).
p40(Trading_Account_Id,R,Cm,Cm_account, Traded_Unit) :-
	ensure_account_exists(Cm_account, _, 1, rl('Trading_Accounts'/Trading_Account_Id/R/Cm/Traded_Unit), _).

 trading_sub_account((Movement_Account, Unit_Accounts)) :-
	account_by_role(rl('Trading_Accounts'/_/_/_), Movement_Account),
	account_direct_children(Movement_Account, Unit_Accounts).

 gains_accounts(
	/*input*/ Trading_Account, Realized_Or_Unrealized, Traded_Unit,
	/*output*/ Currency_Movement_Account, Excluding_Forex_Account
) :-
	account_role(Trading_Account, rl('Trading_Accounts'/Id)),
	abrlt('Trading_Accounts'/Id/Realized_Or_Unrealized/onlyCurrencyMovement/Traded_Unit, Currency_Movement_Account),
	abrlt('Trading_Accounts'/Id/Realized_Or_Unrealized/withoutCurrencyMovement/Traded_Unit, Excluding_Forex_Account).



/*

rl__TradingAccounts__Trading_Account_Id__Realized_Or_Unrealized__onlyCurrencyMovement__Traded_Unit(Trading_Account_Id/Realized_Or_Unrealized/withoutCurrencyMovement/Traded_Unit)

---or:

$>rc('Trading_Accounts'/Trading_Account_Id/Realized_Or_Unrealized/withoutCurrencyMovement/Traded_Unit)
because:
rc(X,X) :- role(X).
and:
role('Trading_Accounts'/Trading_Account_Id/Realized_Or_Unrealized/withoutCurrencyMovement/Traded_Unit).
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
	(	account_by_role(rl(smsf_equity), Equity)
	->	ensure_smsf_equity_tree3(Equity)
	;	true).

ensure_smsf_equity_tree3(Root) :-
	% find leaf accounts
	findall(A,
		(
			account_in_set(A, Root),
			\+account_parent(_, A)
		),
		As
	),
	maplist(ensure_smsf_equity_tree6, As).

ensure_smsf_equity_tree6(A) :-
	!smsf_members_throw(Members),
	!account_name(A, Account),
	maplist(subcategorize_by_smsf_member((Account), A), Members).


%-----

 subcategorize_by_smsf_members :-
 	findall(A, doc(A, accounts:subcategorize_by_smsf_member, true, accounts), As),
 	maplist(!subcategorize_by_smsf_members3, As).

 subcategorize_by_smsf_members3(A) :-
	!smsf_members_throw(Members),
	!account_name(A, Account),
	maplist(!subcategorize_by_smsf_member(Account, A), Members).

 subcategorize_by_smsf_member(Role_prefix, A, Member) :-
	!doc_value(Member, smsf:member_name, Member_Name_str),
	atom_string(Member_Name, Member_Name_str),
	ensure_account_exists(A, _, 1, rl(Role_prefix/Member_Name), _).

%------


/*					<!-- todo: we should allow multiple roles on one account -->*/

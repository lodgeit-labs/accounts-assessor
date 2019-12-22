:- module(_, []).
:- use_module('system_accounts', []).
:- use_module('accounts', []).
:- use_module(library(xbrl/utils), []).
:- use_module('xbrl_contexts', []).
:- use_module('ledger_report', []).
:- use_module('fact_output').


/* given information about a xbrl dimension, print each account as a point in that dimension. 
this means each account results in a fact with a context that contains the value for that dimension.
*/
print_detail_accounts(_,_,_,[],Results,Results,[]).

print_detail_accounts(
	Static_Data, Context_Info, Fact_Name, 
	[Bank_Account|Bank_Accounts],  
	In, Out, [XmlH|XmlT]
) :-
	assertion(ground((in, In))),
	print_detail_account(Static_Data, Context_Info, Fact_Name, Bank_Account, In, Mid, XmlH),
	assertion(ground((mid, Mid))),
	print_detail_accounts(Static_Data, Context_Info, Fact_Name, Bank_Accounts, Mid, Out, XmlT),
	assertion(ground((out, Out))).

print_detail_account(Static_Data, Context_Info, Fact_Name, Account_In,
	Contexts_In, Contexts_Out, Xml
) :-
	dict_vars(Static_Data, [End_Date, Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency]),
	(	(Account, Dimension_Value) = Account_In
	->	true
	;	(
			Account = Account_In,
			Dimension_Value = Short_Id
		)
	),
	accounts:account_role_by_id(Accounts, Account, (_/Short_Id)),
	xbrl_contexts:ensure_context_exists(Short_Id, Dimension_Value, Context_Info, Contexts_In, Contexts_Out, Context_Id),
	(	xbrl_contexts:context_arg0_period(Context_Info, (_,_))
	->	ledger_report:net_activity_by_account(Static_Data, Account, Balance, Transactions_Count)
	;	ledger_report:balance_by_account(Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency, End_Date, Account, End_Date, Balance, Transactions_Count)
	),
	fact_output:format_report_entries(
		xbrl, 0, Accounts, 1, Report_Currency, Context_Id,
		[entry(Fact_Name, Balance, [], Transactions_Count)],
		Xml).

print_banks(Static_Data, Context_Id_Base, In, Out, Xml) :-
	dict_vars(Static_Data, [End_Date, Accounts, Entity_Identifier]),
	system_accounts:bank_accounts(Accounts, Bank_Accounts),
	Context_Info = context_arg0(
		Context_Id_Base, 
		End_Date, 
		entity(Entity_Identifier, ''), 
		[dimension_value(dimension_reference('basic:Dimension_BankAccounts', 'basic:BankAccount'), _)]
	),
	findall(
		(Account, [element(name,[],[Account]),element(value,[],[Num])]),
		(
			member(Account, Bank_Accounts),
			nth0(Index, Bank_Accounts, Account),
			Num is (Index+1)*10000
		),
		Accounts_And_Points
	),
	print_detail_accounts(Static_Data, Context_Info, 'Banks', Accounts_And_Points, In, Out, Xml).

print_forex(Static_Data, Context_Id_Base, In, Out, Xml) :-
	dict_vars(Static_Data, [Start_Date, End_Date, Entity_Identifier, Accounts]),
    findall(Account, accounts:account_by_role_nothrow(Accounts, ('CurrencyMovement'/_), Account), Movement_Accounts),
	Context_Info = context_arg0(
		Context_Id_Base, 
		(Start_Date, End_Date), 
		entity(
			Entity_Identifier, 
			[dimension_value(dimension_reference('basic:Dimension_BankAccounts', 'basic:BankAccount'), _)]
		),
		''
	),
	print_detail_accounts(Static_Data, Context_Info, 'CurrencyMovement', Movement_Accounts, In, Out, Xml).

print_trading(Sd, In, Out, Xml) :-
	findall(Pair, trading_sub_account(Sd, Pair), Pairs),
	print_trading2(Sd, Pairs, In, Out, Xml).

/* for a list of (Sub_Account, Unit_Accounts) pairs..*/
print_trading2(Static_Data, [(Sub_Account,Unit_Accounts)|Tail], In, Out, [XmlH|XmlT]):-
	dict_vars(Static_Data, [Start_Date, End_Date, Entity_Identifier, Duration_Context_Id_Base]),
	Context_Info = context_arg0(
		Duration_Context_Id_Base, 
		(Start_Date, End_Date),
		entity(
			Entity_Identifier, 
			[dimension_value(dimension_reference('basic:Dimension_Investments', 'basic:Investment'), _)]
		),
		''
	),
	print_detail_accounts(Static_Data, Context_Info, Sub_Account, Unit_Accounts, In, Mid, XmlH),
	print_trading2(Static_Data, Tail, Mid, Out, XmlT).
	
print_trading2(_,[],Results,Results,[]).
	
trading_sub_account(Sd, (Movement_Account, Unit_Accounts)) :-
	system_accounts:trading_account_ids(Trading_Accounts),
	member(Trading_Account, Trading_Accounts),
	accounts:account_by_role_nothrow(Sd.accounts, (Trading_Account/_), Gains_Account),
	accounts:account_by_role_nothrow(Sd.accounts, (Gains_Account/_), Movement_Account),
	accounts:child_accounts(Sd.accounts, Movement_Account, Unit_Accounts).
	

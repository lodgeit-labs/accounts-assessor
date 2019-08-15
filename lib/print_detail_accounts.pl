/* given information about a xbrl dimension, print each account as a point in that dimension. 
this means each account results in a fact with a context that contains the value for that dimension.
*/
print_detail_accounts(_,_,_,[],Results,Results).

print_detail_accounts(
	Static_Data, Context_Info, Fact_Name, 
	[Bank_Account|Bank_Accounts],  
	In, Out
) :-
	assertion(ground((in, In))),
	print_detail_account(Static_Data, Context_Info, Fact_Name, Bank_Account, In, Mid),
	assertion(ground((mid, Mid))),
	print_detail_accounts(Static_Data, Context_Info, Fact_Name, Bank_Accounts, Mid, Out),
	assertion(ground((out, Out))).


print_detail_account(Static_Data, Context_Info, Fact_Name, Account_In,
	(Contexts_In, Used_Units_In, Lines_In), (Contexts_Out, Used_Units_Out, Lines_Out)
) :-
	dict_vars(Static_Data, [End_Date, Exchange_Rates, Accounts, Transactions, Report_Currency]),
	(
		(Account, Dimension_Value) = Account_In
	->
		true
	;
		(
			Account = Account_In,
			Dimension_Value = Short_Id
		)
	),
	account_role_by_id(Accounts, Account, (_/Short_Id_Unsanitized)),
	replace_nonalphanum_chars_with_underscore(Short_Id_Unsanitized, Short_Id),
	ensure_context_exists(Short_Id, Dimension_Value, Context_Info, Contexts_In, Contexts_Out, Context_Id),
	(
		context_arg0_period(Context_Info, (_,_))
	->
		net_activity_by_account(Static_Data, Account, Balance, Transactions_Count)
	;
		balance_by_account(Exchange_Rates, Accounts, Transactions, Report_Currency, End_Date, Account, End_Date, Balance, Transactions_Count)
	),
	format_report_entries(
		xbrl, Accounts, 1, Report_Currency, Context_Id, 
		[entry(Fact_Name, Balance, [], Transactions_Count)],
		Used_Units_In, Used_Units_Out, Lines_In, Lines_Out).

print_banks(Static_Data, Context_Id_Base, Entity_Identifier, In, Out) :- 
	dict_vars(Static_Data, [End_Date, Accounts]),
	bank_accounts(Accounts, Bank_Accounts),
	Context_Info = context_arg0(
		Context_Id_Base, 
		End_Date, 
		entity(Entity_Identifier, ''), 
		[dimension_value(dimension_reference('basic:Dimension_BankAccounts', 'basic:BankAccount'), _)]
	),
	findall(
		(Account, Value),
		(
			member(Account, Bank_Accounts),
			nth0(Index, Bank_Accounts, Account),
			Num is (Index+1)*10000,
			atomic_list_concat(['<name>', Account, '</name><value>',Num,'</value>'], Value)
		),
		Accounts_And_Points
	),
	print_detail_accounts(Static_Data, Context_Info, 'Bank', Accounts_And_Points, In, Out).

print_forex(Static_Data, Context_Id_Base, Entity_Identifier, In, Out) :- 
	dict_vars(Static_Data, [Start_Date, End_Date, Accounts]),
    findall(Account, account_by_role_nothrow(Accounts, ('CurrencyMovement'/_), Account), Movement_Accounts),
	Context_Info = context_arg0(
		Context_Id_Base, 
		(Start_Date, End_Date), 
		entity(
			Entity_Identifier, 
			[dimension_value(dimension_reference('basic:Dimension_BankAccounts', 'basic:BankAccount'), _)]
		),
		''
	),
	print_detail_accounts(Static_Data, Context_Info, 'CurrencyMovement', Movement_Accounts, In, Out).

/* for a list of (Sub_Account, Unit_Accounts) pairs..*/
print_trading2(Static_Data, [(Sub_Account,Unit_Accounts)|Tail], In, Out):-
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
	print_detail_accounts(Static_Data, Context_Info, Sub_Account, Unit_Accounts, In, Mid),
	print_trading2(Static_Data, Tail, Mid, Out).
	
print_trading2(_,[],Results,Results).
	
trading_sub_account(Sd, (Movement_Account, Unit_Accounts)) :-
	trading_account_ids(Sd.transaction_types, Trading_Accounts),
	member(Trading_Account, Trading_Accounts),
	account_by_role(Sd.accounts, (Trading_Account/_), Gains_Account),
	account_by_role(Sd.accounts, (Gains_Account/_), Movement_Account),
	child_accounts(Sd.accounts, Movement_Account, Unit_Accounts).
	
print_trading(Sd, In, Out) :-
	findall(
		Pair,
		trading_sub_account(Sd, Pair),
		Pairs
	),
	print_trading2(Sd, Pairs, In, Out).

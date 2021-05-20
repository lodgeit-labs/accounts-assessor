

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
	dict_vars(Static_Data, [End_Date, Exchange_Rates, Transactions_By_Account, Report_Currency]),
	(	(Account, Dimension_Value) = Account_In
	->	true
	;	(
			Account = Account_In,
			Dimension_Value = Short_Id
		)
	),
	account_role(Account, rl(_/Short_Id0)),
	account_normal_side(Account, Normal_side),
	sane_id(Short_Id0, Short_Id), % todo this sanitization is probably unnecessary
	% <basic:Investment_Duration>Short_Id</basic:Investment_Duration>
	ensure_context_exists(Short_Id, Dimension_Value, Context_Info, Contexts_In, Contexts_Out, Context_Id),
	(	context_arg0_period(Context_Info, (_,_))
	->	net_activity_by_account(Static_Data, Account, Balance, Transactions_Count)
	;	balance_by_account(Exchange_Rates, Transactions_By_Account, Report_Currency, End_Date, Account, End_Date, Balance, Transactions_Count)
	),
	!make_report_entry(Fact_Name, [], Entry),
	!doc_add(Entry, report_entries:total_vec, Balance),
	!doc_add(Entry, report_entries:normal_side, Normal_side),
	!doc_add(Entry, report_entries:transaction_count, Transactions_Count),
	!format_report_entries(xbrl, 0, 1, Report_Currency, Context_Id, [Entry], Xml).

print_banks(Static_Data, Context_Id_Base, In, Out, Xml) :-
	dict_vars(Static_Data, [End_Date, Entity_Identifier]),
	bank_accounts(Bank_Accounts),
	Context_Info = context_arg0(
		Context_Id_Base, 
		End_Date, 
		entity(Entity_Identifier, ''), 
		[dimension_value(dimension_reference('basic:Dimension_BankAccounts', 'basic:BankAccount'), _)]
	),
	findall(
		(Gl_account, [Id]),
		(
			member(Account, Bank_Accounts),
			!doc(Account, l:name, Id),
			abrlt('Banks'/Id, Gl_account)
		),
		Accounts_And_Points
	),
	print_detail_accounts(Static_Data, Context_Info, 'Banks', Accounts_And_Points, In, Out, Xml).

print_forex(Static_Data, Context_Id_Base, In, Out, Xml) :-
	dict_vars(Static_Data, [Start_Date, End_Date, Entity_Identifier]),
    findall(Account, account_by_role(rl('Currency_Movement'/_), Account), Movement_Accounts),
	Context_Info = context_arg0(
		Context_Id_Base, 
		(Start_Date, End_Date), 
		entity(
			Entity_Identifier, 
			[dimension_value(dimension_reference('basic:Dimension_BankAccounts', 'basic:BankAccount'), _)]
		),
		''
	),
	print_detail_accounts(Static_Data, Context_Info, 'Currency_Movement', Movement_Accounts, In, Out, Xml).

print_trading(Sd, In, Out, Xml) :-
	findall(Pair, trading_sub_account(Pair), Pairs),
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
	

 maybe_print_dimensional_facts(Static_Data,Contexts_In, Contexts_Out, Xml) :-
	(	result_property(l:output_dimensional_facts, on)
	->	print_dimensional_facts(Static_Data, Contexts_In, Contexts_Out, Xml)
	;	Contexts_In = Contexts_Out).

 print_dimensional_facts(Static_Data, Results0, Results3, [Xml1, Xml2, Xml3]) :-
 	dict_vars(Static_Data, [Instant_Context_Id_Base, Duration_Context_Id_Base]),
	!print_banks(Static_Data, Instant_Context_Id_Base, Results0, Results1, Xml1),
	!print_forex(Static_Data, Duration_Context_Id_Base, Results1, Results2, Xml2),
	!print_trading(Static_Data, Results2, Results3, Xml3).

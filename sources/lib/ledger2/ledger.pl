process_ledger(
	Cost_Or_Market,
	Initial_Txs,
	S_Transactions0,
	Start_Date,
	End_Date, 
	Exchange_Rates,
	Report_Currency,
	Accounts_In,
	Accounts, 
	Transactions_With_Livestock,
	Transactions_By_Account,
	Outstanding_Out,
	Processed_Until,
	Gl
) :-

	s_transactions_up_to(End_Date, S_Transactions0, S_Transactions),
	add_comment_stringize('Exchange rates extracted', Exchange_Rates),
	add_comment_stringize('Accounts extracted',Accounts_In),


	generate_system_accounts(S_Transactions, Accounts_In, Generated_Accounts),
	flatten([Accounts_In, Generated_Accounts], Accounts),
	maplist(check_account_parent(Accounts), Accounts),
	write_accounts_json_report(Accounts),
	result(T),
	doc_add(T, l:accounts, Accounts),


	dict_from_vars(Static_Data0, [Accounts, Report_Currency, Start_Date, End_Date, Exchange_Rates, Cost_Or_Market]),
	prepreprocess(Static_Data0, S_Transactions, Prepreprocessed_S_Transactions),

	preprocess_until_error(Static_Data0, Prepreprocessed_S_Transactions, Processed_S_Transactions, Transactions_From_Bst, Outstanding_Out, End_Date, Processed_Until),

	/* since it's not possibly to determine order of transactions that transpiled on one day, when we fail to process a transaction, we go back all the way to the end of the previous day, and try to run a report up to that day
	*/
	(	End_Date \= Processed_Until
	->	add_alert('warning', ['trying with earlier report end date: ', Processed_Until])
	;	true),

	append([Initial_Txs], Transactions_From_Bst, Transactions0),
	flatten(Transactions0, Transactions1),

	process_livestock((Processed_S_Transactions, Transactions1), Livestock_Transactions),
	flatten([Transactions1,	Livestock_Transactions], Transactions_With_Livestock),

	/*
	this is probably the right place to plug in hirepurchase and depreciation,
	take Transactions_With_Livestock and produce an updated list.
	notes:
	transaction term now carries date() instead of absolute days count. (probably to be reverted)
	transactions are produced with transactions:make_transaction.
	account id is obtained like this: account_by_role(Accounts, ('Accounts'/'Assets'), Assets_AID).
	to be explained:
		how to get balance on account
		how to generate json+html reports
	*/

	maplist(check_transaction_account(Accounts), Transactions_With_Livestock),

	Static_Data2 = Static_Data0.put(end_date, Processed_Until).put(transactions, Transactions_With_Livestock),
	gl_export(
		Static_Data2, 
		Processed_S_Transactions, 
		/* list of lists */
		Transactions0,
		Livestock_Transactions,
		/* output */
		Gl),
	transactions_by_account(Static_Data2, Transactions_By_Account),
	trial_balance_between(Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency, End_Date, Start_Date, End_Date, [Trial_Balance_Section]),
	(
		(
			trial_balance_ok(Trial_Balance_Section)
		;
			Report_Currency = []
		)
	->
		true
	;
		(	term_string(trial_balance(Trial_Balance_Section), Tb_Str),
			add_alert('SYSTEM_WARNING', Tb_Str))
	).


gather_ledger_warnings(S_Transactions, Start_Date, End_Date, Warnings) :-
	(
		find_s_transactions_in_period(S_Transactions, Start_Date, End_Date, [])
	->
		Warnings = ['WARNING':'no transactions within request period']
	;
		Warnings = []
	).

gather_ledger_errors(Debug) :-
	(	(last(Debug, Last),	Last \== 'done.')
	->	add_alert('ERROR', Last)
	;	true).



filter_out_market_values(_S_Transactions, _Exchange_Rates0, []).


/*
filter_out_market_values(S_Transactions, Exchange_Rates0, Exchange_Rates) :-

	fixme, this should also take into account initial_GL and whichever other transaction input channenl,
	and since we haven't seen any use of users specifying currency exchange rates with the Unit_Values sheet,
	i think it's safe-ish to just ignore all input exchange rates for now

	traded_units(S_Transactions, Units),
=======
/* see misc/system_account_generation */
exchange_rates_without_market_values([]).

	

find_s_transactions_in_period(S_Transactions, Opening_Date, Closing_Date, Out) :-
	findall(
		S_Transaction,
		(
			member(S_Transaction, S_Transactions),
			s_transaction_day(S_Transaction, Date),
			date_between(Opening_Date, Closing_Date, Date)
		),
		Out
	).

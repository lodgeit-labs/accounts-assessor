
%:- rdet(generate_gl_data/5).
%:- rdet(make_gl_entry/4).
%:- rdet(transaction_with_converted_vector/4).

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

process_ledger(
	Cost_Or_Market,
	Initial_Txs,
	S_Transactions0,
	Start_Date,
	End_Date, 
	Exchange_Rates0, 
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
	add_comment_stringize('Exchange rates extracted', Exchange_Rates0),
	add_comment_stringize('Accounts extracted',Accounts_In),

	(	Cost_Or_Market = cost
	->	filter_out_market_values(S_Transactions, Exchange_Rates0, Exchange_Rates)
	;	Exchange_Rates0 = Exchange_Rates),
	
	generate_system_accounts(S_Transactions, Accounts_In, Generated_Accounts),
	add_comment_stringize('Accounts generated', Generated_Accounts),
	flatten([Accounts_In, Generated_Accounts], Accounts),
	maplist(check_account_parent(Accounts), Accounts),
	write_accounts_json_report(Accounts),
	doc(T, rdf:type, l:request),
	doc_add(T, l:accounts, Accounts),

	dict_from_vars(Static_Data0, [Accounts, Report_Currency, Start_Date, End_Date, Exchange_Rates, Cost_Or_Market]),
	prepreprocess(Static_Data0, S_Transactions, Prepreprocessed_S_Transactions),
	preprocess_until_error(Static_Data0, Prepreprocessed_S_Transactions, Processed_S_Transactions, Transactions_From_Bst, Outstanding_Out, Transaction_Transformation_Debug, End_Date, Processed_Until),
	append([Initial_Txs], Transactions_From_Bst, Transactions0),
	flatten(Transactions0, Transactions1),

	process_livestock((Processed_S_Transactions, Transactions1), Livestock_Transactions),
	flatten([Transactions1,	Livestock_Transactions], Transactions_With_Livestock),

	/*
	this is probably the right place to plug in hirepurchase and depreciation,
	take Transactions_With_Livestock and produce an updated list.
	notes:
	transaction term now carries date() instead of absolute days count.
	transactions are produced with transactions:make_transaction.
	account id is obtained like this: account_by_role(Accounts, ('Accounts'/'Assets'), Assets_AID).
	to be explained:
		how to get balance on account
		how to generate and return json+html reports
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
	),
	gather_ledger_errors(Transaction_Transformation_Debug).


preprocess_until_error(Static_Data0, Prepreprocessed_S_Transactions, Preprocessed_S_Transactions, Transactions0, Outstanding_Out, Transaction_Transformation_Debug, Report_End_Date, Processed_Until) :-
	preprocess_s_transactions(Static_Data0, Prepreprocessed_S_Transactions, Preprocessed_S_Transactions, Transactions0, Outstanding_Out, Transaction_Transformation_Debug),
	%gtrace,
	(
		Preprocessed_S_Transactions = Prepreprocessed_S_Transactions
	->
		(
			Processed_Until = Report_End_Date/*,
			Last_Good_Day = Report_End_Date*/
		)
	;
		(
			(	last(Preprocessed_S_Transactions, Last_Processed_S_Transaction)
			->	(
					s_transaction_day(Last_Processed_S_Transaction, Date),
					% todo we could/should do: Processed_Until = with_note(Date, 'until error'),
					Processed_Until = Date/*,
					add_days(Date, -1, Last_Good_Day)*/
				)
			;
				Processed_Until = date(1,1,1)
			)
		)
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

filter_out_market_values(S_Transactions, Exchange_Rates0, Exchange_Rates) :-
	traded_units(S_Transactions, Units),
	findall(
		R,
		(
			member(R, Exchange_Rates0),
			R = exchange_rate(_, Src, Dst, _),
			\+member(Src, Units),
			\+member(Dst, Units)
		),
		Exchange_Rates
	).
			
	
	
	

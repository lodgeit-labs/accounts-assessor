 process_ledger(
	Cost_Or_Market,
	S_Transactions0,
	Start_Date,
	End_Date, 
	Exchange_Rates,
	Report_Currency,
	Transactions_With_Livestock,
	Outstanding_Out,
	Processed_Until
) :-
	!add_comment_stringize('Exchange rates extracted', Exchange_Rates),
	!s_transactions_up_to(End_Date, S_Transactions0, S_Transactions),
	!result_add_property(l:bank_s_transactions, S_Transactions),
	!result_add_property(l:exchange_rates, Exchange_Rates),

	!cf(make_gl_viewer_report),
	!cf(write_accounts_json_report),

	!cf('ensure system accounts exist'(S_Transactions)),
	!cf(check_accounts_parent),
	!cf(check_accounts_roles),
	!cf(propagate_accounts_side),
	!cf(write_accounts_json_report),

	process_ledger_phase2(Report_Currency,Start_Date, End_Date, Exchange_Rates, Cost_Or_Market, S_Transactions,Outstanding_Out,Processed_Until,Transactions_With_Livestock).


 process_ledger_phase2(Report_Currency,Start_Date, End_Date, Exchange_Rates, Cost_Or_Market, S_Transactions,Outstanding_Out,Processed_Until,Transactions_With_Livestock) :-
	!cf(extract_gl_inputs(Gl_input_txs)),
	!cf(extract_reallocations(Reallocation_Txs)),
	!cf(extract_smsf_distribution(Smsf_distribution_txs)),

	dict_from_vars(Static_Data0, [Report_Currency, Start_Date, End_Date, Exchange_Rates, Cost_Or_Market]),
	!cf('pre-preprocess source transactions'(Static_Data0, S_Transactions, Prepreprocessed_S_Transactions)),

	!cf(preprocess_until_error(Static_Data0, Prepreprocessed_S_Transactions, Processed_S_Transactions, Transactions_From_Bst, Outstanding_Out, End_Date, Processed_Until)),

	(	(($>length(Processed_S_Transactions)) == ($>length(Prepreprocessed_S_Transactions)))
	->	true
	;	add_alert('warning', 'not all bank statement transactions processed, proceeding with reports anyway..')),

	append([Gl_input_txs, Reallocation_Txs, Smsf_distribution_txs], Transactions_From_Bst, Transactions0),
	flatten(Transactions0, Transactions1),
	!cf(process_livestock((Processed_S_Transactions, Transactions1), Livestock_Transactions)),
	flatten([Transactions1,	Livestock_Transactions], Transactions_With_Livestock).
	/*
	this is probably the right place to plug in hirepurchase and depreciation,
	take Transactions_With_Livestock and produce an updated list.
	notes:
	transaction term now carries date() instead of absolute days count. (probably to be reverted, because day count is easier for CLP)
	transactions are produced with transactions:make_transaction.
	account id is obtained like this: account_by_role(Accounts, ('Accounts'/'Assets'), Assets_AID).
	to be explained:
		how to get balance of account
		how to generate json+html reports
	*/
	%Static_Data2 = Static_Data0.put(end_date, Processed_Until).put(transactions, Transactions_With_Livestock).
	/*
	fixme: doc still contains original end date, not Processed_Until.
	*/



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
	findall(
		R,
		(
			member(R, Exchange_Rates0),
			R = exchange_rate(_, Src, Dst, _),
			\+member(Src, Units),
			\+member(Dst, Units)
		),
		Exchange_Rates
	).*/
			
	
	

find_s_transactions_in_period(S_Transactions, Opening_Date, Closing_Date, Out) :-
	findall(
		S_Transaction,
		(
			member(S_Transaction, S_Transactions),
			!s_transaction_day(S_Transaction, Date),
			?date_between(Opening_Date, Closing_Date, Date)
		),
		Out
	).

trial_balance_ok(Trial_Balance_Section) :-
	!report_entry_children(Trial_Balance_Section, []),
	!report_entry_total_vec(Trial_Balance_Section, Balance),
	maplist(coord_is_almost_zero, Balance).

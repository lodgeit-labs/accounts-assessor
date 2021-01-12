
	!s_transactions_up_to(End_Date, S_Transactions0, S_Transactions),
	!result_add_property(l:bank_s_transactions, S_Transactions),


	!cf('ensure system accounts exist'(S_Transactions)),
	!cf(check_accounts_parent),
	!cf(check_accounts_roles),
	!cf(propagate_accounts_side),
	!cf(write_accounts_json_report),


	!cf(extract_gl_inputs(Gl_input_txs)),
	!cf(extract_reallocations(Reallocation_Txs)),
	!cf(extract_smsf_distribution(Smsf_distribution_txs)),



	handle_sts(Sd0, S_Transactions0, Transactions, Outstanding_Out, End_Date, Processed_Until)


	flatten([Gl_input_txs, Reallocation_Txs, Smsf_distribution_txs, Transactions_From_Bst], Transactions1),

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


	!s_transactions_up_to(End_Date, S_Transactions0, S_Transactions),
	!result_add_property(l:bank_s_transactions, S_Transactions),

	!cf('ensure system accounts exist 0'(S_Transactions)),

	!cf(extract_gl_inputs(Gl_input_txs)),
	!cf(extract_reallocations(Reallocation_Txs)),
	!cf(extract_smsf_distribution(Smsf_distribution_txs)),
	handle_sts(Sd0, S_Transactions0, Transactions, Outstanding_Out, End_Date, Processed_Until)
	flatten([Gl_input_txs, Reallocation_Txs, Smsf_distribution_txs, Transactions_From_Bst], Transactions1),
	!cf(process_livestock((Processed_S_Transactions, Transactions1), Livestock_Transactions)),
	flatten([Transactions1,	Livestock_Transactions], Transactions_With_Livestock).
???????


gather_ledger_warnings(S_Transactions, Start_Date, End_Date, Warnings) :-
	(
		find_s_transactions_in_period(S_Transactions, Start_Date, End_Date, [])
	->
		Warnings = ['WARNING':'no transactions within request period']
	;
		Warnings = []
	).

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

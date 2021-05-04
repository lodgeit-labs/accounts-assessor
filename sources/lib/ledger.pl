


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

check_trial_balance_section(Trial_Balance_Section) :-
	!report_entry_children(Trial_Balance_Section, []),
	!report_entry_total_vec(Trial_Balance_Section, Balance),
	(	maplist(coord_is_almost_zero, Balance)
	->	true
	;	(	round_term(Balance, Balance2),
			term_string(trial_balance(Balance2), Tb_Str),
			add_alert('SYSTEM_WARNING', Tb_Str)
		)
	).


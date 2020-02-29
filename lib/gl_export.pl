/*

	generate json used by general_ledger_viewer

*/


gl_export(Sd, Processed_S_Transactions, Transactions0, Livestock_Transactions, Report_Dict) :-
	/* Outputs list is lists of generated transactions, one list for each s_transaction */
	append(Transactions0, [Livestock_Transactions], Results),
	/* Sources list is all the s_transactions + livestock */
	append(['initial_GL'], Processed_S_Transactions, Sources0),
	append(Sources0, ['livestock'], Sources),
	running_balance_initialization,
	maplist(make_gl_entry(Sd), Sources, Results, Report_Dict0),
	round_term(2, Report_Dict0, Report_Dict).

make_gl_entry(Sd, Source, Transactions, Entry) :-
	Entry = _{source: S, transactions: T},
	(	s_transaction_to_dict(Source, S0)
	->	s_transaction_with_transacted_amount(Sd, S0, S)
	; 	S = Source),
	maplist(transaction_to_dict, Transactions, T0),
	maplist(transaction_with_converted_vector(Sd), T0, T1),
	maplist(running_balance_tx_enrichment, T1, T2),
	round_term(T2, T).

s_transaction_with_transacted_amount(Sd, D1, D2) :-
	D2 = D1.put([
		report_currency_transacted_amount_converted_at_transaction_date=A,report_currency_transacted_amount_converted_at_balance_date=B]),
	vec_change_bases(Sd.exchange_rates, D1.date, Sd.report_currency, D1.vector, A),
	vec_change_bases(Sd.exchange_rates, Sd.end_date, Sd.report_currency, D1.vector, B).

transaction_with_converted_vector(Sd, Transaction, Transaction2) :-
	Transaction2 = Transaction.put([
		vector_converted_at_transaction_date=A,
		vector_converted_at_balance_date=B
	]),
	vec_change_bases(Sd.exchange_rates, Transaction.date, Sd.report_currency, Transaction.vector, A),
	vec_change_bases(Sd.exchange_rates, Sd.end_date, Sd.report_currency, Transaction.vector, B).


running_balance_initialization :-
	b_setval(gl_export_running_balances, _{}).

running_balance_ensure_key_for_account_exists(Account) :-
	b_getval(gl_export_running_balances, Balances),
	(	get_dict(Account, Balances, _)
	->	true
	;	b_setval(gl_export_running_balances, Balances.put(Account, []))).

running_balance_tx_enrichment(Tx, Tx_New) :-
	Account = Tx.account,
	Vector = Tx.vector,
	running_balance_ensure_key_for_account_exists(Account),
	b_getval(gl_export_running_balances, Balances),
	get_dict(Account, Balances, Old),
	vec_add(Old, Vector, New),
	b_setval(gl_export_running_balances, Balances.put(Account, New)),
	Tx_New = Tx.put(running_balance, New).



trial_balance_ok(Trial_Balance_Section) :-
	Trial_Balance_Section = entry(_, Balance, [], _, _),
	maplist(coord_is_almost_zero, Balance).







/*+
+this could be useful if we parse the prolog code and collect o's in one place so that they're all visible when gtracing, and we visualize the process
+       o(gl_export_rounding(final), round_term(2, Report_Dict0, Report_Dict)).
+could be just:
+       o(gl_export_rounding(final))). if its a unique operation on the global store
+*/

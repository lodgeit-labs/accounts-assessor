/*

	generate json used by general_ledger_viewer

*/
	/* finishme. GL_input will create multiple source transactions. Also, gl viewer is broken now wrt account ids vs uris */


 gl_export(Sd, Txs, Json_list) :-
 	/*todo: this should be simply handled by a json-ld projection*/
	findall(
		Source,
		(
			member(Tx, Txs),
			assertion(nonvar(Tx)),
			doc(Tx, transactions:origin, Source, transactions),
			assertion(nonvar(Source))
		),
		Sources),
	list_to_set(Sources, Sources2),
	running_balance_initialization,
	maplist(gl_export2(Sd, Txs), Sources2, Json_list0),
	round_term(2, Json_list0, Json_list).

gl_export2(Sd, All_txs, Source, Json) :-
	findall(
		Tx,
		(
			member(Tx, All_txs),
			doc(Tx, transactions:origin, Source, transactions)
		),
		Txs0),
	maplist(gl_export_tx(Sd), Txs0, Txs),
	gl_export_st(Sd, Source, Source_dict),
	Json = _{source: Source_dict, transactions: Txs}.

gl_export_st(Sd, Source, Source_json) :-
	(	s_transaction_to_dict(Source, S0)
	->	s_transaction_with_transacted_amount(Sd, S0, Source_json)
	; 	(
			doc_value(Source, transactions:description, Source_json, transactions)
			->	true
			;	Source_json = Source)).

gl_export_tx(Sd, Tx0, Tx9) :-
	transaction_to_dict(Tx0, Tx3),
	transaction_with_converted_vector(Sd, Tx3, Tx6),
	running_balance_tx_enrichment(Tx6, Tx9).

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

% running_balance_for_relevant_period?

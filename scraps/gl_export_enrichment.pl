
	enrich s_transactions and transactions for display in general_ledger_viewer

gl_export_enrichment(Sd, Txs, Report_Dict) :-
	running_balance_initialization,
	maplist(running_balance_tx_enrichment(Txs, Txs3)
	maplist(s_transaction_add_transacted_amount(Sd), S_transactions),
	maplist(transaction_add_converted_vector(Sd), Txs3).

s_transaction_add_transacted_amount(Sd, St) :-
	vec_change_bases(Sd.exchange_rates, St_date, Sd.report_currency, St_vector, A),
	vec_change_bases(Sd.exchange_rates, Sd.end_date, Sd.report_currency, St_vector, B),
	doc_add_value(St, ic:report_currency_transacted_amount_converted_at_transaction_date, A, transactions),
	doc_add_value(St, ic:report_currency_transacted_amount_converted_at_balance_date, B, transactions).

transaction_add_converted_vector(Sd, T) :-
	vec_change_bases(Sd.exchange_rates, Transaction_date, Sd.report_currency, Transaction_vector, A),
	vec_change_bases(Sd.exchange_rates, Sd.end_date, Sd.report_currency, Transaction_vector, B),
	doc_add_value(T, ic:vector_converted_at_transaction_date, A, transactions),
	doc_add_value(T, ic:vector_converted_at_balance_date, B, transactions).

transactions_add_rounded_properties(Tx) :-
	transaction_dict(Tx, Tx3),
	round_term(Tx3, Tx6),
	doc_add(Tx, transaction_vector_json, $>dict_json_text(Tx6.vector), transactions),
	...

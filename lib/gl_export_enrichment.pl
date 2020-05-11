/*
	enrich s_transactions and transactions for display in general_ledger_viewer

gl_export_enrichment(Sd, Tst, Txs, Report_Dict) :-
	maplist(s_transaction_add_transacted_amount(Sd), S_transactions),
	maplist(transaction_add_converted_vector(Sd), Transactions).

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

*/

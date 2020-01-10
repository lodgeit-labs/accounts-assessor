gl_export(Sd, Processed_S_Transactions, Transactions0, Livestock_Transactions, Report_Dict) :-
	/* Outputs list is lists of generated transactions, one list for each s_transaction */
	append(Transactions0, [Livestock_Transactions], Processing_Results),
	/* Sources list is all the s_transactions + livestock */
	append(Processed_S_Transactions, ['livestock'], Sources),
	maplist(make_gl_entry(Sd), Sources, Processing_Results, Report_Dict).

make_gl_entry(Sd, Source, Transactions, Entry) :-
	Entry = _{source: S, transactions: T},
	(	atom(Source)
	->	S = Source
	; 	(
			s_transaction_to_dict(Source, S0),
			s_transaction_with_transacted_amount(Sd, S0, S)
		)
	),
	maplist(transaction_to_dict, Transactions, T0),
	maplist(transaction_with_converted_vector(Sd), T0, T).

s_transaction_with_transacted_amount(Sd, D1, D2) :-
	D2 = D1.put([
		report_currency_transacted_amount_converted_at_transaction_date=ConvertedA,report_currency_transacted_amount_converted_at_balance_date=ConvertedB]),
	vec_change_bases(Sd.exchange_rates, D1.date, Sd.report_currency, D1.vector, ConvertedA),
	vec_change_bases(Sd.exchange_rates, Sd.end_date, Sd.report_currency, D1.vector, ConvertedB).

transaction_with_converted_vector(Sd, Transaction, Transaction_Converted) :-
	Transaction_Converted = Transaction.put([
		vector_converted_at_transaction_date=Vector_ConvertedA,
		vector_converted_at_balance_date=Vector_ConvertedB
	]),
	vec_change_bases(Sd.exchange_rates, Transaction.date, Sd.report_currency, Transaction.vector, Vector_ConvertedA),
	vec_change_bases(Sd.exchange_rates, Sd.end_date, Sd.report_currency, Transaction.vector, Vector_ConvertedB).

trial_balance_ok(Trial_Balance_Section) :-
	Trial_Balance_Section = entry(_, Balance, [], _),
	maplist(coord_is_almost_zero, Balance).

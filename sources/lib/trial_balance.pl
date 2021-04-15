 check_txset(Txs) :-
 	push_format('check ~q', [Txs]),
	result_property(l:report_currency, Report_Currency),
	result_property(l:exchange_rates, Exchange_Rates),
	result_property(l:end_date, End_Date),
	get_txset_date(Transaction_Date, Txs),
	(	Report_Currency = []
	->	true
	;	(
			cf(check_txset_at(Exchange_Rates, Report_Currency, End_Date, Txs)),
			cf(check_txset_at(Exchange_Rates, Report_Currency, Transaction_Date, Txs)),
			true
		)
	),
	pop_format.

 get_txset_date(Date, Txs) :-
 	assertion(is_list(Txs)),
 	assertion(Txs \= []),
 	!all_txs_have_same_date(Date, Txs).

 all_txs_have_same_date(_, []).

 all_txs_have_same_date(D, [Tx|Txs]) :-
	transaction_day(Tx,D),
	all_txs_have_same_date(D, Txs).

 check_txset_at(Exchange_Rates, Report_Currency, Date, Transactions) :-
	Desc = '',
	transactions_report_currency_sum_at_(Exchange_Rates, Report_Currency, Date, Transactions, Total),
	exclude(coord_is_almost_zero, Total, Rest),
	Report_Currency = [RC],
	(	maplist(coord_unit, Rest, RC)
	->	true
	;	(
			format_balances(error_msg, Report_Currency, unused, unused, kb:debit, Total, Vecs_text_list),
			atomics_to_string(Vecs_text_list, ' ', Vecs_text),
			add_alert('SYSTEM_WARNING', $>format(string(<$), '~w: trial balance at ~w is ~w\n', [Desc, Date, Vecs_text]))
		)
	).


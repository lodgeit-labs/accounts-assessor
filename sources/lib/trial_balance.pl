 txset_sources(Txs, Sources2) :-
 	findall(Source,
		(
			member(Tx, Txs),
			doc(Tx, transactions:origin, Source, transactions)
		),
		Sources
	),
	list_to_set(Sources, Sources2).

 st_txs(St, Txs) :-
 	findall(
 		Tx,
 		doc(Tx, transactions:origin, St, transactions),
 		Txs).

 check_st_tb(Tx) :-
	doc(Tx, s_transactions:tb, _, transactions),
	!.
 check_st_tb(Source) :-
	st_txs(Source, Txs),
	check_txset(Source, Txs).

 check_txsets(Txs) :-
 	push_format('check ~q', [Txs]),
 	txset_sources(Txs, Sources),
 	maplist(check_st_tb, Sources).

 check_txset(St, Txs) :-
	result_property(l:report_currency, Report_Currency),
	result_property(l:exchange_rates, Exchange_Rates),
	result_property(l:end_date, End_Date),
	(	Report_Currency = []
	->	true
	;	(
			cf(!check_txset_at(St, Exchange_Rates, Report_Currency, End_Date, Txs)),
			(	get_txset_date(Transaction_Date, Txs)
			->	cf(!check_txset_at(St, Exchange_Rates, Report_Currency, Transaction_Date, Txs))
			;	true),
			true
		)
	),
	pop_format.


 get_txset_date(Date, Txs) :-
 	assertion(is_list(Txs)),
 	assertion(Txs \= []),
 	all_txs_have_same_date(Date, Txs).


 all_txs_have_same_date(_, []).


 all_txs_have_same_date(D, [Tx|Txs]) :-
	transaction_day(Tx,D),
	all_txs_have_same_date(D, Txs).


 check_txset_at(Source, Exchange_Rates, Report_Currency, Date, Transactions) :-
	Desc = 'check_txset_at',
	!transactions_report_currency_sum_at_(Exchange_Rates, Report_Currency, Date, Transactions, Total),
	exclude(coord_is_almost_zero, Total, Rest),
	doc_add(Source, l:has_tb, Rest),

	(	vec_is_almost_zero(Rest)
	->	true
	;	(
			vec_is_just_report_currency(Rest)
		->
			(
				!format_balances(
					error_msg,
					Report_Currency,
					unused,
					unused,
					kb:debit,
					Rest,
					Vecs_text_list
				),
				atomics_to_string(Vecs_text_list, ' ', Vecs_text),
				!pretty_transactions_string(Transactions, Transactions_string),
				add_alert(
					'SYSTEM_WARNING',
					$>format(
						string(<$),
						'~w: trial balance of txset, at ~w, is ~w:\n~q',
						[Desc, Date, Vecs_text, Transactions_string]
					),
					Alert
				),
				doc_add(Source, l:has_alert, Alert)
			)
		;	true
		)
	).


 vec_is_just_report_currency(Vec) :-
 	!exclude(coord_is_almost_zero, Vec, Rest),
 	!result_property(l:report_currency, Report_Currency),
 	!'='(Report_Currency,[RC]),
 	maplist({RC}/[Coord]>>coord_unit(Coord,RC), Rest).

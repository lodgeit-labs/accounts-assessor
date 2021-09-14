 check_txsets(Txs0) :-
 	push_context(check_txsets),
 	flatten(Txs0, Txs),
 	collect_sources_set(Txs, Sources, Txs_by_sources),
 	maplist(check_st_tb(Txs_by_sources), Sources),
 	pop_context.

/*
 st_txs(St, Txs) :-
 	findall(
 		Tx,
 		doc(Tx, transactions:origin, St, transactions),
 		Txs
 	).
*/

 check_st_tb(_, Source) :-
 	/* nothing to do if this ST already has a TB calculated */
	doc(Source, s_transactions:tb, _, transactions),
	!.
 check_st_tb(_, Source) :-
 	% this option should probably be removed - there's no reason that this now can't be a balanced transaction that nullifies P&L
	doc(Source, s_transactions:unbalanced, true, transactions),
	!.
 check_st_tb(Txs_by_sources, Source) :-
	check_txset(Source, Txs_by_sources.get(Source)).


 check_txset(St, Txs) :-
 	%push_format('~q', [check_txset(St, Txs)]),
	result_property(l:report_currency, Report_Currency),
	result_property(l:exchange_rates, Exchange_Rates),
	result_property(l:end_date, End_Date),
	(	Report_Currency = []
	->	true
	;	(
			/* check TB as of end date */
			!cf(check_txset_at(St, Exchange_Rates, Report_Currency, End_Date, Txs)),
			/* check TB as of ST date if it has a singular date */
			(	get_txset_date(Transaction_Date, Txs)
			->	!cf(check_txset_at(St, Exchange_Rates, Report_Currency, Transaction_Date, Txs))
			/* if it doesn't have a singular date, we can't meaningfully calculate TB as of that date. */
			;	true),
			true
		)
	)/*,
	pop_format*/.


 get_txset_date(Date, Txs) :-
 	assertion(is_list(Txs)),
 	assertion(Txs \= []),
 	all_txs_have_same_date(Date, Txs).


 all_txs_have_same_date(D, []) :- ground(D).


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
	;	(	vec_is_just_report_currency(Rest)
		->	report_bad_tb(Report_Currency,Rest,Transactions,Desc, Date, Source)
		;	/* we couldn't convert all values to report_currency at date */
			true
		)
	).


report_bad_tb(Report_Currency,Rest,Transactions,Desc, Date, Source) :-
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
	).


 vec_is_just_report_currency(Vec) :-
 	!exclude(coord_is_almost_zero, Vec, Rest),
 	!result_property(l:report_currency, Report_Currency),
 	!'='(Report_Currency,[RC]),
 	maplist({RC}/[Coord]>>coord_unit(Coord,RC), Rest).

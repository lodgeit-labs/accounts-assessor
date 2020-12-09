/*

	generate json used by general_ledger_viewer

*/

 'export GL'(Sd, Txs, Json_list) :-
 	!gl_export_sources(Txs, Sources),
 	!gl_export_add_ids_to_sources(Sources),
 	!cf(gl_viewer_json_gl_export(Sd, Sources, Txs, Json_list))/*,
 	!cf('QuickBooks CSV GL export'(Sd, Txs))*/.

gl_export_add_ids_to_sources(Sources) :-
	b_setval(gl_export_add_ids_to_sources, 1),
	maplist(gl_export_add_id_to_source, Sources).

gl_export_add_id_to_source(Source) :-
	b_getval(gl_export_add_ids_to_sources, Id),
	doc_add(Source, s_transactions:id, Id, transactions),
	Next_id is Id + 1,
	b_setval(gl_export_add_ids_to_sources, Next_id).

gl_export_sources(Txs, Sources) :-
	findall(
		Source,
		(
			member(Tx, Txs),
			assertion(nonvar(Tx)),
			doc(Tx, transactions:origin, Source, transactions),
			assertion(nonvar(Source))
		),
		Sources0),
	list_to_set(Sources0, Sources).

gl_viewer_json_gl_export(Sd, Sources, Txs, Json_list) :-
	running_balance_initialization,
	maplist(gl_export2(Sd, Txs), Sources, Json_list0),
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
	% todo running_balance_for_relevant_period?

'QuickBooks CSV GL export'(Sd, Txs) :-
	File_name = 'QBO_GL_coord_converted_at_tx_time.csv',
	File_loc = loc(file_name, File_name),
	!report_file_path(File_loc, Url, loc(absolute_path, File_path)),
	maplist(!qb_csv_gl_export(Sd), Txs, Rows0),
	flatten([Header, Rows0], Rows3),
	Header = row('*JournalNo', '*JournalDate', '*Currency', 'Memo', '*AccountName', 'Debits', 'Credits',  'Description', 'Name', 'Location', 'Class'),
	!csv_write_file(File_path, Rows3),
	!add_report_file(-10, File_name, File_name, Url).

qb_csv_gl_export(Sd, Tx, Rows) :-
	!transaction_vector(Tx, Vector),
	maplist(!qb_csv_gl_export2(Sd, Tx), Vector, Rows).

qb_csv_gl_export2(Sd, Tx, Coord0, Row) :-
	!transaction_day(Tx, Date),
	!coord_converted_at_time(Sd, Date, Coord0, Coord),
	!doc(Tx, transactions:origin, Origin, transactions),
	(s_transaction_description2(Origin, D2) -> true ; D2 = ''),
	(s_transaction_description3(Origin, D3) -> true ; D3 = ''),
	!dr_cr_coord(Unit, Debit, Credit, Coord),
	Row = row(
		Id,
		$>format_time(string(<$), '%d/%m/%Y', Date),
		Unit,
		$>transaction_description(Tx),
		$>account_name($>transaction_account(Tx)),
		$>round_to_significant_digit(Debit),
		$>round_to_significant_digit(Credit),
		D2,
		D3,
		'',
		''),
	!doc(Tx, transactions:origin, Origin, transactions),
	!doc(Origin, s_transactions:id, Id, transactions).

coord_converted_at_time(Sd, Date, Coord0, Coord1) :-
	!vec_change_bases_throw(Sd.exchange_rates, Date, Sd.report_currency, [Coord0], Vec2),
	Sd.report_currency = [Report_currency],
	Coord1 = coord(Report_currency, _),
	coord_vec(Coord1, Vec2).

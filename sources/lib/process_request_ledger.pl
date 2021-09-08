
/*


state ( -> static data) -> structured reports ( -> crosschecks)


*/


 process_request_ledger :-
	ct(
		/* fixme, use l:Request type
		'this is an Investment Calculator query',
		get_optional_singleton_sheet(ic_ui:report_details_sheet, _)
	),
 	!ledger_initialization,
 	*valid_ledger_model,
 	ct('process_request_ledger is finished.').


 ledger_initialization :-
	!cf(extract_start_and_end_date),
	!cf(stamp_result),
	!cf(extract_report_parameters),
	!cf(make_gl_viewer_report),
	!cf(write_accounts_json_report),
	!cf(extract_exchange_rates).

 valid_ledger_model :-

 	!initial_state(S0),

	once(cf(generate_bank_opening_balances_sts(Bank_Lump_STs))),
	cf('ensure system accounts exist 0'(Bank_Lump_STs)),

	handle_sts(S0, Bank_Lump_STs, S2),
	doc_add(S2, rdfs:comment, "with bank opening STSs"),

	ct('phase: opening balance GL inputs',
		/* todo implement cutoffs inside extract_gl_inputs */
		(extract_gl_inputs(phases:opening_balance, Gl_input_txs),
	 	handle_txs(S2, Gl_input_txs, S4))),
	doc_add(S4, rdfs:comment, "with Gl_input_txs"),

	(	account_by_role(rl(smsf_equity), _)
	->	ct('automated: SMSF rollover',
			smsf_rollover0(S4, S6))
	;	S4 = S6),

 	cf('phase: main 1'(S6, S7)),
 	doc_add(S7, rdfs:comment, "after main 1"),
 	cf('phase: main 2'(S7, S8)),
 	doc_add(S8, rdfs:comment, "after main 2"),

	(	account_by_role(rl(smsf_equity), _)
	->	(	!cf(smsf_distributions_reports(_)),
			!cf(smsf_income_tax_stuff(S8, S10)))
	;	S10 = S8),

	once(!cf(create_reports(S10))),
	true.


 'phase: main 1'(S0, S2) :-
 	(	is_not_cutoff
 	->	(
			!cf(handle_additional_files(Sts0)),
			!cf('extract bank statement transactions'(Sts1)),
			!cf(extract_action_inputs(_, Sts2)),
			%$>!cf(extract_livestock_data_from_ledger_request(Dom)),
			flatten([Sts0, Sts1, Sts2], Sts3)
		)
	;	Sts3 = []
	),
	handle_sts(S0, Sts3, S2),
 	!once(cf('ensure system accounts exist 0'(Sts3))).


'phase: main 2'(S2, S4) :-
 	(	is_not_cutoff
 	->	(
			!cf(extract_gl_inputs(_, Txs7)),
			!cf(extract_reallocations(_, Txs8)),
			!cf(extract_smsf_distribution(S2, Txs9)),
			%!cf(process_livestock((Processed_S_Transactions, Transactions1), Livestock_Transactions)),
			handle_txs(S2, [Txs7, Txs8, Txs9], S4)
		)
	;	S4 = S2),
	true.

 create_reports(Vanilla_state) :-

	!rp(l:start_date, Start_date),
	!rp(l:end_date, End_date),
	!'with current and historical earnings equity balances'(
		Vanilla_state,
		Start_date,
		End_date,
		Closed_books_state),
	doc_add(Closed_books_state, rdfs:comment, "with closed books"),
	check_state_transactions_accounts(Closed_books_state),

	!static_data_from_state(Closed_books_state, Closed_books_static_data),
	!static_data_from_state(Vanilla_state, Vanilla_static_data),

	(!cf('export GL'(Vanilla_static_data))),

	!cf(all_balance_reports(Vanilla_state, Closed_books_state, Sr)),
	!html_reports('final_', Sr),

	(	account_by_role(rl(smsf_equity), _)
	->	cf(smsf_member_reports('final_', Sr))
	;	true),


	!cf(cf_page(Vanilla_static_data, Sr.cf)),
	!cf(investment_reports(
		Vanilla_static_data,
		Investment_Report_Info)
	),
	Sr2 = Sr.put(ir, Investment_Report_Info),
	Ir = Sr2.ir.current,
	(	get_dict(columns,Ir,_)
	->	!'table sheet'(Ir)
	;	true),

	'create XBRL instance'(Closed_books_static_data, Sr),

	!cf(crosschecks_report0(
		Closed_books_static_data.put(reports, Sr2),
		Crosschecks_Report_Json)
	),
	Final_structured_reports = Sr2.put(crosschecks, Crosschecks_Report_Json),
	!add_result_sheets_report($>result_sheets_graph),

	!nicety(make_json_report(Final_structured_reports, reports_json)).




 'create XBRL instance'(Closed_books_static_data, Sr) :-
	!taxonomy_url_base,
	!cf('create XBRL instance'(
		Xbrl,
		Closed_books_static_data,
		Closed_books_static_data.start_date,
		Closed_books_static_data.end_date,
		Closed_books_static_data.report_currency,
		Sr.bs.current.entries,
		Sr.pl.current.entries,
		Sr.pl.historical,
	Sr.tb)),
	!add_xml_report(xbrl_instance, xbrl_instance, [Xbrl]).


  check_state_transactions_accounts(State) :-
 	doc(State, l:has_transactions, Transactions),
 	maplist(!(check_transaction_account), Transactions).


 static_data_with_dates(Sd, dates(Start_date,End_date,Exchange_date), Sd2) :-
 	Sd2 = Sd.put(start_date,Start_date).put(end_date,End_date).put(exchange_date,Exchange_date).


 all_balance_reports(Vanilla_State, Closed_books_state, Structured_Reports) :-
 	Structured_Reports = x{
		pl: x{
			current: ProfitAndLoss,
			historical: ProfitAndLoss2_Historical
			% before_closing_books: ... % if needed.
		},
		bs: x{
			current: Balance_Sheet,
			historical: Balance_Sheet2_Historical,
			delta: Balance_Sheet_delta /*todo crosscheck*/
			% before_closing_books: ... % if needed.
		},
		tb:	Trial_Balance,
		cf: Cf
	},

	historical_reports(Vanilla_State, Balance_Sheet2_Historical,ProfitAndLoss2_Historical),
	current_balance_entries(Closed_books_state, Cf,Balance_Sheet,Balance_Sheet_delta,ProfitAndLoss,Trial_Balance).


 current_balance_entries(State, Cf, Balance_Sheet,Balance_Sheet_delta,ProfitAndLoss,Trial_Balance) :-
 	!doc(State, l:note, "This State includes historical and current portions of PL posted into balance sheet"),
	static_data_from_state(State, Static_Data_with_eq),
	!cf(cashflow(Static_Data_with_eq, Cf)),
	!cf(balance_sheet_at(Static_Data_with_eq, Balance_Sheet)),
	!cf(balance_sheet_delta(Static_Data_with_eq, Balance_Sheet_delta)),
	!cf(profitandloss_between(Static_Data_with_eq, ProfitAndLoss)),
	trial_balance_report(
		$>result_property(l:exchange_rates),
		$>transactions_dict_from_state(State),
		$>result_property(l:report_currency),
		$>!result_property(l:end_date),
		$>!result_property(l:end_date),
		Trial_Balance
	).



 % only take Sr0, not transactions_by_account
 html_reports(Report_prefix, Sr0) :-
	!report_entry_tree_html_page(
		Report_prefix, Sr0.bs.delta,
		'balance sheet delta', 'balance_sheet_delta.html'),
	!report_entry_tree_html_page(
		Report_prefix, Sr0.bs.current,
		'balance sheet', 'balance_sheet.html'),
	!report_entry_tree_html_page(
		Report_prefix, Sr0.pl.current,
		'profit and loss', 'profit_and_loss.html'),
	!report_entry_tree_html_page(
		Report_prefix, Sr0.bs.historical,
		'balance sheet - historical', 'balance_sheet_historical.html'),
	!report_entry_tree_html_page(
		Report_prefix, Sr0.pl.historical,
		'profit and loss - historical', 'profit_and_loss_historical.html').


 make_gl_viewer_report :-
	%format(user_error, 'make_gl_viewer_report..~n',[]),
	Viewer_Dir = 'general_ledger_viewer',
	!absolute_file_name(my_static(Viewer_Dir), Src, [file_type(directory)]),
	!report_file_path__singleton(loc(file_name, Viewer_Dir), loc(absolute_url, Dir_Url), loc(absolute_path, Dst)),
	/* symlink or copy, which one is more convenient depends on what we're working on at the moment. However, copy is better, as it allows full reproducibility */
	% Cmd = ['ln', '-s', '-n', '-f', Src, Dst],
	Cmd = ['cp', '-r', Src, Dst],
	%format(user_error, 'shell..~q ~n',[Cmd]),
	!shell4(Cmd, _),
	%format(user_error, 'shell.~n',[]),
	!atomic_list_concat([Dir_Url, '/link.html'], Full_Url),
	!add_report_file(0,'gl_html', 'GL viewer', loc(absolute_url, Full_Url)),
	%format(user_error, 'make_gl_viewer_report done.~n',[]),
	true.

 investment_reports(Static_Data, Ir) :-
	Data =
	[
		(current,'',Static_Data),
		(since_beginning,'_since_beginning',Static_Data.put(start_date, date(1,1,1)))
	],
	maplist(
		(
			[
				(Structured_Report_Key, Suffix, Sd),
				(Structured_Report_Key-Semantic_Json)
			]
			>>
				(!investment_report_2_0(Sd, Suffix, Semantic_Json))
		),
		Data,
		Structured_Json_Pairs
	),
	dict_pairs(Ir, _, Structured_Json_Pairs).

/*
To ensure that each response references the shared taxonomy via a unique url,
a flag can be used when running the server, for example like this:
```swipl -s prolog_server.pl  -g "set_flag(prepare_unique_taxonomy_url, true),run_simple_server"```
This is done with a symlink. This allows to bypass cache, for example in pesseract.
*/
 taxonomy_url_base :-
	!symlink_tmp_taxonomy_to_static_taxonomy(Unique_Taxonomy_Dir_Url),
	(	get_flag(prepare_unique_taxonomy_url, true)
	->	Taxonomy_Dir_Url = Unique_Taxonomy_Dir_Url
	;	Taxonomy_Dir_Url = 'taxonomy/'),
	!result_add_property(l:taxonomy_url_base, Taxonomy_Dir_Url).

 symlink_tmp_taxonomy_to_static_taxonomy(Unique_Taxonomy_Dir_Url) :-
	!my_request_tmp_dir(loc(tmp_directory_name,Tmp_Dir)),
	!server_public_url(Server_Public_Url),
	!atomic_list_concat([Server_Public_Url, '/tmp/', Tmp_Dir, '/taxonomy/'], Unique_Taxonomy_Dir_Url),
	!absolute_tmp_path(loc(file_name, 'taxonomy'), loc(absolute_path, Tmp_Taxonomy)),
	!resolve_specifier(loc(specifier, my_static('taxonomy')), loc(absolute_path,Static_Taxonomy)),
	Cmd = ['ln', '-s', '-n', '-f', Static_Taxonomy, Tmp_Taxonomy],
	%format(user_error, 'shell..~q ~n',[Cmd]),
	!shell4(Cmd, _).
	%format(user_error, 'shell.~n',[]).

	
/*

	extraction of input data from request xml
	
*/	
   
 extract_report_currency :-
	!report_details(Details),
	doc_value(Details, ic:currency, C),
	atom_string(Ca, C),
	Report_Currency = [Ca],
	!result_add_property(l:report_currency, Report_Currency).

/*
 If an investment was held prior to the from date then it MUST have an opening market value if the reports are expressed in market rather than cost. You can't mix market value and cost in one set of reports. One or the other.
 Market or Cost. M or C.
 Cost value per unit will always be there if there are units of anything i.e. sheep for livestock trading or shares for Investments. But I suppose if you do not find any market values then assume cost basis.
*/

 'extract "cost_or_market"' :-
	!report_details(D),
	doc_value(D, ic:cost_or_market, C),
	(	(	e(C, ic:cost)
		;	e(C, ic:market))
	->	true
	;	throw_format('invalid ic:cost_or_market: ~q',[C])),
	!doc_add($>result, l:cost_or_market, C).

 'extract "output_dimensional_facts"' :-
	!result_add_property(l:output_dimensional_facts, on).
	
 extract_start_and_end_date :-
 	!report_details(D),
	!read_date(D, ic:from, Start_Date),
	!read_date(D, ic:to, End_Date),
	!result(R),
	!doc_add(R, l:start_date, Start_Date),
	!doc_add(R, l:end_date, End_Date).

 stamp_result :-
	!result(Result),
	!get_time(TimeStamp),
	!stamp_date_time(TimeStamp, DateTime, 'UTC'),
	!doc_add(Result, l:timestamp, DateTime),
	doc_add($>result, l:type, l:ledger).

 extract_report_parameters :-
	!cf('extract "output_dimensional_facts"'),
	!cf('extract "cost_or_market"'),
	!cf(extract_report_currency),
	!cf('extract action verbs'),
	!cf('extract bank accounts'),
	!cf('extract GL accounts').


 read_ic_n_sts_processed(N) :-
	b_current_num_with_default(ic_n_sts_processed, 0, N).

 bump_ic_n_sts_processed :-
	read_ic_n_sts_processed(N),
	Next is N + 1,
	b_setval(ic_n_sts_processed, Next).


 report_details(Details) :-
	get_singleton_sheet_data(ic_ui:report_details_sheet, Details).


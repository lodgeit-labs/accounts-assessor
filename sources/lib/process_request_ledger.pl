
 process_request_ledger :-
	ct(
		'this is an Investment Calculator query',
		doc($>request_data, ic_ui:report_details, _)
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
 	initial_state(S0),

	once(cf(generate_bank_opening_balances_sts(Bank_Lump_STs))),
	cf('ensure system accounts exist 0'(Bank_Lump_STs)),

	handle_sts(S0, Bank_Lump_STs, S2),

	ct('phase: opening balance GL inputs',
		(extract_gl_inputs(phases:opening_balance, Gl_input_txs),
	 	handle_txs(S2, Gl_input_txs, S4))),

	(	account_by_role(rl(smsf_equity), _)
	->	ct('automated: SMSF rollover',
			smsf_rollover0(S4, S6))
	;	S4 = S6),

 	cf('phase: main 1'(S6, S7)),
 	cf('phase: main 2'(S7, S8)),

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

 create_reports(State) :-
	!static_data_from_state(State, Static_Data),
	!cf('export GL'(Static_Data)),
	!all_balance_reports(State, Sr),
	!html_reports('final_', Sr),
	!misc_reports(Static_Data, Static_Data.outstanding, Sr, _Sr2),
	!taxonomy_url_base,
	!cf('create XBRL instance'(Xbrl, Static_Data, Static_Data.start_date, Static_Data.end_date, Static_Data.report_currency, Sr.bs.current.entries, Sr.pl.current.entries, Sr.pl.historical, Sr.tb)),
	!add_xml_report(xbrl_instance, xbrl_instance, [Xbrl]).


 trial_balance_between2(State, Trial_Balance) :-
	!cf(trial_balance_between(
		$>result_property(l:exchange_rates),
		$>transactions_dict_from_state(State),
		$>result_property(l:report_currency),
		$>!result_property(l:end_date),
		$>!result_property(l:end_date),
		Trial_Balance
	)).


 check_state_transactions_accounts(State) :-
 	doc(State, l:has_transactions, Transactions),
 	maplist(!(check_transaction_account), Transactions).


 static_data_with_dates(Sd, dates(Start_date,End_date,Exchange_date), Sd2) :-
 	Sd2 = Sd.put(start_date,Start_date).put(end_date,End_date).put(exchange_date,Exchange_date).


 all_balance_reports(State, Structured_Reports) :-
 	Structured_Reports = _{
		pl: _{
			current: ProfitAndLoss,
			historical: ProfitAndLoss2_Historical
		},
		bs: _{
			current: Balance_Sheet,
			historical: Balance_Sheet2_Historical,
			delta: Balance_Sheet_delta /*todo crosscheck*/
		},
		tb:	$>trial_balance_between2(State),
		cf: Cf
	},
	check_state_transactions_accounts(State),
	current_balance_entries(State, Cf,Balance_Sheet,Balance_Sheet_delta,ProfitAndLoss),
	historical_balance_entries(State, Balance_Sheet2_Historical,ProfitAndLoss2_Historical).


 current_balance_entries(State, Cf, Balance_Sheet,Balance_Sheet_delta,ProfitAndLoss) :-
	!'with current and historical earnings equity balances'(
		State,
		$>!rp(l:start_date),
		$>!rp(l:end_date),
		State2),
	static_data_from_state(State2, Static_Data_with_eq),
	!cf(cashflow(Static_Data_with_eq, Cf)),
	!cf(balance_sheet_at(Static_Data_with_eq, Balance_Sheet)),
	!cf(balance_sheet_delta(Static_Data_with_eq, Balance_Sheet_delta)),
	!cf(profitandloss_between(Static_Data_with_eq, ProfitAndLoss)).


 historical_balance_entries(State, Balance_Sheet2_Historical,ProfitAndLoss2_Historical) :-
	historical_dates(Dates),
	Dates = dates(Start_date,End_date,_),
	!'with current and historical earnings equity balances'(State,Start_date,End_date,State2),
	static_data_from_state(State2, Sd),
 	static_data_with_dates(Sd, Dates, Sd2),
	!cf(balance_sheet_at(Sd2, Balance_Sheet2_Historical)),
	!cf(profitandloss_between(Sd2, ProfitAndLoss2_Historical)).


 static_data_historical(Static_Data, Static_Data_Historical) :-
	add_days(Static_Data.start_date, -1, Before_Start),
	Static_Data_Historical = Static_Data.put(
		start_date, date(1,1,1)).put(
		end_date, Before_Start).put(
		exchange_date, Static_Data.start_date).

 historical_dates(dates(Start_date,End_date,Exchange_date)) :-
 	!rp(l:start_date, Current_start_date),
 	%!rp(l:end_date, Current_end_date),
 	Start_date = date(1,1,1),
	add_days(Current_start_date, -1, End_date),
	Exchange_date = Current_start_date.

 % only take Sr0, not transactions_by_account
 html_reports(Report_prefix, Sr0) :-

	(	account_by_role(rl(smsf_equity), _)
	->	cf(smsf_member_reports(Report_prefix, Sr0))
	;	true),

	!report_entry_tree_html_page(
		Report_prefix, Sr0.bs.current,
		'balance sheet', 'balance_sheet.html'),
	!report_entry_tree_html_page(
		Report_prefix, Sr0.bs.delta,
		'balance sheet delta', 'balance_sheet_delta.html'),
	!report_entry_tree_html_page(
		Report_prefix, Sr0.pl.current,
		'profit and loss', 'profit_and_loss.html'),
	!report_entry_tree_html_page(
		Report_prefix, Sr0.bs.historical,
		'balance sheet - historical', 'balance_sheet_historical.html'),
	!report_entry_tree_html_page(
		Report_prefix, Sr0.pl.historical,
		'profit and loss - historical', 'profit_and_loss_historical.html').


 misc_reports(
	Static_Data,
	Outstanding,
	Sr0,
	Sr5				% Structured Reports - Dict <Report Abbr : _>
) :-
	!cf(cf_page(Static_Data, Sr0.cf)),
	!cf(investment_reports(Static_Data.put(outstanding, Outstanding), Investment_Report_Info)),
	Sr1 = Sr0.put(ir, Investment_Report_Info),
	!cf(crosschecks_report0(Static_Data.put(reports, Sr1), Crosschecks_Report_Json)),
	Sr5 = Sr1.put(crosschecks, Crosschecks_Report_Json),
	!make_json_report(Sr1, reports_json).


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
	!request_data(Request_Data),
	doc(Request_Data, ic_ui:report_details, D),
	doc_value(D, ic:currency, C),
	atom_string(Ca, C),
	Report_Currency = [Ca],
	!result_add_property(l:report_currency, Report_Currency).

/*
 If an investment was held prior to the from date then it MUST have an opening market value if the reports are expressed in market rather than cost. You can't mix market value and cost in one set of reports. One or the other.
 Market or Cost. M or C.
 Cost value per unit will always be there if there are units of anything i.e. sheep for livestock trading or shares for Investments. But I suppose if you do not find any market values then assume cost basis.
*/

 'extract "cost_or_market"' :-
	!request_data(Request_Data),
	doc(Request_Data, ic_ui:report_details, D),
	doc_value(D, ic:cost_or_market, C),
	(	rdf_equal2(C, ic:cost)
	->	Cost_Or_Market = cost
	;	Cost_Or_Market = market),
	!doc_add($>result, l:cost_or_market, Cost_Or_Market).
	
 'extract "output_dimensional_facts"' :-
	!result_add_property(l:output_dimensional_facts, on).
	
 extract_start_and_end_date :-
 	!doc($>request_data, ic_ui:report_details, D),
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


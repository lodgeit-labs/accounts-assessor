
 process_request_ledger :-
	cf(extract_report_parameters),
 	push_context('phase:'),
 	initial_state(S0),
gtrace,
	ct('automated: post bank opening balances',
		(generate_bank_opening_balances_sts(Bank_Lump_STs),
		'ensure system accounts exist 0'(Bank_Lump_STs),
		handle_sts(S0, Bank_Lump_STs, S2))),

	ct('phase: opening balance',
		(extract_gl_inputs(phases:opening_balance, Gl_input_txs),
	 	handle_txs(S2, Gl_input_txs, S4))),

	(	account_by_role(rl(smsf_equity), _)
	->	ct('automated: SMSF rollover',
			smsf_rollover0(S4, S6))
	;	S4 = S6),

	cf('phase: main'(S6, S8)),

	(	account_by_role(rl(smsf_equity), _)
	->	(	!cf(smsf_distributions_reports(_)),
			!cf(smsf_income_tax_stuff(S8, S10)))
	;	S10 = S8),

	once(!cf(create_reports(S10))),
	true.



'phase: main'(S0, S4) :-
	% a bunch of ST's.

	!cf(handle_additional_files(Txs0)),
	!cf('extract bank statement transactions'(Txs1)),
	!cf(extract_action_inputs(_, Txs2)),
	%$>!cf(extract_livestock_data_from_ledger_request(Dom))

	flatten([Txs0, Txs1, Txs2], Sts0),

 	handle_sts(S0, Sts0, S2),
 	!cf('ensure system accounts exist 0'(Sts0)),

	Txs0 = [
		$>!cf(extract_gl_inputs(_)),
		$>!cf(extract_reallocations(_)),
		$>!cf(extract_smsf_distribution(S2))
	],
	handle_txs(S2, Txs0, S4),

	%!cf(process_livestock((Processed_S_Transactions, Transactions1), Livestock_Transactions)),

	true.


create_reports(State) :-
	!static_data_from_state(State, Static_Data),

	%!'with current and historical earnings equity balances'(S4,S_out).

	!balance_entries(Static_Data, Sr),
	!other_reports2('final_', Static_Data, Sr),
	!other_reports(Static_Data, Static_Data.outstanding, Sr, _Sr2),
	!taxonomy_url_base,
	!cf('create XBRL instance'(Xbrl, Static_Data, Static_Data.start_date, Static_Data.end_date, Static_Data.report_currency, Sr.bs.current, Sr.pl.current, Sr.pl.historical, Sr.tb)),
	!add_xml_report(xbrl_instance, xbrl_instance, [Xbrl]).


balance_entries(
	Static_Data,				% Static Data
	Structured_Reports
) :-
	static_data_historical(Static_Data, Static_Data_Historical),
	maplist(!(check_transaction_account), Static_Data.transactions),
	!cf(trial_balance_between(
		Static_Data.exchange_rates,
		Static_Data.transactions_by_account,
		Static_Data.report_currency,
		Static_Data.end_date,
		Static_Data.end_date,
		Trial_Balance
	)),
	!cf(balance_sheet_at(Static_Data, Balance_Sheet)),
	!cf(balance_sheet_delta(Static_Data, Balance_Sheet_delta)),
	!cf(balance_sheet_at(Static_Data_Historical, Balance_Sheet2_Historical)),
	!cf(profitandloss_between(Static_Data, ProfitAndLoss)),
	!cf(profitandloss_between(Static_Data_Historical, ProfitAndLoss2_Historical)),
	!cf(cashflow(Static_Data, Cf)),

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
		tb: Trial_Balance,
		cf: Cf
	}.


static_data_historical(Static_Data, Static_Data_Historical) :-
	add_days(Static_Data.start_date, -1, Before_Start),
	Static_Data_Historical = Static_Data.put(
		start_date, date(1,1,1)).put(
		end_date, Before_Start).put(
		exchange_date, Static_Data.start_date).



 other_reports(
	Static_Data,
	Outstanding,
	Sr0,
	Sr5				% Structured Reports - Dict <Report Abbr : _>
) :-
	!cf(cf_page(Static_Data, Sr0.cf)),
	!cf('export GL'(Static_Data, Static_Data.transactions, Gl)),
	!cf(make_json_report(Gl, general_ledger_json)),
	!cf(make_gl_viewer_report),

	!cf(investment_reports(Static_Data.put(outstanding, Outstanding), Investment_Report_Info)),
	Sr1 = Sr0.put(ir, Investment_Report_Info),

	!cf(crosschecks_report0(Static_Data.put(reports, Sr1), Crosschecks_Report_Json)),
	Sr5 = Sr1.put(crosschecks, Crosschecks_Report_Json),
	!make_json_report(Sr1, reports_json).


 other_reports2(Report_prefix, Static_Data, Sr0) :-
	!static_data_historical(Static_Data, Static_Data_Historical),
	(	account_by_role(rl(smsf_equity), _)
	->	cf(smsf_member_reports(Report_prefix, Sr0))
	;	true),
	!report_entry_tree_html_page(Report_prefix, Static_Data, Sr0.bs.current, 'balance sheet', 'balance_sheet.html'),
	!report_entry_tree_html_page(Report_prefix, Static_Data, Sr0.bs.delta, 'balance sheet delta', 'balance_sheet_delta.html'),
	!report_entry_tree_html_page(Report_prefix, Static_Data_Historical, Sr0.bs.historical, 'balance sheet - historical', 'balance_sheet_historical.html'),
	!report_entry_tree_html_page(Report_prefix, Static_Data, Sr0.pl.current, 'profit and loss', 'profit_and_loss.html'),
	!report_entry_tree_html_page(Report_prefix, Static_Data_Historical, Sr0.pl.historical, 'profit and loss - historical', 'profit_and_loss_historical.html').



make_gl_viewer_report :-
	%format(user_error, 'make_gl_viewer_report..~n',[]),
	Viewer_Dir = 'general_ledger_viewer',
	!absolute_file_name(my_static(Viewer_Dir), Src, [file_type(directory)]),
	!report_file_path(loc(file_name, Viewer_Dir), loc(absolute_url, Dir_Url), loc(absolute_path, Dst)),

	/* symlink or copy, which one is more convenient depends on what we're working on */
	Cmd = ['ln', '-s', '-n', '-f', Src, Dst],
	%Cmd = ['cp', '-r', Src, Dst],

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
	!doc_add($>result, l:output_dimensional_facts, on).
	
 extract_start_and_end_date :-
	!request_data(Request_Data),
	!doc(Request_Data, ic_ui:report_details, D),
	!read_date(D, ic:from, Start_Date),
	!read_date(D, ic:to, End_Date),
	!result(R),
	!doc_add(R, l:start_date, Start_Date),
	!doc_add(R, l:end_date, End_Date).

 extract_request_details :-
	!result(Result),
	!get_time(TimeStamp),
	!stamp_date_time(TimeStamp, DateTime, 'UTC'),
	!doc_add(Result, l:timestamp, DateTime),
	doc_add($>result, l:type, l:ledger).

 extract_report_parameters :-
	cf(extract_start_and_end_date),
	!cf(extract_request_details),
	!cf('extract "output_dimensional_facts"'),
	!cf('extract "cost_or_market"'),
	!cf(extract_report_currency),
	!cf('extract action verbs'),
	!cf('extract bank accounts'),
	!cf('extract GL accounts'),
	!cf(make_gl_viewer_report),
	!cf(write_accounts_json_report),
	!cf(extract_exchange_rates).

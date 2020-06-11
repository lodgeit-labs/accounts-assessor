

process_request_ledger(File_Path, Dom) :-
	inner_xml(Dom, //reports/balanceSheetRequest, _),
	!validate_xml2(File_Path, 'bases/Reports.xsd'),

	Data = (Dom, Start_Date, End_Date, Output_Dimensional_Facts, Cost_Or_Market, Report_Currency),
	!extract_request_details(Dom),
	!extract_start_and_end_date(Dom, Start_Date, End_Date),
	!extract_output_dimensional_facts(Dom, Output_Dimensional_Facts),
	!extract_cost_or_market(Dom, Cost_Or_Market),
	!extract_report_currency(Dom, Report_Currency),
	!extract_action_verbs_from_bs_request(Dom),
	!extract_s_transactions0(Dom, S_Transactions),

	/*profile*/(!process_request_ledger2(Data, S_Transactions, _, _Transactions)).
	%process_request_ledger_debug(Dom, S_Transactions).

/* a little debugging facitliy that tries processing s_transactions one by one until it runs into an error */
process_request_ledger_debug(Data, S_Transactions0) :-
	findall(Count, ggg(Data, S_Transactions0, Count), Counts), writeq(Counts).

ggg(Data, S_Transactions0, Count) :-
	Count = 20000,
	%between(100, $>length(S_Transactions0), Count),
	take(S_Transactions0, Count, STs),
	format(user_error, 'total s_transactions: ~q~n', [$>length(S_Transactions0)]),
	format(user_error, '~q: ~q ~n ~n', [$>length(STs), $>last(STs)]),
	profile(once(process_request_ledger2(Data, STs, _Structured_Reports, _))).
	/*length(Structured_Reports.crosschecks.errors, L),
	(	L \= 2
	->	true
	;	(gtrace,format(user_error, '~q: ~q ~n', [Count, Structured_Reports.crosschecks.errors]))).*/



process_request_ledger2((Dom, Start_Date, End_Date, Output_Dimensional_Facts, Cost_Or_Market, Report_Currency),   S_Transactions, Structured_Reports, Transactions) :-
	%request(Request),
	%doc_add(Request, l:kind, l:ledger_request),
	!extract_accounts,
	!extract_livestock_data_from_ledger_request(Dom),
	!extract_exchange_rates(Cost_Or_Market, Dom, S_Transactions, Start_Date, End_Date, Report_Currency, Exchange_Rates),
	!extract_invoices_payable(Dom),
	!process_ledger(
		Cost_Or_Market,
		S_Transactions,
		Start_Date,
		End_Date,
		Exchange_Rates,
		Report_Currency,
		Transactions,
		Outstanding,
		Processed_Until_Date),
	/* if some s_transaction failed to process, there should be an alert created by now. Now we just compile a report up until that transaction. It would maybe be cleaner to do this by calling process_ledger a second time */
	dict_from_vars(Static_Data0,
		[Cost_Or_Market,
		Output_Dimensional_Facts,
		Start_Date,
		Exchange_Rates,
		Transactions,
		Report_Currency,
		Outstanding
	]),
	Static_Data0b = Static_Data0.put([
		end_date=Processed_Until_Date,
		exchange_date=Processed_Until_Date
	]),
	!transactions_by_account(Static_Data0b, Transactions_By_Account1),
	Static_Data1 = Static_Data0b.put([transactions_by_account=Transactions_By_Account1]),
	(	account_by_role(rl(smsf_equity), _)
	->	(
			update_static_data_with_transactions(
				Static_Data1,
				$>smsf_income_tax_stuff(Static_Data1),
				Static_Data2)
		)
	;	Static_Data2 = Static_Data1),
	check_trial_balance2(Exchange_Rates, Static_Data2.transactions_by_account, Report_Currency, Static_Data2.end_date, Start_Date, Static_Data2.end_date),
	once(!create_reports(Static_Data2, Structured_Reports)).

update_static_data_with_transactions(In, Txs, Out) :-
	append(In.transactions,$>flatten(Txs),Transactions2),
	Static_Data1b = In.put([transactions=Transactions2]),
	!transactions_by_account(Static_Data1b, Transactions_By_Account),
	Out = Static_Data1b.put([transactions_by_account=Transactions_By_Account]).



check_trial_balance2(Exchange_Rates, Transactions_By_Account, Report_Currency, End_Date, Start_Date, End_Date) :-
	!trial_balance_between(Exchange_Rates, Transactions_By_Account, Report_Currency, End_Date, Start_Date, End_Date, [Trial_Balance_Section]),
	(
		(
			trial_balance_ok(Trial_Balance_Section)
		;
			Report_Currency = []
		)
	->
		true
	;
		(	term_string(trial_balance(Trial_Balance_Section), Tb_Str),
			add_alert('SYSTEM_WARNING', Tb_Str))
	).



create_reports(
	Static_Data,				% Static Data
	Sr2							% Structured Reports (dict)
) :-
	!balance_entries(Static_Data, Sr),
	!taxonomy_url_base,
	!format(user_error, 'create_instance..', []),
	!create_instance(Xbrl, Static_Data, Static_Data.start_date, Static_Data.end_date, Static_Data.report_currency, Sr.bs.current, Sr.pl.current, Sr.pl.historical, Sr.tb),
	!add_xml_report(xbrl_instance, xbrl_instance, [Xbrl]),
	!other_reports(Static_Data, Static_Data.outstanding, Sr, Sr2).


balance_entries(
	Static_Data,				% Static Data
	Structured_Reports
) :-
	static_data_historical(Static_Data, Static_Data_Historical),
	maplist(!check_transaction_account, Static_Data.transactions),
	/* sum up the coords of all transactions for each account and apply unit conversions */
	!trial_balance_between(Static_Data.exchange_rates, Static_Data.transactions_by_account, Static_Data.report_currency, Static_Data.end_date, Static_Data.start_date, Static_Data.end_date, Trial_Balance),
	!balance_sheet_at(Static_Data, Balance_Sheet),
	!balance_sheet_delta(Static_Data, Balance_Sheet_delta),
	!balance_sheet_at(Static_Data_Historical, Balance_Sheet2_Historical),
	!profitandloss_between(Static_Data, ProfitAndLoss),
	!profitandloss_between(Static_Data_Historical, ProfitAndLoss2_Historical),
	!cashflow(Static_Data, Cf),

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
	!static_data_historical(Static_Data, Static_Data_Historical),
	(	account_by_role(rl(smsf_equity), _)
	->	smsf_member_reports(Sr0)
	;	true),
	!report_entry_tree_html_page(Static_Data, Sr0.bs.current, 'balance sheet', 'balance_sheet.html'),
	!report_entry_tree_html_page(Static_Data, Sr0.bs.delta, 'balance sheet delta', 'balance_sheet_delta.html'),
	!report_entry_tree_html_page(Static_Data_Historical, Sr0.bs.historical, 'balance sheet - historical', 'balance_sheet_historical.html'),
	!report_entry_tree_html_page(Static_Data, Sr0.pl.current, 'profit and loss', 'profit_and_loss.html'),
	!report_entry_tree_html_page(Static_Data_Historical, Sr0.pl.historical, 'profit and loss - historical', 'profit_and_loss_historical.html'),
	!cf_page(Static_Data, Sr0.cf),

	!gl_export(Static_Data, Static_Data.transactions, Gl),
	!make_json_report(Gl, general_ledger_json),
	!make_gl_viewer_report,

	!investment_reports(Static_Data.put(outstanding, Outstanding), Investment_Report_Info),
	Sr1 = Sr0.put(ir, Investment_Report_Info),

	!crosschecks_report0(Static_Data.put(reports, Sr1), Crosschecks_Report_Json),
	Sr5 = Sr1.put(crosschecks, Crosschecks_Report_Json),
	!make_json_report(Sr1, reports_json).


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
	!request_add_property(l:taxonomy_url_base, Taxonomy_Dir_Url).

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
   
extract_report_currency(Dom, Report_Currency) :-
	!request_data(Request_Data),
	(	doc(Request_Data, ic_ui:report_details, D)
	->	(
			doc_value(D, ic:currency, C),
			atom_string(Ca, C),
			Report_Currency = [Ca]
		)
	;	inner_xml_throw(Dom, //reports/balanceSheetRequest/reportCurrency/unitType, Report_Currency)).


/*
*If an investment was held prior to the from date then it MUST have an opening market value if the reports are expressed in market rather than cost.You can't mix market valu
e and cost in one set of reports. One or the other.
+       Market or Cost. M or C.
+       Cost value per unit will always be there if there are units of anything i.e. sheep for livestock trading or shares for Investments. But I suppose if you do not find any marke
t values then assume cost basis.*/

extract_cost_or_market(Dom, Cost_Or_Market) :-
	!request_data(Request_Data),
	(	doc(Request_Data, ic_ui:report_details, D)
	->	(
			doc_value(D, ic:cost_or_market, C),
			(	rdf_equal2(C, ic:cost)
			->	Cost_Or_Market = cost
			;	Cost_Or_Market = market)
		)
	;
	(
		inner_xml(Dom, //reports/balanceSheetRequest/costOrMarket, [Cost_Or_Market])
	->
		(
			member(Cost_Or_Market, [cost, market])
		->
			true
		;
			throw_string('//reports/balanceSheetRequest/costOrMarket tag\'s content must be "cost" or "market"')
		)
	;
		Cost_Or_Market = market
	)
	).
	
extract_output_dimensional_facts(Dom, Output_Dimensional_Facts) :-
	(
		inner_xml(Dom, //reports/balanceSheetRequest/outputDimensionalFacts, [Output_Dimensional_Facts])
	->
		(
			member(Output_Dimensional_Facts, [on, off])
		->
			true
		;
			throw_string('//reports/balanceSheetRequest/outputDimensionalFacts tag\'s content must be "on" or "off"')
		)
	;
		Output_Dimensional_Facts = on
	).
	
extract_start_and_end_date(_Dom, Start_Date, End_Date) :-
	!request_data(Request_Data),
	!doc(Request_Data, ic_ui:report_details, D),
	!doc_value(D, ic:from, Start_Date),
	!doc_value(D, ic:to, End_Date),
	!result(R),
	!doc_add(R, l:start_date, Start_Date),
	!doc_add(R, l:end_date, End_Date),
	(	Start_Date = date(1,1,1)
	->	throw_string(['start date missing?'])
	;	true),
	(	End_Date = date(1,1,1)
	->	throw_string(['end date missing?'])
	;	true)
	.

extract_request_details(Dom) :-
	assertion(Dom = [element(_,_,_)]),
	!request(Request),
	!result(Result),
	(	xpath(Dom, //reports/balanceSheetRequest/company/clientcode, element(_, [], [Client_code_atom]))
	->	(
			!atom_string(Client_code_atom, Client_code_string),
			!doc_add(Request, l:client_code, Client_code_string)
		)
	;	true),
	!get_time(TimeStamp),
	!stamp_date_time(TimeStamp, DateTime, 'UTC'),
	!doc_add(Result, l:timestamp, DateTime).

/*
:- comment(Structured_Reports:
	the idea is that the dicts containing the high-level, semantic information of all reports would be passed all the way up, and we'd have some test runner making use of that / generating a lot of permutations of requests and checking the results computationally, in addition to endpoint_tests checking report files against saved versions.
Not sure if/when we want to work on that.
*/


	/*
	how we could test inference of s_transactions from gl transactions:
	gl_doc_eq_json(Transactions, Transactions_Json),
	doc_init,
	gl_doc_eq_json(Transactions2, Transactions_Json),
	process_request_ledger2(Dom, S_Transactions2, _, Transactions2),
	assertion(eq(S_Transactions, S_Transactions2)).
	...
	gl_json :-
		maplist(transaction_to_dict, Transactions, T0),
	...
	*/


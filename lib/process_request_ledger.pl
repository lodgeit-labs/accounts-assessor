

:- rdet(process/2).


process_request_ledger(File_Name, Dom) :-
	/* does it look like a ledger request? */
	% ideally should be able to omit this and have this check be done as part of the schema validation, but currently  process_request.pl is using this to check whether to use this endpoint.
	inner_xml(Dom, //reports/balanceSheetRequest, _),

	absolute_tmp_path(File_Name, Instance_File),
	absolute_file_name(my_schemas('bases/Reports.xsd'), Schema_File, []),
	validate_xml(Instance_File, Schema_File, Schema_Errors),
	(	Schema_Errors = []
	->	process_xml_ledger_request2(Dom)
	;	maplist(add_alert(error), Schema_Errors)
	).


process_xml_ledger_request2(Dom) :-
	/*
		first let's extract data from the request
	*/
	extract_output_dimensional_facts(Dom, Output_Dimensional_Facts),
	extract_cost_or_market(Dom, Cost_Or_Market),
	extract_default_currency(Dom, Default_Currency),
	extract_report_currency(Dom, Report_Currency),
	extract_action_verbs_from_bs_request(Dom),
	extract_account_hierarchy_from_request_dom(Dom, Accounts0),
	inner_xml(Dom, //reports/balanceSheetRequest/startDate, [Start_Date_Atom]),
	parse_date(Start_Date_Atom, Start_Date),
	doc(R, rdf:type, l:request),
	doc_add(R, l:start_date, Start_Date),
	inner_xml(Dom, //reports/balanceSheetRequest/endDate, [End_Date_Atom]),
	parse_date(End_Date_Atom, End_Date),
	doc_add(R, l:end_date, End_Date),
	
	extract_exchange_rates(Dom, Start_Date, End_Date, Default_Currency, Exchange_Rates),
	extract(Dom),
    extract_s_transactions(Dom, Start_Date_Atom, S_Transactions),
	/* 
		generate transactions (ledger entries) from s_transactions
	*/
	process_ledger(
		Cost_Or_Market,
		S_Transactions,
		Start_Date,
		End_Date,
		Exchange_Rates,
		Report_Currency,
		Accounts0,
		Accounts,
		Transactions,
		Transactions_By_Account,
		Outstanding,
		Processed_Until_Date,
		Gl),
	/*print_relevant_exchange_rates_comment(Report_Currency, End_Date, Exchange_Rates, Transactions),*/
	/*writeln("<!-- exchange rates 2:"),writeln(Exchange_Rates),writeln("-->"),*/
	process_invoices_payable(Dom),
	dict_from_vars(Static_Data0,
		[Cost_Or_Market, Output_Dimensional_Facts, Start_Date, Exchange_Rates, Accounts, Transactions, Report_Currency, Gl, Transactions_By_Account, Outstanding]),
	Static_Data1 = Static_Data0.put([
		end_date=Processed_Until_Date
		,exchange_date=Processed_Until_Date
	]),
	create_reports(Static_Data1).

create_reports(Static_Data) :-
	static_data_historical(Static_Data, Static_Data_Historical),
	balance_entries(Static_Data, Static_Data_Historical, Entries),
	dict_vars(Entries, [Balance_Sheet, ProfitAndLoss, Balance_Sheet2_Historical, ProfitAndLoss2_Historical, Trial_Balance]),
	taxonomy_url_base,
	create_instance(Xbrl, Static_Data, Static_Data.start_date, Static_Data.end_date, Static_Data.accounts, Static_Data.report_currency, Balance_Sheet, ProfitAndLoss, ProfitAndLoss2_Historical, Trial_Balance),
	other_reports(Static_Data, Static_Data_Historical, Static_Data.outstanding, Balance_Sheet, ProfitAndLoss, Balance_Sheet2_Historical, ProfitAndLoss2_Historical, Trial_Balance),
	add_xml_report(xbrl_instance, xbrl_instance, [Xbrl]).

balance_entries(Static_Data, Static_Data_Historical, Entries) :-
	/* sum up the coords of all transactions for each account and apply unit conversions */
	trial_balance_between(Static_Data.exchange_rates, Static_Data.accounts, Static_Data.transactions_by_account, Static_Data.report_currency, Static_Data.end_date, Static_Data.start_date, Static_Data.end_date, Trial_Balance),
	balance_sheet_at(Static_Data, Balance_Sheet),
	profitandloss_between(Static_Data, ProfitAndLoss),
	balance_sheet_at(Static_Data_Historical, Balance_Sheet2_Historical),
	profitandloss_between(Static_Data_Historical, ProfitAndLoss2_Historical),
	assertion(ground((Balance_Sheet, ProfitAndLoss, ProfitAndLoss2_Historical, Trial_Balance))),
	dict_from_vars(Entries, [Balance_Sheet, ProfitAndLoss, Balance_Sheet2_Historical, ProfitAndLoss2_Historical, Trial_Balance]).


static_data_historical(Static_Data, Static_Data_Historical) :-
	add_days(Static_Data.start_date, -1, Before_Start),
	Static_Data_Historical = Static_Data.put(
		start_date, date(1,1,1)).put(
		end_date, Before_Start).put(
		exchange_date, Static_Data.start_date).


other_reports(Static_Data, Static_Data_Historical, Outstanding, Balance_Sheet, ProfitAndLoss, Balance_Sheet2_Historical, ProfitAndLoss2_Historical, Trial_Balance) :-
	investment_reports(Static_Data, Outstanding, Investment_Report_Info),
	bs_page(Static_Data, Balance_Sheet),
	pl_page(Static_Data, ProfitAndLoss, ''),
	pl_page(Static_Data_Historical, ProfitAndLoss2_Historical, '_historical'),
	make_json_report(Static_Data.gl, general_ledger_json),
	make_gl_viewer_report,

	Structured_Reports = _{
		pl: _{
			current: ProfitAndLoss,
			historical: ProfitAndLoss2_Historical
		},
		ir: Investment_Report_Info,
		bs: _{
			current: Balance_Sheet,
			historical: Balance_Sheet2_Historical
		},
		tb: Trial_Balance
	},
	report(Static_Data.put(reports, Structured_Reports), Crosschecks_Report_Json),
	make_json_report(Structured_Reports.put(crosschecks, Crosschecks_Report_Json), reports_json).

make_gl_viewer_report :-
	Viewer_Dir = 'general_ledger_viewer',
	absolute_file_name(my_static(Viewer_Dir), Viewer_Dir_Absolute, [file_type(directory)]),
	report_file_path(Viewer_Dir, Url, Tmp_Viewer_Dir_Absolute),
	atomic_list_concat(['cp -r ', Viewer_Dir_Absolute, ' ', Tmp_Viewer_Dir_Absolute], Cmd),
	shell(Cmd),
	atomic_list_concat([Url, '/gl.html'], Url_With_Slash),
	report_entry('GL viewer', Url_With_Slash, 'gl_html').
	
make_json_report(Dict, Fn) :-
	Title = Key, Fn = Key,
	dict_json_text(Dict, Json_Text),
	atomic_list_concat([Fn, '.json'], Fn2),
	report_item(Fn2, Json_Text, Report_File_URL),
	report_entry(Title, Report_File_URL, Key).


investment_reports(Static_Data, Outstanding, Ir) :-
	catch_maybe_with_backtrace(
		investment_reports2(Static_Data, Outstanding, Ir),
		Err,
		(
			term_string(Err, Err_Str),
			format(string(Msg), 'investment reports fail: ~w', [Err_Str]),
			add_alert('SYSTEM_WARNING', Msg),
			Ir =  _{}
		)
	).

investment_reports2(Static_Data, Outstanding, Ir) :-
	(Static_Data.report_currency = [_] -> true ; throw_string('report currency expected')),
	/*get_dict(start_date, Static_Data, Report_Start),
	add_days(Report_Start, -1, Before_Start),*/

	% report period	
	investment_report_2(Static_Data, Outstanding, '', Json1),

	/* TODO: we cant do all_time without market values, use last known? */
	investment_report_2(Static_Data.put(start_date, date(1,1,1)), Outstanding, '_since_beginning', Json2),
	
	% historical
	%investment_report_2(Static_Data.put(start_date, date(1,1,1)).put(end_date, Before_Start), Outstanding, '_historical', Json3, Files3),
	Ir =  _{
	%	 historical: Json3,
		 current: Json1,
		 since_beginning: Json2
		}.
/*
To ensure that each response references the shared taxonomy via a unique url,
a flag can be used when running the server, for example like this:
```swipl -s prolog_server.pl  -g "set_flag(prepare_unique_taxonomy_url, true),run_simple_server"```
This is done with a symlink. This allows to bypass cache, for example in pesseract.
*/
taxonomy_url_base :-
	symlink_tmp_taxonomy_to_static_taxonomy(Unique_Taxonomy_Dir_Url),
	(	get_flag(prepare_unique_taxonomy_url, true)
	->	Taxonomy_Dir_Url = Unique_Taxonomy_Dir_Url
	;	Taxonomy_Dir_Url = 'taxonomy/'),
	request_add_property(l:taxonomy_url_base, Taxonomy_Dir_Url).

symlink_tmp_taxonomy_to_static_taxonomy(Unique_Taxonomy_Dir_Url) :-
	request_tmp_dir(Tmp_Dir),
	server_public_url(Server_Public_Url),
	atomic_list_concat([Server_Public_Url, '/tmp/', Tmp_Dir, '/taxonomy/'], Unique_Taxonomy_Dir_Url),
	absolute_tmp_path('/taxonomy', Tmp_Taxonomy),
	absolute_file_name(my_static('taxonomy/'), Static_Taxonomy, [file_type(directory)]),
	atomic_list_concat(['ln -s ', Static_Taxonomy, ' ', Tmp_Taxonomy], Cmd),
	shell(Cmd, _).

	
/*

	extraction of input data from request xml
	
*/	
   
extract_default_currency(Dom, Default_Currency) :-
	inner_xml_throw(Dom, //reports/balanceSheetRequest/defaultCurrency/unitType, Default_Currency).

extract_report_currency(Dom, Report_Currency) :-
	inner_xml_throw(Dom, //reports/balanceSheetRequest/reportCurrency/unitType, Report_Currency).

   
extract_exchange_rates(Dom, Start_Date, End_Date, Default_Currency, Exchange_Rates_Out) :-
/*If an investment was held prior to the from date then it MUST have an opening market value if the reports are expressed in.market rather than cost.You can't mix market value and cost in one set of reports. One or the other.2:27 AMi see. Have you thought about how to let the user specify the method?Andrew, 2:31 AMMarket or Cost. M or C. Sorry. Never mentioned it to you.2:44 AMyou mentioned the different approaches, but i ended up assuming that this would be best selected by specifying or not specifying the unitValues. I see there is a field for it already in the excel templateAndrew, 2:47 AMCost value per unit will always be there if there are units of anything i.e. sheep for livestock trading or shares for InvestmentsAndrew, 3:04 AMBut I suppose if you do not find any market values then assume cost basis.*/
   findall(Unit_Value_Dom, xpath(Dom, //reports/balanceSheetRequest/unitValues/unitValue, Unit_Value_Dom), Unit_Value_Doms),
   maplist(extract_exchange_rate(Start_Date, End_Date, Default_Currency), Unit_Value_Doms, Exchange_Rates),
   include(ground, Exchange_Rates, Exchange_Rates_Out).
   
extract_exchange_rate(Start_Date, End_Date, Optional_Default_Currency, Unit_Value, Exchange_Rate) :-
	Exchange_Rate = exchange_rate(Date, Src_Currency, Dest_Currency, Rate),
	fields(Unit_Value, [
		unitType, Src_Currency0,
		unitValueCurrency, (Dest_Currency, _),
		unitValue, (Rate_Atom, _),
		unitValueDate, (Date_Atom, _)]
	),
	(
		var(Rate_Atom)
	->
		format(user_error, 'unitValue missing, ignoring\n', [])
		/*Rate will stay unbound and the whole term will be filtered out in the caller*/
	;
		atom_number(Rate_Atom, Rate)
	),
	
	(
		var(Date_Atom)
	->
		(
			once(string_concat('closing | ', Src_Currency, Src_Currency0))
		->
			Date_Atom = 'closing'
		;
			(
				once(string_concat('opening | ', Src_Currency, Src_Currency0))
			->
				Date_Atom = 'opening'
			;
				Src_Currency = Src_Currency0
			)
		)
	;
		Src_Currency = Src_Currency0
	),
	
	(
		var(Dest_Currency)
	->
		(
			Optional_Default_Currency = []
		->
			throw_string(['unitValueCurrency missing and no defaultCurrency specified'])
		;
			[Dest_Currency] = Optional_Default_Currency
		)
	;
		true
	),
	(var(Date_Atom) -> Date_Atom = closing ; true),
	(
		Date_Atom = opening
	->
		Date = Start_Date
	;
		(
			(
				Date_Atom = closing
			->
				Date = End_Date
			;
				parse_date(Date_Atom, Date)
			)
		)
	).

extract_cost_or_market(Dom, Cost_Or_Market) :-
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
	


	
%:- tspy(process_xml_ledger_request2/2).
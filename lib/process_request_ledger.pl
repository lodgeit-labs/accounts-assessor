process_request_ledger(File_Path, Dom) :-
%gtrace,
	inner_xml(Dom, //reports/balanceSheetRequest, _),
	validate_xml2(File_Path, 'bases/Reports.xsd'),

	extract_start_and_end_date(Dom, Start_Date, End_Date, Start_Date_Atom),
	extract_output_dimensional_facts(Dom, Output_Dimensional_Facts),
	extract_cost_or_market(Dom, Cost_Or_Market),
	extract_default_currency(Dom, Default_Currency),
	extract_report_currency(Dom, Report_Currency),
	extract_action_verbs_from_bs_request(Dom),
	extract_account_hierarchy_from_request_dom(Dom, Accounts0),
	extract_livestock_data_from_ledger_request(Dom),
	/* Start_Date, End_Date to substitute of "opening", "closing" */
	extract_exchange_rates(Dom, Start_Date, End_Date, Default_Currency, Exchange_Rates),
	/* Start_Date_Atom in case of missing Date */
	extract_bank_accounts(Dom),
    extract_s_transactions(Dom, Start_Date_Atom, S_Transactions0),
	extract_invoices_payable(Dom),

    create_opening_balances(Bank_Lump_Txs),
    append(Bank_Lump_Txs, S_Transactions0, S_Transactions),

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

	/* if some s_transaction failed to process, there should be an alert created by now. Now we just compile a report up until that transaction. It would be cleaner to do this by calling process_ledger a second time */
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
	%gtrace,
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
	crosschecks_report0(Static_Data.put(reports, Structured_Reports), Crosschecks_Report_Json),
	make_json_report(Structured_Reports.put(crosschecks, Crosschecks_Report_Json), reports_json).

make_gl_viewer_report :-
	Viewer_Dir = 'general_ledger_viewer',
	absolute_file_name(my_static(Viewer_Dir), Src, [file_type(directory)]),
	report_file_path(loc(file_name, Viewer_Dir), loc(absolute_url, Dir_Url), loc(absolute_path, Dst)),
	atomic_list_concat(['cp -r ', Src, ' ', Dst], Cmd),
	shell(Cmd),
	atomic_list_concat([Dir_Url, '/gl.html'], Full_Url),
	report_entry('GL viewer', loc(absolute_url, Full_Url), 'gl_html').

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
	my_request_tmp_dir(loc(tmp_directory_name,Tmp_Dir)),
	server_public_url(Server_Public_Url),
	atomic_list_concat([Server_Public_Url, '/tmp/', Tmp_Dir, '/taxonomy/'], Unique_Taxonomy_Dir_Url),
	absolute_tmp_path(loc(file_name, 'taxonomy'), loc(absolute_path, Tmp_Taxonomy)),
	resolve_specifier(loc(specifier, my_static('taxonomy')), loc(absolute_path,Static_Taxonomy)),
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
	
extract_start_and_end_date(Dom, Start_Date, End_Date, Start_Date_Atom) :-
	inner_xml(Dom, //reports/balanceSheetRequest/startDate, [Start_Date_Atom]),
	parse_date(Start_Date_Atom, Start_Date),
	doc(R, rdf:type, l:request),
	doc_add(R, l:start_date, Start_Date),
	inner_xml(Dom, //reports/balanceSheetRequest/endDate, [End_Date_Atom]),
	parse_date(End_Date_Atom, End_Date),
	doc_add(R, l:end_date, End_Date).

	
%:- tspy(process_xml_ledger_request2/2).

extract_bank_accounts(Dom) :-
	findall(Account, xpath(Dom, //reports/balanceSheetRequest/bankStatement/accountDetails, Account), Accounts),
	maplist(extract_bank_account, Accounts).

extract_bank_account(Account) :-
	fields(Account, [
		accountName, Account_Name,
		currency, Account_Currency]),
	numeric_fields(Account, [
		openingBalance, (Opening_Balance_Number, 0)]),
	Opening_Balance = coord(Account_Currency, Opening_Balance_Number),
	doc_new_uri(Uri),
	request_add_property(l:bank_account, Uri),
	doc_add(Uri, l:name, Account_Name),
	doc_add_value(Uri, l:opening_balance, Opening_Balance).

create_opening_balances(Txs) :-
	request(R),
	findall(Bank_Account_Name, docm(R, l:bank_account, Bank_Account_Name), Bank_Accounts),
	maplist(create_opening_balances2, Bank_Accounts, Txs).

create_opening_balances2(Bank_Account, Tx) :-
	doc(Bank_Account, l:name, Bank_Account_Name),
	doc_value(Bank_Account, l:opening_balance, Opening_Balance),
	request_has_property(l:start_date, Start_Date),
	Tx = s_transaction(Start_Date, 'Historical_Earnings_Lump', [Opening_Balance], Bank_Account_Name, vector([])).


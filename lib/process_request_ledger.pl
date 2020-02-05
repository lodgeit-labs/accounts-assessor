process_request_ledger(File_Path, Dom) :-
	inner_xml(Dom, //reports/balanceSheetRequest, _),
	validate_xml2(File_Path, 'bases/Reports.xsd'),
	extract_start_and_end_date(Dom, Start_Date, End_Date, Start_Date_Atom),
	extract_bank_opening_balances(Bank_Lump_STs),
	handle_additional_files(S_Transactions0),
	extract_s_transactions(Dom, Start_Date_Atom, S_Transactions1),
	flatten([Bank_Lump_STs, S_Transactions0, S_Transactions1], S_Transactions2),
	sort_s_transactions(S_Transactions2, S_Transactions),
	process_request_ledger2((Dom, Start_Date, End_Date), S_Transactions, _).
	%process_request_ledger_debug((Dom, Start_Date, End_Date), S_Transactions).

process_request_ledger_debug(Data, S_Transactions0) :-
	findall(Count, ggg(Data, S_Transactions0, Count), Counts), writeq(Counts).

ggg(Data, S_Transactions0, Count) :-
	Count = 41,
	between(0, $>length(S_Transactions0), Count),
	take(S_Transactions0, Count, STs),
	format(user_error, '~q: ~q ~n ~n', [Count, $>last(STs)]),
	once(process_request_ledger2(Data, STs, Structured_Reports)),
	length(Structured_Reports.crosschecks.errors, L),
	(	L \= 2
	->	true
	;	(gtrace,format(user_error, '~q: ~q ~n', [Count, Structured_Reports.crosschecks.errors]))).

process_request_ledger2((Dom, Start_Date, End_Date), S_Transactions, Structured_Reports) :-
	extract_output_dimensional_facts(Dom, Output_Dimensional_Facts),
	extract_cost_or_market(Dom, Cost_Or_Market),
	extract_report_currency(Dom, Report_Currency),
	extract_action_verbs_from_bs_request(Dom),
	extract_account_hierarchy_from_request_dom(Dom, Accounts0),
	extract_livestock_data_from_ledger_request(Dom),
	/* Start_Date, End_Date to substitute of "opening", "closing" */
	extract_default_currency(Dom, Default_Currency),
	extract_exchange_rates(Dom, Start_Date, End_Date, Default_Currency, Exchange_Rates0),
	(	Cost_Or_Market = cost
	->	filter_out_market_values(S_Transactions, Exchange_Rates0, Exchange_Rates)
	;	Exchange_Rates0 = Exchange_Rates),
	/* Start_Date_Atom in case of missing Date */
	extract_bank_accounts(Dom),
	extract_invoices_payable(Dom),
	extract_initial_gl(Initial_Txs),

	process_ledger(
		Cost_Or_Market,
		Initial_Txs,
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

	create_reports(Static_Data1, Structured_Reports).



create_reports(
	Static_Data,				% Static Data
	Structured_Reports			% ...
) :-
	static_data_historical(Static_Data, Static_Data_Historical),

	balance_entries(Static_Data, Static_Data_Historical, Entries),

	dict_vars(Entries, [Balance_Sheet, ProfitAndLoss, Balance_Sheet2_Historical, ProfitAndLoss2_Historical, Trial_Balance, Cf]),

	taxonomy_url_base,

	create_instance(Xbrl, Static_Data, Static_Data.start_date, Static_Data.end_date, Static_Data.accounts, Static_Data.report_currency, Balance_Sheet, ProfitAndLoss, ProfitAndLoss2_Historical, Trial_Balance),

	other_reports(Static_Data, Static_Data_Historical, Static_Data.outstanding, Balance_Sheet, ProfitAndLoss, Balance_Sheet2_Historical, ProfitAndLoss2_Historical, Trial_Balance, Cf, Structured_Reports),

	add_xml_report(xbrl_instance, xbrl_instance, [Xbrl]).



balance_entries(
	Static_Data,				% Static Data
	Static_Data_Historical,		% Static Data
	Entries						% Dict Entry
) :-
	/* sum up the coords of all transactions for each account and apply unit conversions */
	trial_balance_between(Static_Data.exchange_rates, Static_Data.accounts, Static_Data.transactions_by_account, Static_Data.report_currency, Static_Data.end_date, Static_Data.start_date, Static_Data.end_date, Trial_Balance),

	balance_sheet_at(Static_Data, Balance_Sheet),

	profitandloss_between(Static_Data, ProfitAndLoss),

	balance_sheet_at(Static_Data_Historical, Balance_Sheet2_Historical),

	cashflow(Static_Data, Cf),

	profitandloss_between(Static_Data_Historical, ProfitAndLoss2_Historical),

	assertion(ground((Balance_Sheet, ProfitAndLoss, ProfitAndLoss2_Historical, Trial_Balance))),

	dict_from_vars(Entries, [Balance_Sheet, ProfitAndLoss, Balance_Sheet2_Historical, ProfitAndLoss2_Historical, Trial_Balance, Cf]).


static_data_historical(Static_Data, Static_Data_Historical) :-
	add_days(Static_Data.start_date, -1, Before_Start),
	Static_Data_Historical = Static_Data.put(
		start_date, date(1,1,1)).put(
		end_date, Before_Start).put(
		exchange_date, Static_Data.start_date).


other_reports(
	Static_Data,
	Static_Data_Historical,
	Outstanding,
	Balance_Sheet,
	ProfitAndLoss,
	Balance_Sheet2_Historical,
	ProfitAndLoss2_Historical,
	Trial_Balance,
	Cf,
	Structured_Reports				% Dict <Report Abbr : _>
) :-

	investment_reports(Static_Data.put(outstanding, Outstanding), Investment_Report_Info),
	bs_page(Static_Data, Balance_Sheet),
	pl_page(Static_Data, ProfitAndLoss, ''),
	pl_page(Static_Data_Historical, ProfitAndLoss2_Historical, '_historical'),
	cf_page(Static_Data, Cf),
	make_json_report(Static_Data.gl, general_ledger_json),

	make_gl_viewer_report,

	Structured_Reports0 = _{
		pl: _{
			current: ProfitAndLoss,
			historical: ProfitAndLoss2_Historical
		},
		ir: Investment_Report_Info,
		bs: _{
			current: Balance_Sheet,
			historical: Balance_Sheet2_Historical
		},
		tb: Trial_Balance,
		cf: Cf
	},

	crosschecks_report0(Static_Data.put(reports, Structured_Reports0), Crosschecks_Report_Json),

	Structured_Reports = Structured_Reports0.put(crosschecks, Crosschecks_Report_Json),

	make_json_report(Structured_Reports, reports_json).

make_gl_viewer_report :-
	Viewer_Dir = 'general_ledger_viewer',
	absolute_file_name(my_static(Viewer_Dir), Src, [file_type(directory)]),
	report_file_path(loc(file_name, Viewer_Dir), loc(absolute_url, Dir_Url), loc(absolute_path, Dst)),
	atomic_list_concat(['ln -s -n -f ', Src, ' ', Dst], Cmd),
	%atomic_list_concat(['cp -r ', Src, ' ', Dst], Cmd),
	shell(Cmd, _),
	atomic_list_concat([Dir_Url, '/link.html'], Full_Url),
	add_report_file('gl_html', 'GL viewer', loc(absolute_url, Full_Url)).

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
				investment_report_2_0(Sd, Suffix, Semantic_Json)
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
	atomic_list_concat(['ln -s -n -f ', Static_Taxonomy, ' ', Tmp_Taxonomy], Cmd),
	shell(Cmd, _).

	
/*

	extraction of input data from request xml
	
*/	
   
extract_default_currency(Dom, Default_Currency) :-
	inner_xml_throw(Dom, //reports/balanceSheetRequest/defaultCurrency/unitType, Default_Currency).

extract_report_currency(Dom, Report_Currency) :-
	inner_xml_throw(Dom, //reports/balanceSheetRequest/reportCurrency/unitType, Report_Currency).


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

extract_bank_opening_balances(Txs) :-
	request(R),
	findall(Bank_Account_Name, docm(R, l:bank_account, Bank_Account_Name), Bank_Accounts),
	maplist(extract_bank_opening_balances2, Bank_Accounts, Txs).

extract_bank_opening_balances2(Bank_Account, Tx) :-
	doc(Bank_Account, l:name, Bank_Account_Name),
	doc_value(Bank_Account, l:opening_balance, Opening_Balance),
	request_has_property(l:start_date, Start_Date),
	make_s_transaction(Tx, [
		day(Start_Date),
		type_id('Historical_Earnings_Lump'),
		vector([Opening_Balance]),
		account_id(Bank_Account_Name),
		exchanged(vector([])),
		misc(misc{desc2:'Historical_Earnings_Lump'})
	]),
	add_s_transaction(Tx).

extract_initial_gl(Txs) :-
	(	doc(l:request, ic_ui:gl, Gl)
	->	(
			doc_value(Gl, ic:default_currency, Default_Currency0),
			atom_string(Default_Currency, Default_Currency0),
			doc_value(Gl, ic:items, List),
			doc_list_items(List, Items),
			maplist(extract_initial_gl_tx(Default_Currency), Items, Txs)
		)
	;	Txs = []).

extract_initial_gl_tx(Default_Currency, Item, Tx) :-
	doc_value(Item, ic:date, Date),
	doc_value(Item, ic:account, Account_String),
	/*fixme, support multiple description fields in transaction */
	(	doc_value(Item, ic:description, Description)
	->	true
	;	Description = 'initial_GL'),
	atom_string(Account, Account_String),
	(	doc_value(Item, ic:debit, Debit_String)
	->	vector_string(Default_Currency, debit, Debit_String, Debit_Vector)
	;	Debit_Vector = []),
	(	doc_value(Item, ic:credit, Credit_String)
	->	vector_string(Default_Currency, credit, Credit_String, Credit_Vector)
	;	Credit_Vector = []),
	append(Debit_Vector, Credit_Vector, Vector),
	make_transaction(Date, Description, Account, Vector, Tx).


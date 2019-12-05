% ===================================================================
% Project:   LodgeiT
% Module:    process_xml_ledger_request.pl  
% Author:    Jindrich
% Date:      2019-06-02
% ===================================================================

% -------------------------------------------------------------------
% Modules
% -------------------------------------------------------------------
:- module(process_xml_ledger_request, [process_xml_ledger_request/3]).

:- use_module('days', [
		add_days/3, 
		parse_date/2]).
:- use_module(library(xbrl/utils), [
		inner_xml/3, 
		inner_xml_throw/3,
		fields/2,
		pretty_term_string/2, 
		throw_string/1,
		catch_maybe_with_backtrace/3,
		dict_json_text/2]).
:- use_module('ledger_report', [
		trial_balance_between/8, 
		profitandloss_between/2, 
		balance_sheet_at/2]).
:- use_module('ledger_html_reports').
:- use_module('report_page').
:- use_module('bank_statement', [
		print_relevant_exchange_rates_comment/4,

		fill_in_missing_units/6
]).
:- use_module('s_transaction', []).
:- use_module('ledger', []).
:- use_module('livestock', []).
:- use_module('files', [
		absolute_tmp_path/2,
		request_tmp_dir/1,
		server_public_url/1]).
:- use_module('xml', [
		validate_xml/3
]).
:- use_module('action_verbs', []).
:- use_module('accounts_extract', []).
:- use_module('investment_report_2').
:- use_module('crosschecks_report').
:- use_module('invoices').
:- use_module('xbrl_output', [create_instance/10]).
:- use_module('doc', []).
:- use_module(library(xpath)).
:- use_module(library(rdet)).
:- use_module(library(xsd/validate)).
:- use_module(library(sgml)).
:- use_module(library(xbrl/structured_xml)).


:- rdet(process_xml_ledger_request2/2).


process_xml_ledger_request(File_Name, Dom, Reports) :-

	/* does it look like a ledger request? */
	% ideally should be able to omit this and have this check be done as part of the schema validation, but currently that's problematic because process_data.pl is using this to check whether to use this endpoint. 
	inner_xml(Dom, //reports/balanceSheetRequest, _),

	absolute_tmp_path(File_Name, Instance_File),
	absolute_file_name(my_schemas('bases/Reports.xsd'), Schema_File, []),
	validate_xml(Instance_File, Schema_File, Schema_Errors),
	(
		Schema_Errors = []
	->
		process_xml_ledger_request2(Dom, Reports)
	;
		Reports = _{
			files: [],
			errors: Schema_Errors,
			warnings: []
		}
	).


process_xml_ledger_request2(Dom, Reports_Out) :-
	/*
		first let's extract data from the request
	*/
	extract_output_dimensional_facts(Dom, Output_Dimensional_Facts),
	extract_cost_or_market(Dom, Cost_Or_Market),
	extract_default_currency(Dom, Default_Currency),
	extract_report_currency(Dom, Report_Currency),
	action_verbs:extract_action_verbs_from_bs_request(Dom),
	accounts_extract:extract_account_hierarchy_from_request_dom(Dom, Accounts0),
	inner_xml(Dom, //reports/balanceSheetRequest/startDate, [Start_Date_Atom]),
	parse_date(Start_Date_Atom, Start_Date),
	doc:doc(R, rdf:a, l:request),
	doc:doc_add(R, l:start_date, Start_Date),
	inner_xml(Dom, //reports/balanceSheetRequest/endDate, [End_Date_Atom]),
	parse_date(End_Date_Atom, End_Date),
	doc:doc_add(R, l:end_date, End_Date),
	
	extract_exchange_rates(Dom, Start_Date, End_Date, Default_Currency, Exchange_Rates),
	livestock_extract:extract(Dom),
    s_transaction:extract_s_transactions(Dom, Start_Date_Atom, S_Transactions),
	/* 
		generate transactions (ledger entries) from s_transactions
	*/
	ledger:process_ledger(
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
		Warnings,
		Errors,
		Gl),

	print_relevant_exchange_rates_comment(Report_Currency, End_Date, Exchange_Rates, Transactions),
	writeln("<!-- exchange rates 2:"),
	writeln(Exchange_Rates),
	writeln("-->"),

	invoices:process_invoices_payable(Dom),

	dict_from_vars(Static_Data0,
		[Cost_Or_Market, Output_Dimensional_Facts, Start_Date, Exchange_Rates, Accounts, Transactions, Report_Currency, Gl, Transactions_By_Account, Outstanding]),
	Static_Data1 = Static_Data0.put([
		end_date=Processed_Until_Date
		,exchange_date=Processed_Until_Date
	]),
	create_reports(Static_Data1, Reports),
	
	Reports_Out = _{
		files: Reports.files,
		errors: [Errors, Reports.errors],
		warnings: [Warnings, Reports.warnings]
	},
		
	writeln('<!-- '),
	writeq(Warnings), nl,
	writeq(Errors),
	writeln(' -->'),
	nl, nl.

create_reports(Static_Data, Json_Request_Results) :-
	static_data_historical(Static_Data, Static_Data_Historical),
	balance_entries(Static_Data, Static_Data_Historical, Entries),
	dict_vars(Entries, [Balance_Sheet, ProfitAndLoss, Balance_Sheet2_Historical, ProfitAndLoss2_Historical, Trial_Balance]),
	maybe_prepare_unique_taxonomy_url(Taxonomy_Url_Base),
	/*xbrl_output:*/create_instance(Static_Data, Taxonomy_Url_Base, Static_Data.start_date, Static_Data.end_date, Static_Data.accounts, Static_Data.report_currency, Balance_Sheet, ProfitAndLoss, ProfitAndLoss2_Historical, Trial_Balance),
	other_reports(Static_Data, Static_Data_Historical, Static_Data.outstanding, Balance_Sheet, ProfitAndLoss, Balance_Sheet2_Historical, ProfitAndLoss2_Historical, Trial_Balance, Json_Request_Results).

balance_entries(Static_Data, Static_Data_Historical, Entries) :-
	/* sum up the coords of all transactions for each account and apply unit conversions */
	writeln("<!-- compiling Trial balance -->"),
	trial_balance_between(Static_Data.exchange_rates, Static_Data.accounts, Static_Data.transactions_by_account, Static_Data.report_currency, Static_Data.end_date, Static_Data.start_date, Static_Data.end_date, Trial_Balance),
	writeln("<!-- compiling Balance sheet -->"),
	balance_sheet_at(Static_Data, Balance_Sheet),
	writeln("<!-- compiling Profit and loss -->"),
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


other_reports(Static_Data, Static_Data_Historical, Outstanding, Balance_Sheet, ProfitAndLoss, Balance_Sheet2_Historical, ProfitAndLoss2_Historical, Trial_Balance, Json_Request_Results) :-
	investment_reports(Static_Data, Outstanding, Investment_Report_Info),
	ledger_html_reports:bs_page(Static_Data, Balance_Sheet, Bs_Report_Page_Info),
	ledger_html_reports:pl_page(Static_Data, ProfitAndLoss, '', Pl_Report_Page_Info),
	ledger_html_reports:pl_page(Static_Data_Historical, ProfitAndLoss2_Historical, '_historical', Pl_Html_Historical_Info),

	make_gl_viewer_report(Gl_Viewer_Page_Info),
	make_gl_report(Static_Data.gl, '', Gl_Report_File_Info),
	
	/* All the info in a json-like format. Currently only used in crosschecks */
	Structured_Reports = _{
		pl: _{
			current: ProfitAndLoss,
			historical: ProfitAndLoss2_Historical
		},
		ir: Investment_Report_Info.ir,
		bs: _{
			current: Balance_Sheet,
			historical: Balance_Sheet2_Historical
		},
		tb: Trial_Balance
	},

	crosschecks_report:report(Static_Data, Structured_Reports, Crosschecks_Report_Files_Info, Crosschecks_Report_Json),
	Structured_Reports2 = Structured_Reports.put(crosschecks, Crosschecks_Report_Json),

	append([
		   	Gl_Viewer_Page_Info,
			Bs_Report_Page_Info,
			Pl_Report_Page_Info,
			Pl_Html_Historical_Info,
			Gl_Report_File_Info
		],
		Investment_Report_Info.files,
		Files
	),

	Json_Request_Results = _{
		files:[Files, Crosschecks_Report_Files_Info],
		errors:[Investment_Report_Info.alerts, Crosschecks_Report_Json.errors],
		warnings:[],
		structured: Structured_Reports2
	}.



make_gl_viewer_report(Info) :-
	Viewer_Dir = 'general_ledger_viewer',
	absolute_file_name(my_static(Viewer_Dir), Viewer_Dir_Absolute, [file_type(directory)]),
	files:report_file_path(Viewer_Dir, Url, Tmp_Viewer_Dir_Absolute),
	atomic_list_concat(['cp -r ', Viewer_Dir_Absolute, ' ', Tmp_Viewer_Dir_Absolute], Cmd),
	shell(Cmd),
	atomic_list_concat([Url, '/gl.html'], Url_With_Slash),
	report_entry('GL viewer', Url_With_Slash, 'gl_html', Info).
	
make_gl_report(Dict, Suffix, Report_File_Info) :-
	dict_json_text(Dict, Json_Text),
	atomic_list_concat(['general_ledger', Suffix, '.json'], Fn),
	report_item(Fn, Json_Text, Report_File_URL),
	report_entry('General Ledger Report', Report_File_URL, 'general_ledger_json', Report_File_Info).



investment_reports(Static_Data, Outstanding, Reports) :-
	catch_maybe_with_backtrace(
				   process_xml_ledger_request:investment_reports2(Static_Data, Outstanding, Alerts, Ir, Files),
				   Err,
				   (
				    term_string(Err, Err_Str),
				    format(string(Msg), 'investment reports fail: ~w', [Err_Str]),
				    Alerts = ['SYSTEM_WARNING':Msg],
				    structured_xml:print_xml_comment(Alerts),
				    Ir =  _{},
				    Files = []
				   )
				  ),
	Reports = _{
		    files: Files, 
		    alerts:Alerts,
		    ir: Ir
		   }.

investment_reports2(Static_Data, Outstanding, Alerts, Ir, Files) :-
	(Static_Data.report_currency = [_] -> true ; throw_string('report currency expected')),
	/*get_dict(start_date, Static_Data, Report_Start),
	add_days(Report_Start, -1, Before_Start),*/

	% report period	
	investment_report_2:investment_report_2(Static_Data, Outstanding, '', Json1, Files1),

	/* TODO: we cant do all_time without market values, use last known? */
	investment_report_2:investment_report_2(Static_Data.put(start_date, date(1,1,1)), Outstanding, '_since_beginning', Json2, Files2),
	
	% historical
	%investment_report_2:investment_report_2(Static_Data.put(start_date, date(1,1,1)).put(end_date, Before_Start), Outstanding, '_historical', Json3, Files3),
	Alerts = [],
	Ir =  _{
	%	 historical: Json3,
		 current: Json1,
		 since_beginning: Json2
		},
	flatten([Files1, Files2/*, Files3*/], Files_Flat),
	exclude(var, Files_Flat, Files).

/*
To ensure that each response references the shared taxonomy via a unique url,
a flag can be used when running the server, for example like this:
```swipl -s prolog_server.pl  -g "set_flag(prepare_unique_taxonomy_url, true),run_simple_server"```
This is done with a symlink. This allows to bypass cache, for example in pesseract.
*/
maybe_prepare_unique_taxonomy_url(Taxonomy_Dir_Url) :-
	symlink_tmp_taxonomy_to_static_taxonomy(Unique_Taxonomy_Dir_Url),
	(
		get_flag(prepare_unique_taxonomy_url, true)
	->
		Taxonomy_Dir_Url = Unique_Taxonomy_Dir_Url
	;
		Taxonomy_Dir_Url = 'taxonomy/'
	).

symlink_tmp_taxonomy_to_static_taxonomy(Unique_Taxonomy_Dir_Url) :-
	request_tmp_dir(Tmp_Dir),
	server_public_url(Server_Public_Url),
	atomic_list_concat([Server_Public_Url, '/tmp/', Tmp_Dir, '/taxonomy/'], Unique_Taxonomy_Dir_Url),
	absolute_tmp_path('/taxonomy', Tmp_Taxonomy),
	absolute_file_name(my_static('taxonomy/'), Static_Taxonomy, [file_type(directory)]),
	atomic_list_concat(['ln -s ', Static_Taxonomy, ' ', Tmp_Taxonomy], Cmd),
	shell(Cmd, 0).

	
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

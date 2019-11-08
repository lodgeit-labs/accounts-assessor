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

:- use_module(library(xpath)).
:- use_module(library(rdet)).
:- use_module(library(xsd/validate)).
:- use_module(library(sgml)).

:- rdet(output_results/4).
:- rdet(process_xml_ledger_request2/2).	

:- use_module('../days', [
		format_date/2, 
		add_days/3, 
		parse_date/2, 
		gregorian_date/2]).
:- use_module('../utils', [
		inner_xml/3, 
		inner_xml_throw/3,
		write_tag/2, 
		fields/2, 
		numeric_fields/2, 
		pretty_term_string/2, 
		throw_string/1,
	  replace_nonalphanum_chars_with_underscore/2,
	  catch_maybe_with_backtrace/3,
	  dict_json_text/2]).
:- use_module('../ledger_report', [
		trial_balance_between/8, 
		profitandloss_between/2, 
		balance_sheet_at/2,
		format_report_entries/10, 
		bs_and_pl_entries/8,
		net_activity_by_account/4]).
:- use_module('../ledger_html_reports').
:- use_module('../report_page').
:- use_module('../statements', [
		extract_s_transaction/3, 
		print_relevant_exchange_rates_comment/4, 
		invert_s_transaction_vector/2, 
		fill_in_missing_units/6,
		sort_s_transactions/2]).
:- use_module('../ledger', [
		process_ledger/21]).
:- use_module('../livestock', [
		get_livestock_types/2, 
		extract_livestock_opening_costs_and_counts/2]).
:- use_module('../accounts', [
		extract_account_hierarchy/2,
		sub_accounts_upto_level/4,
		child_accounts/3,
		account_by_role/3,
		account_by_role_nothrow/3, 
		account_role_by_id/3]).
:- use_module('../exchange_rates', [
		exchange_rate/5]).
:- use_module('../files', [
		absolute_tmp_path/2,
		request_tmp_dir/1,
		server_public_url/1]).
:- use_module('../system_accounts', [
		trading_account_ids/2,
		bank_accounts/2]).
:- use_module('../xbrl_contexts', [
		print_contexts/1,
		context_id_base/3
]).
:- use_module('../print_detail_accounts', [
		print_banks/5,
		print_forex/5,
		print_trading/3
]).
:- use_module('../xml', [
		validate_xml/3
]).

:- use_module('../investment_report_2').
:- use_module('../crosschecks_report').


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
	extract_action_verbs(Dom),
	extract_account_hierarchy(Dom, Accounts0),

	inner_xml(Dom, //reports/balanceSheetRequest/startDate, [Start_Date_Atom]),
	parse_date(Start_Date_Atom, Start_Date),
	inner_xml(Dom, //reports/balanceSheetRequest/endDate, [End_Date_Atom]),
	parse_date(End_Date_Atom, End_Date),
	
	extract_exchange_rates(Dom, Start_Date, End_Date, Default_Currency, Exchange_Rates0),
	findall(Livestock_Dom, xpath(Dom, //reports/balanceSheetRequest/livestockData, Livestock_Dom), Livestock_Doms),
	get_livestock_types(Livestock_Doms, Livestock_Types),
   	extract_livestock_opening_costs_and_counts(Livestock_Doms, Livestock_Opening_Costs_And_Counts),
	findall(S_Transaction, extract_s_transaction(Dom, Start_Date_Atom, S_Transaction), S_Transactions0),
	
	/* 
		flip s_transactions from bank's perspective to our perspective and sort 
	*/
	maplist(invert_s_transaction_vector, S_Transactions0, S_Transactions0b),
	sort_s_transactions(S_Transactions0b, S_Transactions),
	
	/* 
		process_ledger turns s_transactions into transactions
	*/
	process_ledger(Cost_Or_Market, Livestock_Doms, S_Transactions, Processed_S_Transactions, Start_Date, End_Date, Exchange_Rates0, Report_Currency, Livestock_Types, Livestock_Opening_Costs_And_Counts, Accounts0, Accounts, Transactions, Transactions_By_Account, _Transaction_Transformation_Debug, Outstanding, Processed_Until, Warnings, Errors, Gl),

	print_relevant_exchange_rates_comment(Report_Currency, End_Date, Exchange_Rates0, Transactions),
	infer_exchange_rates(Transactions, Processed_S_Transactions, Start_Date, End_Date, Accounts, Report_Currency, Exchange_Rates0, Exchange_Rates),
	writeln("<!-- exchange rates 2:"),
	writeln(Exchange_Rates),
	writeln("-->"),
	
	print_xbrl_header,

	dict_from_vars(Static_Data,
		[Cost_Or_Market, Output_Dimensional_Facts, Start_Date, End_Date, Exchange_Rates, Accounts, Transactions, Report_Currency, Gl, Transactions_By_Account]),
	output_results(Static_Data, Outstanding, Processed_Until, Reports),
	
	Reports_Out = _{
		files: Reports.files,
		errors: [Errors, Reports.errors],
		warnings: [Warnings, Reports.warnings]
	},
		
	writeln('</xbrli:xbrl>'),

	writeln('<!-- '),
	writeq(Warnings), nl,
	writeq(Errors),
	writeln(' -->'),
	nl, nl.

output_results(Static_Data0, Outstanding, Processed_Until, Json_Request_Results) :-
	
	Static_Data = Static_Data0.put([
		end_date=Processed_Until,
		exchange_date=Processed_Until,
		entity_identifier=Entity_Identifier,
		duration_context_id_base=Duration_Context_Id_Base]),

	Static_Data.start_date = Start_Date,
	Static_Data.exchange_rates = Exchange_Rates, 
	Static_Data.accounts = Accounts, 
	Static_Data.transactions_by_account = Transactions_By_Account, 
	
	Static_Data.report_currency = Report_Currency, 
		
	writeln("<!-- Build contexts -->"),	
	/* build up two basic non-dimensional contexts used for simple xbrl facts */
	date(Context_Id_Year,_,_) = Processed_Until,
	Entity_Identifier = '<identifier scheme="http://www.example.com">TestData</identifier>',
	context_id_base('I', Context_Id_Year, Instant_Context_Id_Base),
	context_id_base('D', Context_Id_Year, Duration_Context_Id_Base),
	Base_Contexts = [
		context(Instant_Context_Id_Base, Processed_Until, entity(Entity_Identifier, ''), ''),
		context(Duration_Context_Id_Base, (Start_Date, Processed_Until), entity(Entity_Identifier, ''), '')
	],
	/* sum up the coords of all transactions for each account and apply unit conversions */

	writeln("<!-- Trial balance -->"),
	trial_balance_between(Exchange_Rates, Accounts, Transactions_By_Account, Report_Currency, Processed_Until, Start_Date, Processed_Until, Trial_Balance2),

		
	writeln("<!-- Balance sheet -->"),
	balance_sheet_at(Static_Data, Balance_Sheet2),
	writeln("<!-- Profit and loss -->"),
	profitandloss_between(Static_Data, ProfitAndLoss2),

	add_days(Start_Date, -1, Before_Start),
	Static_Data_Historical = Static_Data.put(
		start_date, date(1,1,1)).put(
		end_date, Before_Start).put(
		exchange_date, Start_Date),

	balance_sheet_at(Static_Data_Historical, Balance_Sheet2_Historical),
	profitandloss_between(Static_Data_Historical, ProfitAndLoss2_Historical),


	assertion(ground((Balance_Sheet2, ProfitAndLoss2, ProfitAndLoss2_Historical, Trial_Balance2))),

	/* TODO can we do without this units in units out nonsense? */
	format_report_entries(xbrl, Accounts, 0, Report_Currency, Instant_Context_Id_Base,  Balance_Sheet2, [], Units0, [], Bs_Lines),
	format_report_entries(xbrl, Accounts, 0, Report_Currency, Duration_Context_Id_Base, ProfitAndLoss2,  Units0, Units1, [], Pl_Lines),
	format_report_entries(xbrl, Accounts, 0, Report_Currency, Duration_Context_Id_Base, ProfitAndLoss2_Historical,  Units1, Units2, [], Pl_Historical_Lines),
	format_report_entries(xbrl, Accounts, 0, Report_Currency, Instant_Context_Id_Base,  Trial_Balance2, Units2, Units3, [], Tb_Lines),

	investment_reports(Static_Data, Outstanding, Investment_Report_Info),
	ledger_html_reports:bs_page(Static_Data, Balance_Sheet2, Bs_Report_Page_Info),
	ledger_html_reports:pl_page(Static_Data, ProfitAndLoss2, '', Pl_Report_Page_Info),
	ledger_html_reports:pl_page(Static_Data_Historical, ProfitAndLoss2_Historical, '_historical', Pl_Html_Historical_Info),

	make_gl_viewer_report(Gl_Viewer_Page_Info),
	make_gl_report(Static_Data0.gl, '', Gl_Report_File_Info),
	
	Reports = _{
		pl: _{
			current: ProfitAndLoss2,
			historical: ProfitAndLoss2_Historical
		},
		ir: Investment_Report_Info.ir,
		bs: _{
			current: Balance_Sheet2,
			historical: Balance_Sheet2_Historical
		},
		tb: Trial_Balance2
	},

	crosschecks_report:report(Static_Data, Reports, Crosschecks_Report_Files_Info, Crosschecks_Report_Json),
	Reports2 = Reports.put(crosschecks, Crosschecks_Report_Json),

	(
		Static_Data.output_dimensional_facts = on
	->
		print_dimensional_facts(Static_Data, Instant_Context_Id_Base, Duration_Context_Id_Base, Entity_Identifier, (Base_Contexts, Units3, []), (Contexts3, Units4, Dimensions_Lines))
	;
		(
			Contexts3 = Base_Contexts, 
			Units4 = Units3, 
			Dimensions_Lines = ['<!-- off -->\n']
		)
	),

	maplist(write_used_unit, Units4), nl, nl,
	print_contexts(Contexts3), nl, nl,
	writeln('<!-- dimensional facts: -->'),
	maplist(write, Dimensions_Lines),
	
	flatten([
		'\n<!-- balance sheet: -->\n', Bs_Lines, 
		'\n<!-- profit and loss: -->\n', Pl_Lines,
		'\n<!-- historical profit and loss: \n', Pl_Historical_Lines, '\n-->\n',
		'\n<!-- trial balance: -->\n',  Tb_Lines
	], Report_Lines_List),
	atomic_list_concat(Report_Lines_List, Report_Lines),
	writeln(Report_Lines),
	
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
		reports: Reports2
	}.

/* todo this should be done in output_results */
make_gl_viewer_report(Info) :-
	%gtrace,
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

print_dimensional_facts(Static_Data, Instant_Context_Id_Base, Duration_Context_Id_Base, Entity_Identifier, Results0, Results3) :-
	print_banks(Static_Data, Instant_Context_Id_Base, Entity_Identifier, Results0, Results1),
	print_forex(Static_Data, Duration_Context_Id_Base, Entity_Identifier, Results1, Results2),
	print_trading(Static_Data, Results2, Results3).
	
investment_reports(Static_Data, Outstanding, Reports) :-
	catch_maybe_with_backtrace(
				   process_xml_ledger_request:investment_reports2(Static_Data, Outstanding, Alerts, Ir, Files),
				   Err,
				   (
				    term_string(Err, Err_Str),
				    format(string(Msg), 'investment reports fail: ~w', [Err_Str]),
				    Alerts = ['SYSTEM_WARNING':Msg],
				    writeq(Alerts),
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

	
print_xbrl_header :-
	maybe_prepare_unique_taxonomy_url(Taxonomy),
	write('<xbrli:xbrl xmlns:xbrli="http://www.xbrl.org/2003/instance" xmlns:link="http://www.xbrl.org/2003/linkbase" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:iso4217="http://www.xbrl.org/2003/iso4217" xmlns:basic="http://www.xbrlsite.com/basic" xmlns:xbrldi="http://xbrl.org/2006/xbrldi" xsi:schemaLocation="http://www.xbrlsite.com/basic '),write(Taxonomy),writeln('basic.xsd http://www.xbrl.org/2003/instance http://www.xbrl.org/2003/xbrl-instance-2003-12-31.xsd http://www.xbrl.org/2003/linkbase http://www.xbrl.org/2003/xbrl-linkbase-2003-12-31.xsd http://xbrl.org/2006/xbrldi http://www.xbrl.org/2006/xbrldi-2006.xsd">'),
	write('  <link:schemaRef xlink:type="simple" xlink:href="'), write(Taxonomy), writeln('basic.xsd" xlink:title="Taxonomy schema" />'),
	write('  <link:linkbaseRef xlink:type="simple" xlink:href="'), write(Taxonomy), writeln('basic-formulas.xml" xlink:arcrole="http://www.w3.org/1999/xlink/properties/linkbase" />'),
	write('  <link:linkBaseRef xlink:type="simple" xlink:href="'), write(Taxonomy), writeln('basic-formulas-cross-checks.xml" xlink:arcrole="http://www.w3.org/1999/xlink/properties/linkbase" />'),
	nl.
 
/*
To ensure that each response references the shared taxonomy via a unique url,
a flag can be used when running the server, for example like this:
```swipl -s prolog_server.pl  -g "set_flag(prepare_unique_taxonomy_url, true),run_simple_server"```
This is done with a symlink. This allows to bypass cache, for example in pesseract.
*/
maybe_prepare_unique_taxonomy_url(Taxonomy_Dir_Url) :-
	request_tmp_dir(Tmp_Dir),
	server_public_url(Server_Public_Url),
	atomic_list_concat([Server_Public_Url, '/tmp/', Tmp_Dir, '/taxonomy/'], Unique_Taxonomy_Dir_Url),
	absolute_tmp_path('/taxonomy', Tmp_Taxonomy),
	absolute_file_name(my_static('taxonomy/'), Static_Taxonomy, [file_type(directory)]),
	atomic_list_concat(['ln -s ', Static_Taxonomy, ' ', Tmp_Taxonomy], Cmd),
	shell(Cmd, 0),
	(
		get_flag(prepare_unique_taxonomy_url, true)
	->
		Taxonomy_Dir_Url = Unique_Taxonomy_Dir_Url
	;
		Taxonomy_Dir_Url = 'taxonomy/'
	).

/**/
write_used_unit(Unit) :-
	format('  <xbrli:unit id="U-~w"><xbrli:measure>iso4217:~w</xbrli:measure></xbrli:unit>\n', [Unit, Unit]).
	
/*this functionality is disabled for now, maybe delete*/
infer_exchange_rates(_, _, _, _, _, _, Exchange_Rates, Exchange_Rates) :- 
	!.

%infer_exchange_rates(Transactions, S_Transactions, Start_Date, End_Date, Accounts, Report_Currency, Exchange_Rates, Exchange_Rates_With_Inferred_Values) :-
	%/* a dry run of bs_and_pl_entries to find out units used */
	%trial_balance_between(Exchange_Rates, Accounts, Transactions, Report_Currency, End_Date, Start_Date, End_Date, Trial_Balance),
	%balance_sheet_at(Exchange_Rates, Accounts, Transactions, Report_Currency, End_Date, Start_Date, End_Date, Balance_Sheet),

	%profitandloss_between(Exchange_Rates, Accounts, Transactions, Report_Currency, End_Date, Start_Date, End_Date, ProfitAndLoss),
	%bs_and_pl_entries(Accounts, Report_Currency, none, Balance_Sheet, ProfitAndLoss, Used_Units, _, _),
	%pretty_term_string(Balance_Sheet, Message4),
	%pretty_term_string(Trial_Balance, Message4b),
	%pretty_term_string(ProfitAndLoss, Message4c),
	%atomic_list_concat([
		%'\n<!--',
		%'BalanceSheet:\n', Message4,'\n\n',
		%'ProfitAndLoss:\n', Message4c,'\n\n',
		%'Trial_Balance:\n', Message4b,'\n\n',
		%'-->\n\n'], 
	%Debug_Message2),
	%writeln(Debug_Message2),
	%assertion(ground((Balance_Sheet, ProfitAndLoss, Trial_Balance))),
	%pretty_term_string(Used_Units, Used_Units_Str),
	%writeln('<!-- units used in balance sheet: \n'),
	%writeln(Used_Units_Str),
	%writeln('\n-->\n'),
	%fill_in_missing_units(S_Transactions, End_Date, Report_Currency, Used_Units, Exchange_Rates, Inferred_Rates),
	%pretty_term_string(Inferred_Rates, Inferred_Rates_Str),
	%writeln('<!-- Inferred_Rates: \n'),
	%writeln(Inferred_Rates_Str),
	%writeln('\n-->\n'),
	%append(Exchange_Rates, Inferred_Rates, Exchange_Rates_With_Inferred_Values).


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
%gtrace,
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

% ===================================================================
% Project:   LodgeiT
% Module:    process_xml_ledger_request.pl  
% Author:    Jindrich
% Date:      2019-06-02
% ===================================================================

% -------------------------------------------------------------------
% Modules
% -------------------------------------------------------------------

:- module(process_xml_ledger_request, [process_xml_ledger_request/2]).

:- use_module(library(xpath)).
:- use_module(library(rdet)).

:- rdet(output_results/4).
:- rdet(process_xml_ledger_request2/2).	

:- use_module('../../lib/days', [
		format_date/2, 
		add_days/3, 
		parse_date/2, 
		gregorian_date/2]).
:- use_module('../../lib/utils', [
		inner_xml/3, 
		inner_xml_throw/3,
		write_tag/2, 
		fields/2, 
		numeric_fields/2, 
		pretty_term_string/2, 
		throw_string/1,
		replace_nonalphanum_chars_with_underscore/2]).
:- use_module('../../lib/ledger_report', [
		trial_balance_between/8, 
		profitandloss_between/2, 
		%balance_by_account/9,
		%accounts_report/2,
		balance_sheet_at/2,
		format_report_entries/10, 
		bs_and_pl_entries/8,
		net_activity_by_account/4]).
:- use_module('../../lib/ledger_report_details', [
		investment_report_1/2,
		investment_report_2/4,
		bs_report/3,
		pl_report/4]).
:- use_module('../../lib/statements', [
		extract_s_transaction/3, 
		print_relevant_exchange_rates_comment/4, 
		invert_s_transaction_vector/2, 
		fill_in_missing_units/6,
		sort_s_transactions/2]).
:- use_module('../../lib/ledger', [
		emit_ledger_warnings/3,
		emit_ledger_errors/1,
		process_ledger/15]).
:- use_module('../../lib/livestock', [
		get_livestock_types/2, 
		process_livestock/14, 
		make_livestock_accounts/2,
		extract_livestock_opening_costs_and_counts/2]).
:- use_module('../../lib/accounts', [
		extract_account_hierarchy/2,
		sub_accounts_upto_level/4,
		child_accounts/3,
		account_by_role/3,
		account_by_role_nothrow/3, 
		account_role_by_id/3]).
:- use_module('../../lib/exchange_rates', [
		exchange_rate/5]).
:- use_module('../../lib/files', [
		my_tmp_file_name/2,
		request_tmp_dir/1,
		server_public_url/1]).
:- use_module('../../lib/system_accounts', [
		trading_account_ids/2,
		bank_accounts/2]).
:- use_module('../../lib/xbrl_contexts', [
		print_contexts/1,
		context_id_base/3
]).
:- use_module('../../lib/transactions', [
		transactions_by_account/2
]).
:- use_module('../../lib/print_detail_accounts', [
		print_banks/5,
		print_forex/5,
		print_trading/3
]).



% ------------------------------------------------------------------
% process_xml_ledger_request/2
% ------------------------------------------------------------------

process_xml_ledger_request(_, Dom) :-
	/* does it look like a ledger request? */
	inner_xml(Dom, //reports/balanceSheetRequest, _),
	/*
		print the xml header, and after that, we can print random xml comments.
	*/
	writeln('<?xml version="1.0"?>'), nl, nl,
	process_xml_ledger_request2(_, Dom).

process_xml_ledger_request2(_, Dom) :-
	/*
		first let's extract data from the request
	*/
	extract_output_dimensional_facts(Dom, Output_Dimensional_Facts),
	extract_cost_or_market(Dom, Cost_Or_Market),
	extract_default_currency(Dom, Default_Currency),
	extract_report_currency(Dom, Report_Currency),
	extract_action_taxonomy(Dom, Transaction_Types),
	extract_account_hierarchy(Dom, Accounts0),

	inner_xml(Dom, //reports/balanceSheetRequest/startDate, [Start_Date_Atom]),
	parse_date(Start_Date_Atom, Start_Date),
	inner_xml(Dom, //reports/balanceSheetRequest/endDate, [End_Date_Atom]),
	parse_date(End_Date_Atom, End_Date),
	
	extract_exchange_rates(Dom, End_Date_Atom, Default_Currency, Exchange_Rates0),
	findall(Livestock_Dom, xpath(Dom, //reports/balanceSheetRequest/livestockData, Livestock_Dom), Livestock_Doms),
	get_livestock_types(Livestock_Doms, Livestock_Types),
   	extract_livestock_opening_costs_and_counts(Livestock_Doms, Livestock_Opening_Costs_And_Counts),
	findall(S_Transaction, extract_s_transaction(Dom, Start_Date_Atom, S_Transaction), S_Transactions0),
	/* flip from bank's perspective to our perspective */
	maplist(invert_s_transaction_vector, S_Transactions0, S_Transactions0b),
	sort_s_transactions(S_Transactions0b, S_Transactions),
	/* process_ledger turns s_transactions into transactions */
	process_ledger(Cost_Or_Market, Livestock_Doms, S_Transactions, Start_Date, End_Date, Exchange_Rates0, Transaction_Types, Report_Currency, Livestock_Types, Livestock_Opening_Costs_And_Counts, Accounts0, Accounts, Transactions, Transaction_Transformation_Debug, Outstanding),
	print_relevant_exchange_rates_comment(Report_Currency, End_Date, Exchange_Rates0, Transactions),
	infer_exchange_rates(Transactions, S_Transactions, Start_Date, End_Date, Accounts, Report_Currency, Exchange_Rates0, Exchange_Rates),
	writeln("<!-- exchange rates 2:"),
	writeln(Exchange_Rates),
	writeln("-->"),
	print_xbrl_header,
%gtrace,
	dict_from_vars(Static_Data,
		[Cost_Or_Market, Output_Dimensional_Facts, Start_Date, End_Date, Exchange_Rates, Accounts, Transactions, Report_Currency, Transaction_Types]),
	transactions_by_account(Static_Data, Transactions_By_Account),
	% print_term(Transactions_By_Account, []),
	Static_Data2 = Static_Data.put(accounts_transactions, Transactions_By_Account),
	output_results(Static_Data2, S_Transactions, Transaction_Transformation_Debug, Outstanding),
	writeln('</xbrli:xbrl>'),
	nl, nl.

output_results(Static_Data0, S_Transactions, Transaction_Transformation_Debug, Outstanding) :-
	
	Static_Data = Static_Data0.put([
		exchange_date=End_Date,
		entity_identifier=Entity_Identifier,
		duration_context_id_base=Duration_Context_Id_Base]),

	Static_Data.start_date = Start_Date,
	Static_Data.end_date = End_Date, 
	Static_Data.exchange_rates = Exchange_Rates, 
	Static_Data.accounts = Accounts, 
	Static_Data.transactions = Transactions, 
	Static_Data.report_currency = Report_Currency, 
		
	writeln("<!-- Build contexts -->"),	
	/* build up two basic non-dimensional contexts used for simple xbrl facts */
	date(Context_Id_Year,_,_) = End_Date,
	Entity_Identifier = '<identifier scheme="http://www.example.com">TestData</identifier>',
	context_id_base('I', Context_Id_Year, Instant_Context_Id_Base),
	context_id_base('D', Context_Id_Year, Duration_Context_Id_Base),
	Base_Contexts = [
		context(Instant_Context_Id_Base, End_Date, entity(Entity_Identifier, ''), ''),
		context(Duration_Context_Id_Base, (Start_Date, End_Date), entity(Entity_Identifier, ''), '')
	],
	/* sum up the coords of all transactions for each account and apply unit conversions */

	writeln("<!-- Trial balance -->"),
	%trial_balance_between(Static_Data, Trial_Balance2),
	trial_balance_between(Exchange_Rates, Accounts, Transactions, Report_Currency, End_Date, Start_Date, End_Date, Trial_Balance2),

	writeln("<!-- Balance sheet -->"),
	% fix to only include balance  sheet accounts
	%accounts_report(Static_Data, Balance_Sheet2),
	balance_sheet_at(Static_Data, Balance_Sheet2),

	writeln("<!-- Profit and loss -->"),
	profitandloss_between(Static_Data, ProftAndLoss2),

	add_days(Start_Date, -1, Before_Start),
	Static_Data_Historical = Static_Data.put(
		start_date, date(1,1,1)).put(
		end_date, Before_Start).put(
		exchange_date, Start_Date),
	
	profitandloss_between(Static_Data_Historical, ProftAndLoss2_Historical),

	assertion(ground((Balance_Sheet2, ProftAndLoss2, ProftAndLoss2_Historical, Trial_Balance2))),
	
	format_report_entries(xbrl, Accounts, 0, Report_Currency, Instant_Context_Id_Base,  Balance_Sheet2, [], Units0, [], Bs_Lines),
	format_report_entries(xbrl, Accounts, 0, Report_Currency, Duration_Context_Id_Base, ProftAndLoss2,  Units0, Units1, [], Pl_Lines),
	%write_term(format_report_entries(xbrl, Accounts, 0, Report_Currency, Duration_Context_Id_Base, ProftAndLoss2_Historical,  Units0, Units1, [], Pl_Historical_Lines), [quoted(true)]),
	format_report_entries(xbrl, Accounts, 0, Report_Currency, Duration_Context_Id_Base, ProftAndLoss2_Historical,  Units1, Units2, [], Pl_Historical_Lines),
	/*todo can we do without this units in units out nonsense? */
	format_report_entries(xbrl, Accounts, 0, Report_Currency, Instant_Context_Id_Base,  Trial_Balance2, Units2, Units3, [], Tb_Lines),
	%gtrace,	
	investment_reports(Static_Data, Outstanding, Investment_Report_2_Lines, Investment_Report_2_Since_Beginning_Lines),
	bs_report(Static_Data, Balance_Sheet2, Bs_Html),
	pl_report(Static_Data, ProftAndLoss2, '', Pl_Html),
	pl_report(Static_Data_Historical, ProftAndLoss2_Historical, '_historical', Pl_Html_Historical),

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
		'\n<!-- investment report:\n', Investment_Report_2_Lines, '\n -->\n',		
		'\n<!-- bs html:\n', Bs_Html, '\n -->\n',
		'\n<!-- pl html:\n', Pl_Html, '\n -->\n',
		'\n<!-- balance sheet: -->\n', Bs_Lines, 
		'\n<!-- profit and loss: -->\n', Pl_Lines,
		'\n<!-- historical profit and loss: \n', Pl_Historical_Lines, '\n-->\n',
		'\n<!-- historical pl html:\n', Pl_Html_Historical, '\n -->\n',
		'\n<!-- investment report all time:\n', Investment_Report_2_Since_Beginning_Lines, '\n -->\n',		
		'\n<!-- trial balance: -->\n',  Tb_Lines
	], Report_Lines_List),
	atomic_list_concat(Report_Lines_List, Report_Lines),
	writeln(Report_Lines),
	emit_ledger_warnings(S_Transactions, Start_Date, End_Date),
	emit_ledger_errors(Transaction_Transformation_Debug).

print_dimensional_facts(Static_Data, Instant_Context_Id_Base, Duration_Context_Id_Base, Entity_Identifier, Results0, Results3) :-
	print_banks(Static_Data, Instant_Context_Id_Base, Entity_Identifier, Results0, Results1),
	print_forex(Static_Data, Duration_Context_Id_Base, Entity_Identifier, Results1, Results2),
	print_trading(Static_Data, Results2, Results3).
	
investment_reports(Static_Data, Outstanding, Investment_Report_2_Lines, Investment_Report_2_Since_Beginning_Lines) :-
	catch( /*fixme*/
		(
			/* investment_report_1 is useless but does useful cross-checks while it's being compiled */
			investment_report_1(Static_Data, _),
			investment_report_2(Static_Data, Outstanding, '', Investment_Report_2_Lines),
			/* todo we cant do all_time without market values, use last known? */
			investment_report_2(Static_Data.put(start_date, date(1,1,1)), Outstanding, '_since_beginning', Investment_Report_2_Since_Beginning_Lines)
		),
		Err,
		(
			term_string(Err, Err_Str),
			format(string(Msg), 'SYSTEM_WARNING:investment reports fail: ~w', [Err_Str]),
			writeln(Msg),
			Investment_Report_2_Lines = Msg,
			Investment_Report_2_Since_Beginning_Lines = Msg
		)
	).

	
print_xbrl_header :-
	(
		get_flag(prepare_unique_taxonomy_url, true)
	->
		prepare_unique_taxonomy_url(Taxonomy)
	;
		Taxonomy = ''
	),
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
prepare_unique_taxonomy_url(Taxonomy_Dir_Url) :-
   request_tmp_dir(Tmp_Dir),
   server_public_url(Server_Public_Url),
   atomic_list_concat([Server_Public_Url, '/tmp/', Tmp_Dir, '/taxonomy/'], Taxonomy_Dir_Url),
   my_tmp_file_name('/taxonomy', Tmp_Taxonomy),
   absolute_file_name(my_static('taxonomy/'), Static_Taxonomy, [file_type(directory)]),
   atomic_list_concat(['ln -s ', Static_Taxonomy, ' ', Tmp_Taxonomy], Cmd),
   shell(Cmd, 0).

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

	%profitandloss_between(Exchange_Rates, Accounts, Transactions, Report_Currency, End_Date, Start_Date, End_Date, ProftAndLoss),
	%bs_and_pl_entries(Accounts, Report_Currency, none, Balance_Sheet, ProftAndLoss, Used_Units, _, _),
	%pretty_term_string(Balance_Sheet, Message4),
	%pretty_term_string(Trial_Balance, Message4b),
	%pretty_term_string(ProftAndLoss, Message4c),
	%atomic_list_concat([
		%'\n<!--',
		%'BalanceSheet:\n', Message4,'\n\n',
		%'ProftAndLoss:\n', Message4c,'\n\n',
		%'Trial_Balance:\n', Message4b,'\n\n',
		%'-->\n\n'], 
	%Debug_Message2),
	%writeln(Debug_Message2),
	%assertion(ground((Balance_Sheet, ProftAndLoss, Trial_Balance))),
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

extract_action_taxonomy(Dom, Transaction_Types) :-
	(
		(xpath(Dom, //reports/balanceSheetRequest/actionTaxonomy, Taxonomy_Dom),!)
	;
		(
			absolute_file_name(my_static('default_action_taxonomy.xml'), Default_Transaction_Types_File, [ access(read) ]),
			load_xml(Default_Transaction_Types_File, Taxonomy_Dom, [])
		)
	),
	extract_action_taxonomy2(Taxonomy_Dom, Transaction_Types).
   
extract_action_taxonomy2(Dom, Transaction_Types) :-
   findall(Action, xpath(Dom, //action, Action), Actions),
   maplist(extract_action, Actions, Transaction_Types).
   
extract_action(In, transaction_type(Id, Exchange_Account, Trading_Account, Description)) :-
	fields(In, [
		id, Id,
		description, (Description, _),
		exchangeAccount, (Exchange_Account, _),
		tradingAccount, (Trading_Account, _)]).
   
extract_exchange_rates(Dom, End_Date, Default_Currency, Exchange_Rates_Out) :-
/*If an investment was held prior to the from date then it MUST have an opening market value if the reports are expressed in.market rather than cost.You can't mix market value and cost in one set of reports. One or the other.2:27 AMi see. Have you thought about how to let the user specify the method?Andrew, 2:31 AMMarket or Cost. M or C. Sorry. Never mentioned it to you.2:44 AMyou mentioned the different approaches, but i ended up assuming that this would be best selected by specifying or not specifying the unitValues. I see there is a field for it already in the excel templateAndrew, 2:47 AMCost value per unit will always be there if there are units of anything i.e. sheep for livestock trading or shares for InvestmentsAndrew, 3:04 AMBut I suppose if you do not find any market values then assume cost basis.*/
   findall(Unit_Value_Dom, xpath(Dom, //reports/balanceSheetRequest/unitValues/unitValue, Unit_Value_Dom), Unit_Value_Doms),
   maplist(extract_exchange_rate(End_Date, Default_Currency), Unit_Value_Doms, Exchange_Rates),
   include(ground, Exchange_Rates, Exchange_Rates_Out).
   
extract_exchange_rate(End_Date, Optional_Default_Currency, Unit_Value, Exchange_Rate) :-
	Exchange_Rate = exchange_rate(Date, Src_Currency, Dest_Currency, Rate),
	fields(Unit_Value, [
		unitType, Src_Currency,
		unitValueCurrency, (Dest_Currency, _),
		unitValue, (Rate_Atom, _),
		unitValueDate, (Date_Atom, End_Date)]),
	(
		var(Rate_Atom)
	->
		 format(user_error, 'unitValue missing, ignoring\n', [])
	;
		atom_number(Rate_Atom, Rate)
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
	parse_date(Date_Atom, Date)	.

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
	

	
	

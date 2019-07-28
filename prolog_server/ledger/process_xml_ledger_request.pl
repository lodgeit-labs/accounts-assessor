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

:- use_module('../../lib/days', [
		format_date/2, 
		parse_date/2, 
		gregorian_date/2]).
:- use_module('../../lib/utils', [
		inner_xml/3, 
		write_tag/2, 
		fields/2, 
		numeric_fields/2, 
		pretty_term_string/2, 
		throw_string/1]).
:- use_module('../../lib/ledger_report', [
		trial_balance_between/8, 
		profitandloss_between/8, 
		balance_by_account/9, 
		balance_sheet_at/8,
		format_report_entries/9, 
		bs_and_pl_entries/8,
		net_activity_by_account/10]).
:- use_module('../../lib/ledger_report_details', [
		investment_report/3]).
:- use_module('../../lib/statements', [
		extract_transaction/3, 
		preprocess_s_transactions/4, 
		print_relevant_exchange_rates/4, 
		invert_s_transaction_vector/2, 
		fill_in_missing_units/6,
		sort_s_transactions/2]).
:- use_module('../../lib/ledger', [
		emit_ledger_warnings/3,
		process_ledger/12]).
:- use_module('../../lib/livestock', [
		get_livestock_types/2, 
		process_livestock/14, 
		make_livestock_accounts/2,
		extract_livestock_opening_costs_and_counts/2]).
:- use_module('../../lib/accounts', [
		extract_account_hierarchy/2,
		sub_accounts_upto_level/4,
		child_accounts/3,
		account_by_role/3 
		]).
:- use_module('../../lib/exchange_rates', [
		exchange_rate/5]).
:- use_module('../../lib/files', [
		my_tmp_file_name/2,
		request_tmp_dir/1,
		server_public_url/1]).
:- use_module('../../lib/system_accounts', [
		bank_accounts/2]).

% ------------------------------------------------------------------
% process_xml_ledger_request/2
% ------------------------------------------------------------------

process_xml_ledger_request(_, Dom) :-
	extract_default_currency(Dom, Default_Currency),
	extract_report_currency(Dom, Report_Currency),
	extract_action_taxonomy(Dom, Transaction_Types),
	extract_account_hierarchy(Dom, Account_Hierarchy0),

	inner_xml(Dom, //reports/balanceSheetRequest/startDate, [Start_Date_Atom]),
	parse_date(Start_Date_Atom, Start_Date),
	inner_xml(Dom, //reports/balanceSheetRequest/endDate, [End_Date_Atom]),
	parse_date(End_Date_Atom, End_Date),

	writeln('<?xml version="1.0"?>'), nl, nl,
	
	extract_exchange_rates(Dom, End_Date_Atom, Default_Currency, Exchange_Rates),
	findall(Livestock_Dom, xpath(Dom, //reports/balanceSheetRequest/livestockData, Livestock_Dom), Livestock_Doms),
	get_livestock_types(Livestock_Doms, Livestock_Types),
   	extract_livestock_opening_costs_and_counts(Livestock_Doms, Livestock_Opening_Costs_And_Counts),
	findall(S_Transaction, extract_transaction(Dom, Start_Date_Atom, S_Transaction), S_Transactions0),
	maplist(invert_s_transaction_vector, S_Transactions0, S_Transactions0b),
	sort_s_transactions(S_Transactions0b, S_Transactions),
	
	process_ledger(Livestock_Doms, S_Transactions, Start_Date, End_Date, Exchange_Rates, Transaction_Types, Report_Currency, Livestock_Types, Livestock_Opening_Costs_And_Counts, Account_Hierarchy0, Accounts, Transactions),
	output_results(S_Transactions, Transactions, Start_Date, End_Date, Exchange_Rates, Accounts, Report_Currency, Transaction_Types).

	
	
	
	
:- ['../../lib/xbrl_contexts'].

/* given information about a xbrl dimension, print each account as a point in that dimension. 
this means each account results in a fact with a context that contains the value for that dimension.
*/
print_detail_accounts(_,_,[],Results,Results).

print_detail_accounts(
	Static_Data, Context_Info,
	[Bank_Account|Bank_Accounts],  
	In, Out
) :-
	print_detail_account(Static_Data, Context_Info, Bank_Account, In, Mid),
	print_detail_accounts(Static_Data, Context_Info, Bank_Accounts, Mid, Out).
	
print_detail_account(Static_Data, Context_Info, Account, 
	(Contexts_In, Used_Units_In, Lines_In), (Contexts_Out, Used_Units_Out, Lines_Out)
) :-
	dict_vars(Static_Data, [Start_Date, End_Date, Exchange_Rates, Accounts, Transactions, Report_Currency]),
	get_context_id(Account, Context_Info, Contexts_In, Contexts_Out, Context_Id),
	context_arg0_period_type(Context_Info, Period_Type),
	(
		Period_Type = duration
	->
		net_activity_by_account(Exchange_Rates, Accounts, Transactions, Report_Currency, End_Date, Account, Start_Date, End_Date, Balance, Transactions_Count)
	;
		balance_by_account(Exchange_Rates, Accounts, Transactions, Report_Currency, End_Date, Account, End_Date, Balance, Transactions_Count)
	),
	context_arg0_fact_name(Context_Info, Fact_Name),
	format_report_entries(
		Accounts, 1, Report_Currency, Context_Id, 
		[entry(Fact_Name, Balance, [], Transactions_Count)],
		Used_Units_In, Used_Units_Out, Lines_In, Lines_Out).

print_banks(Static_Data, Context_Id_Base, Entity_Identifier, In, Out) :- 
	dict_vars(Static_Data, [End_Date, Accounts]),
	bank_accounts(Accounts, Bank_Accounts),
	Context_Template = context(_, End_Date, entity(Entity_Identifier, _)),
	Context_Info = context_arg0(Context_Id_Base, Context_Template, instant, 'Bank', 'basic:Dimension_BankAccounts', 'basic:BankAccount'),
	print_detail_accounts(Static_Data, Context_Info, Bank_Accounts, In, Out).

print_forex(Static_Data, Context_Id_Base, Entity_Identifier, In, Out) :- 
	dict_vars(Static_Data, [Start_Date, End_Date, Accounts]),
    findall(Account, account_by_role(Accounts, ('Currency_Movement'/_), Account), Movement_Accounts),
	Context_Template = context(_, (Start_Date, End_Date), entity(Entity_Identifier, _)),
	Context_Info = context_arg0(Context_Id_Base, Context_Template, duration, 'Currency_Movement', 'basic:Dimension_BankAccounts', 'basic:BankAccount'),
	print_detail_accounts(Static_Data, Context_Info, Movement_Accounts, In, Out).

print_trading(Sd, In, Out) :-
	findall(
		(Sub_Account, Unit_Accounts),
		(
			trading_account_ids(Sd.transaction_types, Trading_Accounts),
			member(Trading_Account, Trading_Accounts),
			sub_accounts_upto_level(Sd.accounts, Trading_Account, 2, Sub_Accounts),
			member(Sub_Account, Sub_Accounts),
			child_accounts(Sd.accounts, Sub_Account, Unit_Accounts)
		),
		Pairs
	),
	print_trading2(Sd, Pairs, In, Out).
		
/* for a list of (Sub_Account, Unit_Accounts) pairs..*/
print_trading2(Static_Data, [(Sub_Account,Unit_Accounts)|Tail], In, Out):-
	dict_vars(Static_Data, [Start_Date, End_Date, Entity_Identifier, Context_Id_Base]),
	Context_Template = context(_, (Start_Date, End_Date), entity(Entity_Identifier, _)),
	Context_Info = context_arg0(Context_Id_Base, Context_Template, duration, Sub_Account, 'basic:Dimension_Investments', 'basic:Investment'),
	print_detail_accounts(Static_Data, Context_Info, Unit_Accounts, In, Mid),
	print_trading(Static_Data, Tail, Mid, Out).
	
print_trading(_,[],Results,Results).


output_results(S_Transactions, Transactions, Start_Date, End_Date, Exchange_Rates, Accounts, Report_Currency, Transaction_Types) :-

	print_relevant_exchange_rates(Report_Currency, End_Date, Exchange_Rates, Transactions),
	infer_exchange_rates(Transactions, S_Transactions, Start_Date, End_Date, Accounts, Report_Currency, Exchange_Rates, Exchange_Rates2),

	print_xbrl_header,
	
	/* first, let's build up the two non-dimensional contexts */
	date(Context_Id_Year,_,_) = End_Date,
	Entity_Identifier = '<identifier scheme="http://www.example.com">TestData</identifier>',
	context_id_base('I', Context_Id_Year, Instant_Context_Id_Base),
	context_id_base('D', Context_Id_Year, Duration_Context_Id_Base),
	Base_Contexts = [
		context(Instant_Context_Id_Base, End_Date, entity(Entity_Identifier, '')),
		context(Duration_Context_Id_Base, (Start_Date, End_Date), entity(Entity_Identifier, ''))
	],
	
	trial_balance_between(Exchange_Rates2, Accounts, Transactions, Report_Currency, End_Date, Start_Date, End_Date, Trial_Balance2),
	balance_sheet_at(Exchange_Rates2, Accounts, Transactions, Report_Currency, End_Date, Start_Date, End_Date, Balance_Sheet2),
	profitandloss_between(Exchange_Rates2, Accounts, Transactions, Report_Currency, End_Date, Start_Date, End_Date, ProftAndLoss2),
	assertion(ground((Balance_Sheet2, ProftAndLoss2, Trial_Balance2))),
	format_report_entries(Accounts, 0, Report_Currency, Instant_Context_Id_Base,  Balance_Sheet2, [],     Units0, [], Bs_Lines),
	format_report_entries(Accounts, 0, Report_Currency, Duration_Context_Id_Base, ProftAndLoss2,  Units0, Units1, [], Pl_Lines),
	format_report_entries(Accounts, 0, Report_Currency, 'TB',  Trial_Balance2, Units1, Units2, [], Tb_Lines),
	investment_report(
		(Exchange_Rates2, Accounts, Transactions, Report_Currency, End_Date), 
		Transaction_Types, Investment_Report_Lines),
	
	Results0 = (Base_Contexts, Units2, []),
	dict_from_vars(Static_Data, [Start_Date, End_Date, Exchange_Rates, Accounts, Transactions, 
	Report_Currency, Transaction_Types]),

	print_banks(Static_Data, Instant_Context_Id_Base, Entity_Identifier, Results0, Results1),
	gtrace,
	print_forex(Static_Data, Duration_Context_Id_Base, Entity_Identifier, Results1, Results2),
	Results2 = (Contexts3, Units3, Dimensions_Lines),

	print_contexts(Contexts3), nl,
	maplist(write_used_unit, Units3), nl,
	maplist(writeln, Dimensions_Lines),
	
	flatten([
		'\n<!-- balance sheet: -->\n', Bs_Lines, 
		'\n<!-- profit and loss: -->\n', Pl_Lines,
		'\n<!-- investment report:\n', Investment_Report_Lines, '\n -->\n',
		'\n<!-- trial balance: -->\n',  Tb_Lines
	], Report_Lines_List),
	atomic_list_concat(Report_Lines_List, Report_Lines),
	writeln(Report_Lines),
	writeln('</xbrli:xbrl>'),
	emit_ledger_warnings(S_Transactions, Start_Date, End_Date),
	nl, nl.


print_xbrl_header :-
	(
		get_flag(prepare_unique_taxonomy_url, true)
	->
		prepare_unique_taxonomy_url(Taxonomy)
	;
		Taxonomy = ''
	),
	write('<xbrli:xbrl xmlns:xbrli="http://www.xbrl.org/2003/instance" xmlns:link="http://www.xbrl.org/2003/linkbase" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:iso4217="http://www.xbrl.org/2003/iso4217" xmlns:basic="http://www.xbrlsite.com/basic" xmlns:xbrldi="http://xbrl.org/2006/xbrldi" xsi:schemaLocation="http://www.xbrlsite.com/basic '),write(Taxonomy),writeln('basic.xsd http://www.xbrl.org/2003/instance http://www.xbrl.org/2003/xbrl-instance-2003-12-31.xsd http://www.xbrl.org/2003/linkbase http://www.xbrl.org/2003/xbrl-linkbase-2003-12-31.xsd http://xbrl.org/2006/xbrldi http://www.xbrl.org/2006/xbrldi-2006.xsd>'),
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
   absolute_file_name(my_taxonomy('/'), Static_Taxonomy, [file_type(directory)]),
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
   inner_xml(Dom, //reports/balanceSheetRequest/defaultCurrency/unitType, Default_Currency).

extract_report_currency(Dom, Report_Currency) :-
   inner_xml(Dom, //reports/balanceSheetRequest/reportCurrency/unitType, Report_Currency).

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



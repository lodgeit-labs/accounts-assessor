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
:- use_module('../../lib/days', [format_date/2, parse_date/2, gregorian_date/2]).
:- use_module('../../lib/utils', [
	inner_xml/3, write_tag/2, fields/2, fields_nothrow/2, numeric_fields/2, 
	pretty_term_string/2, throw_string/1]).
:- use_module('../../lib/ledger', [balance_sheet_at/8, trial_balance_between/8, profitandloss_between/8, balance_by_account/9]).
:- use_module('../../lib/statements', [extract_transaction/3, preprocess_s_transactions/4, add_bank_accounts/3,  get_relevant_exchange_rates/5, invert_s_transaction_vector/2, find_s_transactions_in_period/4, fill_in_missing_units/6]).
:- use_module('../../lib/livestock', [get_livestock_types/2, process_livestock/14, make_livestock_accounts/2, livestock_counts/5, extract_livestock_opening_costs_and_counts/2]).
:- use_module('../../lib/accounts', [extract_account_hierarchy/2, account_ancestor_id/3]).
:- use_module('../../lib/transactions', [check_transaction_account/2]).
:- use_module('../../lib/exchange_rates', [exchange_rate/5]).

% ------------------------------------------------------------------
% process_xml_ledger_request/2
% ------------------------------------------------------------------

process_xml_ledger_request(_, Dom) :-

	extract_default_currency(Dom, Default_Currency),
	extract_report_currency(Dom, Report_Currency),
	extract_action_taxonomy(Dom, Action_Taxonomy),
	extract_account_hierarchy(Dom, Account_Hierarchy0),

	inner_xml(Dom, //reports/balanceSheetRequest/startDate, [Start_Date_Atom]),
	parse_date(Start_Date_Atom, Start_Days),
	inner_xml(Dom, //reports/balanceSheetRequest/endDate, [End_Date_Atom]),
	parse_date(End_Date_Atom, End_Days),

	findall(S_Transaction, extract_transaction(Dom, Start_Date_Atom, S_Transaction), S_Transactions0),

	writeln('<?xml version="1.0"?>'), nl, nl,

	emit_warnings(S_Transactions0, Start_Days, End_Days),

	maplist(invert_s_transaction_vector, S_Transactions0, S_Transactions0b),
	sort_s_transactions(S_Transactions0b, S_Transactions),
	
	extract_exchange_rates(Dom, End_Date_Atom, Default_Currency, Exchange_Rates),

	pretty_term_string(Exchange_Rates, Message1b),
	pretty_term_string(Action_Taxonomy, Message2),
	pretty_term_string(Account_Hierarchy0, Message3),
	atomic_list_concat([
	'\n<!--',
	'Exchange rates extracted:\n', Message1b,'\n\n',
	'Action_Taxonomy extracted:\n',Message2,'\n\n',
	'Account_Hierarchy extracted:\n',Message3,'\n\n',
	'-->\n\n'], Debug_Message0),
	writeln(Debug_Message0),
	
	findall(Livestock_Dom, xpath(Dom, //reports/balanceSheetRequest/livestockData, Livestock_Dom), Livestock_Doms),
	get_livestock_types(Livestock_Doms, Livestock_Types),
	
	maplist(make_livestock_accounts, Livestock_Types, Livestock_Accounts_Nested),
	flatten(Livestock_Accounts_Nested, Livestock_Accounts),
	append(Account_Hierarchy0, Livestock_Accounts, Account_Hierarchy0b),
	
	add_bank_accounts(S_Transactions, Account_Hierarchy0b, Account_Hierarchy),
	preprocess_s_transactions((Account_Hierarchy, Report_Currency, Action_Taxonomy, End_Days, Exchange_Rates), S_Transactions, Transactions1, Transaction_Transformation_Debug),
   
   	extract_livestock_opening_costs_and_counts(Livestock_Doms, Livestock_Opening_Costs_And_Counts),
   
	process_livestock(Livestock_Doms, Livestock_Types, S_Transactions, Transactions1, Livestock_Opening_Costs_And_Counts, Start_Days, End_Days, Exchange_Rates, Account_Hierarchy, Report_Currency, Transactions_With_Livestock, Livestock_Events, Average_Costs, Average_Costs_Explanations),
   
	maplist(check_transaction_account(Account_Hierarchy), Transactions_With_Livestock),

	
	trial_balance_between(Exchange_Rates, Account_Hierarchy, Transactions_With_Livestock, Report_Currency, End_Days, Start_Days, End_Days, Trial_Balance),
	balance_sheet_at(Exchange_Rates, Account_Hierarchy, Transactions_With_Livestock, Report_Currency, End_Days, Start_Days, End_Days, Balance_Sheet),
	profitandloss_between(Exchange_Rates, Account_Hierarchy, Transactions_With_Livestock, Report_Currency, End_Days, Start_Days, End_Days, ProftAndLoss),

	
	livestock_counts(Livestock_Types, Transactions_With_Livestock, Livestock_Opening_Costs_And_Counts, End_Days, Livestock_Counts),
	
	(
		Report_Currency = []
	->
		true
	;	
		get_relevant_exchange_rates(Report_Currency, End_Days, Exchange_Rates, Transactions_With_Livestock, Exchange_Rates_Of_Interest)
	),
	
%	pretty_term_string(S_Transactions, Message0),
	pretty_term_string(Livestock_Events, Message0b),
	pretty_term_string(Transactions_With_Livestock, Message1),
	pretty_term_string(Exchange_Rates_Of_Interest, Message1c),
	pretty_term_string(Livestock_Counts, Message12),
	pretty_term_string(Balance_Sheet, Message4),
	pretty_term_string(Trial_Balance, Message4b),
	pretty_term_string(ProftAndLoss, Message4c),
	pretty_term_string(Average_Costs, Message5),
	pretty_term_string(Average_Costs_Explanations, Message5b),
	atomic_list_concat(Transaction_Transformation_Debug, Message10),

	(
		Livestock_Doms = []
	->
		Livestock_Debug = ''
	;
		atomic_list_concat([
		'Livestock Events:\n', Message0b,'\n\n',
		'Livestock Counts:\n', Message12,'\n\n',
		'Average_Costs:\n', Message5,'\n\n',
		'Average_Costs_Explanations:\n', Message5b,'\n\n',
		'Transactions_With_Livestock:\n', Message1,'\n\n'
		], Livestock_Debug)
	),
	
	(
	%Debug_Message = '',!;
	atomic_list_concat([
	'\n<!--',
%	'S_Transactions:\n', Message0,'\n\n',
	Livestock_Debug,
	'Transaction_Transformation_Debug:\n', Message10,'\n\n',
	'Exchange rates2:\n', Message1c,'\n\n',
	'BalanceSheet:\n', Message4,'\n\n',
	'ProftAndLoss:\n', Message4c,'\n\n',
	'Trial_Balance:\n', Message4b,'\n\n',
	'-->\n\n'], Debug_Message)
	),

	assertion(ground((Balance_Sheet, ProftAndLoss))),
	balance_sheet_entries(Account_Hierarchy, Report_Currency, 666, Balance_Sheet, ProftAndLoss, Used_Units, _, _),
	
	pretty_term_string(Used_Units, Used_Units_Str),
	writeln('<!-- units used in balance sheet: \n'),
	writeln(Used_Units_Str),
	writeln('\n-->\n'),
	
	fill_in_missing_units(S_Transactions, End_Days, Report_Currency, Used_Units, Exchange_Rates, Inferred_Rates),
	
	pretty_term_string(Inferred_Rates, Inferred_Rates_Str),
	writeln('<!-- Inferred_Rates: \n'),
	writeln(Inferred_Rates_Str),
	writeln('\n-->\n'),
	
	append(Exchange_Rates, Inferred_Rates, Exchange_Rates_With_Inferred_Values),
	%append(Exchange_Rates, [], Exchange_Rates_With_Inferred_Values),
	
/*	
	gtrace,
	exchange_rate(
		Exchange_Rates_With_Inferred_Values, date(2018,12,30), 
		'CHF','AUD',
		RRRRRRRR),
	print_term(RRRRRRRR,[]),*/
	/*
	exchange_rate(
		Exchange_Rates_With_Inferred_Values, End_Days, 
		without_currency_movement_against_since('Raiffeisen Switzerland_B.V.', 
		'USD', ['AUD'],date(2018,7,2)),
		'AUD',
		RRRRRRRR),
	print_term(RRRRRRRR,[]),
	*/
	
	trial_balance_between(Exchange_Rates_With_Inferred_Values, Account_Hierarchy, Transactions_With_Livestock, Report_Currency, End_Days, Start_Days, End_Days, Trial_Balance2),
	balance_sheet_at(Exchange_Rates_With_Inferred_Values, Account_Hierarchy, Transactions_With_Livestock, Report_Currency, End_Days, Start_Days, End_Days, Balance_Sheet2),
	profitandloss_between(Exchange_Rates_With_Inferred_Values, Account_Hierarchy, Transactions_With_Livestock, Report_Currency, End_Days, Start_Days, End_Days, ProftAndLoss2),


	display_xbrl_ledger_response(Account_Hierarchy, Report_Currency, Debug_Message, Start_Days, End_Days, Balance_Sheet2, Trial_Balance2, ProftAndLoss2),
	emit_warnings(S_Transactions0, Start_Days, End_Days),
	nl, nl.


% -----------------------------------------------------
% display_xbrl_ledger_response/4
% -----------------------------------------------------

display_xbrl_ledger_response(Account_Hierarchy, Report_Currency, Debug_Message, Start_Days, End_Days, Balance_Sheet_Entries, Trial_Balance, ProftAndLoss_Entries) :-
   writeln('<xbrli:xbrl xmlns:xbrli="http://www.xbrl.org/2003/instance" xmlns:link="http://www.xbrl.org/2003/linkbase" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:iso4217="http://www.xbrl.org/2003/iso4217" xmlns:basic="http://www.xbrlsite.com/basic">'),
   writeln('  <link:schemaRef xlink:type="simple" xlink:href="basic.xsd" xlink:title="Taxonomy schema" />'),
   writeln('  <link:linkbaseRef xlink:type="simple" xlink:href="basic-formulas.xml" xlink:arcrole="http://www.w3.org/1999/xlink/properties/linkbase" />'),
   writeln('  <link:linkBaseRef xlink:type="simple" xlink:href="basic-formulas-cross-checks.xml" xlink:arcrole="http://www.w3.org/1999/xlink/properties/linkbase" />'),

   format_date(End_Days, End_Date_String),
   format_date(Start_Days, Start_Date_String),
   End_Days = date(End_Year,_,_),
   
   format( '  <context id="D-~w">\n', End_Year),
   writeln('    <entity>'),
   writeln('      <identifier scheme="http://standards.iso.org/iso/17442">30810137d58f76b84afd</identifier>'),
   writeln('    </entity>'),
   writeln('    <period>'),
   format( '      <startDate>~w</startDate>\n', Start_Date_String),
   format( '      <endDate>~w</endDate>\n', End_Date_String),
   writeln('    </period>'),
   writeln('  </context>'),

   balance_sheet_entries(Account_Hierarchy, Report_Currency, End_Year, Balance_Sheet_Entries, ProftAndLoss_Entries, Used_Units, Lines2, Lines3),

   format_balance_sheet_entries(Account_Hierarchy, 0, Report_Currency, End_Year, Trial_Balance, [], _, [], Lines1),
   maplist(write_used_unit, Used_Units), 

   flatten([
		'<!-- balance sheet: -->\n', Lines3, 
		'<!-- profit and loss: -->\n', Lines2,
		'<!-- trial balance: -->\n',  Lines1
	], Lines),
   atomic_list_concat(Lines, LinesString),
   writeln(LinesString),
   writeln('</xbrli:xbrl>'),
   writeln(Debug_Message).

balance_sheet_entries(Account_Hierarchy, Report_Currency, End_Year, Balance_Sheet_Entries, ProftAndLoss_Entries, Used_Units_Out, Lines2, Lines3) :-
	format_balance_sheet_entries(Account_Hierarchy, 0, Report_Currency, End_Year, Balance_Sheet_Entries, [], Used_Units, [], Lines3),
	format_balance_sheet_entries(Account_Hierarchy, 0, Report_Currency, End_Year, ProftAndLoss_Entries, Used_Units, Used_Units_Out, [], Lines2).

format_balance_sheet_entries(_,_,_,_, [], Used_Units, Used_Units, Lines, Lines).

format_balance_sheet_entries(Account_Hierarchy, Level, Report_Currency, End_Year, Entries, Used_Units_In, UsedUnitsOut, LinesIn, LinesOut) :-
	[entry(Name, Balances, Children, Transactions_Count)|EntriesTail] = Entries,
	(
		(Balances = [],(Transactions_Count \= 0; Level = 0))
	->
		format_balance(Account_Hierarchy, Level, Report_Currency, End_Year, Name, [],
			Used_Units_In, UsedUnitsIntermediate, LinesIn, LinesIntermediate)
	;
		format_balances(Account_Hierarchy, Level, Report_Currency, End_Year, Name, Balances, 
			Used_Units_In, UsedUnitsIntermediate, LinesIn, LinesIntermediate)
	),
	Level_New is Level + 1,
	format_balance_sheet_entries(Account_Hierarchy, Level_New, Report_Currency, End_Year, Children, UsedUnitsIntermediate, UsedUnitsIntermediate2, LinesIntermediate, LinesIntermediate2),
	format_balance_sheet_entries(Account_Hierarchy, Level, Report_Currency, End_Year, EntriesTail, UsedUnitsIntermediate2, UsedUnitsOut, LinesIntermediate2, LinesOut),
	!.

format_balance_sheet_entries(_, _, _, _, [], Used_Units, Used_Units, Lines, Lines).

format_balances(_, _, _, _, _, [], Used_Units, Used_Units, Lines, Lines).

format_balances(Account_Hierarchy, Level, Report_Currency, End_Year, Name, [Balance|Balances], Used_Units_In, UsedUnitsOut, LinesIn, LinesOut) :-
   format_balance(Account_Hierarchy, Level, Report_Currency, End_Year, Name, [Balance], Used_Units_In, UsedUnitsIntermediate, LinesIn, LinesIntermediate),
   format_balances(Account_Hierarchy, Level, Report_Currency, End_Year, Name, Balances, UsedUnitsIntermediate, UsedUnitsOut, LinesIntermediate, LinesOut).

format_balance(Account_Hierarchy, Level, Report_Currency_List, End_Year, Name, [], Used_Units_In, UsedUnitsOut, LinesIn, LinesOut) :-
	(
		[Report_Currency] = Report_Currency_List
	->
		true
	;
		Report_Currency = 'AUD' % just for displaying zero balance
	),
	format_balance(Account_Hierarchy, Level, _, End_Year, Name, [coord(Report_Currency, 0, 0)], Used_Units_In, UsedUnitsOut, LinesIn, LinesOut).
   
format_balance(Account_Hierarchy, Level, _, End_Year, Name, [coord(Unit, Debit, Credit)], Used_Units_In, UsedUnitsOut, LinesIn, LinesOut) :-
	union([Unit], Used_Units_In, UsedUnitsOut),
	(
		account_ancestor_id(Account_Hierarchy, Name, 'Liabilities')
	->
		Balance is (Credit - Debit)
	;
	(
		account_ancestor_id(Account_Hierarchy, Name, 'Equity')
	->
		Balance is (Credit - Debit)
	;
	(
		account_ancestor_id(Account_Hierarchy, Name, 'Expenses')
	->
		Balance is (Debit - Credit)
	;
	(
		account_ancestor_id(Account_Hierarchy, Name, 'Earnings')
	->
		Balance is (Credit - Debit)
	;
		Balance is (Debit - Credit)
	)))),
	get_indentation(Level, Indentation),
	format(string(BalanceSheetLine), '~w<basic:~w contextRef="D-~w" unitRef="U-~w" decimals="INF">~2:f</basic:~w>\n', [Indentation, Name, End_Year, Unit, Balance, Name]),
	append(LinesIn, [BalanceSheetLine], LinesOut).

get_indentation(Level, Indentation) :-
	Level > 0,
	Level2 is Level - 1,
	get_indentation(Level2, Indentation2),
	atomic_list_concat([Indentation2, ' '], Indentation).

get_indentation(0, ' ').

write_used_unit(Unit) :-
	format('  <unit id="U-~w"><measure>~w</measure></unit>\n', [Unit, Unit]).
   
	
extract_default_currency(Dom, Default_Currency) :-
   inner_xml(Dom, //reports/balanceSheetRequest/defaultCurrency/unitType, Default_Currency).

extract_report_currency(Dom, Report_Currency) :-
   inner_xml(Dom, //reports/balanceSheetRequest/reportCurrency/unitType, Report_Currency).

extract_action_taxonomy(Dom, Action_Taxonomy) :-
	(
		(xpath(Dom, //reports/balanceSheetRequest/actionTaxonomy, Taxonomy_Dom),!)
	;
		(
			absolute_file_name(my_static('actual-loan-response.xml'), Default_Action_Taxonomy_File, [ access(read) ]),
			load_xml(Default_Action_Taxonomy_File, Taxonomy_Dom, [])
		)
	),
	extract_action_taxonomy2(Taxonomy_Dom, Action_Taxonomy).
   
extract_action_taxonomy2(Dom, Action_Taxonomy) :-
   findall(Action, xpath(Dom, //action, Action), Actions),
   maplist(extract_action, Actions, Action_Taxonomy).
   
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

   
sort_s_transactions(In, Out) :-
	/*
	If a buy and a sale of same thing happens on the same day, we want to process the buy first.
	We first sort by our debit on the bank account. Transactions with zero of our debit are not sales.
	*/
	sort(
	/*
	this is a path inside the structure of the elements of the sorted array (inside the s_transactions):
	3th sub-term is the amount from bank perspective. 
	1st (and hopefully only) item of the vector is the coord,
	3rd item of the coord is bank credit, our debit.
	*/
	[3,1,3], @=<,  In, Mid),
	/*now we can sort by date ascending, and the order of transactions with same date, as sorted above, will be preserved*/
	sort(1, @=<,  Mid, Out).


test0 :-
	In = [ s_transaction(736542,
			'Borrow',
			[coord('AUD',0,100)],
			'NationalAustraliaBank',
			bases(['AUD'])),
	s_transaction(736704,
			'Dispose_Of',
			[coord('AUD',0.0,1000.0)],
			'NationalAustraliaBank',
			vector([coord('TLS',0,11)])),
	s_transaction(736511,
			'Introduce_Capital',
			[coord('USD',0,200)],
			'WellsFargo',
			bases(['USD'])),
	s_transaction(736704,
			'Invest_In',
			[coord('USD',50,0)],
			'WellsFargo',
			vector([coord('TLS',10,0)])),
	s_transaction(736520,
			'Invest_In',
			[coord('USD',100.0,0.0)],
			'WellsFargo',
			vector([coord('TLS',10,0)])),
	s_transaction(736704,
			'Dispose_Of',
			[coord('USD',0.0,420.0)],
			'WellsFargo',
			vector([coord('TLS',0,4)]))
	],

	Out = [ s_transaction(736511,
			'Introduce_Capital',
			[coord('USD',0,200)],
			'WellsFargo',
			bases(['USD'])),
	s_transaction(736520,
			'Invest_In',
			[coord('USD',100.0,0.0)],
			'WellsFargo',
			vector([coord('TLS',10,0)])),
	s_transaction(736542,
			'Borrow',
			[coord('AUD',0,100)],
			'NationalAustraliaBank',
			bases(['AUD'])),
	s_transaction(736704,
			'Invest_In',
			[coord('USD',50,0)],
			'WellsFargo',
			vector([coord('TLS',10,0)])),
	s_transaction(736704,
			'Dispose_Of',
			[coord('USD',0.0,420.0)],
			'WellsFargo',
			vector([coord('TLS',0,4)])),
	s_transaction(736704,
			'Dispose_Of',
			[coord('AUD',0.0,1000.0)],
			'NationalAustraliaBank',
			vector([coord('TLS',0,11)]))
	],
	
	sort_s_transactions(In, Out).
test0.


emit_warnings(S_Transactions0, Start_Days, End_Days) :-
	(
		find_s_transactions_in_period(S_Transactions0, Start_Days, End_Days, [])
	->
		writeln('<!-- WARNING: no transactions within request period -->\n')
	;
		true
	).


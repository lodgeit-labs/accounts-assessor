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
	pretty_term_string/2]).
:- use_module('../../lib/ledger', [balance_sheet_at/8, trial_balance_between/8, profitandloss_between/8, balance_by_account/8]).
:- use_module('../../lib/statements', [extract_transaction/4, preprocess_s_transactions/4, add_bank_accounts/3,  get_relevant_exchange_rates/5]).
:- use_module('../../lib/livestock', [get_livestock_types/2, process_livestock/15, make_livestock_accounts/2, livestock_counts/5, extract_livestock_opening_costs_and_counts/2]).
:- use_module('../../lib/accounts', [extract_account_hierarchy/2]).
:- use_module('../../lib/transactions', [check_transaction_account/2]).


% ------------------------------------------------------------------
% process_xml_ledger_request/2
% ------------------------------------------------------------------

process_xml_ledger_request(_, Dom) :-
	% this serves as an indicator of the desired report currency
	extract_default_bases(Dom, Default_Bases),
	extract_action_taxonomy(Dom, Action_Taxonomy),
	extract_account_hierarchy(Dom, Account_Hierarchy0),
	[Default_Currency] = Default_Bases,
	Report_Currency = Default_Currency,
	extract_exchange_rates(Dom, End_Days, Exchange_Rates, Default_Currency),

	inner_xml(Dom, //reports/balanceSheetRequest/startDate, [Start_Date_Atom]),
	parse_date(Start_Date_Atom, Start_Days),
	inner_xml(Dom, //reports/balanceSheetRequest/endDate, [End_Date_Atom]),
	parse_date(End_Date_Atom, End_Days),

	findall(Livestock_Dom, xpath(Dom, //reports/balanceSheetRequest/livestockData, Livestock_Dom), Livestock_Doms),
	get_livestock_types(Livestock_Doms, Livestock_Types),
	
	maplist(make_livestock_accounts, Livestock_Types, Livestock_Accounts_Nested),
	flatten(Livestock_Accounts_Nested, Livestock_Accounts),
	append(Account_Hierarchy0, Livestock_Accounts, Account_Hierarchy0b),
	
	findall(Transaction, extract_transaction(Dom, Default_Bases, Start_Date_Atom, Transaction), S_Transactions0),
	sort_s_transactions(S_Transactions0, S_Transactions),
	add_bank_accounts(S_Transactions, Account_Hierarchy0b, Account_Hierarchy),
	preprocess_s_transactions((Account_Hierarchy, Report_Currency, Action_Taxonomy, End_Days, Exchange_Rates), S_Transactions, Transactions1, Transaction_Transformation_Debug),
   
   	extract_livestock_opening_costs_and_counts(Livestock_Doms, Livestock_Opening_Costs_And_Counts),
   
	process_livestock(Livestock_Doms, Livestock_Types, Default_Bases, S_Transactions, Transactions1, Livestock_Opening_Costs_And_Counts, Start_Days, End_Days, Exchange_Rates, Account_Hierarchy, Default_Bases, Transactions2, Livestock_Events, Average_Costs, Average_Costs_Explanations),
   
	%print_term(Transactions1, []),
	
	maplist(check_transaction_account(Account_Hierarchy), Transactions2),
	   
	trial_balance_between(Exchange_Rates, Account_Hierarchy, Transactions2, Default_Bases, End_Days, Start_Days, End_Days, Trial_Balance),

	balance_sheet_at(Exchange_Rates, Account_Hierarchy, Transactions2, Default_Bases, End_Days, Start_Days, End_Days, Balance_Sheet),
	
	profitandloss_between(Exchange_Rates, Account_Hierarchy, Transactions2, Default_Bases, End_Days, Start_Days, End_Days, ProftAndLoss),

	livestock_counts(Livestock_Types, Transactions2, Livestock_Opening_Costs_And_Counts, End_Days, Livestock_Counts),
	
	get_relevant_exchange_rates(Report_Currency, End_Days, Exchange_Rates, Transactions2, Exchange_Rates2),
	
	pretty_term_string(S_Transactions, Message0),
	pretty_term_string(Livestock_Events, Message0b),
	pretty_term_string(Transactions2, Message1),
	pretty_term_string(Exchange_Rates, Message1b),
	pretty_term_string(Exchange_Rates2, Message1c),
	pretty_term_string(Action_Taxonomy, Message2),
	pretty_term_string(Account_Hierarchy, Message3),
	pretty_term_string(Livestock_Counts, Message12),
	pretty_term_string(Balance_Sheet, Message4),
	pretty_term_string(Trial_Balance, Message4b),
	pretty_term_string(ProftAndLoss, Message4c),
	pretty_term_string(Average_Costs, Message5),
	pretty_term_string(Average_Costs_Explanations, Message5b),
	atomic_list_concat(Transaction_Transformation_Debug, Message10),
	(
	%Debug_Message = '',!;
	atomic_list_concat([
	'\n<!--',
	'Action_Taxonomy:\n',Message2,'\n\n',
	'Account_Hierarchy:\n',Message3,'\n\n',
	'S_Transactions:\n', Message0,'\n\n',
	'Livestock Events:\n', Message0b,'\n\n',
	'Livestock Counts:\n', Message12,'\n\n',
	'Average_Costs:\n', Message5,'\n\n',
	'Average_Costs_Explanations:\n', Message5b,'\n\n',
	'Transactions:\n', Message1,'\n\n',
	'Transaction_Transformation_Debug:\n', Message10,'\n\n',
	'Exchange rates:\n', Message1b,'\n\n',
	'Exchange rates2:\n', Message1c,'\n\n',
	'BalanceSheet:\n', Message4,'\n\n',
	'ProftAndLoss:\n', Message4c,'\n\n',
	'Trial_Balance:\n', Message4b,'\n\n',
	'-->\n\n'], Debug_Message)
	),

	display_xbrl_ledger_response(Debug_Message, Start_Days, End_Days, Balance_Sheet, Trial_Balance, ProftAndLoss).

	
extract_default_bases(Dom, Bases) :-
   inner_xml(Dom, //reports/balanceSheetRequest/defaultUnitTypes/unitType, Bases).

extract_action_taxonomy(Dom, Action_Taxonomy) :-
	(
		(xpath(Dom, //reports/balanceSheetRequest/actionTaxonomy, Taxonomy_Dom),!)
	;
		load_xml('./static/default_action_taxonomy.xml', Taxonomy_Dom, [])
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
   
extract_exchange_rates(Dom, End_Date, Exchange_Rates, Default_Currency) :-
   findall(Unit_Value_Dom, xpath(Dom, //reports/balanceSheetRequest/unitValues/unitValue, Unit_Value_Dom), Unit_Value_Doms),
   maplist(extract_exchange_rate(End_Date, Default_Currency), Unit_Value_Doms, Exchange_Rates).
   
extract_exchange_rate(End_Date, Default_Currency, Unit_Value, Exchange_Rate) :-
	Exchange_Rate = exchange_rate(End_Date, Src_Currency, Dest_Currency, Rate),
	fields(Unit_Value, [
		unitType, Src_Currency,
		unitValueCurrency, (Dest_Currency, Default_Currency),
		unitValue, Rate_Atom]),
	atom_number(Rate_Atom, Rate).

% -----------------------------------------------------
% display_xbrl_ledger_response/4
% -----------------------------------------------------

display_xbrl_ledger_response(Debug_Message, Start_Days, End_Days, Balance_Sheet_Entries, Trial_Balance, ProftAndLoss_Entries) :-
   format('Content-type: text/xml~n~n'), 
   writeln('<?xml version="1.0"?>'),
   writeln('<xbrli:xbrl xmlns:xbrli="http://www.xbrl.org/2003/instance" xmlns:link="http://www.xbrl.org/2003/linkbase" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:iso4217="http://www.xbrl.org/2003/iso4217" xmlns:basic="http://www.xbrlsite.com/basic">'),
   writeln('  <link:schemaRef xlink:type="simple" xlink:href="basic.xsd" xlink:title="Taxonomy schema" />'),
   writeln('  <link:linkbaseRef xlink:type="simple" xlink:href="basic-formulas.xml" xlink:arcrole="http://www.w3.org/1999/xlink/properties/linkbase" />'),
   writeln('  <link:linkBaseRef xlink:type="simple" xlink:href="basic-formulas-cross-checks.xml" xlink:arcrole="http://www.w3.org/1999/xlink/properties/linkbase" />'),

   format_date(End_Days, End_Date_String),
   format_date(Start_Days, Start_Date_String),
   gregorian_date(End_Days, date(End_Year,_,_)),
   
   format( '  <context id="D-~w">\n', End_Year),
   writeln('    <entity>'),
   writeln('      <identifier scheme="http://standards.iso.org/iso/17442">30810137d58f76b84afd</identifier>'),
   writeln('    </entity>'),
   writeln('    <period>'),
   format( '      <startDate>~w</startDate>\n', Start_Date_String),
   format( '      <endDate>~w</endDate>\n', End_Date_String),
   writeln('    </period>'),
   writeln('  </context>'),

   format_balance_sheet_entries(End_Year, Balance_Sheet_Entries, [], Used_Units, [], Lines3),
   format_balance_sheet_entries(End_Year, Trial_Balance, [], _, [], Lines1),
   format_balance_sheet_entries(End_Year, ProftAndLoss_Entries, [], _, [], Lines2),
   maplist(write_used_unit, Used_Units), 

   flatten([Lines1, Lines2, Lines3], Lines),
   atomic_list_concat(Lines, LinesString),
   writeln(LinesString),
   writeln('</xbrli:xbrl>'),
   writeln(Debug_Message),
   nl, nl.

format_balance_sheet_entries(_, [], Used_Units, Used_Units, Lines, Lines).

format_balance_sheet_entries(End_Year, Entries, Used_Units_In, UsedUnitsOut, LinesIn, LinesOut) :-
   [entry(Name, Balances, Children)|EntriesTail] = Entries,
   format_balances(End_Year, Name, Balances, Used_Units_In, UsedUnitsIntermediate, LinesIn, LinesIntermediate),
   format_balance_sheet_entries(End_Year, Children, UsedUnitsIntermediate, UsedUnitsIntermediate2, LinesIntermediate, LinesIntermediate2),
   format_balance_sheet_entries(End_Year, EntriesTail, UsedUnitsIntermediate2, UsedUnitsOut, LinesIntermediate2, LinesOut).

format_balances(_, _, [], Used_Units, Used_Units, Lines, Lines).

format_balances(End_Year, Name, [Balance|Balances], Used_Units_In, UsedUnitsOut, LinesIn, LinesOut) :-
   format_balance(End_Year, Name, Balance, Used_Units_In, UsedUnitsIntermediate, LinesIn, LinesIntermediate),
   format_balances(End_Year, Name, Balances, UsedUnitsIntermediate, UsedUnitsOut, LinesIntermediate, LinesOut).
  
format_balance(End_Year, Name, coord(Unit, Debit, Credit), Used_Units_In, UsedUnitsOut, LinesIn, LinesOut) :-
   union([Unit], Used_Units_In, UsedUnitsOut),
   Balance is round(Debit - Credit),
   format(string(BalanceSheetLine), '  <basic:~w contextRef="D-~w" unitRef="U-~w" decimals="INF">~D</basic:~w>\n', [Name, End_Year, Unit, Balance, Name]),
   append(LinesIn, [BalanceSheetLine], LinesOut).

write_used_unit(Unit) :-
   format('  <unit id="U-~w"><measure>~w</measure></unit>\n', [Unit, Unit]).
   

   
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

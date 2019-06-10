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
	inner_xml/3, write_tag/2, fields/2, numeric_fields/2, 
	pretty_term_string/2]).
:- use_module('../../lib/ledger', [balance_sheet_at/8]).
:- use_module('../../lib/statements', [preprocess_s_transactions/5]).


% ------------------------------------------------------------------
% process_xml_ledger_request/2
% ------------------------------------------------------------------

process_xml_ledger_request(_, Dom) :-
   extract_default_bases(Dom, Default_Bases),
   extract_action_taxonomy(Dom, Action_Taxonomy),
   extract_account_hierarchy(Dom, Account_Hierarchy),
   extract_exchange_rates(Dom, End_Days, Exchange_Rates),
 
   findall(Transaction, extract_transactions(Dom, Default_Bases, Transaction), S_Transactions),

   inner_xml(Dom, //reports/balanceSheetRequest/startDate, [Start_Date_Atom]),
   parse_date(Start_Date_Atom, Start_Days),
   inner_xml(Dom, //reports/balanceSheetRequest/endDate, [End_Date_Atom]),
   parse_date(End_Date_Atom, End_Days),

   preprocess_s_transactions(Account_Hierarchy, Exchange_Rates, Action_Taxonomy, S_Transactions, Transactions_Nested),
   flatten(Transactions_Nested, Transactions),
   
   findall(Livestock_Dom, xpath(Dom, //reports/balanceSheetRequest/livestockData, Livestock_Dom), Livestock_Doms),

  % get_livestock_types(Account_Hierarchy, Livestock_Types),
   Livestock_Types = ['Sheep'],

   extract_livestock_events(Livestock_Doms, Livestock_Events),
   extract_natural_increase_costs(Livestock_Doms, Natural_Increase_Costs),
   extract_opening_costs_and_counts(Livestock_Doms, Opening_Costs_And_Counts),

   maplist(preprocess_livestock_event, Livestock_Events, Livestock_Event_Transactions_Nested),
   flatten(Livestock_Event_Transactions_Nested, Livestock_Event_Transactions),
   append(Transactions, Livestock_Event_Transactions, Transactions2),

   get_average_costs(Livestock_Types, Opening_Costs_And_Counts, (Start_Days, End_Days, S_Transactions, Livestock_Events, Natural_Increase_Costs), Average_Costs_With_Explanations),
   maplist(with_info_value_and_info, Average_Costs_With_Explanations, Average_Costs, Average_Costs_Explanations),
      
   get_more_transactions(Livestock_Types, Average_Costs, S_Transactions, Livestock_Events, More_Transactions),
   
   append(Transactions2, More_Transactions, Transactions3),  
   
   
   livestock_cogs_transactions(Livestock_Types, Opening_Costs_And_Counts, Average_Costs, (Start_Days, End_Days, Default_Bases, Average_Costs, Transactions3, S_Transactions),  Cogs_Transactions),
   append(Transactions3, Cogs_Transactions, Transactions4),  

   
   balance_sheet_at(Exchange_Rates, Account_Hierarchy, Transactions4, Default_Bases, End_Days, Start_Days, End_Days, BalanceSheet),

   pretty_term_string(S_Transactions, Message0),
   pretty_term_string(Livestock_Events, Message0b),
   pretty_term_string(Transactions4, Message1),
   /*pretty_term_string(Exchange_Rates, Message1b),
   pretty_term_string(Action_Taxonomy, Message2),
   pretty_term_string(Account_Hierarchy, Message3),*/
   pretty_term_string(BalanceSheet, Message4),
   pretty_term_string(Average_Costs, Message5),
   pretty_term_string(Average_Costs_Explanations, Message5b),

   atomic_list_concat([
   	'S_Transactions:\n', Message0,'\n\n',
	'Events:\n', Message0b,'\n\n',
   	'Transactions:\n', Message1,'\n\n',
   	%'Exchange rates::\n', Message1b,'\n\n',
   	%'Action_Taxonomy:\n',Message2,'\n\n',
   	%'Account_Hierarchy:\n',Message3,'\n\n',
   	'BalanceSheet:\n', Message4,'\n\n',
   	'Average_Costs:\n', Message5,'\n\n',
   	'Average_Costs_Explanations:\n', Message5b,'\n\n',
     ''], Debug_Message),
   display_xbrl_ledger_response(Debug_Message, Start_Days, End_Days, BalanceSheet).

/*
get_livestock_types(Account_Hierarchy, Livestock_Types) :-
	findall(Livestock_Type, account_parent_id(Account_Hierarchy, Livestock_Type, 'Livestock'), Livestock_Types).
*/

get_average_costs(Livestock_Types, Opening_Costs_And_Counts, Info, Average_Costs) :-
	maplist(get_average_costs2(Opening_Costs_And_Counts, Info), Livestock_Types, Average_Costs).

get_average_costs2(Opening_Costs_And_Counts, Info, Livestock_Type, Rate) :-
	member(opening_cost_and_count(Livestock_Type, Opening_Cost, Opening_Count), Opening_Costs_And_Counts),
	average_cost(Livestock_Type, Opening_Cost, Opening_Count, Info, Rate).
	
livestock_cogs_transactions(Livestock_Types, Opening_Costs_And_Counts, Average_Costs, Info, Transactions_Out) :-
	findall(Txs, 
		(
			member(Livestock_Type, Livestock_Types),
			member(opening_cost_and_count(Livestock_Type, Opening_Cost, Opening_Count), Opening_Costs_And_Counts),	
			member(Average_Cost, Average_Costs),
			Average_Cost = exchange_rate(_, Livestock_Type, _, _),
			yield_livestock_cogs_transactions(
				Livestock_Type, 
				Opening_Cost, Opening_Count,
				Average_Cost,
				Info,
				Txs)
		),
		Transactions_Nested),
	flatten(Transactions_Nested, Transactions_Out).

   
% this logic is dependent on having the average cost value
get_more_transactions(Livestock_Types, Average_costs, S_Transactions, Livestock_Events, More_Transactions) :-
   maplist(
		yield_more_transactions(Average_costs, S_Transactions, Livestock_Events),
		Livestock_Types, 
		Lists),
	flatten(Lists, More_Transactions).
   
yield_more_transactions(Average_costs, S_Transactions, Livestock_Events, Livestock_Type, [Rations_Transactions, Sales_Transactions, Buys_Transactions]) :-
	member(Average_Cost, Average_costs),
	Average_Cost = exchange_rate(_, Livestock_Type, _, _),
	maplist(preprocess_rations(Livestock_Type, Average_Cost), Livestock_Events, Rations_Transactions),
	preprocess_sales(Livestock_Type, Average_Cost, S_Transactions, Sales_Transactions),
	preprocess_buys(Livestock_Type, Average_Cost, S_Transactions, Buys_Transactions).

extract_natural_increase_costs(Livestock_Doms, Natural_Increase_Costs) :-
	maplist(
		extract_natural_increase_cost,
		Livestock_Doms,
		Natural_Increase_Costs).

extract_natural_increase_cost(Livestock_Dom, natural_increase_cost(Type, [coord('AUD', Cost, 0)])) :-
	fields(Livestock_Dom, ['type', Type]),
	numeric_fields(Livestock_Dom, ['naturalIncreaseValuePerUnit', Cost]).

extract_opening_costs_and_counts(Livestock_Doms, Opening_Costs_And_Counts) :-
	maplist(extract_opening_cost_and_count,	Livestock_Doms, Opening_Costs_And_Counts).

extract_opening_cost_and_count(Livestock_Dom,	Opening_Cost_And_Count) :-
	numeric_fields(Livestock_Dom, [
		'openingCost', Opening_Cost,
		'openingCount', Opening_Count]),
	fields(Livestock_Dom, ['type', Type]),
	Opening_Cost_And_Count = opening_cost_and_count(Type, [coord('AUD', Opening_Cost, 0)], Opening_Count).
	
extract_livestock_events(Livestock_Doms, Events) :-
   maplist(extract_livestock_events2, Livestock_Doms, Events_Nested),
   flatten(Events_Nested, Events).
   
extract_livestock_events2(Data, Events) :-
   inner_xml(Data, type, [Type]),
   findall(Event, xpath(Data, events/(*), Event), Xml_Events),
   maplist(extract_livestock_event(Type), Xml_Events, Events).

extract_livestock_event(Type, Dom, Event) :-
   inner_xml(Dom, date, [Date]),
   parse_date(Date, Days),
   inner_xml(Dom, count, [Count_Atom]),
   atom_number(Count_Atom, Count),
   extract_livestock_event2(Type, Days, Count, Dom, Event).

extract_livestock_event2(Type, Days, Count, element(naturalIncrease,_,_),  born(Type, Days, Count)).
extract_livestock_event2(Type, Days, Count, element(loss,_,_),                     loss(Type, Days, Count)).
extract_livestock_event2(Type, Days, Count, element(rations,_,_),                rations(Type, Days, Count)).
	

extract_default_bases(Dom, Bases) :-
   inner_xml(Dom, //reports/balanceSheetRequest/defaultUnitTypes/unitType, Bases).


extract_action_taxonomy(Dom, Action_Taxonomy) :-
   findall(Action, xpath(Dom, //reports/balanceSheetRequest/actionTaxonomy/action, Action), Actions),
   maplist(extract_action, Actions, Action_Taxonomy).
   
extract_action(In, transaction_type(Id, Exchange_Account, Trading_Account, Description)) :-
   inner_xml(In, id, [Id]),
   inner_xml(In, description, [Description]),
   inner_xml(In, exchangeAccount, [Exchange_Account]),
   inner_xml(In, tradingAccount, [Trading_Account]).
   
extract_exchange_rates(Dom, End_Date, Exchange_Rates) :-
   findall(Unit_Value, xpath(Dom, //reports/balanceSheetRequest/unitValues/unitValue, Unit_Value), Unit_Values),
   maplist(extract_exchange_rate(End_Date), Unit_Values, Exchange_Rates).
   
extract_exchange_rate(End_Date, Unit_Value, Exchange_Rate) :-
   Exchange_Rate = exchange_rate(End_Date, Src_Currency, Dest_Currency, Rate),
   inner_xml(Unit_Value, unitType, [Src_Currency]),
   inner_xml(Unit_Value, unitValueCurrency, [Dest_Currency]),
   inner_xml(Unit_Value, unitValue, [Rate_String]),
   atom_number(Rate_String, Rate).

   
% yield all transactions from all accounts one by one
% these are s_transactions, the raw transactions from bank statements. Later each s_transaction will be preprocessed
% into multiple transaction(..) terms.
% fixme dont fail silently
extract_transactions(Dom, Default_Bases, Transaction) :-
   xpath(Dom, //reports/balanceSheetRequest/bankStatement/accountDetails, Account),
   inner_xml(Account, accountName, [AccountName]),
   inner_xml(Account, currency, [Currency]),
   xpath(Account, transactions/transaction, Tx_Dom),
   extract_transaction2(Tx_Dom, Currency, Default_Bases, AccountName, Transaction).

extract_transaction2(Tx_Dom, Currency, Default_Bases, Account, ST) :-
   xpath(Tx_Dom, debit, element(_,_,[DebitAtom])),
   xpath(Tx_Dom, credit, element(_,_,[CreditAtom])),
   ((xpath(Tx_Dom, transdesc, element(_,_,[Desc])),!);Desc=""),
   xpath(Tx_Dom, transdate, element(_,_,[Date_Atom])),
   parse_date(Date_Atom, Absolute_Days),
   atom_number(DebitAtom, Debit),
   atom_number(CreditAtom, Credit),
   Coord = coord(Currency, Debit, Credit),
   ST = s_transaction(Absolute_Days, Desc, [Coord], Account, Exchanged),
   extract_exchanged_value(Tx_Dom, Default_Bases, Exchanged).

extract_exchanged_value(Tx_Dom, Default_Bases, Exchanged) :-
   % if unit type and count is specified, unifies Exchanged with a one-item vector with a coord with those values
   % otherwise unifies Exchanged with bases(..) to trigger unit conversion later
   % todo rewrite this with ->/2 ?
   (
      xpath(Tx_Dom, unitType, element(_,_,[Unit_Type])),
      (
         (
            xpath(Tx_Dom, unit, element(_,_,[Unit_Count_Atom])),
            %  If the user has specified both the unit quantity and type, then exchange rate
            %  conversion and hence a target bases is unnecessary.
            atom_number(Unit_Count_Atom, Unit_Count),
            Exchanged = vector([coord(Unit_Type, Unit_Count, 0)]),!
         )
         ;
         (
            % If the user has specified only a unit type, then automatically do a conversion to that unit.
            Exchanged = bases([Unit_Type])
         )
      ),!
   )
   ;
   (
      % If the user has not specified neither the unit quantity nor type, then automatically
      %  do a conversion to the default bases.
      Exchanged = bases(Default_Bases)
   ).


% -----------------------------------------------------
% display_xbrl_ledger_response/4
% -----------------------------------------------------

display_xbrl_ledger_response(Debug_Message, Start_Days, End_Days, Balance_Sheet_Entries) :-
   format('Content-type: text/xml~n~n'), 
   writeln('<?xml version="1.0"?>'),
   writeln('<!--'),
   writeln(Debug_Message),
   writeln('-->'),
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

   format_balance_sheet_entries(End_Year, Balance_Sheet_Entries, [], Used_Units, [], Lines),
   maplist(write_used_unit, Used_Units), 
   atomic_list_concat(Lines, LinesString),
   writeln(LinesString),
   writeln('</xbrli:xbrl>'), nl, nl.

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
   Balance is Debit - Credit,
   format(string(BalanceSheetLine), '  <basic:~w contextRef="D-~w" unitRef="U-~w" decimals="INF">~w</basic:~w>\n', [Name, End_Year, Unit, Balance, Name]),
   append(LinesIn, [BalanceSheetLine], LinesOut).

write_used_unit(Unit) :-
   format('  <unit id="U-~w"><measure>~w</measure></unit>\n', [Unit, Unit]).
   

% ===================================================================
% Project:   LodgeiT
% Module:    process_xml_ledger_request.pl  
% Author:    Jindrich
% ===================================================================

% -------------------------------------------------------------------
% Modules
% -------------------------------------------------------------------

:- use_module(library(xpath)).


% -------------------------------------------------------------------
% Load files
% -------------------------------------------------------------------

:- ['../../src/days'].
:- ['../../src/ledger'].
:- ['../../src/statements'].


% ------------------------------------------------------------------
% process_xml_ledger_request/2
% ------------------------------------------------------------------

process_xml_ledger_request(_FileNameIn, Dom) :-
   extract_default_bases(Dom, DefaultBases),
   extract_action_taxonomy(Dom, ActionTaxonomy),
   (
      (
         inner_xml(Dom, //reports/balanceSheetRequest/accountHierarchyUrl, [AccountHierarchyUrl]), 
         fetch_account_hierarchy_from_url(AccountHierarchyUrl, AccountHierarchyDom), !
      )
      ;
         load_xml('./taxonomy/account_hierarchy.xml', AccountHierarchyDom, [])
   ),
   extract_account_hierarchy(AccountHierarchyDom, AccountHierarchy),
 
   findall(Transaction, extract_transactions(Dom, DefaultBases, Transaction), S_Transactions),

   inner_xml(Dom, //reports/balanceSheetRequest/startDate, [BalanceSheetStartDateAtom]),
   parse_date(BalanceSheetStartDateAtom, BalanceSheetStartAbsoluteDays),
   inner_xml(Dom, //reports/balanceSheetRequest/endDate, [BalanceSheetEndDateAtom]),
   parse_date(BalanceSheetEndDateAtom, BalanceSheetEndAbsoluteDays),

   extract_exchange_rates(Dom, BalanceSheetEndAbsoluteDays, ExchangeRates),

   preprocess_s_transactions(AccountHierarchy, ExchangeRates, ActionTaxonomy, S_Transactions, Transactions),
   
   gtrace,
   extract_livestock_events(Dom, Livestock_Events),

   	
   maplist(preprocess_livestock_event, Livestock_Events, Livestock_Event_Transactions_Nested),
   flatten(Livestock_Event_Transactions_Nested, Livestock_Event_Transactions),
   append(Transactions, Livestock_Event_Transactions, Transactions2),

   extract_natural_increase_costs(Dom, Natural_increase_costs),
   
   findall(Rate, 
   (	livestock_account_ids(Livestock_Account, _, _, _),
		account_ancestor_id(Accounts, Livestock_Type, Livestock_Account),
		average_cost(Livestock_Type, S_Transactions, Livestock_Events, Natural_increase_costs, Average_cost)
	),
	Average_Costs), 
      
   get_more_transactions(Average_Costs, AccountHierarchy, S_Transactions, Livestock_Events, More_Transactions),
   
   append(Transactions2, More_Transactions, Transactions3),  
   
   
   balance_sheet_at(ExchangeRates, AccountHierarchy, Transactions3, DefaultBases, BalanceSheetEndAbsoluteDays, BalanceSheetStartAbsoluteDays, BalanceSheetEndAbsoluteDays, BalanceSheet),

   pretty_term_string(S_Transactions, Message0),
   pretty_term_string(Transactions3, Message1),
   pretty_term_string(ExchangeRates, Message1b),
   pretty_term_string(ActionTaxonomy, Message2),
   pretty_term_string(AccountHierarchy, Message3),
   pretty_term_string(BalanceSheet, Message4),
   atomic_list_concat([
   	'S_Transactions:\n', Message0,'\n\n',
   	'Transactions:\n', Message1,'\n\n',
   	'Exchange rates::\n', Message1b,'\n\n',
   	'ActionTaxonomy:\n',Message2,'\n\n',
   	'AccountHierarchy:\n',Message3,'\n\n',
   	'BalanceSheet:\n', Message4,'\n\n'],
      DebugMessage),
   display_xbrl_ledger_response(DebugMessage, BalanceSheetStartAbsoluteDays, BalanceSheetEndAbsoluteDays, BalanceSheet).

% this logic is dependent on having the average cost value
get_more_transactions(Dom, Accounts, S_Transactions, Livestock_Events, More_Transactions) :-
   findall(List, yield_more_transactions(Accounts, S_Transactions, Livestock_Events, List), Lists),
   flatten(Lists, More_Transactions).
   
yield_more_transactions(Accounts, S_Transactions, Livestock_Events, [Rations_Transactions, Sales_Transactions]) :-
	livestock_account_ids(Livestock_Account, _, _, _),
	account_ancestor_id(Accounts, Livestock_Type, Livestock_Account),
	member(exchange_rate(_, Livestock_Type, 'AUD', Average_cost),
	maplist(preprocess_rations(Livestock_Type, Average_cost), Livestock_Events, Rations_Transactions),
	preprocess_sales(Livestock_Type, Average_cost, Accounts, S_Transactions, Sales_Transactions).

extract_natural_increase_costs(Dom, Natural_increase_costs) :-
	findall(Cost,
	(
		xpath(Dom, //reports/balanceSheetRequest/livestockData, Data),
		extract_natural_increase_cost(Data, Cost)
	), Natural_increase_costs).

extract_natural_increase_cost(LivestockData, natural_increase_cost(Type, Cost)) :-
	fields(LivestockData, ['type', Type]),
	numeric_fields(LivestockData, [	'naturalIncreaseValuePerUnit', Cost]).

% -----------------------------------------------------

extract_livestock_events(Dom, Events) :-
   findall(Data, xpath(Dom, //reports/balanceSheetRequest/livestockData, Data), Datas),
   maplist(extract_livestock_events2, Datas, Events_Nested),
   flatten(Events_Nested, Events).
   
extract_livestock_events2(Data, Events) :-
   inner_xml(Data, type, [Type]),
   findall(Event, xpath(Data, events/(*), Event), Xml_Events),
   maplist(extract_livestock_event(Type), Xml_Events, Events).

extract_livestock_event(Type, Dom, Event) :-
   inner_xml(Dom, date, [Date]),
   parse_date(Date, Days),
   inner_xml(Dom, count, [CountAtom]),
   atom_number(CountAtom, Count),
   extract_livestock_event2(Type, Days, Count, Dom, Event).

extract_livestock_event2(Type, Days, Count, element(naturalIncrease,_,_),  born(Type, Days, Count)).
extract_livestock_event2(Type, Days, Count, element(loss,_,_),                     loss(Type, Days, Count)).
extract_livestock_event2(Type, Days, Count, element(rations,_,_),                rations(Type, Days, Count)).
	

pretty_term_string(Term, String) :-
   new_memory_file(X),
   open_memory_file(X, write, S),
   print_term(Term, [output(S)]),
   close(S),
   memory_file_to_string(X, String).

extract_default_bases(Dom, Bases) :-
   inner_xml(Dom, //reports/balanceSheetRequest/defaultUnitTypes/unitType, Bases).

  
fetch_account_hierarchy_from_url(AccountHierarchyUrl, AccountHierarchyDom) :-
   http_get(AccountHierarchyUrl, AccountHierarchyXmlText, []),
   store_xml_document('tmp/account_hierarchy.xml', AccountHierarchyXmlText),
   load_xml('tmp/account_hierarchy.xml', AccountHierarchyDom, []).
  
% ------------------------------------------------------------------
% extract_account_hierarchy/2
%
% Load Account Hierarchy terms from Dom
% ------------------------------------------------------------------

extract_account_hierarchy(AccountHierarchyDom, AccountHierarchy) :-   
   % fixme when input format is agreed on
   findall(Account, xpath(AccountHierarchyDom, //accounts, Account), Accounts),
   findall(Link, (member(TopLevelAccount, Accounts), accounts_link(TopLevelAccount, Link)), AccountHierarchy).

 
% yields all child-parent pairs describing the account hierarchy
accounts_link(element(ParentName,_,Children), Link) :-
   member(Child, Children), 
   Child = element(ChildName,_,_),
   (
      % yield an account(Child, Parent) term for this child
      Link = account(ChildName, ParentName)
      ;
      % recurse on the child
      accounts_link(Child, Link)
   ).

extract_action_taxonomy(Dom, ActionTaxonomy) :-
   findall(Action, xpath(Dom, //reports/balanceSheetRequest/actionTaxonomy/action, Action), Actions),
   maplist(extract_action, Actions, ActionTaxonomy).
   
extract_action(In, transaction_type(Id, ExchangeAccount, TradingAccount, Description)) :-
   inner_xml(In, id, [Id]),
   inner_xml(In, description, [Description]),
   inner_xml(In, exchangeAccount, [ExchangeAccount]),
   inner_xml(In, tradingAccount, [TradingAccount]).
   
extract_exchange_rates(Dom, BalanceSheetEndDate, ExchangeRates) :-
   findall(UnitValue, xpath(Dom, //reports/balanceSheetRequest/unitValues/unitValue, UnitValue), UnitValues),
   maplist(extract_exchange_rate(BalanceSheetEndDate), UnitValues, ExchangeRates).
   
extract_exchange_rate(BalanceSheetEndDate, UnitValue, ExchangeRate) :-
   ExchangeRate = exchange_rate(BalanceSheetEndDate, SrcCurrency, DestCurrency, Rate),
   inner_xml(UnitValue, unitType, [SrcCurrency]),
   inner_xml(UnitValue, unitValueCurrency, [DestCurrency]),
   inner_xml(UnitValue, unitValue, [RateString]),
   atom_number(RateString, Rate).

% yield all transactions from all accounts one by one
% these are s_transactions, the raw transactions from bank statements. Later each s_transaction will be preprocessed
% into multiple transaction(..) terms.
extract_transactions(Dom, DefaultBases, Transaction) :-
   xpath(Dom, //reports/balanceSheetRequest/bankStatement/accountDetails, Account),
   inner_xml(Account, accountName, [AccountName]),
   inner_xml(Account, currency, [Currency]),
   xpath(Account, transactions/transaction, T),
   extract_transaction2(T, Currency, DefaultBases, AccountName, Transaction).

extract_transaction2(T, Currency, DefaultBases, Account, ST) :-
   xpath(T, debit, element(_,_,[DebitAtom])),
   xpath(T, credit, element(_,_,[CreditAtom])),
   ((xpath(T, transdesc, element(_,_,[Desc])),!);Desc=""),
   xpath(T, transdate, element(_,_,[DateAtom])),
   parse_date(DateAtom, AbsoluteDays),
   atom_number(DebitAtom, Debit),
   atom_number(CreditAtom, Credit),
   Coord = coord(Currency, Debit, Credit),
   ST = s_transaction(AbsoluteDays, Desc, [Coord], Account, Exchanged),
   extract_exchanged_value(T, DefaultBases, Exchanged).

extract_exchanged_value(T, DefaultBases, Exchanged) :-
   % if unit type and count is specified, unifies Exchanged with a one-item vector with a coord with those values
   % otherwise unifies Exchanged with bases(..) to trigger unit conversion later
   % todo rewrite this with ->/2 ?
   (
      xpath(T, unitType, element(_,_,[UnitType])),
      (
         (
            xpath(T, unit, element(_,_,[UnitCountAtom])),
            %  If the user has specified both the unit quantity and type, then exchange rate
            %  conversion and hence a target bases is unnecessary.
            atom_number(UnitCountAtom, UnitCount),
            Exchanged = vector([coord(UnitType, UnitCount, 0)]),!
         )
         ;
         (
            % If the user has specified only a unit type, then automatically do a conversion to that unit.
            Exchanged = bases([UnitType])
         )
      ),!
   )
   ;
   (
      % If the user has not specified neither the unit quantity nor type, then automatically
      %  do a conversion to the default bases.
      Exchanged = bases(DefaultBases)
   ).


% -----------------------------------------------------
% display_xbrl_ledger_response/4
% -----------------------------------------------------

display_xbrl_ledger_response(DebugMessage, BalanceSheetStartAbsoluteDays, BalanceSheetEndAbsoluteDays, BalanceSheetEntries) :-
   format('Content-type: text/xml~n~n'), 
   writeln('<?xml version="1.0"?>'),
   writeln('<!--'),
   writeln(DebugMessage),
   writeln('-->'),
   writeln('<xbrli:xbrl xmlns:xbrli="http://www.xbrl.org/2003/instance" xmlns:link="http://www.xbrl.org/2003/linkbase" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:iso4217="http://www.xbrl.org/2003/iso4217" xmlns:basic="http://www.xbrlsite.com/basic">'),
   writeln('  <link:schemaRef xlink:type="simple" xlink:href="basic.xsd" xlink:title="Taxonomy schema" />'),
   writeln('  <link:linkbaseRef xlink:type="simple" xlink:href="basic-formulas.xml" xlink:arcrole="http://www.w3.org/1999/xlink/properties/linkbase" />'),
   writeln('  <link:linkBaseRef xlink:type="simple" xlink:href="basic-formulas-cross-checks.xml" xlink:arcrole="http://www.w3.org/1999/xlink/properties/linkbase" />'),

   format_date(BalanceSheetEndAbsoluteDays, BalanceSheetEndDateString),
   format_date(BalanceSheetStartAbsoluteDays, BalanceSheetStartDateString),
   gregorian_date(BalanceSheetEndAbsoluteDays, date(BalanceSheetEndYear,_,_)),
   
   format( '  <context id="D-~w">\n', BalanceSheetEndYear),
   writeln('    <entity>'),
   writeln('      <identifier scheme="http://standards.iso.org/iso/17442">30810137d58f76b84afd</identifier>'),
   writeln('    </entity>'),
   writeln('    <period>'),
   format( '      <startDate>~w</startDate>\n', BalanceSheetStartDateString),
   format( '      <endDate>~w</endDate>\n', BalanceSheetEndDateString),
   writeln('    </period>'),
   writeln('  </context>'),

   format_balance_sheet_entries(BalanceSheetEndYear, BalanceSheetEntries, [], UsedUnits, [], BalanceSheetLines),
   maplist(write_used_unit, UsedUnits), 
   atomic_list_concat(BalanceSheetLines, BalanceSheetLinesString),
   writeln(BalanceSheetLinesString),
   writeln('</xbrli:xbrl>'), nl, nl.

format_balance_sheet_entries(_, [], UsedUnits, UsedUnits, BalanceSheetLines, BalanceSheetLines).

format_balance_sheet_entries(BalanceSheetEndYear, Entries, UsedUnitsIn, UsedUnitsOut, BalanceSheetLinesIn, BalanceSheetLinesOut) :-
   [entry(Name, Balances, Children)|EntriesTail] = Entries,
   format_balances(BalanceSheetEndYear, Name, Balances, UsedUnitsIn, UsedUnitsIntermediate, BalanceSheetLinesIn, BalanceSheetLinesIntermediate),
   format_balance_sheet_entries(BalanceSheetEndYear, Children, UsedUnitsIntermediate, UsedUnitsIntermediate2, BalanceSheetLinesIntermediate, BalanceSheetLinesIntermediate2),
   format_balance_sheet_entries(BalanceSheetEndYear, EntriesTail, UsedUnitsIntermediate2, UsedUnitsOut, BalanceSheetLinesIntermediate2, BalanceSheetLinesOut).

format_balances(_, _, [], UsedUnits, UsedUnits, BalanceSheetLines, BalanceSheetLines).

format_balances(BalanceSheetEndYear, Name, [Balance|Balances], UsedUnitsIn, UsedUnitsOut, BalanceSheetLinesIn, BalanceSheetLinesOut) :-
   format_balance(BalanceSheetEndYear, Name, Balance, UsedUnitsIn, UsedUnitsIntermediate, BalanceSheetLinesIn, BalanceSheetLinesIntermediate),
   format_balances(BalanceSheetEndYear, Name, Balances, UsedUnitsIntermediate, UsedUnitsOut, BalanceSheetLinesIntermediate, BalanceSheetLinesOut).
  
format_balance(BalanceSheetEndYear, Name, coord(Unit, Debit, Credit), UsedUnitsIn, UsedUnitsOut, BalanceSheetLinesIn, BalanceSheetLinesOut) :-
   union([Unit], UsedUnitsIn, UsedUnitsOut),
   Balance is Debit - Credit,
   format(string(BalanceSheetLine), '  <basic:~w contextRef="D-~w" unitRef="U-~w" decimals="INF">~w</basic:~w>\n', [Name, BalanceSheetEndYear, Unit, Balance, Name]),
   append(BalanceSheetLinesIn, [BalanceSheetLine], BalanceSheetLinesOut).

write_used_unit(Unit) :-
   format('  <unit id="U-~w"><measure>~w</measure></unit>\n', [Unit, Unit]).
   

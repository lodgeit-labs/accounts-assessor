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

process_xml_ledger_request(_FileNameIn, DOM) :-
   extract_default_bases(DOM, DefaultBases),
   extract_action_taxonomy(DOM, ActionTaxonomy),
   (
      (extract_account_hierarchy(DOM, AccountHierarchy), !);
      (
         % need to update the file location when Taxonomy location is fixed.
         load_xml('./taxonomy/account_hierarchy.xml', AccountHierarchyDom, []),
         extract_account_hierarchy(AccountHierarchyDom, AccountHierarchy)
      )
   ),
   findall(Transaction, extract_transactions(DOM, DefaultBases, Transaction), S_Transactions),

   inner_xml(DOM, //reports/balanceSheetRequest/startDate, [BalanceSheetStartDateAtom]),
   parse_date(BalanceSheetStartDateAtom, BalanceSheetStartAbsoluteDays),
   inner_xml(DOM, //reports/balanceSheetRequest/endDate, [BalanceSheetEndDateAtom]),
   parse_date(BalanceSheetEndDateAtom, BalanceSheetEndAbsoluteDays),

   extract_exchange_rates(DOM, BalanceSheetEndAbsoluteDays, ExchangeRates),
   preprocess_s_transactions(ExchangeRates, ActionTaxonomy, S_Transactions, Transactions),
   balance_sheet_at(ExchangeRates, AccountHierarchy, Transactions, DefaultBases, BalanceSheetEndAbsoluteDays, BalanceSheetStartAbsoluteDays, BalanceSheetEndAbsoluteDays, BalanceSheet),

   pretty_term_string(S_Transactions, Message0),
   pretty_term_string(Transactions, Message1),
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

% -----------------------------------------------------


% this gets the children of an element with ElementXPath
inner_xml(DOM, ElementXPath, Children) :-
   xpath(DOM, ElementXPath, element(_,_,Children)).

pretty_term_string(Term, String) :-
   new_memory_file(X),
   open_memory_file(X, write, S),
   print_term(Term, [output(S)]),
   close(S),
   memory_file_to_string(X, String).

extract_default_bases(DOM, Bases) :-
   inner_xml(DOM, //reports/balanceSheetRequest/defaultUnitTypes/unitType, Bases).

   
% ------------------------------------------------------------------
% extract_account_hierarchy/2
%
% Load Account Hierarchy from the file stored in the local server.
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

extract_action_taxonomy(DOM, ActionTaxonomy) :-
   findall(Action, xpath(DOM, //reports/balanceSheetRequest/actionTaxonomy/action, Action), Actions),
   maplist(extract_action, Actions, ActionTaxonomy).
   
extract_action(In, transaction_type(Id, ExchangeAccount, TradingAccount, Description)) :-
   inner_xml(In, id, [Id]),
   inner_xml(In, description, [Description]),
   inner_xml(In, exchangeAccount, [ExchangeAccount]),
   inner_xml(In, tradingAccount, [TradingAccount]).
   
extract_exchange_rates(DOM, BalanceSheetEndDate, ExchangeRates) :-
   findall(UnitValue, xpath(DOM, //reports/balanceSheetRequest/unitValues/unitValue, UnitValue), UnitValues),
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
extract_transactions(DOM, DefaultBases, Transaction) :-
   xpath(DOM, //reports/balanceSheetRequest/bankStatement/accountDetails, Account),
   inner_xml(Account, accountName, [AccountName]),
   inner_xml(Account, currency, [Currency]),
   xpath(Account, transactions/transaction, T),
   extract_transaction2(T, Currency, DefaultBases, AccountName, Transaction).

extract_transaction2(T, Currency, DefaultBases, Account, ST) :-
   xpath(T, debit, element(_,_,[DebitAtom])),
   xpath(T, credit, element(_,_,[CreditAtom])),
   xpath(T, transdesc, element(_,_,[Desc])),
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
   

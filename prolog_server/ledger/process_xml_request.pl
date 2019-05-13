% ===================================================================
% Project:   LodgeiT
% Module:    process_xml_request.pl
% ===================================================================

/*
how to make it robust? processing an account or a transaction cannot silently fail,
probably should first find all transactions and then process them.


*/


:- ['../../src/days'].
:- ['../../src/ledger'].
:- ['../../src/statements'].
:- use_module(library(xpath)).


one(DOM, ElementName, ElementContents) :-
   xpath(DOM, ElementName, element(_,_,[ElementContents])).

pretty_term_string(Term, String) :-
   new_memory_file(X),
   open_memory_file(X, write, S),
   print_term(Term, [output(S)]),
   close(S),
   memory_file_to_string(X, String).

extract_default_bases(DOM, Bases) :-
   xpath(DOM, //reports/balanceSheetRequest/defaultUnitTypes/unitType, element(_,_,Bases)).

extract_account_hierarchy(_DOM, AccountHierarchy) :-
   %  xpath(DOM, //reports/balanceSheetRequest/accountHierarchy ...
   http_get('https://raw.githubusercontent.com/LodgeiT/labs-accounts-assessor/prolog_server_ledger/prolog_server/ledger/default_account_hierarchy.xml?token=AAA34ZATJ5VPKDNFZXQRHVK434H2M', D, []),
   store_xml_document('account_hierarchy.xml', D),
   load_xml('account_hierarchy.xml', AccountHierarchyDom, []),
   %print_term(AccountHierarchyDom,[]),
   findall(Account, xpath(AccountHierarchyDom, //accounts/(*), Account), Accounts),
   % gtrace,
   findall(Link, (member(TopLevelAccount, Accounts), accounts_link(TopLevelAccount, Link)), AccountHierarchy).

accounts_link(element(Name,_,Children), Link) :-
   member(Child, Children), 
   Child = element(ChildName,_,_),
   (
      Link = account(ChildName, Name);
      accounts_link(Child, Link)
   ).
   
extract_action(In, transaction_type(Id, Description, ExchangeAccount, TradingAccount)) :-
   one(In, id, Id),
   one(In, description, Description),
   one(In, exchangeAccount, ExchangeAccount),
   one(In, tradingAccount, TradingAccount).
   
extract_action_taxonomy(DOM, ActionTaxonomy) :-
   findall(Action, xpath(DOM, //reports/balanceSheetRequest/actionTaxonomy/action, Action), Actions),
   maplist(extract_action, Actions, ActionTaxonomy).

extract_exchange_rates(DOM, BalanceSheetEndDate, ExchangeRates) :-
   findall(UnitValue, xpath(DOM, //reports/balanceSheetRequest/unitValues/unitValue, UnitValue), UnitValues),
   maplist(extract_exchange_rate(BalanceSheetEndDate), UnitValues, ExchangeRates).
   
extract_exchange_rate(BalanceSheetEndDate, UnitValue, ExchangeRate) :-
   ExchangeRate = exchange_rate(BalanceSheetEndDate, SrcCurrency, DestCurrency, Rate),
   one(UnitValue, unitType, SrcCurrency),
   one(UnitValue, unitValueCurrency, DestCurrency),
   one(UnitValue, unitValue, RateString),
   atom_number(RateString, Rate).

extract_transactions(DOM, DefaultBases, Transaction) :-
   xpath(DOM, //reports/balanceSheetRequest/bankStatement/accountDetails, Account),
   xpath(Account, accountName, element(_,_,[AccountName])),
   xpath(Account, currency, element(_,_,[Currency])),
   xpath(Account, transactions/transaction, T),
   extract_transaction(T, Currency, DefaultBases, AccountName, Transaction).

extract_transaction(T, Currency, DefaultBases, Account, ST) :-
   xpath(T, debit, element(_,_,[DebitString])),
   xpath(T, credit, element(_,_,[CreditString])),
   xpath(T, transdesc, element(_,_,[Desc])),
   xpath(T, transdate, element(_,_,[DateString])),
   parse_date(DateString, AbsoluteDays),
   atom_number(DebitString, Debit),
   atom_number(CreditString, Credit),
   Coord = coord(Currency, Debit, Credit),
   ST = s_transaction(AbsoluteDays, Desc, [Coord], Account, Exchanged),
   (
      (
         xpath(T, unitType, element(_,_,[UnitType])),
         (
            (
               xpath(T, unit, element(_,_,[UnitCount])),
               %  If the user has specified both the unit quantity and type, then exchange rate
               %  conversion and hence a target bases is unnecessary.
               atom_number(UnitCount, UnitCountNumber),
               Exchanged = vector([coord(UnitType, UnitCountNumber, 0)]),!
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
      )
   ).

process_xml_request(_FileNameIn, DOM) :-
   FileNameOut = 'ledger-response.xml',
   extract_default_bases(DOM, DefaultBases),
   extract_action_taxonomy(DOM, ActionTaxonomy),
   extract_account_hierarchy(DOM, AccountHierarchy),
   findall(Transaction, extract_transactions(DOM, DefaultBases, Transaction), S_Transactions),

   one(DOM, //reports/balanceSheetRequest/startDate, BalanceSheetStartDateString),
   parse_date(BalanceSheetStartDateString, BalanceSheetStartAbsoluteDays),
   one(DOM, //reports/balanceSheetRequest/endDate, BalanceSheetEndDateString),
   parse_date(BalanceSheetEndDateString, BalanceSheetEndAbsoluteDays),

   extract_exchange_rates(DOM, BalanceSheetEndAbsoluteDays, ExchangeRates),
   preprocess_s_transactions(ExchangeRates, ActionTaxonomy, S_Transactions, Transactions),
   balance_sheet_at(ExchangeRates, AccountHierarchy, Transactions, DefaultBases, BalanceSheetEndAbsoluteDays, BalanceSheetStartAbsoluteDays, BalanceSheetEndAbsoluteDays, BalanceSheet),

   pretty_term_string(ActionTaxonomy, Message0),
   pretty_term_string(S_Transactions, Message1),
   pretty_term_string(Transactions, Message2),
   pretty_term_string(AccountHierarchy, Message3),
   pretty_term_string(BalanceSheet, Message4),
   atomic_list_concat([
   	'ActionTaxonomy:\n',Message0,'\n\n',
   	'S_Transactions:\n', Message1,'\n\n',
   	'Transactions:\n', Message2,'\n\n',
   	'AccountHierarchy:\n',Message3,'\n\n',
   	'BalanceSheet:\n', Message4,'\n\n'],Message),
   display_xml_response(FileNameOut, Message, BalanceSheetStartAbsoluteDays, BalanceSheetEndAbsoluteDays, BalanceSheet),
   true.

display_xml_response(_FileNameOut, DebugMessage, BalanceSheetStartAbsoluteDays, BalanceSheetEndAbsoluteDays, BalanceSheetEntries) :-
%   gtrace,
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

   gregorian_date(BalanceSheetEndAbsoluteDays, BalanceSheetEndDate),
   BalanceSheetEndDate = date(BalanceSheetEndYear,_,_),
   
   format( '  <context id="D-~w">\n', BalanceSheetEndYear),
   writeln('    <entity>'),
   writeln('      <identifier scheme="http://standards.iso.org/iso/17442">30810137d58f76b84afd</identifier>'),
   writeln('    </entity>'),
   writeln('    <period>'),
   format( '      <startDate>~w</startDate>\n', BalanceSheetStartDateString),
   format( '      <endDate>~w</endDate>\n', BalanceSheetEndDateString),
   writeln('    </period>'),
   writeln('  </context>'),

   write_balance_sheet_entries(BalanceSheetEndYear, BalanceSheetEntries, [], UsedUnits),
   maplist(write_used_unit, UsedUnits, _),
   writeln('</xbrli:xbrl>'), nl, nl.

write_used_unit(Unit, _) :-
   format('  <unit id="U-~w"><measure>~w</measure></unit>\n', [Unit, Unit]).

write_balance_sheet_entries(_, [], UsedUnits, UsedUnits).

write_balance_sheet_entries(BalanceSheetEndYear, [entry(Name, Balances, Children)|Entries], UsedUnitsIn, UsedUnitsOut) :-
   write_balances(BalanceSheetEndYear, Name, Balances, UsedUnitsIn, UsedUnitsIntermediate),

   %foldl(write_balance(BalanceSheetEndYear, Name), Balances, UsedUnitsIn, UsedUnitsIntermediate),

   write_balance_sheet_entries(BalanceSheetEndYear, Children, UsedUnitsIntermediate, UsedUnitsIntermediate2),
   write_balance_sheet_entries(BalanceSheetEndYear, Entries, UsedUnitsIntermediate2, UsedUnitsOut).

write_balances(_, _, [], UsedUnits, UsedUnits).

write_balances(BalanceSheetEndYear, Name, [Balance|Balances], UsedUnitsIn, UsedUnitsOut) :-
   write_balance(BalanceSheetEndYear, Name, Balance, UsedUnitsIn, UsedUnitsIntermediate),
   write_balances(BalanceSheetEndYear, Name, Balances, UsedUnitsIntermediate, UsedUnitsOut).
  
write_balance(BalanceSheetEndYear, Name, coord(Unit, Debit, Credit), UsedUnitsIn, UsedUnitsOut) :-
   union([Unit], UsedUnitsIn, UsedUnitsOut),
   Balance is Debit - Credit,
   format('  <basic:~w contextRef="D-~w" unitRef="U-~w" decimals="INF">~w</basic:~w>\n', [Name, BalanceSheetEndYear, Unit, Balance, Name]).
   
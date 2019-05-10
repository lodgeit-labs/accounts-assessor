% ===================================================================
% Project:   LodgeiT
% Module:    process_xml_request.pl
% ===================================================================

pretty_term_string(Term, String) :-
   new_memory_file(X),
   open_memory_file(X, write, S),
   print_term(Term, [output(S)]),
   close(S),
   memory_file_to_string(X, String).

default_bases(DOM, Bases) :-
   xpath(DOM, //reports/balanceSheetRequest/defaultUnitTypes/unitType, element(_,_,Bases)).


process_xml_request(_FileNameIn, DOM) :-
   _FileNameOut = 'ledger-response.xml',
   default_bases(DOM, DefaultBases),
   xpath(DOM, //reports/balanceSheetRequest/bankStatement/accountDetails, Account),
   process_account(Account, DefaultBases).

process_account(Account, DefaultBases) :-
   xpath(Account, accountName, element(_,_,Name)),
   xpath(Account, currency, element(_,_,[Currency])),
   findall(T, xpath(Account, transactions/transaction, T), TransactionsXml),
   % gtrace,
   process_transactions(TransactionsXml, Currency, DefaultBases, Name, StatementTransactions),
   pretty_term_string(StatementTransactions, Message),
   display_xml_response(_FileNameOut, Message).

process_transactions([T|Ts], Currency, DefaultBases, Account, [ST|STs]) :-
   process_transaction(T, Currency, DefaultBases, Account, ST),
   process_transactions(Ts, Currency, DefaultBases, Account, STs).

process_transactions([], _, _, _, []).

process_transaction(T, Currency, DefaultBases, Account, ST) :-
   %write(T),
   Coordinate = coordinate(Currency, Debit, Credit),
   xpath(T, debit, element(_,_,[Debit])),
   xpath(T, credit, element(_,_,[Credit])),
   %write(Coordinate),
   xpath(T, transdesc, element(_,_,[Desc])),
   xpath(T, transdate, element(_,_,[Date])),
   Day = Date,
   ST = s_transaction(Day, Desc, [Coordinate], Account, Exchanged),
   (
      (
         xpath(T, unitType, element(_,_,[UnitType])),
         (
            (
               xpath(T, unit, element(_,_,[UnitCount])),
               %  If the user has specified both the unit quantity and type, then exchange rate
               %  conversion and hence a target bases is unnecessary.
               Exchanged = [coordinate(UnitType, UnitCount, 0)]
            )
            ;
            (
               % If the user has specified only a unit type, then automatically do a conversion to that unit.
               Exchanged = [UnitType]
            )
         )
      )
      ;
      (
         % If the user has not specified neither the unit quantity nor type, then automatically
         %  do a conversion to the default bases.
         Exchanged = DefaultBases
      )
   ).
/*
process_xml_request(FileNameIn, DOM) :-
   xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Income year of loan creation', @value=CreationIncomeYear), E1),
   xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Full term of loan in years', @value=Term), E2),
   xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Principal amount of loan', @value=PrincipalAmount), E3),
   xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Lodgment day of private company', @value=LodgementDate), E4),
   xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Income year of computation', @value=ComputationYear), E5),   
   (
     xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Opening balance of computation', @value=OB), E6)
     ->
     OpeningBalance = OB
   ;
     OpeningBalance = -1
   ),   
   % need to handle empty repayments/repayment, needs to be tested
   findall(loan_repayment(Date, Value), xpath(DOM, //reports/loanDetails/repayments/repayment(@date=Date, @value=Value), E7), LoanRepayments),
   convert_xpath_results(CreationIncomeYear,  Term,  PrincipalAmount,  LodgementDate,  ComputationYear,  OpeningBalance,  LoanRepayments,
		         NCreationIncomeYear, NTerm, NPrincipalAmount, NLodgementDate, NComputationYear, NOpeningBalance, NLoanRepayments),   
   loan_agr_summary(loan_agreement(0, NPrincipalAmount, NLodgementDate, NCreationIncomeYear, NTerm, 
				   NComputationYear, NOpeningBalance, NLoanRepayments), Summary),
   display_xml_response(FileNameOut, NComputationYear, Summary).
*/
   
% -------------------------------------------------------------------
% display_xml_request/3
% -------------------------------------------------------------------

display_xml_response(_FileNameOut, M) :-
   format('Content-type: text/xml~n~n'), 
   writeln('<?xml version="1.0"?>'),
   writeln('<xbrli:xbrl xmlns:xbrli="http://www.xbrl.org/2003/instance" xmlns:link="http://www.xbrl.org/2003/linkbase" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:iso4217="http://www.xbrl.org/2003/iso4217" xmlns:basic="http://www.xbrlsite.com/basic">'),
   writeln('<link:schemaRef xlink:type="simple" xlink:href="basic.xsd" xlink:title="Taxonomy schema" />'),
   writeln('<link:linkbaseRef xlink:type="simple" xlink:href="basic-formulas.xml" xlink:arcrole="http://www.w3.org/1999/xlink/properties/linkbase" />'),
   writeln('<link:linkBaseRef xlink:type="simple" xlink:href="basic-formulas-cross-checks.xml" xlink:arcrole="http://www.w3.org/1999/xlink/properties/linkbase" />'),
   writeln('<context id="D-2018">'),
   writeln('<!--'),
   writeln(M),
   writeln('-->'),
   /*
   writeln('<context>'),
    <entity>
      <identifier scheme="http://standards.iso.org/iso/17442">30810137d58f76b84afd</identifier>
    </entity>
    <period>
      <startDate>2015-07-01</startDate>
      <endDate>2018-06-30</endDate>
    </period>
  writeln('</context>'),
  <unit id="U-AUD"><measure>AUD</measure></unit>
  <basic:Assets contextRef="D-2018" unitRef="U-AUD" decimals="INF">248.58844</basic:Assets>
  <basic:CurrentAssets contextRef="D-2018" unitRef="U-AUD" decimals="INF">221.57236</basic:CurrentAssets>
  <basic:CashAndCashEquivalents contextRef="D-2018" unitRef="U-AUD" decimals="INF">221.57236</basic:CashAndCashEquivalents>
  <basic:WellsFargo contextRef="D-2018" unitRef="U-AUD" decimals="INF">121.57235999999999</basic:WellsFargo>
  <basic:NationalAustraliaBank contextRef="D-2018" unitRef="U-AUD" decimals="INF">100</basic:NationalAustraliaBank>
  <basic:NoncurrentAssets contextRef="D-2018" unitRef="U-AUD" decimals="INF">27.01608</basic:NoncurrentAssets>
  <basic:FinancialInvestments contextRef="D-2018" unitRef="U-AUD" decimals="INF">27.01608</basic:FinancialInvestments>
  <basic:Liabilities contextRef="D-2018" unitRef="U-AUD" decimals="INF">-100</basic:Liabilities>
  <basic:NoncurrentLiabilities contextRef="D-2018" unitRef="U-AUD" decimals="INF">-100</basic:NoncurrentLiabilities>
  <basic:NoncurrentLoans contextRef="D-2018" unitRef="U-AUD" decimals="INF">-100</basic:NoncurrentLoans>
  <basic:Earnings contextRef="D-2018" unitRef="U-AUD" decimals="INF">111.52336000000001</basic:Earnings>
  <basic:CurrentEarningsLosses contextRef="D-2018" unitRef="U-AUD" decimals="INF">111.52336000000001</basic:CurrentEarningsLosses>
  <basic:Equity contextRef="D-2018" unitRef="U-AUD" decimals="INF">-260.1118</basic:Equity>
  <basic:ShareCapital contextRef="D-2018" unitRef="U-AUD" decimals="INF">-260.1118</basic:ShareCapital>
*/
   writeln('</xbrli:xbrl>'), nl, nl.



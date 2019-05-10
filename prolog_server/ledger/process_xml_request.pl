% ===================================================================
% Project:   LodgeiT
% Module:    process_xml_request.pl
% ===================================================================


bases(DOM, Bases) :-
   xpath(DOM, //reports/balanceSheetRequest/defaultUnitTypes/unitType, element(_,_,Bases)).



process_xml_request(_FileNameIn, DOM) :-
   _FileNameOut = 'ledger-response.xml',
   bases(DOM, _Bases),
   xpath(DOM, //reports/balanceSheetRequest/bankStatement/accountDetails, Account),
   process_account(Account).

process_account(Account) :-
   xpath(Account, accountName, element(_,_,Name)),
   xpath(Account, currency, element(_,_,[Currency])),
   xpath(Account, transactions/transaction, TransactionsXml),
   process_transactions(TransactionsXml, Currency, Account, StatementTransactions).

process_transactions([T|Ts], Currency, Account, [ST|STs]) :-
   process_transaction(T, Currency, Account, ST),
   process_transactions(Ts, Currency, Account, STs).

process_transactions([], _, _, []).

process_transaction(T, Currency, Account, ST) :-
   %write(T),
   Coordinate = coordinate(Currency, Debit, Credit),
   xpath(T, debit, element(_,_,[Debit])),
   xpath(T, credit, element(_,_,[Credit])),
   write(Coordinate),

   xpath(T, transdesc, element(_,_,[Desc])),
   xpath(T, transdate, element(_,_,[Date])),
   Day = Date,
   ST = s_transaction(Day, Desc, [Coordinate], Account, Bases),

   (
      (
         xpath(T, unitType, element(_,_,[UnitType])),
         (
            (
               xpath(T, unit, element(_,_,[UnitCount])),
               %  If the user has specified both the unit quantity and type, then exchange rate
               %  conversion and hence a target bases is unnecessary.
               ExchangedAmountVector = [coordinate(unitType, unitCount, 0)]
               ExchangedAmountBases = null
            )
            ;
            (
               % If the user has specified only a unit type, then automatically do a conversion to that unit.
               ExchangedAmountVector = null,
               ExchangedAmountBases = [unitType]
            )
         )
      )
      ;
      (
         % If the user has not specified neither the unit quantity nor type, then automatically
         %  do a conversion to the default bases.
         ExchangedAmountVector = null
         ExchangedAmountBases = defaultBases;
      )
   ),

   
   
   
*/   
   display_xml_response(FileNameOut).
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

display_xml_response(FileNameOut) :-
   format('Content-type: text/xml~n~n'), 
   writeln('<?xml version="1.0"?>').

display_xml_response(FileNameOut, IncomeYear, 
                    loan_summary(_Number, OpeningBalance, InterestRate, MinYearlyRepayment, TotalRepayment,
			         RepaymentShortfall, TotalInterest, TotalPrincipal, ClosingBalance)) :-
   FileNameOut = 'loan-response.xml',
   format('Content-type: text/xml~n~n'), 
   % write(FileNameOut), nl, nl,   
   writeln('<?xml version="1.0"?>'),
   writeln('<LoanSummary xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'),
   format('<IncomeYear>~w</IncomeYear>~n', IncomeYear),
   format('<OpeningBalance>~w</OpeningBalance>~n', OpeningBalance),
   format('<InterestRate>~w</InterestRate>~n', InterestRate),
   format('<MinYearlyRepayment>~w</MinYearlyRepayment>~n', MinYearlyRepayment),
   format('<TotalRepayment>~w</TotalRepayment>~n', TotalRepayment),
   format('<RepaymentShortfall>~w</RepaymentShortfall>~n', RepaymentShortfall),
   format('<TotalInterest>~w</TotalInterest>~n', TotalInterest),
   format('<TotalPrincipal>~w</TotalPrincipal>~n', TotalPrincipal),
   format('<ClosingBalance>~w</ClosingBalance>~n', ClosingBalance),
   write('</LoanSummary>'), nl, nl.


% ===================================================================
% process_xml_request/2: ledger-request.xml
% ===================================================================

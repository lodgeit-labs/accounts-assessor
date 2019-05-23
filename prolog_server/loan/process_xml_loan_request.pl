% ===================================================================
% Project:   LodgeiT
% Module:    process_xml_loan_request.pl
% Author:    Abdus Salam and Rolf Schwitter
% Date:      2019-05-22
% ===================================================================

%--------------------------------------------------------------------
% Load files --- needs to be turned into modules
%--------------------------------------------------------------------

% Loads up calendar related predicates
:- ['../../src/days.pl'].

% Loads up predicates pertaining to hire purchase arrangements
:- ['../../src/hirepurchase.pl'].

% Loads up predicates pertaining to loan arrangements
:- ['../../src/loans.pl'].

% Loads up predicates pertaining to bank statements
:- ['../../src/statements.pl'].

:- ['helper'].
 

% -------------------------------------------------------------------
% process_xml_loan_request/2: loan-request.xml
% -------------------------------------------------------------------

process_xml_loan_request(FileNameIn, DOM) :-
   (
      FileNameIn  = 'tmp/loan-request.xml'
   ->
      FileNameOut = 'tmp/loan-response.xml';true
   ),
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
   display_xml_loan_response(FileNameOut, NComputationYear, Summary).

   
% -------------------------------------------------------------------
% display_xml_loan_response/3
% -------------------------------------------------------------------

display_xml_loan_response(FileNameOut, IncomeYear, 
                    loan_summary(_Number, OpeningBalance, InterestRate, MinYearlyRepayment, TotalRepayment,
			         RepaymentShortfall, TotalInterest, TotalPrincipal, ClosingBalance)) :-
   FileNameOut = 'tmp/loan-response.xml',
   format('Content-type: text/xml~n~n'), 
   writeln('<?xml version="1.0"?>'), nl,   
   writeln('<LoanSummary>'),
   format('<IncomeYear>~w</IncomeYear>~n', IncomeYear),
   format('<OpeningBalance>~w</OpeningBalance>~n', OpeningBalance),
   format('<InterestRate>~w</InterestRate>~n', InterestRate),
   format('<MinYearlyRepayment>~w</MinYearlyRepayment>~n', MinYearlyRepayment),
   format('<TotalRepayment>~w</TotalRepayment>~n', TotalRepayment),
   format('<RepaymentShortfall>~w</RepaymentShortfall>~n', RepaymentShortfall),
   format('<TotalInterest>~w</TotalInterest>~n', TotalInterest),
   format('<TotalPrincipal>~w</TotalPrincipal>~n', TotalPrincipal),
   format('<ClosingBalance>~w</ClosingBalance>~n', ClosingBalance),
   write('</LoanSummary>'), nl.
   


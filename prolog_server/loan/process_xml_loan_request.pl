% ===================================================================
% Project:   LodgeiT
% Module:    process_xml_loan_request.pl
% Author:    Abdus Salam and Rolf Schwitter
% Date:      2019-06-02
% ===================================================================

%--------------------------------------------------------------------
% Modules
%--------------------------------------------------------------------

:- module(process_xml_loan_request, [process_xml_loan_request/2]).

:- use_module('../../lib/loans', [loan_agr_summary/2]).
:- use_module('../../lib/days',  [absolute_day/2]).


% -------------------------------------------------------------------
% process_xml_loan_request/2: loan-request.xml
% -------------------------------------------------------------------

process_xml_loan_request(FileNameIn, DOM) :-
   (
      FileNameIn  = 'loan-request.xml'
      ->
      FileNameOut = 'loan-response.xml' ; true
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
   atom_number(ComputationYear, NIncomeYear),
   convert_xpath_results(CreationIncomeYear,  Term,  PrincipalAmount,  LodgementDate,  ComputationYear,  OpeningBalance,  LoanRepayments,
		         NCreationIncomeYear, NTerm, NPrincipalAmount, NLodgementDate, NComputationYear, NOpeningBalance, NLoanRepayments),   
   loan_agr_summary(loan_agreement(0, NPrincipalAmount, NLodgementDate, NCreationIncomeYear, NTerm, 
				   NComputationYear, NOpeningBalance, NLoanRepayments), Summary),
   display_xml_loan_response(FileNameOut, NIncomeYear, Summary).

   
% -------------------------------------------------------------------
% display_xml_loan_response/3
% -------------------------------------------------------------------

display_xml_loan_response(FileNameOut, IncomeYear, 
                    loan_summary(_Number, OpeningBalance, InterestRate, MinYearlyRepayment, TotalRepayment,
			         RepaymentShortfall, TotalInterest, TotalPrincipal, ClosingBalance)) :-
   FileNameOut = 'loan-response.xml',
   format('Content-type: text/xml~n~n'), 
   writeln('<?xml version="1.0"?>'), nl,   
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
   write('</LoanSummary>'), nl.
   

% ===================================================================
% Various helper predicates
% ===================================================================

% -------------------------------------------------------------------
% convert_xpath_results/14 
% -------------------------------------------------------------------

convert_xpath_results(CreationIncomeYear,  Term,  PrincipalAmount,  LodgementDate,  ComputationYear,  OpeningBalance,  LoanRepayments,
		      NCreationIncomeYear, NTerm, NPrincipalAmount, NLodgementDate, NComputationYear, NOpeningBalance, NLoanRepayments) :-
   generate_absolute_days(CreationIncomeYear, LodgementDate, LoanRepayments, NCreationIncomeYear, NLodgementDate, NLoanRepayments),
   compute_opening_balance(OpeningBalance, NOpeningBalance),
   calculate_computation_year(ComputationYear, CreationIncomeYear, NComputationYear),
   atom_number(PrincipalAmount, NPrincipalAmount),
   atom_number(Term, NTerm).

generate_absolute_days(CreationIncomeYear, LodgementDate, LoanRepayments, NCreationIncomeYear, NLodgementDay, NLoanRepayments) :-
   generate_absolute_day(creation_income_year, CreationIncomeYear, NCreationIncomeYear),
   generate_absolute_day(lodgement_date, LodgementDate, NLodgementDay),
   generate_absolute_day(loan_repayments, LoanRepayments, NLoanRepayments).
     
generate_absolute_day(creation_income_year, CreationIncomeYear, NCreationIncomeYear) :-
   atom_number(CreationIncomeYear, CreationIncomeYearNumber),
   absolute_day(date(CreationIncomeYearNumber, 7, 1), NCreationIncomeYear).

generate_absolute_day(lodgement_date, LodgementDate, NLodgementDay) :-
   generate_absolute_day_from_date_string(LodgementDate, NLodgementDay).

generate_absolute_day(loan_repayments, [], []).

generate_absolute_day(loan_repayments, [loan_repayment(Date, Value)|Rest1], [loan_repayment(NDate, NValue)|Rest2]) :-
   generate_absolute_day_from_date_string(Date, NDate),
   atom_number(Value, NValue),
   generate_absolute_day(loan_repayments, Rest1, Rest2).

   
generate_absolute_day_from_date_string(DateString, AbsoluteDay) :-
   split_string(DateString, "-", "", DateList),
   DateList = [YearString, MonthString, DayString],	
   atom_number(YearString, Year),
   atom_number(MonthString, Month),
   atom_number(DayString, Day),
   absolute_day(date(Year, Month, Day), AbsoluteDay).   
	
	
% ----------------------------------------------------------------------
% compute_opening_balance/2
% ----------------------------------------------------------------------

compute_opening_balance(OpeningBalance, NOpeningBalance) :-
   (
     OpeningBalance = -1
     ->
     NOpeningBalance = false
   ;
     atom_number(OpeningBalance, NOpeningBalance)
   ).

% ----------------------------------------------------------------------
% calculate_computation_year/3
%
% Computation year is calculated as it is done in:
%	- ConstructLoanAgreement function (PrologEngpoint/LoanController.cs)
% ----------------------------------------------------------------------

calculate_computation_year(ComputationYear, CreationIncomeYear, NComputationYear) :-
   atom_number(ComputationYear, NCY),
   atom_number(CreationIncomeYear, NCIY),
   NComputationYear is NCY - NCIY - 1.
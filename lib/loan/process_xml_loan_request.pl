% ===================================================================
% Project:   LodgeiT
% Module:    process_xml_loan_request.pl
% Author:    Abdus Salam and Rolf Schwitter
% Date:      2019-06-21
% ===================================================================

%--------------------------------------------------------------------
% Modules
%--------------------------------------------------------------------

:- module(process_xml_loan_request, [process_xml_loan_request/2]).

% use "XSD" library to validate XML
:- use_module(library(xsd)).
:- use_module(library(xpath)).

:- use_module('../../lib/files').
:- use_module('../../lib/loans', [loan_agr_summary/2]).
:- use_module('../../lib/days',  [absolute_day/2, parse_date/2, parse_date_into_absolute_days/2]).


% -------------------------------------------------------------------
% process_xml_loan_request/2: loan-request.xml
% -------------------------------------------------------------------

process_xml_loan_request(FileNameIn, DOM) :-
   (
      FileNameIn  = 'loan-request.xml'
      ->
      FileNameOut = 'loan-response.xml' ; true
   ),
   xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Income year of loan creation', @value=CreationIncomeYear), _E1),
   xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Full term of loan in years', @value=Term), _E2),
   xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Principal amount of loan', @value=PrincipalAmount), _E3),
   xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Lodgment day of private company', @value=LodgementDate), _E4),
   xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Income year of computation', @value=ComputationYear), _E5),   
   (
     xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Opening balance of computation', @value=OB), _E6)
     ->
     OpeningBalance = OB
   ;
     OpeningBalance = -1
   ),   
   % need to handle empty repayments/repayment, needs to be tested
   findall(loan_repayment(Date, Value), xpath(DOM, //reports/loanDetails/repayments/repayment(@date=Date, @value=Value), _E7), LoanRepayments),
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

   % populate loan response xml
   atomic_list_concat([
   '<LoanSummary xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="loan_response.xsd">\n',
   '<IncomeYear>', IncomeYear, '</IncomeYear>\n', 
   '<OpeningBalance>', OpeningBalance, '</OpeningBalance>\n', 
   '<InterestRate>', InterestRate, '</InterestRate>\n', 
   '<MinYearlyRepayment>', MinYearlyRepayment, '</MinYearlyRepayment>\n', 
   '<TotalRepayment>', TotalRepayment, '</TotalRepayment>\n', 
   '<RepaymentShortfall>', RepaymentShortfall, '</RepaymentShortfall>\n', 
   '<TotalInterest>', TotalInterest, '</TotalInterest>\n', 
   '<TotalPrincipal>', TotalPrincipal, '</TotalPrincipal>\n', 
   '<ClosingBalance>', ClosingBalance, '</ClosingBalance>\n', 
   '</LoanSummary>\n'],
   LoanResponseXML
   ),

   absolute_tmp_path('loan_response.xml', TempFileLoanResponseXML),
   % create a temporary loan xml file to validate the response against the schema
   open(TempFileLoanResponseXML, write, XMLStream),
   write(XMLStream, LoanResponseXML),
   close(XMLStream),

   % read the schema file
   absolute_file_name(my_schemas('responses/loan-response.xsd'), FileLoanResponseXSD, []),
   read_file_to_string(FileLoanResponseXSD, LoanResponseXSD, []),   
   absolute_tmp_path('loan_response.xsd', TempFileLoanResponseXSD),
   % create a temporary loan xsd file to validate the response against the schema
   % a bug in XSD library requires that we create a new schema file for each validation
   open(TempFileLoanResponseXSD, write, XSDStream),
   write(XSDStream, LoanResponseXSD),
   close(XSDStream),
   
   % if the xml response is valid then reply the response, otherwise reply an error message
   (
     xsd_validate(TempFileLoanResponseXSD, TempFileLoanResponseXML)
     ->
     writeln(LoanResponseXML)     
   ;
     atomic_list_concat([
     '<LoanSummary xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="loan_response.xsd">\n',
     '<ErrorMessage>Validation failed for xml loan response.</ErrorMessage>',
     '</LoanSummary>\n'],
     ErrorMessage
     ),
     writeln(ErrorMessage)
   ).
   

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
   parse_date_into_absolute_days(LodgementDate, NLodgementDay),
   generate_absolute_day(loan_repayments, LoanRepayments, NLoanRepayments).
     
generate_absolute_day(creation_income_year, CreationIncomeYear, NCreationIncomeYear) :-
   atom_number(CreationIncomeYear, CreationIncomeYearNumber),
   absolute_day(date(CreationIncomeYearNumber, 7, 1), NCreationIncomeYear).

generate_absolute_day(loan_repayments, [], []).

generate_absolute_day(loan_repayments, [loan_repayment(Date, Value)|Rest1], [loan_repayment(NDate, NValue)|Rest2]) :-
   parse_date_into_absolute_days(Date, NDate),
   atom_number(Value, NValue),
   generate_absolute_day(loan_repayments, Rest1, Rest2).
	
	
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

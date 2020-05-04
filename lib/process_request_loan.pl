
process_request_loan(Request_File, DOM) :-
   xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Income year of loan creation', @value=CreationIncomeYear), _E1),
   xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Full term of loan in years', @value=Term), _E2),
   (xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Principal amount of loan', @value=PrincipalAmount), _E3)->true;true),
   xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Lodgment day of private company', @value=LodgementDate), _E4),
   xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Income year of computation', @value=ComputationYear), _E5),   
   (
     xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Opening balance of computation', @value=OB), _E6)
     ->
     OpeningBalance = OB
   ;
     OpeningBalance = -1
   ),   

   resolve_specifier(loc(specifier, my_schemas('bases/Reports.xsd')), Schema_File),
   validate_xml(Request_File, Schema_File, Schema_Errors),
   (
		Schema_Errors = []
	->
		(
			% need to handle empty repayments/repayment, needs to be tested
			findall(loan_repayment(Date, Value), xpath(DOM, //reports/loanDetails/repayments/repayment(@date=Date, @value=Value), _E7), LoanRepayments),
			atom_number(ComputationYear, NIncomeYear),
			convert_xpath_results(
				CreationIncomeYear,  Term,  PrincipalAmount,  LodgementDate,  ComputationYear,  OpeningBalance,  LoanRepayments,
				NCreationIncomeYear, NTerm, NPrincipalAmount, NLodgementDate, NComputationYear, NOpeningBalance, NLoanRepayments),
			loan_agr_summary(loan_agreement(
				% loan_agr_contract_number:
				0,
				% loan_agr_principal_amount:
				NPrincipalAmount,
				% loan_agr_lodgement_day:
				NLodgementDate,
				% loan_agr_begin_day:
				NCreationIncomeYear,
				% loan_agr_term (length in years):
				NTerm,
				% loan_agr_computation_year
				NComputationYear,
				NOpeningBalance,
				% loan_agr_repayments (list):
				NLoanRepayments),
				% output:
				Summary),
			display_xml_loan_response(NIncomeYear, Summary)
		)
	;
		maplist(add_alert(error), Schema_Errors)
	).

   
% -------------------------------------------------------------------
% display_xml_loan_response/3
% -------------------------------------------------------------------

display_xml_loan_response(IncomeYear,
                    loan_summary(_Number, OpeningBalance, InterestRate, MinYearlyRepayment, TotalRepayment,
			         RepaymentShortfall, TotalInterest, TotalPrincipal, ClosingBalance)) :-
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

   Response_Fn = loc(file_name, 'response.xml'),
   absolute_tmp_path(Response_Fn, TempFileLoanResponseXML),
   TempFileLoanResponseXML = loc(absolute_path, TempFileLoanResponseXML_Value),
   % create a temporary loan xml file to validate the response against the schema
   open(TempFileLoanResponseXML_Value, write, XMLStream),
   write(XMLStream, LoanResponseXML),
   close(XMLStream),

   % read the schema file
   resolve_specifier(loc(specifier, my_schemas('responses/LoanResponse.xsd')), LoanResponseXSD),
   % if the xml response is valid then reply the response, otherwise reply an error message
   (
		validate_xml(TempFileLoanResponseXML, LoanResponseXSD, [])
   ->
		add_result_file_by_path(TempFileLoanResponseXML)
   ;
		add_alert(error, "Validation failed for xml loan response.")
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
   (	nonvar(PrincipalAmount)
   ->	atom_number(PrincipalAmount, NPrincipalAmount)
   ;	NPrincipalAmount = -1),
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

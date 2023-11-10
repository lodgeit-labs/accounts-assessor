
 process_request_loan(Request_File, DOM) :-

	% startDate and endDate in the request xml are ignored.
	% they are not used in the computation.

	/* for example 2014 */
	xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Income year of loan creation', @value=CreationIncomeYear), _E1),

	% yep, seems to be a loan request xml.
	validate_xml2(Request_File, 'bases/Reports.xsd'),

	/* for example 5 */
	xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Full term of loan in years', @value=Term), _E2),

	/* for example 100000, or left undefined if opening balance is specified */
	(xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Principal amount of loan', @value=PrincipalAmount), _E3)->true;true),

	/* for example 2014-07-01 */
	(	xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Lodgement day of private company', @value=LodgementDateStr), _E4)
	->	true
	;	true),

	(	xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Lodgment day of private company', @value=LodgementDateStr), _E4)
	->	true
	;	true),

	/* for example 2018 */
	xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Income year of computation', @value=ComputationYear), _E5),

	/* opening balance is understood to be for the year of computation. Therefore, if term is 2 or more years, lodgement date can be ignored, which should be equivalent to setting it to 1 July of the year of after loan creation. */
	(	xpath(DOM, //reports/loanDetails/loanAgreement/field(@name='Opening balance of computation', @value=OB), _E6)
	->	OpeningBalance = OB
	;	OpeningBalance = -1),

	% need to handle empty repayments/repayment, needs to be tested
	findall(loan_repayment(Date, Value), xpath(DOM, //reports/loanDetails/repayments/repayment(@date=Date, @value=Value), _E7), LoanRepayments),
	atom_number(ComputationYear, NIncomeYear),

%gtrace,

	findall(Summary1, loan_agr_summary_python0(Term, PrincipalAmount, LodgementDateStr, CreationIncomeYear, ComputationYear, OpeningBalance, LoanRepayments, Summary1), [Summary1]),

	div7a_xml_loan_response(NIncomeYear, Summary1, Url),
	add_report_file(0, 'result', 'result', Url),

	/* (	loan_agr_summary_prolog0(Term, PrincipalAmount, LodgementDateStr, CreationIncomeYear, ComputationYear, OpeningBalance, LoanRepayments, Summary2)
	->	(
			div7a_xml_loan_response(NIncomeYear, Summary2, _),
			(	terms_with_floats_close_enough(Summary1, Summary2)
			->	true
			;	throw_string('server error: inconsistent implementations'))
		)
	;	true), % prolog implementation is currently expected to fail for some inputs
	*/
	true.



 loan_agr_summary_prolog0(Term, PrincipalAmount, LodgementDateStr, CreationIncomeYear, ComputationYear, OpeningBalance, LoanRepayments, Summary_dict) :-

	(	ground(LodgementDateStr)
	->	parse_date(LodgementDateStr, LodgementDate)
	;	(
			LodgementDateYear is CreationIncomeYear,
			LodgementDate = date(LodgementDateYear, 7, 1)
		)
	),
	convert_loan_inputs(
		% inputs
		CreationIncomeYear,  Term,  PrincipalAmount,  LodgementDate,  ComputationYear,  OpeningBalance,  LoanRepayments,
		% converted inputs
		NCreationIncomeYear, NTerm, NPrincipalAmount, NLodgementDate, NComputationYear, NOpeningBalance, NLoanRepayments),
	loan_agr_summary(
		loan_agreement(
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
			NLoanRepayments
		),
		Summary_term
	),
	div7a_summary_term_to_dict(Summary_term, Summary_dict).
	
	
	
	
 div7a_summary_term_to_dict(Summary_term, Summary_dict) :-	
    Summary_term = loan_summary(_Number, OpeningBalance, InterestRate, MinYearlyRepayment, TotalRepayment, RepaymentShortfall, TotalInterest, TotalPrincipal, ClosingBalance),
	Summary_dict = _{
				opening_balance: OpeningBalance,
				interest_rate: InterestRate,
				min_yearly_repayment: MinYearlyRepayment,
				total_repayment: TotalRepayment,
				repayment_shortfall: RepaymentShortfall,
				total_interest: TotalInterest,
				total_principal: TotalPrincipal,
				closing_balance: ClosingBalance
	}.





 loan_agr_summary_python0(Term, PrincipalAmount, LodgementDateStr, CreationIncomeYear, ComputationYear, OpeningBalance, LoanRepayments, Summary_dict) :-
	(var(PrincipalAmount) -> PrincipalAmount = -1; true),
	(var(LodgementDateStr) -> LodgementDateStr = -1; true),
	!loan_agr_summary_python(div7a{
		term: Term,
		principal_amount: PrincipalAmount,
		lodgement_date: LodgementDateStr,
		creation_income_year: CreationIncomeYear,
		computation_income_year: ComputationYear,
		opening_balance: OpeningBalance,
		repayments: $>repayments_to_json(LoanRepayments)
	}, Summary_dict).


 loan_agr_summary_python(LA, Summary_dict) :-
	!ground(LA),
	my_request_tmp_dir_path(Tmp_Dir_Path),
	services_rpc('div7a', _{tmp_dir_path:Tmp_Dir_Path,data:LA}, R),
	(	(get_dict(result, R, Summary_dict0), Summary_dict0 \= "error")
	->	true
	;	throw_string(R.error_message)),
	Summary_dict = _{
				opening_balance: _,
				interest_rate: _,
				min_yearly_repayment: _,
				total_repayment: _,
				repayment_shortfall: _,
				total_interest: _,
				total_principal: _,
				closing_balance: _
	},
	Summary_dict :< Summary_dict0.
	
	


repayments_to_json(LoanRepayments, Json) :-
	maplist(repayment_to_json, LoanRepayments, Json).


repayment_to_json(Repayment, Json) :-
	Repayment = loan_repayment(Date, Value),
	Json = repayment{date:Date, value:Value}.


 div7a_xml_loan_response(IncomeYear, LoanSummary, Url) :-
	xml_loan_response(IncomeYear, LoanSummary, LoanResponseXML),

	report_file_path(loc(file_name, 'response.xml'), Url, Path, _),
	loc(absolute_path, Raw) = Path,

	% create a temporary loan xml file to validate the response against the schema
	open(Raw, write, XMLStream),
	write(XMLStream, LoanResponseXML),
	close(XMLStream),

	% read the schema file
	resolve_specifier(loc(specifier, my_schemas('responses/LoanResponse.xsd')), LoanResponseXSD),
	!validate_xml(Path, LoanResponseXSD, []).
	

 xml_loan_response(
	IncomeYear,
	Summary_dict,
	LoanResponseXML
) :-

	_{	opening_balance: OpeningBalance,
		interest_rate: InterestRate,
		min_yearly_repayment: MinYearlyRepayment,
		total_repayment: TotalRepayment,
		repayment_shortfall: RepaymentShortfall,
		total_interest: TotalInterest,
		total_principal: TotalPrincipal,
		closing_balance: ClosingBalance
	} :< Summary_dict,

	ground(x(IncomeYear, OpeningBalance, InterestRate, MinYearlyRepayment, TotalRepayment,RepaymentShortfall, TotalInterest, TotalPrincipal, ClosingBalance)),
	var(LoanResponseXML),

	format(string(LoanResponseXML),
'<?xml version="1.0" ?>\n<LoanSummary xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="loan_response.xsd">\n\c
   <IncomeYear>~q</IncomeYear>\n\c
   <OpeningBalance>~8f</OpeningBalance>\n\c
   <InterestRate>~8f</InterestRate>\n\c
   <MinYearlyRepayment>~8f</MinYearlyRepayment>\n\c
   <TotalRepayment>~8f</TotalRepayment>\n\c
   <RepaymentShortfall>~8f</RepaymentShortfall>\n\c
   <TotalInterest>~8f</TotalInterest>\n\c
   <TotalPrincipal>~8f</TotalPrincipal>\n\c
   <ClosingBalance>~8f</ClosingBalance>\n\c
</LoanSummary>\n',

   [IncomeYear,
	OpeningBalance,
	InterestRate,
	MinYearlyRepayment,
	TotalRepayment,
	RepaymentShortfall,
	TotalInterest,
	TotalPrincipal,
	ClosingBalance]).



% ===================================================================
% Various helper predicates
% ===================================================================

% -------------------------------------------------------------------
% convert_loan_inputs/14
% -------------------------------------------------------------------

 convert_loan_inputs(CreationIncomeYear,  Term,  PrincipalAmount,  LodgementDate,  ComputationYear,  OpeningBalance,  LoanRepayments,
		      NCreationIncomeYear, NTerm, NPrincipalAmount, NLodgementDate, NComputationYear, NOpeningBalance, NLoanRepayments
) :-
	generate_absolute_days(CreationIncomeYear, LodgementDate, LoanRepayments, NCreationIncomeYear, NLodgementDate, NLoanRepayments),
	compute_opening_balance(OpeningBalance, NOpeningBalance),
	calculate_computation_year(ComputationYear, CreationIncomeYear, NComputationYear),
	(	nonvar(PrincipalAmount)
	->	atom_number(PrincipalAmount, NPrincipalAmount)
	;	NPrincipalAmount = -1),
	atom_number(Term, NTerm).



 generate_absolute_days(CreationIncomeYear, LodgementDate, LoanRepayments, NCreationIncomeYear, NLodgementDay, NLoanRepayments) :-
	generate_absolute_day(creation_income_year, CreationIncomeYear, NCreationIncomeYear),
	absolute_day(LodgementDate, NLodgementDay),
	generate_absolute_day(loan_repayments, LoanRepayments, NLoanRepayments).

 generate_absolute_day(creation_income_year, CreationIncomeYear, NCreationIncomeYear) :-
	atom_number(CreationIncomeYear, CreationIncomeYearNumber),
	absolute_day(date(CreationIncomeYearNumber, 7, 1), NCreationIncomeYear).



 % convert a list of loan_repayment terms with textual dates and values into a list of loan_repayment terms with absolute days and numeric values

 generate_absolute_day(loan_repayments, [], []).

 generate_absolute_day(loan_repayments, [loan_repayment(Date, Value)|Rest1], [loan_repayment(NDate, NValue)|Rest2]) :-
	parse_date_into_absolute_days(Date, NDate),
	atom_number(Value, NValue),
	generate_absolute_day(loan_repayments, Rest1, Rest2).


% ----------------------------------------------------------------------
% compute_opening_balance/2
% ----------------------------------------------------------------------

 compute_opening_balance(OpeningBalance, NOpeningBalance) :-
	(	OpeningBalance = -1
	->	NOpeningBalance = false
	;	atom_number(OpeningBalance, NOpeningBalance)).

% ----------------------------------------------------------------------
% calculate_computation_year/3
%
% Computation year is calculated as it is done in:
%	- ConstructLoanAgreement function (PrologEngpoint/LoanController.cs)
% ----------------------------------------------------------------------

 calculate_computation_year(ComputationYear, CreationIncomeYear, NComputationYear) :-
	atom_number(ComputationYear, NCY),
	atom_number(CreationIncomeYear, NCIY),
	calculate_computation_year2(NCY, NCIY, NComputationYear).

 calculate_computation_year2(NCY, NCIY, NComputationYear) :-
	NComputationYear is NCY - NCIY - 1.



% div7a_error_xml_response :-
%	LoanResponseXML = "<error>calculation failed</error>\n",
%	report_file_path(loc(file_name, 'response.xml'), Url, Path, _),
%	loc(absolute_path, Raw) = Path,
%	open(Raw, write, XMLStream),
%	write(XMLStream, LoanResponseXML),
%	close(XMLStream),
%	add_report_file(0,'result', 'result', Url).

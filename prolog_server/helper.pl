% ===================================================================
% Project:   LodgeiT
% Module:    helper.pl
% Author:    Abdus Salam and Rolf Schwitter
% Date:      2019-05-06
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

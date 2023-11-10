
div7a_myr(Loan, Year, Myr) :-
/*
MYR: (minimum yearly repayment)
 for the year in which the amalgamated loan is made, [...] payments made before lodgment day are taken to have been made in the year the amalgamated loan is made.
*/
	Myr = 100.


















/*



===============



*/

div7a_from_loan_agreement(Agreement, Summary) :-

	/*


	*/

	loan_agr_computation_year(Agreement, Comp_Year_0Idx),


	loan_agr_computation_opening_balance(Agreement, Opening_Balance),
	(	Opening_Balance \= false
	->	(
			loan_agr_year_days(Agreement, Comp_Year_0Idx, Computation_Year_Start_Day, _),
			Initial_Sequence = [p(Computation_Year_Start_Day, opening_balance, Opening_Balance)]
		)
	;	throw_string(not_implemented)
	),

	div7a_records(Initial_Sequence, Records),
	div7a_results(Records, Comp_Year_0Idx, Summary).



div7a_to_loan_results(Records, Comp_Year_0Idx, Summary) :-
	% report Interest_Rate for calculation year
	loan_agr_year_days(Agreement, Comp_Year_0Idx, Year_Start_Day, _End_Day),
	benchmark_interest_rate(Year_Start_Day, Interest_Rate),
	loan_sum_interest_rate(Summary, Interest_Rate),

	div7a_year_opening_balance(	Agreement, Comp_Year_0Idx, Opening_Balance),
	div7a_year_closing_balance(	Agreement, Comp_Year_0Idx, Closing_Balance),
	div7a_min_yearly_repayment(	Agreement, Comp_Year_0Idx, Min_Yearly_Repayment),
	div7a_total_repayment(		Agreement, Comp_Year_0Idx, Total_Repayment),
	div7a_total_interest(		Agreement, Comp_Year_0Idx, Total_Interest),
	div7a_total_principal(		Agreement, Comp_Year_0Idx, Total_Principal),
	div7a_repayment_shortfall(	Agreement, Comp_Year_0Idx, Repayment_Shortfall),

	loan_sum_number(				Summary, Comp_Year_0Idx),
	loan_sum_opening_balance(		Summary, Opening_Balance),
	loan_sum_interest_rate(			Summary, Interest_Rate),
	loan_sum_min_yearly_repayment(	Summary, Min_Yearly_Repayment),
	loan_sum_total_repayment(		Summary, Total_Repayment),
	loan_sum_repayment_shortfall(	Summary, Repayment_Shortfall),
	loan_sum_total_interest(		Summary, Total_Interest),
	loan_sum_total_principal(		Summary, Total_Principal),
	loan_sum_closing_balance(		Summary, Closing_Balance).



def interest_accrued(records, i):
	r = records[i]
	return r.info['days'] * r.info['rate'] * balance(records, i) / 365

def balance(records, i):
	# balance at the end of the day of the record
	# (i.e. before the next record)

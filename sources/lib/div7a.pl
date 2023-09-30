


























div7a(Agreement, Summary) :-

	/*
	Minimum yearly repayment depen


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



div7a_results(Records, Comp_Year_0Idx, Summary) :-
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

/*
given a point list In, repeatedly apply div7a_new_points to the last element, until the last element of the result is end.
*/
div7a_records(In, Out) :-
	last(In, Start),
	Start = p(_,_,_,Balance),
	(	Balance > 0,
	->	(
			div7a_new_points(Start, New),
			(	New = end
			->	Out = [In | New]
			;	(
					flatten([In,New], Current),
					div7a_records(Current, Out)
				)
			)
		)
	;	Out = In
	).






loan_agr_year_opening_balance(	Points, Comp_Year_0Idx, Opening_Balance) :-
	findall(P,
		(
			member(P, Points),
	% date(Prev_Year/7/1)?
	%
	%
	true.

loan_agr_year_closing_balance(	Points, Comp_Year_0Idx, Closing_Balance) :-

	true.

loan_agr_min_yearly_repayment(	Points, Comp_Year_0Idx, Min_Yearly_Repayment) :-
	given by opening balance of calculation year and benchmark interest rate.

	true.

loan_agr_total_repayment(		Points, Comp_Year_0Idx, Total_Repayment) :-
	year_points(Points, Points2),
	findall(
		Repayment,
		member(point(_,repayment,_), Points2)
		Repayments
	),
	sum_repayments_list(Repayments, Total_Repayment),
	true.

loan_agr_total_interest(		Points, Comp_Year_0Idx, Total_Interest) :-

	true.

loan_agr_total_principal(		Points, Comp_Year_0Idx, Total_Principal) :-

	true.

loan_agr_repayment_shortfall(	Points, Comp_Year_0Idx, Repayment_Shortfall) :-

	true.





%div7a_new_points(p(Day, opening_balance, Ob), Next) :-



/*
a computation for income year 2006 with opening balance starts like:
 p(1/7/2005, checkpoint, Balance)


* checkpoint
* interest
* repayment

*/
div7a_new_points(Loan, Prev_Points, New_Points) :-
	last(Prev_Points, Prev_Point),
	div7a_new_point_year(Prev_Point, Y),


	(	first_repayment_of_income_year_Y_not_seen_yet(Loan, Prev_Points, Y, R)
	->	(
			R = repayment(_, Day, _),
			Repayment_Point = p(Day, repayment, R),
			interest_accrual_since_last_point_to_current_date(Prev_Points, Day, Accrual_Point),
			Next = [Accrual_Point, Repayment_Point]
		)
	;	/*
			no more repayments this income year
		*/
		(
			interest_accrual_since_last_point_to_current_date(Prev_Points, date(Y,6,30), Accrual_Point),
			Next = [Accrual_Point]
		)
	).



div7a_new_point_year(Prev_Point, Y) :-
	Prev_Point = p(Prev_Point_Day, Prev_Point_Type, _, _),
	gregorian_date(Prev_Point_Day, Prev_Point_Date),

	(	(Prev_Point_Type = accrual, Prev_Point_Date = date(_Y,6,30))
	->	(
			New_Income_Year_Start_Day is Prev_Point_Day + 1,
			day_div7a_income_year(New_Income_Year_Start_Day, Y)
		)
	;	day_div7a_income_year(Prev_Point_Day, Y).


first_repayment_of_income_year_Y_not_seen_yet(Loan, Prev, Y, R) :-
	first_repayment_not_seen_yet(Loan, Prev, R),
	repayment_date(R, date(Y,_,_)).

first_repayment_not_seen_yet(Loan, Prev, R) :-
	repayment_not_seen_yet(Loan, Prev, R),
	!.

repayment_not_seen_yet(Loan, Prev, R) :-
	member(R, $>div7a_repayments(Loan)),
	\+member(p(_,repayment,R), Prev).






/* given a list of points that starts with opening_balance, apply repayments and interest accruals and return ending balance */
balance([p(_,opening_balance,Starting_Amount)|T], Balance_Out) :-
	balance(Starting_Amount, T, Balance_Out).

balance(Balance_In, [P|T], Balance_Out) :-
	P = p(_,interest_accrual,Amount)
	{Balance_With_P_Applied = Balance_In + Amount},
	balance(Balance_With_P_Applied, T, Balance_Out).

balance(Balance_In, [P|T], Balance_Out) :-
	P = p(_,repayment,Amount)
	{Balance_With_P_Applied = Balance_In - Amount},
	balance(Balance_With_P_Applied, T, Balance_Out).









interest_accrual_since_last_point_to_current_date(Prev, Current_Day, p(Current_Day, accrual, Amount)) :-
	last(Prev, p(Prev_Point_Day, _, _, _)),
	interest_accrual_since_A_to_B(Prev, Prev_Point_Day, Current_Day).

interest_accrual_since_A_to_B(Prev, Prev_Point_Day, Current_Day, Amount) :-

	balance(Prev, Prev_Balance),
	Interest_Period is Current_Day - Prev_Point_Day,
	benchmark_interest_rate(Current_Day, Interest_Rate, Income_Year_Days),

	Interest_Amount is Prev_Balance * (Interest_Rate/100) * Interest_Period / Income_Year_Days,



income_year_days(
	absolute_day(Income_Year_Start_Date, Income_Year_Start_Day),
	absolute_day(Income_Year_End_Date, Income_Year_End_Day),











/*


First income year

For the first income year after the amalgamated loan is made:

    no interest is payable in respect of the year the loan is made
    the amount of the loan not repaid by the end of the previous income year is calculated by subtracting:
        the total principal repayments made before the private company's lodgment day, from
        the original amount of the loan.
...

Where a repayment is made before the private company's lodgment day for the year in which the amalgamated loan is made, the principal amount at 1 July of the first income year after the loan is made, is not the sum total of the constituent loans at 1 July. Rather, it is the sum of the constituent loans immediately before the lodgment day. For this purpose, payments made before lodgment day are taken to have been made in the year the amalgamated loan is made.



...

For the following income years, to calculate the amount of the loan not repaid by the end of the previous income year, it's important to know how much of the repayment made in the income year is attributable to interest and how much is applied to reduce the principal.
...

The amount of the loan repaid during an income year is obtained by deducting the interest from the actual repayments made during the year. The opening balance of the loan for the next year is the opening balance at the beginning of the previous year less the principal repaid during that year.


...


. If the interest rate in the written agreement is different from the benchmark interest rate, the benchmark interest rate is used to calculate the minimum yearly repayment for Division 7A purposes.

+--------


>>> '{x:.50f}'.format(x=((1000*0.0545)/(1-(1/(1+0.0545))**7)))
'175.64878368956931353750405833125114440917968750000000'




*/



/*===========scraps===========-*/




/*
div7a_records(Start, [Start,Next|Records_Tail]) :-
	Start = p(_,_,_,Balance),
	(	Balance > 0,
	->	(
			div7a_new_points(Start, Next),
			(	Next = end
			->	Records_Tail = []
			;	(
					last(Next, Last_Element_Of_Next),
					div7a_records(Last_Element_Of_Next, Records_Tail)

				)
			)
		)
	;	Records_Tail = []
	).
*/

% ===================================================================
% Project:   LodgeiT
% Module:    loans.pl
% Author:    Murisi and Rolf Schwitter
% Date:      2019-06-02
% ===================================================================

% -------------------------------------------------------------------
% The purpose of the following program is to derive information about a given loan
% agreement. That is, this program will tell you what the closing balance of the loan
% account is after a particular installment has been paid. It will tell you how much
% interest you have paid for a given income year in the agreement. And it will tell you
% other relevant information.

% This program is part of a larger system for validating and correcting balance sheets.
% More precisely, accounting principles require that the transactions that occur in a loan
% agreement are summarized in balance sheets. This program calculates those summary values
% directly from the original data and ultimately will be expected to add correction
% entries to the balance sheet when it is in error.

% The formulas in this program are completely specified by the examples and rules set
% forth in https://www.ato.gov.au/business/private-company-benefits---division-7a-dividends/in-detail/division-7a---loans/

% ato calculator: https://www.ato.gov.au/calculators-and-tools/division-7a-calculator-and-decision-tool/
/* 
Income year of loan: 2013-14 means our income year 2014.

We are only concerned with unsecured loans here.
*/

% issues:
% https://github.com/lodgeit-labs/accounts-assessor/issues?q=is%3Aissue+is%3Aopen+div7a



% -------------------------------------------------------------------


% Benchmark interest rates
% These rates apply to private companies with an income year ending 30 June.
% Source: https://www.ato.gov.au/rates/division-7a---benchmark-interest-rate/
benchmark_interest_rate(Day, 4.77) :- benchmark_interest_rate_day_in_income_year(Day, 2023).
benchmark_interest_rate(Day, 4.52) :- benchmark_interest_rate_day_in_income_year(Day, 2022).
benchmark_interest_rate(Day, 4.52) :- benchmark_interest_rate_day_in_income_year(Day, 2021).
benchmark_interest_rate(Day, 5.37) :- benchmark_interest_rate_day_in_income_year(Day, 2020).
benchmark_interest_rate(Day, 5.20) :- benchmark_interest_rate_day_in_income_year(Day, 2019).
benchmark_interest_rate(Day, 5.30) :- benchmark_interest_rate_day_in_income_year(Day, 2018).
benchmark_interest_rate(Day, 5.40) :- benchmark_interest_rate_day_in_income_year(Day, 2017).
benchmark_interest_rate(Day, 5.45) :- benchmark_interest_rate_day_in_income_year(Day, 2016).
benchmark_interest_rate(Day, 5.95) :- benchmark_interest_rate_day_in_income_year(Day, 2015).
benchmark_interest_rate(Day, 6.20) :- benchmark_interest_rate_day_in_income_year(Day, 2014).
benchmark_interest_rate(Day, 7.05) :- benchmark_interest_rate_day_in_income_year(Day, 2013).
benchmark_interest_rate(Day, 7.80) :- benchmark_interest_rate_day_in_income_year(Day, 2012).
benchmark_interest_rate(Day, 7.40) :- benchmark_interest_rate_day_in_income_year(Day, 2011).
benchmark_interest_rate(Day, 5.75) :- benchmark_interest_rate_day_in_income_year(Day, 2010).
benchmark_interest_rate(Day, 9.45) :- benchmark_interest_rate_day_in_income_year(Day, 2009).
benchmark_interest_rate(Day, 8.05) :- benchmark_interest_rate_day_in_income_year(Day, 2008).
benchmark_interest_rate(Day, 7.55) :- benchmark_interest_rate_day_in_income_year(Day, 2007).
benchmark_interest_rate(Day, 7.3) :-  benchmark_interest_rate_day_in_income_year(Day, 2006).
benchmark_interest_rate(Day, 7.05) :- benchmark_interest_rate_day_in_income_year(Day, 2005).
benchmark_interest_rate(Day, 6.55) :- benchmark_interest_rate_day_in_income_year(Day, 2004).
benchmark_interest_rate(Day, 6.3) :-  benchmark_interest_rate_day_in_income_year(Day, 2003).
benchmark_interest_rate(Day, 6.8) :-  benchmark_interest_rate_day_in_income_year(Day, 2002).
benchmark_interest_rate(Day, 7.8) :-  benchmark_interest_rate_day_in_income_year(Day, 2001).
benchmark_interest_rate(Day, 6.5) :-  benchmark_interest_rate_day_in_income_year(Day, 2000).
benchmark_interest_rate(Day, 6.7) :-  benchmark_interest_rate_day_in_income_year(Day, 1999).

benchmark_interest_rate_day_in_income_year(Day, Year) :- 
	Previous_year #= Year - 1,
	day_between(date(Previous_year,7,1), date(Year,7,1), Day).

% Predicates for asserting the fields of a loan repayment

% The date the repayment is to be paid
loan_rep_day(loan_repayment(Day, _), Day).
% The amount that constitutes the repayment. A loan_rep with an amount of zero is used to indicate a new
% income year (?).
loan_rep_amount(loan_repayment(_, Amount), Amount).







% Predicates for asserting the fields of a loan agreement

% An identifier for a given loan agreement
loan_agr_contract_number(loan_agreement(Contract_Number, _, _, _, _, _, _, _), Contract_Number).

% The principal amount of the loan agreement
loan_agr_principal_amount(loan_agreement(_, Principal_Amount, _, _, _, _, _, _), Principal_Amount).

% The lodgement day of the whole agreement
/*
 seems to actually be:
Enter the lodgment day, which is the earlier of the due date for lodgment and the date of lodgment for the private company's tax return for the 2016-17 income year - enter a date in the format dd/mm/yyyy *
this seems to be relevant if we're computing the minimum yearly repayment for the first year of the loan agreement.

For the first year of the loan:
    The minimum yearly repayment is calculated using the amount of the amalgamated loan, which is the sum of the amounts of the constituent loans that have not been repaid before the lodgment day of the private company for the year of income in which the amalgamated loan is made.
    Making repayments before the lodgment day will reduce the minimum yearly repayment required for this year, and will contribute towards meeting your minimum yearly repayment.
*/
loan_agr_lodgement_day(loan_agreement(_, _, Lodgement_Day, _, _, _, _, _), Lodgement_Day).

% The first absolute day of the first income year after the agreement is made
loan_agr_begin_day(loan_agreement(_, _, _, Begin_Day, _, _, _, _), Begin_Day).

% The term of the loan agreement in years
loan_agr_term(loan_agreement(_, _, _, _, Term, _, _, _), Term).

% The income year for which the computations will be done. Starting at zero for the first possible year of computation (which is the year following the loan creation) 
loan_agr_computation_year(loan_agreement(_, _, _, _, _, Computation_Year, _, _), Computation_Year).

% If this field is false, the computations will start from the day of the loan agreement.
% Otherwise this will be the opening balance of the computations.
loan_agr_computation_opening_balance(loan_agreement(_, _, _, _, _, _, Computation_Opening_Balance, _), Computation_Opening_Balance).

% A chronologically ordered list of loan agreement repayments. The latter repayments
% where the account balance is negative are ignored.
loan_agr_repayments(loan_agreement(_, _, _, _, _, _, _, Repayments), Repayments).






% Predicates for asserting the fields of a loan record

% Records are indexed in chronological order, starting with 1
loan_rec_number(loan_record(Record_Number, _, _, _, _, _, _, _), Record_Number).
% The balance of the payment at the beginning of the given period
loan_rec_opening_balance(loan_record(_, Opening_Balance, _, _, _, _, _, _), Opening_Balance).
% The interest rate being applied to the opening balance
loan_rec_interest_rate(loan_record(_, _, Interest_Rate, _, _, _, _, _), Interest_Rate).
% The calculated interest since the last payment/beginning of year
loan_rec_interest_amount(loan_record(_, _, _, Interest_Amount, _, _, _, _), Interest_Amount).
% The amount being paid towards the good in the given period
loan_rec_repayment_amount(loan_record(_, _, _, _, Repayment_Amount, _, _, _), Repayment_Amount).
% The balance of the payment at the end of the given period
loan_rec_closing_balance(loan_record(_, _, _, _, _, Closing_Balance, _, _), Closing_Balance).
% The opening day of the given record's period
loan_rec_opening_day(loan_record(_, _, _, _, _, _, Opening_Day, _), Opening_Day).
% The closing day of the given record's period
loan_rec_closing_day(loan_record(_, _, _, _, _, _, _, Closing_Day), Closing_Day).

% Predicates for asserting the fields of a loan summary
% Loan summaries are indexed in chornological order starting from year 0, the first income
% year after the income year in which the loan agreement is made (money is lended).
% loan summary looks like a checkpoint describing what happened during one income year,
% but only one such term is used in this program - for returning results.

loan_sum_number(loan_summary(Summary_Number, _, _, _, _, _, _, _, _), Summary_Number).
% The opening balance of the given income year
loan_sum_opening_balance(loan_summary(_, Opening_Balance, _, _, _, _, _, _, _), Opening_Balance).
% The benchmark interest rate during the given income year
loan_sum_interest_rate(loan_summary(_, _, Interest_Rate, _, _, _, _, _, _), Interest_Rate).
% The minimum yearly repayment for the given income year
loan_sum_min_yearly_repayment(loan_summary(_, _, _, Min_Yearly_Repayment, _, _, _, _, _), Min_Yearly_Repayment).
% The total amount repaid during the given income year
loan_sum_total_repayment(loan_summary(_, _, _, _, Total_Repayments, _, _, _, _), Total_Repayments).
% The additional repayment required in order to meet the minimum yearly payment
loan_sum_repayment_shortfall(loan_summary(_, _, _, _, _, Repayment_Shortfall, _, _, _), Repayment_Shortfall).
% The total interest owed at the end of the given income year
loan_sum_total_interest(loan_summary(_, _, _, _, _, _, Total_Interest, _, _), Total_Interest).
% The total principal paid during the given income year
loan_sum_total_principal(loan_summary(_, _, _, _, _, _, _, Total_Principal, _), Total_Principal).
% The closing balance of the given income year
loan_sum_closing_balance(loan_summary(_, _, _, _, _, _, _, _, Closing_Balance), Closing_Balance).

% The following logic is used instead of relating records to their predecessors because it
% allows Prolog to systematically find all the loan records corresponding to a given
% loan agreement.






% Asserts the necessary relations to get from one loan record to the next
/* create a record that spans from the current day to the next repayment day.
 records the repayment amount of that repayment in the record.
 */

next_loan_record(Repayments_Hd, Current_Rep_Amount, Current_Record_Number, Current_Day, Current_Balance, Interest_Amount, Next_Record) :-

	loan_rep_day(Repayments_Hd, Next_Day),
	loan_rep_amount(Repayments_Hd, Current_Rep_Amount),
	Next_Record_Number is Current_Record_Number + 1,

	
	/* number of days for calculating interest */
	Interest_Period is Next_Day - Current_Day,
	

	/* this must assume that the record only spans a single year, which i guess should be always true.
	 So, the Next_Day_Year should always equal the record start date year i think. */
	gregorian_date(Next_Day, date(Next_Day_Year,_,_)),
	(	leap_year(Next_Day_Year)
	->	Year_Days = 366
	;	Year_Days = 365),
	!check1(Current_Day, Year_Days),


	benchmark_interest_rate(Current_Day, Interest_Rate),
	Interest_Amount is Current_Balance * (Interest_Rate/100) * Interest_Period / Year_Days,


		
	loan_rec_number(			Next_Record, Next_Record_Number),
	loan_rec_opening_day(		Next_Record, Current_Day),
	loan_rec_closing_day(		Next_Record, Next_Day),
	loan_rec_opening_balance(	Next_Record, Current_Balance),
	loan_rec_interest_rate(		Next_Record, Interest_Rate),
	loan_rec_interest_amount(	Next_Record, Interest_Amount),
	loan_rec_repayment_amount(	Next_Record, Current_Rep_Amount).
	
	

check1(Current_Day, Year_Days) :-
	gregorian_date(Current_Day, date(Current_Day_Year,_,_)),
	(	leap_year(Current_Day_Year)
	->	Year_Days = 366
	;	Year_Days = 365),








% Relates a loan agreement to one of its records. This is the entry point to the whole calculation.

loan_agr_record(Agreement, Record) :-
	loan_agr_record2(Agreement, interest, Record).

loan_agr_record2(Agreement, Purpose, Record) :-

	/* this is the case when we have loan principal amount */
	loan_agr_computation_opening_balance(Agreement, false),
	
	loan_agr_principal_amount(Agreement, Principal_Amount),
	loan_agr_repayments(Agreement, Repayments_A),

	/* it seems that lodgement date should be ignored, for interest computation. but not for computation of minimum yearly repayment... */
	loan_agr_begin_day(Agreement, Begin_Day),
	(	Purpose = interest
	->	Lodgement_Day = Begin_Day
	;	loan_agr_lodgement_day(Agreement, Lodgement_Day)),
	
	/* starting from loan principal amount, Repayment_Before_Lodgement simply decreases the opening balance at loan year lodgement day */
	loan_reps_before_lodgement(Lodgement_Day, 0, Repayments_A, Repayment_Before_Lodgement, Repayments_B),

	/* Principal_Amount is never used if Computation_Opening_Balance is false */
	Current_Balance is Principal_Amount - Repayment_Before_Lodgement,

	/* this will yield records one after another (right?) */
	loan_agr_record_aux(Agreement, Record, Current_Balance, Begin_Day, Repayments_B).


% Relates a loan agreement to one of its records starting from the given balance at the given day

loan_agr_record2(Agreement, Purpose, Record) :-
	loan_agr_computation_opening_balance(Agreement, Computation_Opening_Balance),
	Computation_Opening_Balance \= false,
	
	loan_agr_computation_year(Agreement, Computation_Year),
	loan_agr_year_days(Agreement, Computation_Year, Computation_Day, _),
	loan_agr_repayments(Agreement, Repayments_A),

	loan_agr_begin_day(Agreement, Begin_Day),
	(	Purpose = interest
	->	Lodgement_Day = Begin_Day
	;	loan_agr_lodgement_day(Agreement, Lodgement_Day)),
	
	/* we have opening balance at lodgement day, so we ignore repayments before lodgement day */
	loan_reps_before_lodgement(Lodgement_Day, 0, Repayments_A, _Repayment_Before_Lodgement, Repayments_B),

	/* this will yield records one after another (right?) */
	loan_agr_record_aux(Agreement, Record, Computation_Opening_Balance, 
	
	/* this doesn't make any sense, cutting off all repayments before Computation_Day */  
	Computation_Day,
	 
	Repayments_B).


% Asserts the necessary relations to get the first record given the current balance and day

loan_agr_record_aux(Agreement, Record, Current_Balance, Current_Day, Repayments_A) :-
	Current_Acc_Interest = 0,
	Current_Accumulated_Repayment_Amount = 0,
	loan_agr_term(Agreement, Term),
	loan_agr_begin_day(Agreement, Begin_Day),
	gregorian_date(Begin_Day, Begin_Date),
	loan_reps_insert_sentinels(Begin_Date, Term, Repayments_A, Repayments_B),
	make_repayments_with_sentinels_report(Begin_Date, Term, Repayments_B),
	loan_reps_after(Current_Day, Repayments_B, [Repayments_Hd|Repayments_Tl]),
	Current_Record_Number = 0,
	next_loan_record(Repayments_Hd, Current_Record_Number, Current_Day, Current_Balance, Interest_Amount, Next_Record),
	loan_rec_repayment_amount(Next_Record, Current_Rep_Amount)
	New_Acc_Rep is Current_Accumulated_Repayment_Amount + Current_Rep_Amount,
	Next_Acc_Interest is Current_Acc_Interest + Interest_Amount,
	Next_Balance is Current_Balance - Current_Rep_Amount,
	loan_rec_closing_balance(Next_Record, Next_Balance),
	(
		Record = Next_Record
	;
		loan_rec_record(Next_Record, Repayments_Tl, Next_Acc_Interest, New_Acc_Rep, Record)
	).








/*
Relates a loan record to all that follow it, afaict
Seeems to relate records to repayments, but the Repayments list already contains 0-amount sentinels for year beginnings.
Accumulates Current_Accumulated_Repayment_Amount of one year.  
*/


% Relates a loan record to one that follows it, in the case that it is a year-end record

loan_rec_record(Current_Record, [Repayments_Hd|Repayments_Tl], Current_Acc_Interest, _Current_Acc_Rep, Record) :-
	/* in case the repayment is just a sentinel */
	Current_Rep_Amount #= 0,

	next_loan_record0(Repayments_Hd, Current_Record, Interest_Amount, Next_Record),
	loan_rec_repayment_amount(Next_Record, Current_Rep_Amount),
	
	Next_Acc_Rep = 0,
	Next_Acc_Interest = 0,
	Next_Balance is Current_Balance + Current_Acc_Interest + Interest_Amount,
	loan_rec_closing_balance(Next_Record, Next_Balance),
	(
		Record = Next_Record
	;
		loan_rec_record(Next_Record, Repayments_Tl, Next_Acc_Interest, Next_Acc_Rep, Record)
	).


% Relates a loan record to one that follows it, in the case that it is not a year-end record

loan_rec_record(Current_Record, [Repayments_Hd|Repayments_Tl], Current_Acc_Interest, Current_Accumulated_Repayment_Amount, Record) :-
	Current_Rep_Amount #> 0,
	
	next_loan_record0(Repayments_Hd, Current_Record, Interest_Amount, Next_Record),
	loan_rec_repayment_amount(Next_Record, Current_Rep_Amount),
	
	New_Acc_Rep is Current_Accumulated_Repayment_Amount + Current_Rep_Amount,
	Next_Acc_Interest is Current_Acc_Interest + Interest_Amount,
	Next_Balance is Current_Balance - Current_Rep_Amount, Next_Balance >= 0,
	loan_rec_closing_balance(Next_Record, Next_Balance),
	(
		Record = Next_Record
	;
		loan_rec_record(Next_Record, Repayments_Tl, Next_Acc_Interest, New_Acc_Rep, Record)
	).



next_loan_record0(Repayments_Hd, Current_Record, Interest_Amount, Next_Record) :-

	loan_rec_number(			Current_Record, Current_Record_Number),
	loan_rec_closing_day(		Current_Record, Current_Day),
	loan_rec_closing_balance(	Current_Record, Current_Balance),
	
	next_loan_record(Repayments_Hd, Current_Record_Number, Current_Day, Current_Balance, Interest_Amount, Next_Record).



/*This adds up the amounts of repayments before lodgement day, and returns the rest of repayments.*/

% If a loan repayment was made before lodgement day, just add its amount to the total
% repayment and forget it.

loan_reps_before_lodgement(Lodgement_Day, Total_Repayment, [Repayments_Hd|Repayments_Tl], New_Total_Repayment, New_Repayments) :-
	loan_rep_day(Repayments_Hd, Day),
	Day < Lodgement_Day,
	loan_rep_amount(Repayments_Hd, Amount),
	Next_Total_Repayment is Total_Repayment + Amount,
	loan_reps_before_lodgement(Lodgement_Day, Next_Total_Repayment, Repayments_Tl, New_Total_Repayment, New_Repayments).

% Otherwise leave the principal amount and repayments unaltered

loan_reps_before_lodgement(Lodgement_Day, Total_Repayment, Repayments, Total_Repayment, Repayments) :-
	[Repayments_Hd|_] = Repayments,
	loan_rep_day(Repayments_Hd, Day),
	Day >= Lodgement_Day.

loan_reps_before_lodgement(_, Total_Repayment, [], Total_Repayment, []).







% Insert a repayment into a chronologically ordered list of repayments


/* 
 So yeah the following two preds look like they can be significantly simplified, but we can do that after all tests are passing.
 loan_reps_insert_repayment could be replaced with calling sort with a predicate that compares the days of the repayments.(?)
  Inserted should be called Sorted if anything.
loan_reps_insert_sentinels can just come up with a simple list of sentinels and let the sort predicate sort it.  
 */

loan_reps_insert_repayment(New_Repayment, [], [New_Repayment]).

loan_reps_insert_repayment(New_Repayment, [Repayments_Hd|Repayments_Tl], Inserted) :-
	loan_rep_day(Repayments_Hd, Hd_Day),
	loan_rep_day(New_Repayment, New_Day),
	Hd_Day >= New_Day,
	Inserted = [New_Repayment|[Repayments_Hd|Repayments_Tl]].

loan_reps_insert_repayment(New_Repayment, [Repayments_Hd|Repayments_Tl], Inserted) :-
	loan_rep_day(Repayments_Hd, Hd_Day),
	loan_rep_day(New_Repayment, New_Day),
	Hd_Day < New_Day,
	loan_reps_insert_repayment(New_Repayment, Repayments_Tl, Inserted_Tl),
	Inserted = [Repayments_Hd|Inserted_Tl].





% Insert payments of zero at year-beginnings to enable proper interest accumulation

loan_reps_insert_sentinels(_, 0, Repayments, Repayments).

loan_reps_insert_sentinels(Begin_Date, Year_Count, Repayments, Inserted) :-
	Year_Count > 0,
	absolute_day(Begin_Date, Begin_Day),
	loan_reps_insert_repayment(loan_repayment(Begin_Day, 0), Repayments, New_Repayments),
	date_add(Begin_Date, date(1, 0, 0), New_Begin_Date),
	New_Year_Count is Year_Count - 1,
	loan_reps_insert_sentinels(New_Begin_Date, New_Year_Count, New_Repayments, Inserted).





% Get the loan repayments on or after a given day

loan_reps_after(_, [], []).

loan_reps_after(Day, [Repayments_Hd | Repayments_Tl], [Repayments_Hd | Repayments_Tl]) :-
	loan_rep_day(Repayments_Hd, Rep_Day),
	Rep_Day >= Day.

loan_reps_after(Day, [Repayments_Hd | Repayments_Tl], New_Repayments) :-
	loan_rep_day(Repayments_Hd, Rep_Day),
	Rep_Day < Day,
	loan_reps_after(Day, Repayments_Tl, New_Repayments).

% Computes the start and end day of a given income year with respect to the given loan
% agreement.

loan_agr_year_days(Agreement, Year_Num, Year_Start_Day, Year_End_Day) :-
	loan_agr_begin_day(Agreement, Begin_Day),
	gregorian_date(Begin_Day, Begin_Date),
	date_add(Begin_Date, date(Year_Num, 0, 0), Year_Start_Date),
	absolute_day(Year_Start_Date, Year_Start_Day),
	date_add(Year_Start_Date, date(1, 0, 0), Year_End_Date),
	absolute_day(Year_End_Date, Year_End_Day).

% The following predicates assert the opening and closing balances respectively of the
% given income year with respect to the given loan agreement.

loan_agr_year_opening_balance(Agreement, Year_Num, Purpose, Opening_Balance) :-
	loan_agr_year_days(Agreement, Year_Num, Year_Start_Day, _),
	loan_agr_record2(Agreement, Purpose, Year_Record),
	loan_rec_repayment_amount(Year_Record, 0),
	loan_rec_closing_day(Year_Record, Year_Start_Day),
	loan_rec_closing_balance(Year_Record, Opening_Balance).

loan_agr_year_closing_balance(Agreement, Year_Num, Closing_Balance) :-
	loan_agr_year_days(Agreement, Year_Num, _, Year_End_Day),
	loan_agr_record(Agreement, Year_Record),
	loan_rec_repayment_amount(Year_Record, 0),
	loan_rec_closing_day(Year_Record, Year_End_Day),
	loan_rec_closing_balance(Year_Record, Closing_Balance).

% Calculates the minimum required payment of the given year with respect to the given
% agreement. Year 0 is the income year just after the one in which the loan agreement
% was made.

loan_agr_min_yearly_repayment(Agreement, Current_Year_Num, Min_Yearly_Rep) :-
	loan_agr_year_days(Agreement, Current_Year_Num, Year_Begin_Day, _),
	loan_agr_year_opening_balance(Agreement, Current_Year_Num, min_repayment, Balance),
	loan_agr_term(Agreement, Term),
	Remaining_Term is Term - Current_Year_Num,
	benchmark_interest_rate(Year_Begin_Day, Benchmark_Interest_Rate),
	% https://www.ato.gov.au/uploadedImages/Content/Images/40557-3.gif
	Min_Yearly_Rep is Balance * Benchmark_Interest_Rate /
		(100 * (1 - (1 + (Benchmark_Interest_Rate / 100)) ** (-Remaining_Term))).

% A predicate for generating the records of a loan agreement within a given period.

loan_agr_record_between(Agreement, Start_Day, End_Day, Record) :-
	loan_agr_record(Agreement, Record),
		loan_rec_closing_day(Record, Record_Closing_Day),
		Start_Day =< Record_Closing_Day,
		Record_Closing_Day =< End_Day.

% A predicate asserting the total repayment within a given income year of a loan agreement.

loan_agr_total_repayment(Agreement, 0, Total_Repayment) :-
	loan_agr_year_days(Agreement, 0, _, Year_End_Day),
	loan_agr_repayments(Agreement, Repayments),
	findall(Amount,
		(member(loan_repayment(Day, Amount), Repayments), Day < Year_End_Day),
		Amounts),
	sum_list(Amounts, Total_Repayment).

loan_agr_total_repayment(Agreement, Year_Num, Total_Repayment) :-
	Year_Num > 0,
	loan_agr_year_days(Agreement, Year_Num, Year_Start_Day, Year_End_Day),
	findall(Record_Repayment,
		(loan_agr_record_between(Agreement, Year_Start_Day, Year_End_Day, Record),
		loan_rec_repayment_amount(Record, Record_Repayment)),
		Record_Repayments),
	sum_list(Record_Repayments, Total_Repayment).

% A predicate asserting the total interest owed within a given income year of a loan
% agreement.

loan_agr_total_interest(Agreement, Year_Num, Total_Interest) :-
	loan_agr_year_days(Agreement, Year_Num, Year_Start_Day, Year_End_Day),
	findall(Record_Interest,
		(loan_agr_record_between(Agreement, Year_Start_Day, Year_End_Day, Record),
		loan_rec_interest_amount(Record, Record_Interest)),
		Record_Interests),
	sum_list(Record_Interests, Total_Interest).

% A predicate asserting the total pincipal paid within a given income year of a loan
% agreement.

loan_agr_total_principal(Agreement, Year_Num, Total_Principal) :-
	loan_agr_total_repayment(Agreement, Year_Num, Total_Repayment),
	loan_agr_total_interest(Agreement, Year_Num, Total_Interest),
	Total_Principal is Total_Repayment - Total_Interest.

% A predicate asserting the repayment shortfall of a given income year of a loan agreement.

loan_agr_repayment_shortfall(Agreement, Year_Num, Shortfall) :-
	loan_agr_total_repayment(Agreement, Year_Num, Total_Repayment),
	loan_agr_min_yearly_repayment(Agreement, Year_Num, Min_Yearly_Rep),
	Shortfall is max(Min_Yearly_Rep - Total_Repayment, 0).

% A predicate for generating the summary records of a given loan agreement.

loan_agr_summary(Agreement, Summary) :-
gtrace,
	findall(Record, loan_agr_record(Agreement, Record), Recs),
	loan_recs_table(Recs),
	
	/* deconstruct the input term */
	loan_agr_computation_year(Agreement, Summary_Number),
	/* computations */
	loan_agr_year_days(Agreement, Summary_Number, Year_Start_Day, _End_Day),
	benchmark_interest_rate(Year_Start_Day, Interest_Rate),
	loan_agr_year_opening_balance(Agreement, Summary_Number, interest, Opening_Balance),
	loan_agr_year_closing_balance(Agreement, Summary_Number, Closing_Balance),
	loan_agr_min_yearly_repayment(Agreement, Summary_Number, Min_Yearly_Repayment),
	loan_agr_total_repayment(Agreement, Summary_Number, Total_Repayment),
	loan_agr_total_interest(Agreement, Summary_Number, Total_Interest),
	loan_agr_total_principal(Agreement, Summary_Number, Total_Principal),
	loan_agr_repayment_shortfall(Agreement, Summary_Number, Repayment_Shortfall),

	/* assert the fields of the final and only loan summary(result). */
	loan_sum_number(Summary, Summary_Number),
	loan_sum_interest_rate(Summary, Interest_Rate),
	loan_sum_opening_balance(Summary, Opening_Balance),
	loan_sum_closing_balance(Summary, Closing_Balance),
	loan_sum_min_yearly_repayment(Summary, Min_Yearly_Repayment),
	loan_sum_total_repayment(Summary, Total_Repayment),
	loan_sum_total_interest(Summary, Total_Interest),
	loan_sum_total_principal(Summary, Total_Principal),
	loan_sum_repayment_shortfall(Summary, Repayment_Shortfall).



 loan_recs_table(Recs) :-
    
    maplist(loan_rec_row, Recs, Rows),
	Cols = [
		column{id:loan_rec_number, title:"number", options:_{help:'Records are indexed in chronological order, starting with 1'}},
		column{id:loan_rec_opening_day, title:"opening_day", options:_{help:"The opening day of the given record's period"}},
		column{id:loan_rec_closing_day, title:"closing_day", options:_{help:"The closing day of the given record's period"}},
		column{id:loan_rec_opening_balance, title:"opening_balance", options:_{help:'The balance of the payment at the beginning of the given period'}},
		column{id:loan_rec_interest_rate, title:"interest_rate", options:_{help:'The interest rate being applied to the opening balance'}},
		column{id:loan_rec_interest_amount, title:"interest_amount", options:_{help:'The calculated interest since the last payment/beginning of year'}},
		column{id:loan_rec_repayment_amount, title:"repayment_amount", options:_{help:'The amount being paid towards the good in the given period'}},
		column{id:loan_rec_closing_balance, title:"closing_balance", options:_{help:'The balance of the payment at the end of the given period'}}
	],
	
	Table_Json = _{title_short: "loan records", title: "loan records", rows: Rows, columns: Cols},
	!table_html([], Table_Json, Table_Html),
   	!page_with_table_html('loan_records', Table_Html, Html),
   	!add_report_page(0, 'loan_records', Html, loc(file_name,'loan_records.html'), 'loan_records.html').

			

 loan_rec_row(Record, Row) :-
	loan_rec_number(Record, Record_Number),
	loan_rec_opening_balance(Record, Opening_Balance),
	loan_rec_interest_rate(Record, Interest_Rate),
	loan_rec_interest_amount(Record, Interest_Amount),
	loan_rec_repayment_amount(Record, Repayment_Amount),
	loan_rec_closing_balance(Record, Closing_Balance),
	loan_rec_opening_day(Record, O),
	loan_rec_closing_day(Record, C),
	gregorian_date(O, Opening_Day),
	gregorian_date(C, Closing_Day),
	
	Row = _{
		loan_rec_number: Record_Number,
		loan_rec_opening_balance: Opening_Balance,
		loan_rec_interest_rate: Interest_Rate,
		loan_rec_interest_amount: Interest_Amount,
		loan_rec_repayment_amount: Repayment_Amount,
		loan_rec_closing_balance: Closing_Balance,
		loan_rec_opening_day: Opening_Day,
		loan_rec_closing_day: Closing_Day
	},

	format(user_error, '~q: ~q - ~q (~q - ~q):~n', [Record_Number, Opening_Day, Closing_Day, O, C]),
	format(user_error, ': ob: ~q  cb: ~q  ir: ~q  i: ~q  rep: ~q~n', [Opening_Balance, Closing_Balance, Interest_Rate, Interest_Amount, Repayment_Amount]).	









make_repayments_with_sentinels_report(Begin_Date, Term, Repayments) :-
    maplist(loan_repayment_row, Repayments, Rows),
	Cols = [
		column{id:date, title:"date", options:_{}},
		column{id:amount, title:"amount", options:_{help:"0 for sentinel."}}
	],
	
	Table_Json = _{title_short: "repayment records", title: "repayment records", rows: Rows, columns: Cols},
	!table_html([], Table_Json, Table_Html),
   	!page_with_table_html('repayment_records', Table_Html, Html),
   	!add_report_page(0, 'repayments', Html, loc(file_name,'repayments.html'), 'repayments.html').

			

 loan_repayment_row(Record, Row) :-
	loan_rep_day(Record, Day),
	loan_rep_amount(Record, Amount),
	
	gregorian_date(Day, Date),
	
	Row = _{
		date: Date,
		amount: Amoount
	}.
	
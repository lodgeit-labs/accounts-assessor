% Benchmark interest rates
% These rates apply to private companies with an income year ending 30 June.
% Source: https://www.ato.gov.au/rates/division-7a---benchmark-interest-rate/

benchmark_interest_rate(Day, 5.20) :- absolute_day(date(2018,6,30), ODay), absolute_day(date(2019,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 5.30) :- absolute_day(date(2017,6,30), ODay), absolute_day(date(2018,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 5.40) :- absolute_day(date(2016,6,30), ODay), absolute_day(date(2017,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 5.45) :- absolute_day(date(2015,6,30), ODay), absolute_day(date(2016,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 5.95) :- absolute_day(date(2014,6,30), ODay), absolute_day(date(2015,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 6.20) :- absolute_day(date(2013,6,30), ODay), absolute_day(date(2014,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 7.05) :- absolute_day(date(2012,6,30), ODay), absolute_day(date(2013,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 7.80) :- absolute_day(date(2011,6,30), ODay), absolute_day(date(2012,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 7.40) :- absolute_day(date(2010,6,30), ODay), absolute_day(date(2011,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 5.75) :- absolute_day(date(2009,6,30), ODay), absolute_day(date(2010,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 9.45) :- absolute_day(date(2008,6,30), ODay), absolute_day(date(2009,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 8.05) :- absolute_day(date(2007,6,30), ODay), absolute_day(date(2008,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 7.55) :- absolute_day(date(2006,6,30), ODay), absolute_day(date(2007,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 7.3) :- absolute_day(date(2005,6,30), ODay), absolute_day(date(2006,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 7.05) :- absolute_day(date(2004,6,30), ODay), absolute_day(date(2005,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 6.55) :- absolute_day(date(2003,6,30), ODay), absolute_day(date(2004,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 6.3) :- absolute_day(date(2002,6,30), ODay), absolute_day(date(2003,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 6.8) :- absolute_day(date(2001,6,30), ODay), absolute_day(date(2002,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 7.8) :- absolute_day(date(2000,6,30), ODay), absolute_day(date(2001,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 6.5) :- absolute_day(date(1999,6,30), ODay), absolute_day(date(2000,6,30), CDay), ODay < Day, Day =< CDay.
benchmark_interest_rate(Day, 6.7) :- absolute_day(date(1998,6,30), ODay), absolute_day(date(1999,6,30), CDay), ODay < Day, Day =< CDay.

% Predicates for asserting the fields of a loan repayment

% The date the repayment is to be paid
loan_rep_day(loan_repayment(Day, _), Day).
% The amount that constitutes the repayment. An amount of zero is used to indicate a new
% income year.
loan_rep_amount(loan_repayment(_, Amount), Amount).

% Predicates for asserting the fields of a loan agreement

% An identifier for a given loan agreement
loan_agr_contract_number(loan_agreement(Contract_Number, _, _, _, _, _), Contract_Number).
% The principal amount of the loan agreement
loan_agr_principal_amount(loan_agreement(_, Principal_Amount, _, _, _, _), Principal_Amount).
% The lodgement day of the whole agreement
loan_agr_lodgement_day(loan_agreement(_, _, Lodgement_Day, _, _, _), Lodgement_Day).
% The first absolute day of the first income year after the agreement is made
loan_agr_begin_day(loan_agreement(_, _, _, Begin_Day, _, _), Begin_Day).
% The term of the loan agreement in years
loan_agr_term(loan_agreement(_, _, _, _, Term, _), Term).
% A chronologically ordered list of loan agreement repayments. The latter repayments
% where the account balance is negative are ignored.
loan_agr_repayments(loan_agreement(_, _, _, _, _, Repayments), Repayments).

% Predicates for asserting the fields of a loan record

% Records are indexed in chronological order
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

% Asserts the necessary relations to get from one loan record to the next

loan_rec_aux(Repayments_Hd, Current_Rep_Amount, Current_Record_Number, Current_Day, Current_Balance, Interest_Amount, Next_Record) :-
	loan_rep_day(Repayments_Hd, Next_Day),
	benchmark_interest_rate(Current_Day, Interest_Rate),
	loan_rep_amount(Repayments_Hd, Current_Rep_Amount),
	Next_Record_Number is Current_Record_Number + 1,
	loan_rec_number(Next_Record, Next_Record_Number),
	loan_rec_opening_day(Next_Record, Current_Day), loan_rec_closing_day(Next_Record, Next_Day),
	Interest_Period is Next_Day - Current_Day,
	Interest_Amount is Current_Balance * Interest_Rate * Interest_Period / (100 * 365),
	loan_rec_opening_balance(Next_Record, Current_Balance),
	loan_rec_interest_rate(Next_Record, Interest_Rate),
	loan_rec_interest_amount(Next_Record, Interest_Amount),
	loan_rec_repayment_amount(Next_Record, Current_Rep_Amount).

% Relates a loan agreement to one of its records

loan_agr_record(Agreement, Record) :-
	loan_agr_principal_amount(Agreement, Current_Balance),
	loan_agr_begin_day(Agreement, Begin_Day),
	Current_Acc_Interest = 0,
	Current_Acc_Rep = 0,
	loan_agr_repayments(Agreement, [Repayments_Hd|Repayments_Tl]),
	Current_Record_Number = 0,
	Current_Day = Begin_Day,
	loan_rec_aux(Repayments_Hd, Current_Rep_Amount, Current_Record_Number, Current_Day, Current_Balance, Interest_Amount, Next_Record),
	New_Acc_Rep is Current_Acc_Rep + Current_Rep_Amount,
	Next_Acc_Interest is Current_Acc_Interest + Interest_Amount,
	Next_Balance is Current_Balance - Current_Rep_Amount,
	loan_rec_closing_balance(Next_Record, Next_Balance),
	(Record = Next_Record; loan_rec_record(Next_Record, Repayments_Tl, Next_Acc_Interest, New_Acc_Rep, Record)).

% Relates a loan record to one that follows it, in the case that it is not a year-end record

loan_rec_record(Current_Record, [Repayments_Hd|Repayments_Tl], Current_Acc_Interest, Current_Acc_Rep, Record) :-
	loan_rec_number(Current_Record, Current_Record_Number),
	loan_rec_closing_day(Current_Record, Current_Day),
	loan_rec_closing_balance(Current_Record, Current_Balance),
	loan_rec_aux(Repayments_Hd, Current_Rep_Amount, Current_Record_Number, Current_Day, Current_Balance, Interest_Amount, Next_Record),
	New_Acc_Rep is Current_Acc_Rep + Current_Rep_Amount,
	Next_Acc_Interest is Current_Acc_Interest + Interest_Amount,
	Next_Balance is Current_Balance - Current_Rep_Amount, Next_Balance > 0,
	loan_rec_closing_balance(Next_Record, Next_Balance),
	Current_Rep_Amount > 0,
	(Record = Next_Record; loan_rec_record(Next_Record, Repayments_Tl, Next_Acc_Interest, New_Acc_Rep, Record)).

% Relates a loan record to one that follows it, in the case that it is a year-end record

loan_rec_record(Current_Record, [Repayments_Hd|Repayments_Tl], Current_Acc_Interest, Current_Acc_Rep, Record) :-
	loan_rec_number(Current_Record, Current_Record_Number),
	loan_rec_closing_day(Current_Record, Current_Day),
	loan_rec_closing_balance(Current_Record, Current_Balance),
	loan_rec_aux(Repayments_Hd, Current_Rep_Amount, Current_Record_Number, Current_Day, Current_Balance, Interest_Amount, Next_Record),
	Next_Acc_Rep = 0,
	Next_Acc_Interest = 0,
	Next_Balance is Current_Balance + Current_Acc_Interest + Interest_Amount,
	loan_rec_closing_balance(Next_Record, Next_Balance),
	Current_Rep_Amount = 0,
	(Record = Next_Record; loan_rec_record(Next_Record, Repayments_Tl, Next_Acc_Interest, Next_Acc_Rep, Record)).

% If a loan repayment was made before lodgement day, it was effectively paid on the first
% absolute day of the first income year after the loan is made

loan_reps_shift(Begin_Day, Lodgement_Day, [Repayments_Hd|Repayments_Tl], Shifted) :-
	loan_rep_day(Repayments_Hd, Day),
	Day < Lodgement_Day,
	loan_rep_amount(Repayments_Hd, Amount),
	loan_reps_shift(Begin_Day, Lodgement_Day, Repayments_Tl, Shifted_Tl),
	Shifted = [loan_repayment(Begin_Day, Amount)|Shifted_Tl].

% Otherwise leave the repayments schedule unaltered

loan_reps_shift(_, Lodgement_Day, Repayments, Repayments) :-
	[Repayments_Hd|_] = Repayments,
	loan_rep_day(Repayments_Hd, Day),
	Day >= Lodgement_Day.

% Insert a repayment into a chronologically ordered list of repayments

loan_reps_insert_repayment(New_Repayment, [], [New_Repayment]).

loan_reps_insert_repayment(New_Repayment, [Repayments_Hd|Repayments_Tl], Inserted) :-
	loan_rep_day(Repayments_Hd, Hd_Day),
	loan_rep_day(New_Repayment, New_Day),
	Hd_Day > New_Day,
	Inserted = [New_Repayment|[Repayments_Hd|Repayments_Tl]].

loan_reps_insert_repayment(New_Repayment, [Repayments_Hd|Repayments_Tl], Inserted) :-
	loan_rep_day(Repayments_Hd, Hd_Day),
	loan_rep_day(New_Repayment, New_Day),
	Hd_Day =< New_Day,
	loan_reps_insert_repayment(New_Repayment, Repayments_Tl, Inserted_Tl),
	Inserted = [Repayments_Hd|Inserted_Tl].

% Insert payments of zero at year-ends to enable proper interest accumulation

loan_reps_insert_sentinels(_, 0, Repayments, Repayments).

loan_reps_insert_sentinels(Begin_Date, Year_Count, Repayments, Inserted) :-
	Year_Count > 0,
	date_add(Begin_Date, date(1, 0, 0), New_Begin_Date),
	absolute_day(New_Begin_Date, New_Begin_Day),
	loan_reps_insert_repayment(loan_repayment(New_Begin_Day, 0), Repayments, New_Repayments),
	New_Year_Count is Year_Count - 1,
	loan_reps_insert_sentinels(New_Begin_Date, New_Year_Count, New_Repayments, Inserted).

% From the given agreement, prepares a new loan agreement suitable for calculations 

loan_agr_prepare(Agreement, New_Agreement) :-
	loan_agr_contract_number(Agreement, Contract_Number),
	loan_agr_contract_number(New_Agreement, Contract_Number),
	loan_agr_principal_amount(Agreement, Principal_Amount),
	loan_agr_principal_amount(New_Agreement, Principal_Amount),
	loan_agr_lodgement_day(Agreement, Lodgement_Day),
	loan_agr_lodgement_day(New_Agreement, Lodgement_Day),
	loan_agr_begin_day(Agreement, Begin_Day),
	loan_agr_begin_day(New_Agreement, Begin_Day),
	loan_agr_term(Agreement, Term),
	loan_agr_term(New_Agreement, Term),
	loan_agr_repayments(Agreement, Repayments_A),
	loan_reps_shift(Begin_Day, Lodgement_Day, Repayments_A, Repayments_B),
	gregorian_date(Begin_Day, Begin_Date),
	loan_reps_insert_sentinels(Begin_Date, Term, Repayments_B, Repayments_C),
	loan_agr_repayments(New_Agreement, Repayments_C).


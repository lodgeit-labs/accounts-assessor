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
loan_agr_contract_number(loan_agreement(Contract_Number, _, _, _, _, _, _, _, _), Contract_Number).
% The principal amount of the loan agreement
loan_agr_principal_amount(loan_agreement(_, Principal_Amount, _, _, _, _, _, _, _), Principal_Amount).
% The lodgement day of the whole agreement
loan_agr_lodgement_day(loan_agreement(_, _, Lodgement_Day, _, _, _, _, _, _), Lodgement_Day).
% The first absolute day of the first income year after the loan is made
loan_agr_begin_day(loan_agreement(_, _, _, Begin_Day, _, _, _, _, _), Begin_Day).
% The term of the loan agreement in years
loan_agr_term(loan_agreement(_, _, _, _, Term, _, _, _, _), Term).
% For internal usage, user should always set this to 0
loan_agr_current_record(loan_agreement(_, _, _, _, _, Current_Record, _, _, _), Current_Record).
% For internal usage, user should always set this to 0
% The interest accumulated since the beginning of this income year
loan_agr_accumulated_interest(loan_agreement(_, _, _, _, _, _, Accumulated_Interest, _, _), Accumulated_Interest).
% For internal usage, user should always set this to 0
% The repayments accumulated since the beginning of this income year
loan_agr_accumulated_repayment(loan_agreement(_, _, _, _, _, _, _, Accumulated_Repayment, _), Accumulated_Repayment).
% A chronologically ordered list of loan agreement repayments. The latter repayments
% where the account balance is negative are ignored.
loan_agr_repayments(loan_agreement(_, _, _, _, _, _, _, _, Repayments), Repayments).

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

loan_agr_record(Agreement, Record) :-
	loan_agr_current_record(Agreement, 0),
	loan_agr_contract_number(Agreement, Contract_Number), loan_agr_contract_number(New_Agreement, Contract_Number),
	loan_agr_principal_amount(Agreement, Principal_Amount), loan_agr_principal_amount(New_Agreement, Principal_Amount),
	loan_agr_lodgement_day(Agreement, Lodgement_Day), loan_agr_lodgement_day(New_Agreement, Lodgement_Day),
	loan_agr_term(Agreement, Term), loan_agr_term(New_Agreement, Term),
	loan_agr_begin_day(Agreement, Current_Day), loan_agr_begin_day(New_Agreement, Current_Day),
	loan_agr_repayments(Agreement, [Repayments_Hd|Repayments_Tl]), loan_agr_repayments(New_Agreement, Repayments_Tl),
	loan_rep_day(Repayments_Hd, Next_Day), benchmark_interest_rate(Next_Day, Interest_Rate),
	loan_rep_amount(Repayments_Hd, Current_Rep_Amount),
	Principal_Amount > 0,
	
	loan_rec_number(Next_Record, 0),
	loan_rec_opening_day(Next_Record, Current_Day), loan_rec_closing_day(Next_Record, Next_Day),
	loan_agr_accumulated_repayment(New_Agreement, Current_Rep_Amount),
	Interest_Period is Next_Day - Current_Day,
	Interest_Amount is Principal_Amount * Interest_Rate * Interest_Period / (100 * 365),
	loan_rec_interest_rate(Next_Record, Interest_Rate),
	loan_rec_interest_amount(Next_Record, Interest_Amount),
	loan_agr_accumulated_interest(New_Agreement, Interest_Amount),
	loan_rec_repayment_amount(Next_Record, Current_Rep_Amount),
	loan_rec_opening_balance(Next_Record, Principal_Amount),
	Closing_Balance is Principal_Amount - Current_Rep_Amount,
	loan_rec_closing_balance(Next_Record, Closing_Balance),
	loan_agr_current_record(New_Agreement, Next_Record),
	(Record = Next_Record; loan_agr_record(New_Agreement, Record)).

loan_agr_record(Agreement, Record) :-
	loan_agr_current_record(Agreement, Current_Record),
	Current_Record \= 0,
	loan_agr_contract_number(Agreement, Contract_Number), loan_agr_contract_number(New_Agreement, Contract_Number),
	loan_agr_principal_amount(Agreement, Principal_Amount), loan_agr_principal_amount(New_Agreement, Principal_Amount),
	loan_agr_lodgement_day(Agreement, Lodgement_Day), loan_agr_lodgement_day(New_Agreement, Lodgement_Day),
	loan_agr_term(Agreement, Term), loan_agr_term(New_Agreement, Term),
	loan_agr_begin_day(Agreement, Begin_Day), loan_agr_begin_day(New_Agreement, Begin_Day),
	loan_agr_repayments(Agreement, [Repayments_Hd|Repayments_Tl]), loan_agr_repayments(New_Agreement, Repayments_Tl),
	loan_rep_day(Repayments_Hd, Next_Day), benchmark_interest_rate(Next_Day, Interest_Rate),
	loan_rep_amount(Repayments_Hd, Current_Rep_Amount),
	Current_Rep_Amount > 0,
	
	loan_rec_number(Current_Record, Current_Record_Number),
	Next_Record_Number is Current_Record_Number + 1,
	loan_rec_number(Next_Record, Next_Record_Number),
	loan_agr_accumulated_repayment(Agreement, Current_Acc_Rep),
	loan_rec_closing_day(Current_Record, Current_Day),
	loan_rec_opening_day(Next_Record, Current_Day), loan_rec_closing_day(Next_Record, Next_Day),
	New_Acc_Rep is Current_Acc_Rep + Current_Rep_Amount,
	loan_agr_accumulated_repayment(New_Agreement, New_Acc_Rep),
	loan_rec_closing_balance(Current_Record, Current_Balance),
	Interest_Period is Next_Day - Current_Day,
	Interest_Amount is Current_Balance * Interest_Rate * Interest_Period / (100 * 365),
	loan_rec_interest_rate(Next_Record, Interest_Rate),
	loan_rec_interest_amount(Next_Record, Interest_Amount),
	loan_agr_accumulated_interest(Agreement, Current_Acc_Interest),
	Next_Acc_Interest is Current_Acc_Interest + Interest_Amount,
	loan_agr_accumulated_interest(New_Agreement, Next_Acc_Interest),
	loan_rec_repayment_amount(Next_Record, Current_Rep_Amount),
	loan_rec_opening_balance(Next_Record, Current_Balance),
	Next_Balance is Current_Balance - Current_Rep_Amount, Next_Balance > 0,
	loan_rec_closing_balance(Next_Record, Next_Balance),
	loan_agr_current_record(New_Agreement, Next_Record),
	(Record = Next_Record; loan_agr_record(New_Agreement, Record)).

loan_agr_record(Agreement, Record) :-
	loan_agr_current_record(Agreement, Current_Record),
	Current_Record \= 0,
	loan_agr_contract_number(Agreement, Contract_Number), loan_agr_contract_number(New_Agreement, Contract_Number),
	loan_agr_principal_amount(Agreement, Principal_Amount), loan_agr_principal_amount(New_Agreement, Principal_Amount),
	loan_agr_lodgement_day(Agreement, Lodgement_Day), loan_agr_lodgement_day(New_Agreement, Lodgement_Day),
	loan_agr_term(Agreement, Term), loan_agr_term(New_Agreement, Term),
	loan_agr_begin_day(Agreement, Begin_Day), loan_agr_begin_day(New_Agreement, Begin_Day),
	loan_agr_repayments(Agreement, [Repayments_Hd|Repayments_Tl]), loan_agr_repayments(New_Agreement, Repayments_Tl),
	loan_rep_day(Repayments_Hd, Next_Day), benchmark_interest_rate(Next_Day, Interest_Rate),
	loan_rep_amount(Repayments_Hd, 0),
	loan_agr_accumulated_interest(New_Agreement, 0), loan_agr_accumulated_repayment(New_Agreement, 0),
	
	loan_rec_number(Current_Record, Current_Record_Number),
	Next_Record_Number is Current_Record_Number + 1,
	loan_rec_number(Next_Record, Next_Record_Number),
	loan_agr_accumulated_repayment(Agreement, Current_Acc_Rep),
	loan_rec_closing_day(Current_Record, Current_Day),
	loan_rec_opening_day(Next_Record, Current_Day), loan_rec_closing_day(Next_Record, Next_Day),
	loan_rec_closing_balance(Current_Record, Current_Balance),
	Interest_Period is Next_Day - Current_Day,
	Interest_Amount is Current_Balance * Interest_Rate * Interest_Period / (100 * 365),
	loan_rec_interest_rate(Next_Record, Interest_Rate),
	loan_rec_interest_amount(Next_Record, Interest_Amount),
	loan_agr_accumulated_interest(Agreement, Acc_Interest),
	Next_Balance is Current_Balance + Acc_Interest + Interest_Amount,
	loan_rec_repayment_amount(Next_Record, 0),
	loan_rec_opening_balance(Next_Record, Current_Balance),
	loan_rec_closing_balance(Next_Record, Next_Balance),
	loan_agr_current_record(New_Agreement, Next_Record),
	(Record = Next_Record; loan_agr_record(New_Agreement, Record)).


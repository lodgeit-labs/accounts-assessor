% The purpose of the following program is to derive information about a given hire
% purchase arrangement when given a list of potential installments for it. That is, this
% program will tell you what the closing balance would be after some sequence of
% installments has been paid. It will tell you how much interest you would have paid by
% the close of the arrangement. And it will tell you other relevant information.
% The program will ignore the latter potential installments that would make the balance
% negative.

% This program is part of a larger system for validating and correcting balance sheets.
% More precisely, accounting principles require that the transactions that occur in a hire
% purchase arrangement are summarized in balance sheets. This program calculates those
% summary values directly from the original data and ultimately will be expected to add
% correction entries to the balance sheet when it is in error.

% Some facts about the Gregorian calendar, needed to count days between dates

leap_year(Year) :- 0 is mod(Year, 4), X is mod(Year, 100), X =\= 0.

leap_year(Year) :- 0 is mod(Year, 400).

common_year(Year) :-
	((Y is mod(Year, 4), Y =\= 0); 0 is mod(Year, 100)),
	Z is mod(Year, 400), Z =\= 0.

days_in(_, 1, 31). days_in(Year, 2, 29) :- leap_year(Year).
days_in(Year, 2, 28) :- common_year(Year). days_in(_, 3, 31). days_in(_, 4, 30).
days_in(_, 5, 31). days_in(_, 6, 30). days_in(_, 7, 31). days_in(_, 8, 31).
days_in(_, 9, 30). days_in(_, 10, 31). days_in(_, 11, 30). days_in(_, 12, 31).

days_in(Year, Month, Days) :-
	Month =< 0,
	Closer_Year is Year - 1,
	Closer_Year_Month is 12 + Month,
	days_in(Closer_Year, Closer_Year_Month, Days).

days_in(Year, Month, Days) :-
	Month > 12,
	Closer_Year is Year + 1,
	Closer_Year_Month is Month - 12,
	days_in(Closer_Year, Closer_Year_Month, Days).

% A generalized date, date(Y, M, D), means the same thing as a normal date when its value
% is that of a normal date. In addition date(2006, 0, 1) refers to the month before
% date(2006, 1, 1), date(2006, -1, 1) to the month before that, etc. Also date(2006, 5, 0)
% refers to the day before date(2006, 5, 1), date(2006, 5, -1) to the day before that, etc.
% Useful for specifying that payments happen at month-ends.

% Predicates for counting the number of days between two generalized dates

day_diff(date(Year, From_Month, From_Day), date(Year, To_Month, To_Day), Days) :-
	From_Month < To_Month,
	New_To_Month is To_Month - 1,
	days_in(Year, New_To_Month, New_To_Month_Days),
	New_To_Day is To_Day + New_To_Month_Days,
	day_diff(date(Year, From_Month, From_Day), date(Year, New_To_Month, New_To_Day), Days), !.

day_diff(date(Year, From_Month, From_Day), date(Year, To_Month, To_Day), Days) :-
	To_Month < From_Month,
	days_in(Year, To_Month, To_Month_Days),
	New_To_Month is To_Month + 1,
	New_To_Day is To_Day - To_Month_Days,
	day_diff(date(Year, From_Month, From_Day), date(Year, New_To_Month, New_To_Day), Days), !.

day_diff(date(From_Year, From_Month, From_Day), date(To_Year, To_Month, To_Day), Days) :-
	From_Year < To_Year,
	New_To_Year is To_Year - 1,
	New_To_Month is To_Month + 12,
	day_diff(date(From_Year, From_Month, From_Day), date(New_To_Year, New_To_Month, To_Day), Days), !.

day_diff(date(From_Year, From_Month, From_Day), date(To_Year, To_Month, To_Day), Days) :-
	To_Year < From_Year,
	New_To_Year is To_Year + 1,
	New_To_Month is To_Month - 12,
	day_diff(date(From_Year, From_Month, From_Day), date(New_To_Year, New_To_Month, To_Day), Days), !.

day_diff(date(Year, Month, From_Day), date(Year, Month, To_Day), Diff) :-
	Diff is To_Day - From_Day.

% Internal representation for dates is absolute day count since 1st January 2001

absolute_day(Date, Day) :- day_diff(date(2000, 1, 1), Date, Day).

% Predicates for asserting the fields of a potential hire purchase installment

% The date the potential installment is to be paid
hp_pot_inst_day(hp_pot_inst(Day, _), Day).
% The amount that constitutes the potential installment
hp_pot_inst_amount(hp_pot_inst(_, Installment), Installment).

% Predicates for asserting the fields of a hire purchase arrangement

% An identifier for a given hire purchase arrangement
hp_arr_contract_number(hp_arrangement(Contract_Number, _, _, _, _), Contract_Number).
% The opening balance of the whole arrangement
hp_arr_cash_price(hp_arrangement(_, Cash_Price, _, _, _), Cash_Price).
% The beginning day of the whole arrangement
hp_arr_begin_day(hp_arrangement(_, _, Begin_Day, _, _), Begin_Day).
% The stated annual interest rate of the arrangement
hp_arr_interest_rate(hp_arrangement(_, _, _, Interest_Rate, _), Interest_Rate).
% For internal usage, user should always set this to 1
hp_arr_record_offset(hp_arrangement(_, _, _, _, Record_Offset), Record_Offset).

% Predicates for asserting the fields of a hire purchase record

% Records are indexed in chronological order
hp_rec_number(hp_record(Record_Number, _, _, _, _, _), Record_Number).
% The balance of the payment at the beginning of the given period
hp_rec_opening_balance(hp_record(_, Opening_Balance, _, _, _, _), Opening_Balance).
% The interest rate being applied to the opening balance
hp_rec_interest_rate(hp_record(_, _, Interest_Rate, _, _, _), Interest_Rate).
% The calculated interest for the given period
hp_rec_interest_amount(hp_record(_, _, _, Interest_Amount, _, _), Interest_Amount).
% The amount being paid towards the good in the given period
hp_rec_installment_amount(hp_record(_, _, _, _, Installment_Amount, _), Installment_Amount).
% The balance of the payment at the end of the given period
hp_rec_closing_balance(hp_record(_, _, _, _, _, Closing_Balance), Closing_Balance).

% A predicate for generating Num installments starting at the given date and occurring
% after every delta date with a payment amount of Installment_Amount.

installments(_, 0, _, _, []).

installments(date(From_Year, From_Month, From_Day), Num, date(Delta_Year, Delta_Month, Delta_Day), Installment_Amount, Range) :-
	Next_Year is From_Year + Delta_Year,
	Next_Month is From_Month + Delta_Month,
	Next_Day is From_Day + Delta_Day,
	Next_Num is Num - 1,
	installments(date(Next_Year, Next_Month, Next_Day), Next_Num, date(Delta_Year, Delta_Month, Delta_Day), Installment_Amount, Range_Tl),
	absolute_day(date(From_Year, From_Month, From_Day), Installment_Day),
	Range = [hp_pot_inst(Installment_Day, Installment_Amount) | Range_Tl], !.

% A predicate for inserting balloon payment into a list of installments

insert_balloon(Balloon_Installment, [], [Balloon_Installment]).

insert_balloon(Balloon_Installment, [Installments_Hd | Installments_Tl], Result) :-
	hp_pot_inst_day(Balloon_Installment, Bal_Inst_Day),
	hp_pot_inst_day(Installments_Hd, Inst_Hd_Day),
	Bal_Inst_Day =< Inst_Hd_Day,
	Result = [Balloon_Installment | [Installments_Hd | Installments_Tl]].

insert_balloon(Balloon_Installment, [Installments_Hd | Installments_Tl], Result) :-
	hp_pot_inst_day(Balloon_Installment, Bal_Inst_Day),
	hp_pot_inst_day(Installments_Hd, Inst_Hd_Day),
	Bal_Inst_Day > Inst_Hd_Day,
	insert_balloon(Balloon_Installment, Installments_Tl, New_Installments_Tl),
	Result = [Installments_Hd | New_Installments_Tl].

% Predicate relating a hire purchase record to an arrangement and potential installments.
% The logic is that a record is related to a hire purchase arrangement and list of
% potential installments if it is their first, otherwise it must be related to the
% tail of the potential installments and the hypothetical hire purchase arrangement that
% is the same as the present one but had the first potential installment applied to it.
% This logic is used instead of relating records to their predecessors because it allows
% Prolog to systematically find all the hire purchase records corresponding to a given
% arrangement.

record(Arrangement, [Installments_Hd|_], Record) :-
	hp_rec_number(Record, Record_Number), hp_arr_record_offset(Arrangement, Record_Number),
	hp_rec_opening_balance(Record, Cash_Price), hp_arr_cash_price(Arrangement, Cash_Price),
	hp_arr_begin_day(Arrangement, Prev_Inst_Day),
	hp_rec_interest_rate(Record, Interest_Rate), hp_arr_interest_rate(Arrangement, Interest_Rate),
	hp_pot_inst_day(Installments_Hd, Current_Inst_Day),
	hp_pot_inst_amount(Installments_Hd, Current_Inst_Amount),
	Installment_Period is Current_Inst_Day - Prev_Inst_Day,
	Interest_Amount is Cash_Price * Interest_Rate * Installment_Period / (100 * 365),
	hp_rec_interest_amount(Record, Interest_Amount),
	hp_rec_installment_amount(Record, Current_Inst_Amount),
	Closing_Balance is Cash_Price + Interest_Amount - Current_Inst_Amount,
	hp_rec_closing_balance(Record, Closing_Balance),
	Closing_Balance >= 0.

record(Arrangement, [Installments_Hd|Installments_Tl], Record) :-
	hp_arr_record_offset(Arrangement, Record_Offset),
	New_Record_Offset is Record_Offset + 1,
	hp_arr_record_offset(New_Arrangement, New_Record_Offset),
	hp_arr_contract_number(Arrangement, Contract_Number), hp_arr_contract_number(New_Arrangement, Contract_Number),
	hp_arr_cash_price(Arrangement, Cash_Price),
	hp_arr_begin_day(Arrangement, Prev_Inst_Day),
	hp_arr_interest_rate(Arrangement, Interest_Rate), hp_arr_interest_rate(New_Arrangement, Interest_Rate),
	hp_pot_inst_day(Installments_Hd, Current_Inst_Day),
	hp_pot_inst_amount(Installments_Hd, Current_Inst_Amount),
	hp_arr_begin_day(New_Arrangement, Current_Inst_Day),
	Installment_Period is Current_Inst_Day - Prev_Inst_Day,
	Interest_Amount is Cash_Price * Interest_Rate * Installment_Period / (100 * 365),
	New_Cash_Price is Cash_Price + Interest_Amount - Current_Inst_Amount,
	New_Cash_Price >= 0,
	hp_arr_cash_price(New_Arrangement, New_Cash_Price),
	record(New_Arrangement, Installments_Tl, Record).

% Some predicates on hire purchase arrangements and potential installments for them

records(Arrangement, Potential_Installments, Records) :-
	findall(Record, record(Arrangement, Potential_Installments, Record), Records).

record_count(Arrangement, Potential_Installments, Record_Count) :-
	records(Arrangement, Potential_Installments, Records),
	length(Records, Record_Count).

total_payment(Arrangement, Potential_Installments, Total_Payment) :-
	findall(Installment_Amount,
		(record(Arrangement, Potential_Installments, Record), hp_rec_installment_amount(Record, Installment_Amount)),
		Installment_Amounts),
	sum_list(Installment_Amounts, Total_Payment).

total_interest(Arrangement, Potential_Installments, Total_Interest) :-
	findall(Interest_Amount,
		(record(Arrangement, Potential_Installments, Record), hp_rec_interest_amount(Record, Interest_Amount)),
		Interest_Amounts),
	sum_list(Interest_Amounts, Total_Interest).

% Predicate to generate a range of values through stepping forwards from a start point

range(Start, _, _, Value) :-
	Start = Value.

range(Start, Stop, Step, Value) :-
	Next_Start is Start + Step,
	Next_Start < Stop,
	range(Next_Start, Stop, Step, Value).

% Now for some examples:

% Add a ballon to a regular schedule of installments:
% installments(date(2015, 1, 16), 100, date(0, 1, 0), 200.47, Installments),
% absolute_day(date(2014, 12, 16), Balloon_Day),
% insert_balloon(hp_pot_inst(Balloon_Day, 1000), Installments, Installments_With_Balloon).
% Result:
% Installments = [hp_pot_inst(5494, 200.47), hp_pot_inst(5525, 200.47), hp_pot_inst(5553, 200.47), ...|...],
% Balloon_Day = 5463,
% Installments_With_Balloon = [hp_pot_inst(5463, 1000), hp_pot_inst(5494, 200.47), hp_pot_inst(5525, 200.47), ...|...]

% What is the total amount the customer will pay over the course of the hire purchase
% arrangement?
% absolute_day(date(2014, 12, 16), Begin_Day),
% installments(date(2015, 1, 16), 36, date(0, 1, 0), 200.47, Installments),
% total_payment(hp_arrangement(0, 5953.2, Begin_Day, 13, 1), Installments, Total_Payment).
% Result: Total_Payment = 7216.920000000002.

% What is the total interest the customer will pay over the course of the hire purchase
% arrangement?
% absolute_day(date(2014, 12, 16), Begin_Day),
% installments(date(2015, 1, 16), 36, date(0, 1, 0), 200.47, Installments),
% total_interest(hp_arrangement(0, 5953.2, Begin_Day, 13, 1), Installments, Total_Interest).
% Result: Total_Interest = 1269.925914056732.

% Give me all the records of a hire purchase arrangement:
% absolute_day(date(2014, 12, 16), Begin_Day),
% installments(date(2015, 1, 16), 36, date(0, 1, 0), 200.47, Installments),
% record(hp_arrangement(0, 5953.2, Begin_Day, 13, 1), Installments, Record).
% Result:
% Record = hp_record(1, 5953.2, 13, 65.7298520547945, 200.47, 5818.459852054794) ;
% Record = hp_record(2, 5818.459852054794, 13, 64.24217316104335, 200.47, 5682.232025215837) ;
% ...
% Record = hp_record(36, 204.4909423440125, 13, 2.184971712716846, 200.47, 6.205914056729341) ;

% Split the range between 10 and 20 into 100 equally spaced intervals and give me their
% boundaries:
% range(10, 20, 0.1, X).
% Result:
% X = 10 ;
% X = 10.1 ;
% X = 10.2 ;
% ...
% X = 19.900000000000034 ;

% Give me the interest rates in the range of 10% to 20% that will cause the hire purchase
% arrangement to conclude in exactly 36 months:
% range(10, 20, 0.1, Interest_Rate),
% absolute_day(date(2014, 12, 16), Begin_Day),
% installments(date(2015, 1, 16), 100, date(0, 1, 0), 200.47, Installments),
% record_count(hp_arrangement(0, 5953.2, Begin_Day, Interest_Rate, 1), Installments, 36).
% Result:
% Interest_Rate = 12.99999999999999 ;
% Interest_Rate = 13.099999999999989 ;
% ...
% Interest_Rate = 14.399999999999984 ;
% Note that several to different interest rates can result in hire purchase
% arrangements with the same duration. In this case, it is only the closing balance
% after the last installment that changes.


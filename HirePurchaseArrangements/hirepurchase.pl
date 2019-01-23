% Some facts about the Gregorian calendar, needed to count days between dates

leap_year(Year) :- 0 is mod(Year, 4), X is mod(Year, 100), X =\= 0.

leap_year(Year) :- 0 is mod(Year, 400).

common_year(Year) :-
	((Y is mod(Year, 4), Y =\= 0); 0 is mod(Year, 100)),
	Z is mod(Year, 400), Z =\= 0.

days_in(_, 1, 31).
days_in(Year, 2, 29) :- leap_year(Year).
days_in(Year, 2, 28) :- common_year(Year).
days_in(_, 3, 31).
days_in(_, 4, 30).
days_in(_, 5, 31).
days_in(_, 6, 30).
days_in(_, 7, 31).
days_in(_, 8, 31).
days_in(_, 9, 30).
days_in(_, 10, 31).
days_in(_, 11, 30).
days_in(_, 12, 31).

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

% Internal representation for dates is absolute day count since 1st January 2001

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

% A predicate for generating regular sequences of installments with constant payments

installments(_, 0, _, _, []).

installments(date(From_Year, From_Month, From_Day), Num, date(Delta_Year, Delta_Month, Delta_Day), Installment_Amount, Range) :-
	Next_Year is From_Year + Delta_Year,
	Next_Month is From_Month + Delta_Month,
	Next_Day is From_Day + Delta_Day,
	Next_Num is Num - 1,
	installments(date(Next_Year, Next_Month, Next_Day), Next_Num, date(Delta_Year, Delta_Month, Delta_Day), Installment_Amount, Sub_Range),
	day_diff(date(2000, 1, 1), date(From_Year, From_Month, From_Day), Installment_Day),
	Range = [hp_installment(Installment_Day, Installment_Amount) | Sub_Range], !.

% A predicate for inserting balloon payment into a list of installments

insert_balloon(Balloon_Installment, [], [Balloon_Installment]).

insert_balloon(Balloon_Installment, [Installments_Hd | Installments_Tl], Result) :-
	hp_inst_date(Balloon_Installment, Bal_Inst_Date),
	hp_inst_date(Installments_Hd, Inst_Hd_Date),
	Bal_Inst_Date =< Inst_Hd_Date,
	Result = [Balloon_Installment | [Installments_Hd | Installments_Tl]].

insert_balloon(Balloon_Installment, [Installments_Hd | Installments_Tl], Result) :-
	hp_inst_date(Balloon_Installment, Bal_Inst_Date),
	hp_inst_date(Installments_Hd, Inst_Hd_Date),
	Bal_Inst_Date > Inst_Hd_Date,
	insert_balloon(Balloon_Installment, Installments_Tl, New_Installments_Tl),
	Result = [Installments_Hd | New_Installments_Tl].

% Predicates for asserting the fields of a hire purchase installment

% The date the installment is to be paid
hp_inst_date(hp_installment(Date, _), Date).
% The amount that constitutes the installment
hp_inst_amount(hp_installment(_, Installment), Installment).

% Predicates for asserting the fields of a hire purchase arrangement

% An identifier for a given hire purchase arrangement
hp_arr_contract_number(hp_arrangement(Contract_Number, _, _, _, _, _), Contract_Number).
% The opening balance of the whole arrangement
hp_arr_cash_price(hp_arrangement(_, Cash_Price, _, _, _, _), Cash_Price).
% The beginning date of the whole arrangement
hp_arr_begin_date(hp_arrangement(_, _, Begin_Date, _, _, _), Begin_Date).
% The stated annual interest rate of the arrangement
hp_arr_interest_rate(hp_arrangement(_, _, _, Interest_Rate, _, _), Interest_Rate).
% A chronologically ordered list of pairs of installment dates and amounts
hp_arr_installments(hp_arrangement(_, _, _, _, Installments, _), Installments).
% For internal usage, user should always set this to 1
hp_arr_record_offset(hp_arrangement(_, _, _, _, _, Record_Offset), Record_Offset).

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

% Predicate relating a hire purchase record to an agreement. The logic is that a record
% belongs to a hire purchase arrangement if it is its first, otherwise it must belong
% to the hypothetical hire purchase arrangement that is the same as the present one
% but that starts in the second period. This logic is used instead of relating records
% to their predecessors because it allows Prolog to systematically find all the hire
% purchase records corresponding to a given arrangement.

record_of_hp_arr(Arrangement, Record) :-
	hp_rec_number(Record, Record_Number), hp_arr_record_offset(Arrangement, Record_Number),
	hp_rec_opening_balance(Record, Cash_Price), hp_arr_cash_price(Arrangement, Cash_Price),
	hp_arr_begin_date(Arrangement, Prev_Inst_Date),
	hp_rec_interest_rate(Record, Interest_Rate), hp_arr_interest_rate(Arrangement, Interest_Rate),
	hp_arr_installments(Arrangement, [Installments_Hd|_]),
	hp_inst_date(Installments_Hd, Current_Inst_Date),
	hp_inst_amount(Installments_Hd, Current_Inst_Amount),
	Installment_Period is Current_Inst_Date - Prev_Inst_Date,
	Interest_Amount is Cash_Price * Interest_Rate * Installment_Period / (100 * 365),
	hp_rec_interest_amount(Record, Interest_Amount),
	hp_rec_installment_amount(Record, Current_Inst_Amount),
	Closing_Balance is Cash_Price + Interest_Amount - Current_Inst_Amount,
	hp_rec_closing_balance(Record, Closing_Balance),
	Closing_Balance >= 0.

record_of_hp_arr(Arrangement, Record) :-
	hp_arr_record_offset(Arrangement, Record_Offset),
	New_Record_Offset is Record_Offset + 1,
	hp_arr_record_offset(New_Arrangement, New_Record_Offset),
	hp_arr_contract_number(Arrangement, Contract_Number), hp_arr_contract_number(New_Arrangement, Contract_Number),
	hp_arr_cash_price(Arrangement, Cash_Price),
	hp_arr_begin_date(Arrangement, Prev_Inst_Date),
	hp_arr_interest_rate(Arrangement, Interest_Rate), hp_arr_interest_rate(New_Arrangement, Interest_Rate),
	hp_arr_installments(Arrangement, [Installments_Hd|Installments_Tl]),
	hp_inst_date(Installments_Hd, Current_Inst_Date),
	hp_inst_amount(Installments_Hd, Current_Inst_Amount),
	hp_arr_begin_date(New_Arrangement, Current_Inst_Date),
	hp_arr_installments(New_Arrangement, Installments_Tl),
	Installment_Period is Current_Inst_Date - Prev_Inst_Date,
	Interest_Amount is Cash_Price * Interest_Rate * Installment_Period / (100 * 365),
	New_Cash_Price is Cash_Price + Interest_Amount - Current_Inst_Amount,
	New_Cash_Price >= 0,
	hp_arr_cash_price(New_Arrangement, New_Cash_Price),
	record_of_hp_arr(New_Arrangement, Record).

% Some more predicates for hire purchase arrangements

records_of_hp_arr(Arrangement, Records) :-
	findall(Record, record_of_hp_arr(Arrangement, Record), Records).

record_count_of_hp_arr(Arrangement, Record_Count) :-
	records_of_hp_arr(Arrangement, Records),
	length(Records, Record_Count).

total_payment_of_hp_arr(Arrangement, Total_Payment) :-
	findall(Installment_Amount, (record_of_hp_arr(Arrangement, Record), hp_rec_installment_amount(Record, Installment_Amount)),
		Installment_Amounts),
	sum_list(Installment_Amounts, Total_Payment).

total_interest_of_hp_arr(Arrangement, Total_Interest) :-
	findall(Interest_Amount, (record_of_hp_arr(Arrangement, Record), hp_rec_interest_amount(Record, Interest_Amount)),
		Interest_Amounts),
	sum_list(Interest_Amounts, Total_Interest).

% Some predicates for generating arithmetic sequences of numbers

% Predicate to generate a range of values through stepping forwards from a start point

range(Start, _, _, Value) :-
	Start = Value.

range(Start, Stop, Step, Value) :-
	Next_Start is Start + Step,
	Next_Start < Stop,
	range(Next_Start, Stop, Step, Value).

% Now for some examples:

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
% arrangement to conclude in exactly 36 months.
% range(10, 20, 0.1, Interest_Rate),
% day_diff(date(2000, 1, 1), date(2014, 12, 16), Begin_Date),
% installments(date(2015, 1, 16), 100, date(0, 1, 0), 200.47, Installments),
% record_count_of_hp_arr(hp_arrangement(0, 5953.2, Begin_Date, Interest_Rate, Installments, 1), 36).
% Result:
% Interest_Rate = 12.99999999999999 ;
% Interest_Rate = 13.099999999999989 ;
% ...
% Interest_Rate = 14.399999999999984 ;
% Note that instead of getting Prolog to try to solve a system of equations (and hang),
% I cheated by just getting Prolog to exhaustively search a finite domain of generated
% values.
% Also note that several to different interest rates can result in hire purchase
% arrangements with the same duration. In this case, it is only the closing balance
% after the last installment that changes.

% What is the total amount the customer will pay over the course of the hire purchase
% arrangement?
% day_diff(date(2000, 1, 1), date(2014, 12, 16), Begin_Date),
% installments(date(2015, 1, 16), 36, date(0, 1, 0), 200.47, Installments),
% total_payment_of_hp_arr(hp_arrangement(0, 5953.2, Begin_Date, 13, Installments, 1), Total_Payment).
% Result: Total_Payment = 7216.920000000002.

% What is the total interest the customer will pay over the course of the hire purchase
% arrangement?
% day_diff(date(2000, 1, 1), date(2014, 12, 16), Begin_Date),
% installments(date(2015, 1, 16), 36, date(0, 1, 0), 200.47, Installments),
% total_interest_of_hp_arr(hp_arrangement(0, 5953.2, Begin_Date, 13, Installments, 1), Total_Interest).
% Result: Total_Interest = 1269.925914056732.

% Give me all the records of a hire purchase arrangement:
% day_diff(date(2000, 1, 1), date(2014, 12, 16), Begin_Date),
% installments(date(2015, 1, 16), 36, date(0, 1, 0), 200.47, Installments),
% record_of_hp_arr(hp_arrangement(0, 5953.2, Begin_Date, 13, Installments, 1), Records).
% Result:
% Records = hp_record(1, 5953.2, 13, 65.7298520547945, 200.47, 5818.459852054794) ;
% Records = hp_record(2, 5818.459852054794, 13, 64.24217316104335, 200.47, 5682.232025215837) ;
% ...
% Records = hp_record(36, 204.4909423440125, 13, 2.184971712716846, 200.47, 6.205914056729341) ;


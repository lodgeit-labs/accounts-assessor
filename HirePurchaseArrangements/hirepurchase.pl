% Predicates for asserting the fields of a hire purchase arrangement

% An identifier for a given hire purchase arrangement
hp_arr_contract_number(hp_arrangement(Contract_Number, _, _, _, _, _), Contract_Number).
% The opening balance of the whole arrangement
hp_arr_cash_price(hp_arrangement(_, Cash_Price, _, _, _, _), Cash_Price).
% The stated annual interest rate of the arrangement
hp_arr_interest_rate(hp_arrangement(_, _, Interest_Rate, _, _, _), Interest_Rate).
% The number of months between each installment
hp_arr_installment_period(hp_arrangement(_, _, _, Installment_Period, _, _), Installment_Period).
% The amount that is periodically paid towards the good
hp_arr_installment_amount(hp_arrangement(_, _, _, _, Installment_Amount, _), Installment_Amount).
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
	hp_rec_interest_rate(Record, Interest_Rate), hp_arr_interest_rate(Arrangement, Interest_Rate),
	hp_arr_installment_period(Arrangement, Installment_Period),
	Interest_Amount is Cash_Price * Interest_Rate * Installment_Period / (100 * 12),
	hp_rec_interest_amount(Record, Interest_Amount),
	hp_rec_installment_amount(Record, Installment_Amount), hp_arr_installment_amount(Arrangement, Installment_Amount),
	Closing_Balance is Cash_Price + Interest_Amount - Installment_Amount,
	hp_rec_closing_balance(Record, Closing_Balance),
	Closing_Balance >= 0.

record_of_hp_arr(Arrangement, Record) :-
	hp_arr_record_offset(Arrangement, Record_Offset),
	New_Record_Offset is Record_Offset + 1,
	hp_arr_record_offset(New_Arrangement, New_Record_Offset),
	hp_arr_contract_number(Arrangement, Contract_Number), hp_arr_contract_number(New_Arrangement, Contract_Number),
	hp_arr_cash_price(Arrangement, Cash_Price),
	hp_arr_interest_rate(Arrangement, Interest_Rate), hp_arr_interest_rate(New_Arrangement, Interest_Rate),
	hp_arr_installment_period(Arrangement, Installment_Period), hp_arr_installment_period(New_Arrangement, Installment_Period),
	Interest_Amount is Cash_Price * Interest_Rate * Installment_Period / (100 * 12),
	hp_arr_installment_amount(Arrangement, Installment_Amount), hp_arr_installment_amount(New_Arrangement, Installment_Amount),
	New_Cash_Price is Cash_Price + Interest_Amount - Installment_Amount,
	New_Cash_Price >= 0,
	hp_arr_cash_price(New_Arrangement, New_Cash_Price),
	record_of_hp_arr(New_Arrangement, Record).

% Some more predicates for hire purchase arrangements

records_of_hp_arr(Arrangement, Records) :-
	findall(Record, record_of_hp_arr(Arrangement, Record), Records).

installment_count_of_hp_arr(Arrangement, Record_Count) :-
	records_of_hp_arr(Arrangement, Records),
	length(Records, Record_Count).

duration_of_hp_arr(Arrangement, Months) :-
	installment_count_of_hp_arr(Arrangement, Record_Count),
	hp_arr_installment_period(Arrangement, Period),
	Months is Record_Count * Period.

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

% Predicate to generate a range of values that divide some region into equal intervals

linspace(Start, _, _, Value) :-
	Start = Value.

linspace(Start, Stop, Num, Value) :-
	Num > 1,
	Next_Start is Start + ((Stop - Start) / Num),
	Next_Num is Num - 1,
	linspace(Next_Start, Stop, Next_Num, Value).

% Now for some examples:

% Split the range between 10 and 20 into 100 equally spaced intervals and give me their
% boundaries:
% linspace(10, 20, 100, X).
% Result:
% X = 10 ;
% X = 10.1 ;
% X = 10.2 ;
% ...
% X = 19.9 ;

% Give me the interest rates in the range of 10% to 20% that will cause the hire purchase
% arrangement to conclude in exactly 36 months.
% linspace(10, 20, 100, Interest_Rate), installment_count_of_hp_arr(hp_arrangement(0, 5953.2, Interest_Rate, 1, 200.47, 1), 36).
% Result:
% X = 12.99999999999999 ;
% X = 13.099999999999989 ;
% ...
% X = 14.399999999999984 ;
% Note that instead of getting Prolog to try to solve a system of equations (and hang),
% I cheated by just getting Prolog to exhaustively search a finite domain of generated
% values.
% Also note that several to different interest rates can result in hire purchase
% arrangements with the same duration. In this case, it is only the closing balance
% after the last installment that changes.

% What is the total amount the customer will pay over the course of the hire purchase
% arrangement?
% total_payment_of_hp_arr(hp_arrangement(0, 5953.2, 13, 1, 200.47, 1), Total_Payment).
% Result: Total_Payment = 7216.920000000002.

% What is the total interest the customer will pay over the course of the hire purchase
% arrangement?
% total_interest_of_hp_arr(hp_arrangement(0, 5953.2, 13, 1, 200.47, 1), Total_Interest).
% Result: Total_Interest = 1268.8307569608378.

% Give me all the records of a hire purchase arrangement:
% record_of_hp_arr(hp_arrangement(0, 5953.2, 13, 1, 200.47, 1), Records).
% Result:
% Records = hp_record(1, 5953.2, 13, 64.493, 200.47, 5817.223) ;
% Records = hp_record(2, 5817.223, 13, 63.019915833333336, 200.47, 5679.772915833333) ;
% ...
% Records = hp_record(36, 203.3775007032181, 13, 2.203256257618196, 200.47, 5.110756960836284) ;


:- use_module(library(clpq)).

% Predicates for asserting the fields of a hire purchase arrangement

hp_arr_contract_number(hp_arrangement(Contract_Number, _, _, _, _, _), Contract_Number).

hp_arr_cash_price(hp_arrangement(_, Cash_Price, _, _, _, _), Cash_Price).

hp_arr_interest_rate(hp_arrangement(_, _, Interest_Rate, _, _, _), Interest_Rate).

hp_arr_installment_period(hp_arrangement(_, _, _, Installment_Period, _, _), Installment_Period).

hp_arr_installment_amount(hp_arrangement(_, _, _, _, Installment_Amount, _), Installment_Amount).

hp_arr_record_offset(hp_arrangement(_, _, _, _, _, Record_Offset), Record_Offset).

% Predicates for asserting the fields of a hire purchase record

hp_rec_number(hp_record(Record_Number, _, _, _, _, _), Record_Number).

hp_rec_opening_balance(hp_record(_, Opening_Balance, _, _, _, _), Opening_Balance).

hp_rec_interest_rate(hp_record(_, _, Interest_Rate, _, _, _), Interest_Rate).

hp_rec_interest_amount(hp_record(_, _, _, Interest_Amount, _, _), Interest_Amount).

hp_rec_installment_amount(hp_record(_, _, _, _, Installment_Amount, _), Installment_Amount).

hp_rec_closing_balance(hp_record(_, _, _, _, _, Closing_Balance), Closing_Balance).

% Predicate relating a hire purchase record to an agreement

record_of_hp_arr(Arrangement, Record) :-
	hp_rec_number(Record, Record_Number), hp_arr_record_offset(Arrangement, Record_Number),
	hp_rec_opening_balance(Record, Cash_Price), hp_arr_cash_price(Arrangement, Cash_Price),
	hp_rec_interest_rate(Record, Interest_Rate), hp_arr_interest_rate(Arrangement, Interest_Rate),
	hp_arr_installment_period(Arrangement, Installment_Period),
	{Interest_Amount = Cash_Price * Interest_Rate * Installment_Period / (100 * 12)},
	hp_rec_interest_amount(Record, Interest_Amount),
	hp_rec_installment_amount(Record, Installment_Amount), hp_arr_installment_amount(Arrangement, Installment_Amount),
	{Closing_Balance = Cash_Price + Interest_Amount - Installment_Amount},
	hp_rec_closing_balance(Record, Closing_Balance),
	{Cash_Price >= 0}.

record_of_hp_arr(Arrangement, Record) :-
	hp_arr_record_offset(Arrangement, Record_Offset),
	New_Record_Offset is Record_Offset + 1,
	hp_arr_record_offset(New_Arrangement, New_Record_Offset),
	hp_arr_contract_number(Arrangement, Contract_Number), hp_arr_contract_number(New_Arrangement, Contract_Number),
	hp_arr_cash_price(Arrangement, Cash_Price),
	hp_arr_interest_rate(Arrangement, Interest_Rate), hp_arr_interest_rate(New_Arrangement, Interest_Rate),
	hp_arr_installment_period(Arrangement, Installment_Period), hp_arr_installment_period(New_Arrangement, Installment_Period),
	{Interest_Amount = Cash_Price * Interest_Rate * Installment_Period / (100 * 12)},
	hp_arr_installment_amount(Arrangement, Installment_Amount), hp_arr_installment_amount(New_Arrangement, Installment_Amount),
	{New_Cash_Price = Cash_Price + Interest_Amount - Installment_Amount},
	hp_arr_cash_price(New_Arrangement, New_Cash_Price),
	{New_Cash_Price >= 0},
	record_of_hp_arr(New_Arrangement, Record).

% Some more predicates for hire purchase arrangements

records_of_hp_arr(Arrangement, Records) :- findall(Record, record_of_hp_arr(Arrangement, Record), Records).

record_count_of_hp_arr(Arrangement, Record_Count) :-
	record_of_hp_arr(Arrangement, Last_Record),
	hp_rec_number(Last_Record, Record_Count),
	hp_rec_closing_balance(Last_Record, Last_Closing_Balance),
	{Last_Closing_Balance >= 0},
	record_of_hp_arr(Arrangement, Sentinel_Record),
	Sentinel_Record_Number is Record_Count + 1,
	hp_rec_number(Sentinel_Record, Sentinel_Record_Number),
	hp_rec_closing_balance(Sentinel_Record, Sentinel_Closing_Balance),
	{Sentinel_Closing_Balance < 0}.

total_payment_of_hp_arr(Arrangement, Total_Payment) :-
	findall(Installment_Amount, (record_of_hp_arr(Arrangement, Record), hp_rec_installment_amount(Record, Installment_Amount)),
		Installment_Amounts),
	sum_list(Installment_Amounts, Total_Payment).

total_interest_of_hp_arr(Arrangement, Total_Interest) :-
	findall(Interest_Amount, (record_of_hp_arr(Arrangement, Record), hp_rec_interest_amount(Record, Interest_Amount)),
		Interest_Amounts),
	sum_list(Interest_Amounts, Total_Interest).

% record_of_hp_arr(hp_arrangement(0, 5953.2, 13, 1, 200.47, 1), Record).


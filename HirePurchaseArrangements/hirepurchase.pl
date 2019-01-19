% Predicates for asserting the fields of a hire purchase arrangement

hp_arr_contract_number(hp_arrangement(Contract_Number, _, _, _, _, _), Contract_Number).

hp_arr_cash_price(hp_arrangement(_, Cash_Price, _, _, _, _), Cash_Price).

hp_arr_interest_rate(hp_arrangement(_, _, Interest_Rate, _, _, _), Interest_Rate).

hp_arr_installment_period(hp_arrangement(_, _, _, Installment_Period, _, _), Installment_Period).

hp_arr_installment_amount(hp_arrangement(_, _, _, _, Installment_Amount, _), Installment_Amount).

hp_arr_interest(hp_arrangement(_, _, _, _, _, Interest), Interest).

% Predicates for asserting the fields of a hire purchase record

hp_rec_number(hp_record(Record_Number, _, _, _, _, _), Record_Number).

hp_rec_opening_balance(hp_record(_, Opening_Balance, _, _, _, _), Opening_Balance).

hp_rec_interest_rate(hp_record(_, _, Interest_Rate, _, _, _), Interest_Rate).

hp_rec_interest_amount(hp_record(_, _, _, Interest_Amount, _, _), Interest_Amount).

hp_rec_installment_amount(hp_record(_, _, _, _, Installment_Amount, _), Installment_Amount).

hp_rec_closing_balance(hp_record(_, _, _, _, _, Closing_Balance), Closing_Balance).

% Predicate relating a hire purchase record to an agreement

record_of(Record, Arrangement) :-
	hp_rec_number(Record, 1),
	hp_rec_opening_balance(Record, Cash_Price), hp_arr_cash_price(Arrangement, Cash_Price),
	hp_rec_interest_rate(Record, Interest_Rate), hp_arr_interest_rate(Arrangement, Interest_Rate),
	hp_arr_installment_period(Arrangement, Installment_Period),
	Interest_Amount is Cash_Price * Interest_Rate * Installment_Period / (100 * 12),
	hp_rec_interest_amount(Record, Interest_Amount),
	hp_rec_installment_amount(Record, Installment_Amount), hp_arr_installment_amount(Arrangement, Installment_Amount),
	Closing_Balance is Cash_Price + Interest_Amount - Installment_Amount,
	hp_rec_closing_balance(Record, Closing_Balance).

record_of(Record, Arrangement) :-
	hp_rec_number(Record, Record_Number),
	Prev_Record_Number is Record_Number - 1, hp_rec_number(Prev_Record, Prev_Record_Number),
	record_of(Prev_Record, Arrangement),
	hp_rec_closing_balance(Prev_Record, Opening_Balance), hp_rec_opening_balance(Record, Opening_Balance),
	hp_rec_interest_rate(Record, Interest_Rate), hp_arr_interest_rate(Arrangement, Interest_Rate),
	hp_arr_installment_period(Arrangement, Installment_Period),
	Interest_Amount is Opening_Balance * Interest_Rate * Installment_Period / (100 * 12),
	hp_rec_interest_amount(Record, Interest_Amount),
	hp_rec_installment_amount(Record, Installment_Amount), hp_arr_installment_amount(Arrangement, Installment_Amount),
	Closing_Balance is Opening_Balance + Interest_Amount - Installment_Amount,
	hp_rec_closing_balance(Record, Closing_Balance),
	Closing_Balance > 0.

range(X, L, H) :- X is L + 1, X < H.
range(X, L, H) :- L1 is L + 1, L1 < H, range(X, L1, H).

% hp_rec_number(Record, 1), record_of(Record, hp_arrangement(0, 5953.2, 13, 1, 200.47, in_arrears)).


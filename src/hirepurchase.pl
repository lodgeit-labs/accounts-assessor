% The purpose of the following program is to derive information about a given hire
% purchase arrangement. That is, this program will tell you what the closing balance of
% the hire purchase account is after a particular installment has been paid. It will tell
% you how much interest you will have paid by the close of the arrangement. And it will
% tell you other relevant information.

% This program is part of a larger system for validating and correcting balance sheets.
% More precisely, accounting principles require that the transactions that occur in a hire
% purchase arrangement are summarized in balance sheets. This program calculates those
% summary values directly from the original data and ultimately will be expected to add
% correction entries to the balance sheet when it is in error.

% Predicate to generate a range of values through stepping forwards from a start point

range(Start, _, _, Value) :-
	Start = Value.

range(Start, Stop, Step, Value) :-
	Next_Start is Start + Step,
	Next_Start < Stop,
	range(Next_Start, Stop, Step, Value).

% Predicates for asserting the fields of a hire purchase installment

% The date the potential installment is to be paid
hp_inst_day(hp_installment(Day, _), Day).
% The amount that constitutes the potential installment
hp_inst_amount(hp_installment(_, Installment), Installment).

% Predicates for asserting the fields of a hire purchase arrangement

% An identifier for a given hire purchase arrangement
hp_arr_contract_number(hp_arrangement(Contract_Number, _, _, _, _, _), Contract_Number).
% The opening balance of the whole arrangement
hp_arr_cash_price(hp_arrangement(_, Cash_Price, _, _, _, _), Cash_Price).
% The beginning day of the whole arrangement
hp_arr_begin_day(hp_arrangement(_, _, Begin_Day, _, _, _), Begin_Day).
% The stated annual interest rate of the arrangement
hp_arr_interest_rate(hp_arrangement(_, _, _, Interest_Rate, _, _), Interest_Rate).
% For internal usage, user should always set this to 1
hp_arr_record_offset(hp_arrangement(_, _, _, _, Record_Offset, _), Record_Offset).
% A chronologically ordered list of purchase arrangement installments. The latter
% installments where the account balance is negative are ignored.
hp_arr_installments(hp_arrangement(_, _, _, _, _, Installments), Installments).

% Predicates for asserting the fields of a hire purchase record

% Records are indexed in chronological order
hp_rec_number(hp_record(Record_Number, _, _, _, _, _, _, _), Record_Number).
% The balance of the payment at the beginning of the given period
hp_rec_opening_balance(hp_record(_, Opening_Balance, _, _, _, _, _, _), Opening_Balance).
% The interest rate being applied to the opening balance
hp_rec_interest_rate(hp_record(_, _, Interest_Rate, _, _, _, _, _), Interest_Rate).
% The calculated interest for the given period
hp_rec_interest_amount(hp_record(_, _, _, Interest_Amount, _, _, _, _), Interest_Amount).
% The amount being paid towards the good in the given period
hp_rec_installment_amount(hp_record(_, _, _, _, Installment_Amount, _, _, _), Installment_Amount).
% The balance of the payment at the end of the given period
hp_rec_closing_balance(hp_record(_, _, _, _, _, Closing_Balance, _, _), Closing_Balance).
% The opening day of the given record's period
hp_rec_opening_day(hp_record(_, _, _, _, _, _, Opening_Day, _), Opening_Day).
% The closing day of the given record's period
hp_rec_closing_day(hp_record(_, _, _, _, _, _, _, Closing_Day), Closing_Day).

% A predicate for generating Num installments starting at the given date and occurring
% after every delta date with a payment amount of Installment_Amount.

installments(_, 0, _, _, []).

installments(From_Date, Num, Delta_Date, Installment_Amount, Range) :-
	date_add(From_Date, Delta_Date, Next_Date),
	Next_Num is Num - 1,
	installments(Next_Date, Next_Num, Delta_Date, Installment_Amount, Range_Tl),
	absolute_day(From_Date, Installment_Day),
	Range = [hp_installment(Installment_Day, Installment_Amount) | Range_Tl], !.

% A predicate for inserting balloon payment into a list of installments

insert_balloon(Balloon_Installment, [], [Balloon_Installment]).

% Balloon payment precedes all other payments
insert_balloon(Balloon_Installment, [Installments_Hd | Installments_Tl], Result) :-
	hp_inst_day(Balloon_Installment, Bal_Inst_Day),
	hp_inst_day(Installments_Hd, Inst_Hd_Day),
	Bal_Inst_Day < Inst_Hd_Day,
	Result = [Balloon_Installment | [Installments_Hd | Installments_Tl]].

% Balloon payment replaces installment on same date
insert_balloon(Balloon_Installment, [Installments_Hd | Installments_Tl], Result) :-
	hp_inst_day(Balloon_Installment, Bal_Inst_Day),
	hp_inst_day(Installments_Hd, Inst_Hd_Day),
	Bal_Inst_Day = Inst_Hd_Day,
	Result = [Balloon_Installment | Installments_Tl].

% Balloon payment goes into the tail of the installments
insert_balloon(Balloon_Installment, [Installments_Hd | Installments_Tl], Result) :-
	hp_inst_day(Balloon_Installment, Bal_Inst_Day),
	hp_inst_day(Installments_Hd, Inst_Hd_Day),
	Bal_Inst_Day > Inst_Hd_Day,
	insert_balloon(Balloon_Installment, Installments_Tl, New_Installments_Tl),
	Result = [Installments_Hd | New_Installments_Tl].

% Predicate relating a hire purchase record to an arrangement. The logic is that a record
% is related to a hire purchase arrangement if it is its first, otherwise it must be
% related to the hypothetical hire purchase arrangement that is the same as the present
% one but had the first potential installment applied to it. This logic is used instead of
% relating records to their predecessors because it allows Prolog to systematically find
% all the hire purchase records corresponding to a given arrangement.

hp_arr_record(Arrangement, Record) :-
	hp_rec_number(Record, Record_Number), hp_arr_record_offset(Arrangement, Record_Number),
	hp_rec_opening_balance(Record, Cash_Price), hp_arr_cash_price(Arrangement, Cash_Price),
	hp_arr_begin_day(Arrangement, Prev_Inst_Day), hp_rec_opening_day(Record, Prev_Inst_Day),
	hp_rec_interest_rate(Record, Interest_Rate), hp_arr_interest_rate(Arrangement, Interest_Rate),
	hp_arr_installments(Arrangement, [Installments_Hd|_]),
	hp_inst_day(Installments_Hd, Current_Inst_Day), hp_rec_closing_day(Record, Current_Inst_Day),
	hp_inst_amount(Installments_Hd, Current_Inst_Amount),
	Installment_Period is Current_Inst_Day - Prev_Inst_Day,
	Interest_Amount is Cash_Price * Interest_Rate * Installment_Period / (100 * 365.2425),
	hp_rec_interest_amount(Record, Interest_Amount),
	hp_rec_installment_amount(Record, Current_Inst_Amount),
	Closing_Balance is Cash_Price + Interest_Amount - Current_Inst_Amount,
	hp_rec_closing_balance(Record, Closing_Balance),
	Closing_Balance >= 0.

hp_arr_record(Arrangement, Record) :-
	hp_arr_record_offset(Arrangement, Record_Offset),
	New_Record_Offset is Record_Offset + 1,
	hp_arr_record_offset(New_Arrangement, New_Record_Offset),
	hp_arr_contract_number(Arrangement, Contract_Number), hp_arr_contract_number(New_Arrangement, Contract_Number),
	hp_arr_cash_price(Arrangement, Cash_Price),
	hp_arr_begin_day(Arrangement, Prev_Inst_Day),
	hp_arr_interest_rate(Arrangement, Interest_Rate), hp_arr_interest_rate(New_Arrangement, Interest_Rate),
	hp_arr_installments(Arrangement, [Installments_Hd|Installments_Tl]), hp_arr_installments(New_Arrangement, Installments_Tl),
	hp_inst_day(Installments_Hd, Current_Inst_Day),
	hp_inst_amount(Installments_Hd, Current_Inst_Amount),
	hp_arr_begin_day(New_Arrangement, Current_Inst_Day),
	Installment_Period is Current_Inst_Day - Prev_Inst_Day,
	Interest_Amount is Cash_Price * Interest_Rate * Installment_Period / (100 * 365.2425),
	New_Cash_Price is Cash_Price + Interest_Amount - Current_Inst_Amount,
	New_Cash_Price >= 0,
	hp_arr_cash_price(New_Arrangement, New_Cash_Price),
	hp_arr_record(New_Arrangement, Record).

% Some predicates on hire purchase arrangements and potential installments for them

hp_arr_records(Arrangement, Records) :-
	findall(Record, hp_arr_record(Arrangement, Record), Records).

hp_arr_record_count(Arrangement, Record_Count) :-
	hp_arr_records(Arrangement, Records),
	length(Records, Record_Count).

hp_arr_total_payment_from(Arrangement, From_Day, Total_Payment) :-
	findall(Installment_Amount,
		(hp_arr_record(Arrangement, Record), hp_rec_installment_amount(Record, Installment_Amount),
		hp_rec_closing_day(Record, Closing_Day), From_Day =< Closing_Day),
		Installment_Amounts),
	sum_list(Installment_Amounts, Total_Payment).

hp_arr_total_payment_between(Arrangement, From_Day, To_Day, Total_Payment) :-
	findall(Installment_Amount,
		(hp_arr_record(Arrangement, Record), hp_rec_installment_amount(Record, Installment_Amount),
		hp_rec_closing_day(Record, Closing_Day), From_Day =< Closing_Day, Closing_Day < To_Day),
		Installment_Amounts),
	sum_list(Installment_Amounts, Total_Payment).

hp_arr_total_interest_from(Arrangement, From_Day, Total_Interest) :-
	findall(Interest_Amount,
		(hp_arr_record(Arrangement, Record), hp_rec_interest_amount(Record, Interest_Amount),
		hp_rec_closing_day(Record, Closing_Day), From_Day =< Closing_Day),
		Interest_Amounts),
	sum_list(Interest_Amounts, Total_Interest).

hp_arr_total_interest_between(Arrangement, From_Day, To_Day, Total_Interest) :-
	findall(Interest_Amount,
		(hp_arr_record(Arrangement, Record), hp_rec_interest_amount(Record, Interest_Amount),
		hp_rec_closing_day(Record, Closing_Day), From_Day =< Closing_Day, Closing_Day < To_Day),
		Interest_Amounts),
	sum_list(Interest_Amounts, Total_Interest).

% Relates a hire purchase record to a transaction to the given hire purchase account
% that is of an amount equal to that of the record and that occurs within the period of
% the record.

hp_arr_record_transaction(Arrangement, HP_Account, Record, Transaction) :-
	hp_arr_record(Arrangement, Record),
	hp_rec_installment_amount(Record, Installment_Amount),
	hp_rec_opening_day(Record, Opening_Day), hp_rec_closing_day(Record, Closing_Day),
	transactions(Transaction),
	transaction_day(Transaction, Transaction_Day),
	Opening_Day < Transaction_Day, Transaction_Day =< Closing_Day,
	transaction_t_term(Transaction, Transaction_T_Term),
	debit_isomorphism(Transaction_T_Term, Transaction_Amount),
	Installment_Amount =:= Transaction_Amount,
	transaction_account(Transaction, HP_Account).

% Relates a hire purchase record to a duplicate transaction to the given hire purchase
% account that is of an amount equal to that of the record and that occurs within the
% period of the record.

hp_arr_record_duplicate_transaction(Arrangement, HP_Account, Record, Duplicate_Transaction) :-
	once(hp_arr_record_transaction(Arrangement, HP_Account, Record, Chosen_Transaction)),
	hp_arr_record_transaction(Arrangement, HP_Account, Record, Duplicate_Transaction),
	Chosen_Transaction \= Duplicate_Transaction.
	
% Relates a hire purchase record that does not have a transaction in the above sense to a
% transaction to an incorrect account that is of an amount equal to that of the record and
% that occurs within the period of the record.

hp_arr_record_wrong_account_transaction(Arrangement, HP_Account, Record, Transaction) :-
	hp_arr_record(Arrangement, Record),
	\+ hp_arr_record_transaction(Arrangement, HP_Account, Record, _),
	hp_rec_installment_amount(Record, Installment_Amount),
	hp_rec_opening_day(Record, Opening_Day), hp_rec_closing_day(Record, Closing_Day),
	transactions(Transaction),
	transaction_day(Transaction, Transaction_Day),
	Opening_Day < Transaction_Day, Transaction_Day =< Closing_Day,
	transaction_t_term(Transaction, Transaction_T_Term),
	debit_isomorphism(Transaction_T_Term, Transaction_Amount),
	Installment_Amount =:= Transaction_Amount,
	transaction_account(Transaction, Transaction_Account),
	Transaction_Account \= HP_Account, !.

% Relates a hire purchase record that does not have a transaction in the above sense nor
% an incorrect account transaction in the above sense to a transaction to the correct
% account that is of an amount unequal to that of the record and that occurs within the
% period of the record.

hp_arr_record_wrong_amount_transaction(Arrangement, HP_Account, Record, Transaction) :-
	hp_arr_record(Arrangement, Record),
	\+ hp_arr_record_transaction(Arrangement, HP_Account, Record, _),
	\+ hp_arr_record_wrong_account_transaction(Arrangement, HP_Account, Record, _),
	hp_rec_installment_amount(Record, Installment_Amount),
	hp_rec_opening_day(Record, Opening_Day), hp_rec_closing_day(Record, Closing_Day),
	transactions(Transaction),
	transaction_day(Transaction, Transaction_Day),
	Opening_Day < Transaction_Day, Transaction_Day =< Closing_Day,
	transaction_t_term(Transaction, Transaction_T_Term),
	debit_isomorphism(Transaction_T_Term, Transaction_Amount),
	Installment_Amount =\= Transaction_Amount,
	transaction_account(Transaction, HP_Account), !.

% Asserts that a hire purchase record does not have a transaction in the above sense, nor
% does it have an incorrect account transaction in the above sense, nor does it have an
% incorrect amount transaction in the above sense.

hp_arr_record_non_existent_transaction(Arrangement, HP_Account, Record) :-
	hp_arr_record(Arrangement, Record),
	\+ hp_arr_record_transaction(Arrangement, HP_Account, Record, _),
	\+ hp_arr_record_wrong_account_transaction(Arrangement, HP_Account, Record, _),
	\+ hp_arr_record_wrong_amount_transaction(Arrangement, HP_Account, Record, _).

% Relates a hire purchase record that has a duplicate transaction in the above sense to a
% pair of correction transactions that transfer from the hire purchase account to the
% missing hire purchase account.

hp_arr_record_duplicate_transaction_correction(Arrangement, HP_Account, HP_Suspense_Account, Record, Transaction_Correction) :-
	hp_arr_record(Arrangement, Record),
	hp_arr_record_duplicate_transaction(Arrangement, HP_Account, Record, Duplicate_Transaction),
	transaction_t_term(Duplicate_Transaction, Transaction_T_Term),
	pac_inverse(Transaction_T_Term, Transaction_T_Term_Inverted),
	member(Transaction_Correction,
		[transaction(0, correction, HP_Account, Transaction_T_Term_Inverted),
		transaction(0, correction, HP_Suspense_Account, Transaction_T_Term)]).

% Relates a hire purchase record that has a transaction to the incorrect account in the
% above sense to a pair of correction transactions that transfer from the incorrect
% account to the correct account.

hp_arr_record_wrong_account_transaction_correction(Arrangement, HP_Account, Record, Transaction_Correction) :-
	hp_arr_record_wrong_account_transaction(Arrangement, HP_Account, Record, Transaction),
	hp_rec_installment_amount(Record, Installment_Amount),
	transaction_account(Transaction, Transaction_Account),
	member(Transaction_Correction,
		[transaction(0, correction, HP_Account, t_term(Installment_Amount, 0)),
		transaction(0, correction, Transaction_Account, t_term(0, Installment_Amount))]).

% Relates a hire purchase record that has a transaction with an incorrect amount in the
% above sense to a pair of correction transactions that transfer a corrective amount
% from the missing hire purchase payments account.

hp_arr_record_wrong_amount_transaction_correction(Arrangement, HP_Account, HP_Suspense_Account, Record, Transaction_Correction) :-
	hp_arr_record(Arrangement, Record),
	hp_arr_record_wrong_amount_transaction(Arrangement, HP_Account, Record, Transaction),
	transaction_t_term(Transaction, Transaction_T_Term),
	hp_rec_installment_amount(Record, Installment_Amount),
	pac_sub(t_term(Installment_Amount, 0), Transaction_T_Term, Remaining_T_Term),
	pac_reduce(Remaining_T_Term, Remaining_T_Term_Reduced),
	pac_inverse(Remaining_T_Term_Reduced, Remaining_T_Term_Reduced_Inverted),
	member(Transaction_Correction,
		[transaction(0, correction, HP_Account, Remaining_T_Term_Reduced),
		transaction(0, correction, HP_Suspense_Account, Remaining_T_Term_Reduced_Inverted)]).

% Relates a hire purchase record that does not have a transaction in any sense to a pair
% of correction transactions that transfer from the missing hire purchase payments account
% to the hire purchase account.

hp_arr_record_nonexistent_transaction_correction(Arrangement, HP_Account, HP_Suspense_Account, Record, Transaction_Correction) :-
	hp_arr_record_non_existent_transaction(Arrangement, HP_Account, Record),
	hp_rec_installment_amount(Record, Installment_Amount),
	member(Transaction_Correction,
		[transaction(0, correction, HP_Account, t_term(Installment_Amount, 0)),
		transaction(0, correction, HP_Suspense_Account, t_term(0, Installment_Amount))]).

% Relates a hire purchase arrangement to correction transactions. The correction
% transactions correct the cases where payments are made to the wrong account or where
% payments of the wrong amount are made or where no payment has been made.

hp_arr_correction(Arrangement, HP_Account, HP_Suspense_Account, Transaction_Correction) :-
	hp_arr_record_duplicate_transaction_correction(Arrangement, HP_Account, HP_Suspense_Account, _, Transaction_Correction);
	hp_arr_record_wrong_account_transaction_correction(Arrangement, HP_Account, _, Transaction_Correction);
	hp_arr_record_wrong_amount_transaction_correction(Arrangement, HP_Account, HP_Suspense_Account, _, Transaction_Correction);
	hp_arr_record_nonexistent_transaction_correction(Arrangement, HP_Account, HP_Suspense_Account, _, Transaction_Correction).

% Relates a hire purchase arrangement to the fields that summarize it in a financial
% report at a given date. In particular, the time split report refers to the method of
% reporting the hire purchase arrangement's current liability, current unexpired interest,
% non-current liability, and non-current unexpired interest at a given point in time.

hp_arr_time_split_report(Arrangement, Start_Day, Cur_Liability, Cur_Unexpired_Interest, Non_Cur_Liability, Non_Cur_Unexpired_Interest) :-
	gregorian_date(Start_Day, Start_Date), date_add(Start_Date, date(1, 0, 0), End_Date), absolute_day(End_Date, End_Day),
	hp_arr_total_payment_between(Arrangement, Start_Day, End_Day, Cur_Liability),
	hp_arr_total_interest_between(Arrangement, Start_Day, End_Day, Neg_Cur_Unexpired_Interest),
	Cur_Unexpired_Interest is -Neg_Cur_Unexpired_Interest,
	hp_arr_total_payment_from(Arrangement, End_Day, Non_Cur_Liability),
	hp_arr_total_interest_from(Arrangement, End_Day, Neg_Non_Cur_Unexpired_Interest),
	Non_Cur_Unexpired_Interest is -Neg_Non_Cur_Unexpired_Interest.


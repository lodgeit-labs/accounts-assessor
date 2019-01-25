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
hp_rec_opening_day(hp_record(_, _, _, _, _, _, Opening_Day, _), Opening_Day).
hp_rec_closing_day(hp_record(_, _, _, _, _, _, _, Closing_Day), Closing_Day).

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
	Range = [hp_installment(Installment_Day, Installment_Amount) | Range_Tl], !.

% A predicate for inserting balloon payment into a list of installments

insert_balloon(Balloon_Installment, [], [Balloon_Installment]).

insert_balloon(Balloon_Installment, [Installments_Hd | Installments_Tl], Result) :-
	hp_inst_day(Balloon_Installment, Bal_Inst_Day),
	hp_inst_day(Installments_Hd, Inst_Hd_Day),
	Bal_Inst_Day =< Inst_Hd_Day,
	Result = [Balloon_Installment | [Installments_Hd | Installments_Tl]].

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
	Interest_Amount is Cash_Price * Interest_Rate * Installment_Period / (100 * 365),
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
	Interest_Amount is Cash_Price * Interest_Rate * Installment_Period / (100 * 365),
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

hp_arr_total_payment(Arrangement, Total_Payment) :-
	findall(Installment_Amount,
		(hp_arr_record(Arrangement, Record), hp_rec_installment_amount(Record, Installment_Amount)),
		Installment_Amounts),
	sum_list(Installment_Amounts, Total_Payment).

hp_arr_total_interest(Arrangement, Total_Interest) :-
	findall(Interest_Amount,
		(hp_arr_record(Arrangement, Record), hp_rec_interest_amount(Record, Interest_Amount)),
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
	transaction_date(Transaction, Transaction_Date),
	Opening_Day < Transaction_Date, Transaction_Date =< Closing_Day,
	transaction_t_term(Transaction, Transaction_T_Term),
	debit_isomorphism(Transaction_T_Term, Transaction_Amount),
	Installment_Amount =:= Transaction_Amount,
	transaction_account(Transaction, HP_Account), !.

% Relates a hire purchase record that does not have a transaction in the above sense to a
% transaction to an incorrect account that is of an amount equal to that of the record and
% that occurs within the period of the record.

hp_arr_record_wrong_account_transaction(Arrangement, HP_Account, Record, Transaction) :-
	hp_arr_record(Arrangement, Record),
	\+ hp_arr_record_transaction(Arrangement, HP_Account, Record, _),
	hp_rec_installment_amount(Record, Installment_Amount),
	hp_rec_opening_day(Record, Opening_Day), hp_rec_closing_day(Record, Closing_Day),
	transactions(Transaction),
	transaction_date(Transaction, Transaction_Date),
	Opening_Day < Transaction_Date, Transaction_Date =< Closing_Day,
	transaction_t_term(Transaction, Transaction_T_Term),
	debit_isomorphism(Transaction_T_Term, Transaction_Amount),
	Installment_Amount =:= Transaction_Amount,
	transaction_account(Transaction, Transaction_Account),
	Transaction_Account \= HP_Account, !.

% Relates a hire purchase record that has a transaction to the incorrect account in the
% above sense to a pair of correction transactions.

hp_arr_record_wrong_acount_transaction_correction(Arrangement, HP_Account, Record, Transaction_Correction) :-
	hp_arr_record_wrong_account_transaction(Arrangement, HP_Account, Record, Transaction)
	hp_rec_installment_amount(Record, Installment_Amount),
	transaction_account(Transaction, Transaction_Account),
	member(Transaction_Correction,
		[transaction(0, correction, HP_Account, t_term(Installment_Amount, 0)),
		transaction(0, correction, Transaction_Account, t_term(0, Installment_Amount))]).

% Relates a hire purchase record that neither has a transaction nor a transaction to the
% wrong account to a pair of correction transactions.

hp_arr_record_nonexistent_transaction_correction(Arrangement, HP_Account, Missing_HP_Account, Record, Transaction_Correction) :-
	hp_arr_record(Arrangement, Record),
	\+ hp_arr_record_transaction(Arrangement, HP_Account, Record, _),
	\+ hp_arr_wrong_account_record_transaction(Arrangement, HP_Account, Record, _),
	hp_rec_installment_amount(Record, Installment_Amount),
	member(Transaction_Correction,
		[transaction(0, correction, HP_Account, t_term(Installment_Amount, 0)),
		transaction(0, correction, Missing_HP_Account, t_term(0, Installment_Amount))]).


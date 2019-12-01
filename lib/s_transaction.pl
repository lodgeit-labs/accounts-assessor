:- module(_, [
		s_transaction_day/2,
		s_transaction_type_id/2,
		s_transaction_vector/2,
		s_transaction_account_id/2,
		s_transaction_exchanged/2,
		sort_s_transactions/2,
		s_transactions_up_to/3,
		s_transaction_to_dict/2
]).

:- use_module(library(record)).
:- use_module(library(rdet)).

:- rdet(s_transaction_to_dict/2).

:- record s_transaction(day, type_id, vector, account_id, exchanged).
% bank statement transaction record, these are in the input xml
% - The absolute day that the transaction happenned
% - The type identifier/action tag of the transaction
% - The amounts that are being moved in this transaction
% - The account that the transaction modifies without using exchange rate conversions
% - Either the units or the amount to which the transaction amount will be converted to
% depending on whether the term is of the form bases(...) or vector(...).

sort_s_transactions(In, Out) :-
	/*
	If a buy and a sale of same thing happens on the same day, we want to process the buy first.
	We first sort by our debit on the bank account. Transactions with zero of our debit are not sales.
	*/
	sort(
	/*
	this is a path inside the structure of the elements of the sorted array (inside the s_transactions):
	3th sub-term is the amount from bank perspective.
	1st (and hopefully only) item of the vector is the coord,
	3rd item of the coord is bank credit, our debit.
	*/
	[3,1,3], @=<,  In, Mid),
	/*
	now we can sort by date ascending, and the order of transactions with same date, as sorted above, will be preserved
	*/
	sort(1, @=<,  Mid, Out).

s_transactions_up_to(End_Date, S_Transactions_In, S_Transactions_Out) :-
	findall(
		T,
		(
			member(T, S_Transactions_In),
			s_transaction_day(T, D),
			D @=< End_Date
		),
		S_Transactions_Out
	).

s_transaction_to_dict(St, D) :-
	St = s_transaction(Day, Verb, Vector, Account, Exchanged),
	D = _{
		date: Day,
		verb: Verb,
		vector: Vector,
		account: Account,
		exchanged: Exchanged}.


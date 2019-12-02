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

prepreprocess(Static_Data, In, Out) :-
	/*
	at this point:
	s_transactions have to be sorted by date from oldest to newest
	s_transactions have flipped vectors, so they are from our perspective
	*/
	maplist(prepreprocess_s_transaction(Static_Data), In, Out).

prepreprocess_s_transaction(Static_Data, In, Out) :-
	infer_exchanged_units_count(Static_Data, In, Mid),
	!,
	prepreprocess_s_transaction(Static_Data, Mid, Out).

/* add livestock verb uri */
prepreprocess_s_transaction(Static_Data, In, Out) :-
	livestock:infer_livestock_action_verb(In, Mid),
	!,
	prepreprocess_s_transaction(Static_Data, Mid, Out).

/* from verb label to verb uri */
prepreprocess_s_transaction(Static_Data, In, Out) :-
	check_s_transaction_action_verb(S_Transaction),
	s_transaction_action_verb(S_Transaction, Action_Verb),
	!,
	s_transaction:s_transaction_type_id(NS_Transaction, uri(Action_Verb)),
	/* just copy these over */
	s_transaction:s_transaction_exchanged(S_Transaction, Exchanged),
	s_transaction:s_transaction_exchanged(NS_Transaction, Exchanged),
	s_transaction:s_transaction_day(S_Transaction, Transaction_Date),
	s_transaction:s_transaction_day(NS_Transaction, Transaction_Date),
	s_transaction:s_transaction_vector(S_Transaction, Vector),
	s_transaction:s_transaction_vector(NS_Transaction, Vector),
	s_transaction:s_transaction_account_id(S_Transaction, Unexchanged_Account_Id),
	s_transaction:s_transaction_account_id(NS_Transaction, Unexchanged_Account_Id),
	prepreprocess_s_transaction(Static_Data, NS_Transaction, Out).

prepreprocess_s_transaction(Static_Data, T, T) :-
	(	s_transaction:s_transaction_type_id(T, uri(_))
	->	true
	;	utils:throw_string(unrecognized_bank_statement_transaction)).

% ===================================================================
% Project:   LodgeiT
% Module:    transactions.pl
% Date:      2019-06-02
% ===================================================================

:- module(transactions, [transaction_account_ancestor_id/3,
		  	 transaction_in_period/3,
		 	 transaction_vectors_total/2,
			 transactions_before_day_on_account_and_subaccounts/5,
			 transaction_day/2,
			 transaction_description/2,
			 transaction_account_id/2,
			 transaction_vector/2,
			 check_transaction_account/2
		        ]).

:- use_module(accounts, [account_ancestor_id/3, account_parent_id/3]).
:- use_module(days, [absolute_day/2, gregorian_date/2]).
:- use_module(pacioli, [vec_add/3, vec_reduce/2]).
:- use_module(library(record)).

% -------------------------------------------------------------------


:- record transaction(day, description, account_id, vector).
% - The absolute day that the transaction happenned
% - A description of the transaction
% - The account that the transaction modifies
% - The amounts by which the account is being debited and credited


transaction_account_ancestor_id(Accounts, Transaction, Ancestor_Account_Id) :-
	transaction_account_id(Transaction, Transaction_Account_Id),
	account_ancestor_id(Accounts, Transaction_Account_Id, Ancestor_Account_Id).

transaction_in_period(Transaction, From_Day, To_Day) :-
	transaction_day(Transaction, Day),
	From_Day =< Day,
	Day =< To_Day.

% up_to?
transaction_before(Transaction, End_Day) :-
	transaction_day(Transaction, Day),
	Day < End_Day.


% add up and reduce all the vectors of all the transactions, result is one vector

transaction_vectors_total([], []).

transaction_vectors_total([Hd_Transaction | Tl_Transaction], Reduced_Net_Activity) :-
	transaction_vector(Hd_Transaction, Curr),
	transaction_vectors_total(Tl_Transaction, Acc),
	vec_add(Curr, Acc, Net_Activity),
	vec_reduce(Net_Activity, Reduced_Net_Activity).


transactions_before_day_on_account_and_subaccounts(Accounts, Transactions, Account_Id, Day, Filtered_Transactions) :-
	(var(Transactions) -> throw("errrRRR") ; true),
	findall(
		Transaction, (
			member(Transaction, Transactions),
			transaction_before(Transaction, Day),
			% transaction account is Account_Id or sub-account
			transaction_account_ancestor_id(Accounts, Transaction, Account_Id)
		), Filtered_Transactions).


transaction_date(Transaction, Date) :-
	nonvar(Date),
	absolute_day(Date, Day),
	transaction_day(Transaction, Day).
	
transaction_date(Transaction, Date) :-
	transaction_day(Transaction, Day),
	nonvar(Day),
	gregorian_date(Day, Date).


check_transaction_account(Accounts, Transaction) :-
	transaction_account_id(Transaction, Account),
	(
		(
			nonvar(Account),
			account_parent_id(Accounts, Account, _)
		)
		->
			true
		;
		(
			term_string(Account, Str),
			throw(Str)
		)
	).
	

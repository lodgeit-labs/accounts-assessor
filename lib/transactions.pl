% ===================================================================
% Project:   LodgeiT
% Module:    transactions.pl
% Date:      2019-06-02
% ===================================================================

:- module(transactions, [transaction_account_ancestor_id/3,
		  	 transaction_between/3,
		 	 transaction_vectors_total/2,
			 transactions_up_to_day_on_account_and_subaccounts/5,
			 transaction_day/2,
			 transaction_description/2,
			 transaction_account_id/2,
			 transaction_vector/2
		        ]).

:- use_module(accounts, [account_ancestor_id/3]).
:- use_module(days, [absolute_day/2, gregorian_date/2]).
:- use_module(pacioli, [vec_add/3, vec_reduce/2]).

% -------------------------------------------------------------------


% transaction(Day, Description, Account_Id, Vector)

% Predicates for asserting that the fields of given transactions have particular values

% The absolute day that the transaction happenned
transaction_day(transaction(Day, _, _, _), Day).
% A description of the transaction
transaction_description(transaction(_, Description, _, _), Description).
% The account that the transaction modifies
transaction_account_id(transaction(_, _, Account_Id, _), Account_Id).
% The amounts by which the account is being debited and credited
transaction_vector(transaction(_, _, _, Vector), Vector).

transaction_account_ancestor_id(Accounts, Transaction, Ancestor_Account_Id) :-
	transaction_account_id(Transaction, Transaction_Account_Id),
	account_ancestor_id(Accounts, Transaction_Account_Id, Ancestor_Account_Id).

transaction_between(Transaction, From_Day, To_Day) :-
	transaction_day(Transaction, Day),
	From_Day =< Day,
	Day =< To_Day.

% up_to?
transaction_before(Transaction, End_Day) :-
	transaction_day(Transaction, Day),
	Day =< End_Day.


% add up and reduce all the vectors of all the transactions, result is one vector

transaction_vectors_total([], []).

transaction_vectors_total([Hd_Transaction | Tl_Transaction], Reduced_Net_Activity) :-
	transaction_vector(Hd_Transaction, Curr),
	transaction_vectors_total(Tl_Transaction, Acc),
	vec_add(Curr, Acc, Net_Activity),
	vec_reduce(Net_Activity, Reduced_Net_Activity).


transactions_up_to_day_on_account_and_subaccounts(Accounts, Transactions, Account_Id, Day, Filtered_Transactions) :-
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



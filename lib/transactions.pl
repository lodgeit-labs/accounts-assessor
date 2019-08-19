% ===================================================================
% Project:   LodgeiT
% Module:    transactions.pl
% Date:      2019-06-02
% ===================================================================

:- module(transactions, [
			has_empty_vector/1,
			transaction_account_in_set/3,
		  	 transaction_in_period/3,
		 	 transaction_vectors_total/2,
			 transactions_before_day_on_account_and_subaccounts/5,
			 transaction_day/2,
			 transaction_description/2,
			 transaction_account_id/2,
			 transaction_vector/2,
			 transaction_type/2,
			transactions_by_account/2,
			 check_transaction_account/2,
	 		make_transaction/5,
	 		make_transaction2/5
]).

:- use_module(accounts, [account_id/2, account_in_set/3, account_exists/2]).
:- use_module(days, [absolute_day/2, gregorian_date/2]).
:- use_module(pacioli, [vec_add/3, vec_reduce/2]).
:- use_module(library(record)).

% -------------------------------------------------------------------


:- record transaction(day, description, account_id, vector, type).
% - The absolute day that the transaction happenned
% - A description of the transaction
% - The account that the transaction modifies
% - The amounts by which the account is being debited and credited
% - instant or tracking

transaction_account_in_set(Accounts, Transaction, Root_Account_Id) :-
	transaction_account_id(Transaction, Transaction_Account_Id),
	account_in_set(Accounts, Transaction_Account_Id, Root_Account_Id).

% equivalent concept to the "activity" in "net activity"
transaction_in_period(Transaction, From_Day, To_Day) :-
	transaction_day(Transaction, Day),
	absolute_day(From_Day, A),
	absolute_day(To_Day, C),
	absolute_day(Day, B),
	A =< B,
	B =< C.

% up_to?
transaction_before(Transaction, End_Day) :-
	transaction_day(Transaction, Day),
	absolute_day(End_Day, B),
	absolute_day(Day, A),
	A < B.


% add up and reduce all the vectors of all the transactions, result is one vector

transaction_vectors_total([], []).

transaction_vectors_total([Hd_Transaction | Tl_Transaction], Reduced_Net_Activity) :-
	transaction_vector(Hd_Transaction, Curr),
	transaction_vectors_total(Tl_Transaction, Acc),
	vec_add(Curr, Acc, Net_Activity),
	vec_reduce(Net_Activity, Reduced_Net_Activity).


transactions_in_period_on_account_and_subaccounts(Accounts, Transactions, Account_Id, Start_Date, End_Date, Filtered_Transactions) :-
	assertion(nonvar(Transactions)),
	
	findall(
		Transaction,
		(
			member(Transaction,Transactions),
			transaction_in_period(Transaction, Start_Date, End_Date),
			transaction_account_in_set(Accounts, Transaction, Account_Id)
		),
		Filtered_Transactions
	).

transactions_before_day_on_account_and_subaccounts(Accounts, Transactions, Account_Id, Day, Filtered_Transactions) :-
	assertion(nonvar(Transactions)),

	findall(
		Transaction,
		(
			member(Transaction, Transactions),
			transaction_before(Transaction, Day),
			% transaction account is Account_Id or sub-account
			transaction_account_in_set(Accounts, Transaction, Account_Id)
		),
		Filtered_Transactions
	).

transactions_by_account(Static_Data, Dict) :-
	dict_vars(Static_Data,
		[Accounts,Transactions,Start_Date,End_Date]
	),

	assertion(nonvar(Transactions)),

	/*
	Dict = defaultdict(list)

	for Transaction in Transactions:
		Dict[Transaction.account].append(Transaction)
	*/
	findall(
		Key_Value,
		(
			member(Account,Accounts),
			account_id(Account, Account_Id),
			findall(
				Transaction,
				(
					member(Transaction,Transactions),
					%transaction_account_id(Transaction,Account_Id)
					transaction_account_in_set(Accounts,Transaction,Account_Id)
				),
				Account_Transactions
			),
			Key_Value = Account_Id:Account_Transactions
		),
		Pairs
	),

	dict_create(Dict,account_txs,Pairs),
	transactions_before_day_on_account_and_subaccounts(Accounts, Transactions, 'Earnings', Start_Date, Historical_Earnings_Transactions),
	Dict2 = Dict.put('HistoricalEarnings', Historical_Earnings_Transactions),
	writeln(Dict2),
	%Dict2 = Dict2,
	fail,

	transactions_in_period_on_account_and_subaccounts(Accounts, Transactions, 'Earnings', Start_Date, End_Date, Current_Earnings_Transactions),
	Dict.put(_{'CurrentEarnings':Current_Earnings_Transactions}).


check_transaction_account(Accounts, Transaction) :-
	transaction_account_id(Transaction, Id),
	(
		(
			nonvar(Id),
			account_exists(Accounts, Id)
		)
		->
			true
		;
		(
			term_string(Id, Str),
			atomic_list_concat(["an account referenced by a generated transaction does not exist, please add it to account taxonomy: ", Str], Err_Msg),
			throw(string(Err_Msg))
		)
	).
	
has_empty_vector(T) :-
	transaction_vector(T, []).

	
make_transaction2(Date, Description, Account, Vector, Transaction) :-
	flatten([Description], Description_Flat),
	atomic_list_concat(Description_Flat, Description_Str),
	transaction_day(Transaction, Date),
	transaction_description(Transaction, Description_Str),
	transaction_account_id(Transaction, Account),
	transaction_vector(Transaction, Vector).

make_transaction(Date, Description, Account, Vector, Transaction) :-
	make_transaction2(Date, Description, Account, Vector, Transaction),
	transaction_type(Transaction, instant).

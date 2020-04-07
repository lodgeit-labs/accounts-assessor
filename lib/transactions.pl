%:- rdet(transactions_by_account/2).
%%:- rdet(transaction_to_dict/2).



:- record transaction(day, description, account_id, vector, type).
% - The absolute day that the transaction happenned
% - A description of the transaction
% - The account that the transaction modifies
% - The amounts by which the account is being debited and credited
% - instant or tracking

	
transaction_to_dict(T, D) :-
	T = transaction(Day, Description, Account, Vector, Type),
	D = _{
		date: Day,
		description: Description,
		account: Account,
		vector: Vector,
		type: Type}.


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

transaction_vectors_total([Hd_Transaction | Tl_Transaction], Net_Activity) :-
	transaction_vector(Hd_Transaction, Curr),
	transaction_vectors_total(Tl_Transaction, Acc),
	vec_add(Curr, Acc, Net_Activity).

transactions_in_account_set(Accounts, Transactions_By_Account, Account_Id, Result) :-
	findall(
		Transactions,
		(
			account_in_set(Accounts, Account_Id2, Account_Id),
			get_dict(Account_Id2, Transactions_By_Account, Transactions)
		),
		Transactions2
	),
	flatten(Transactions2, Result).
	
transactions_in_period_on_account_and_subaccounts(Accounts, Transactions_By_Account, Account_Id, Start_Date, End_Date, Filtered_Transactions) :-
	transactions_in_account_set(Accounts, Transactions_By_Account, Account_Id, Transactions),
	findall(
		Transaction,
		(
			member(Transaction,Transactions),
			transaction_in_period(Transaction, Start_Date, End_Date)
		),
		Filtered_Transactions
	).

transactions_before_day_on_account_and_subaccounts(Accounts, Transactions_By_Account, Account_Id, Day, Filtered_Transactions) :-
	transactions_in_account_set(Accounts, Transactions_By_Account, Account_Id, Transactions),
	findall(
		Transaction,
		(
			member(Transaction, Transactions),
			transaction_before(Transaction, Day)
		),
		Filtered_Transactions
	).

transactions_by_account(Static_Data, Transactions_By_Account) :-
	dict_vars(Static_Data,
		[Accounts,Transactions,Start_Date,End_Date]
	),

	assertion(nonvar(Transactions)),
	sort_into_dict(transaction_account_id, Transactions, Dict),

	/*this should be somewhere in ledger code*/
	transactions_before_day_on_account_and_subaccounts(Accounts, Dict, 'NetIncomeLoss', Start_Date, Historical_Earnings_Transactions),

	/* ugh, we shouldnt overwrite is */
	Dict2 = Dict.put('HistoricalEarnings', Historical_Earnings_Transactions),

	transactions_in_period_on_account_and_subaccounts(Accounts, Dict, 'NetIncomeLoss', Start_Date, End_Date, Current_Earnings_Transactions),
	Transactions_By_Account = Dict2.put('CurrentEarnings', Current_Earnings_Transactions).


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
			term_string(Transaction, Tx_Str),
			atomic_list_concat(["an account referenced by a generated transaction does not exist, please add it to account taxonomy: ", Str, ", transaction:", Tx_Str], Err_Msg),
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

	
	
	/*
	Dict = defaultdict(list)

	for Transaction in Transactions:
		Dict[Transaction.account].append(Transaction)
	*/
	/*
	findall(
		Key_Value,
		(
			member(Account,Accounts),
			account_id(Account, Account_Id),
			findall(
				Transaction,
				(
					member(Transaction,Transactions),
					transaction_account_id(Transaction,Account_Id)
				),
				Account_Transactions
			),
			Key_Value = Account_Id:Account_Transactions
		),
		Pairs
	),

	dict_create(Dict,account_txs,Pairs),
	*/

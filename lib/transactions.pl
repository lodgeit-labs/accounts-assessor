%:- record transaction(day, description, account_id, vector, type).
% - The absolute day that the transaction happenned
% - A description of the transaction
% - The account that the transaction modifies
% - The amounts by which the account is being debited and credited
% - instant or tracking

transaction_day(T, X) :-
	doc(T, transactions:day, X, transactions).
transaction_description(T, X) :-
	doc(T, transactions:description, X, transactions).
transaction_account(T, X) :-
	doc(T, transactions:account, X, transactions).
transaction_vector(T, X) :-
	doc(T, transactions:vector, X, transactions).
transaction_type(T, X) :-
	doc(T, transactions:type, X, transactions).

/*
transaction_field(T, F, X) :-
	doc(T, $>rdf_global_term(transactions:F), V),
	doc(V, rdf:value, X).
*/

make_transaction2(Date, Description, Account, Vector, Type, Uri) :-
	flatten([Description], Description_Flat),
	atomic_list_concat(Description_Flat, Description_Str),
	doc_new_uri(Uri),
	doc_add(Uri, rdf:type, l:transaction, transactions),
	doc_add(Uri, transactions:day, Date, transactions),
	doc_add(Uri, transactions:description, Description_Str, transactions),
	doc_add(Uri, transactions:account, Account, transactions),
	doc_add(Uri, transactions:vector, Vector, transactions),
	doc_add(Uri, transactions:type, Type, transactions).

make_transaction(Date, Description, Account, Vector, Uri) :-
	make_transaction2(Date, Description, Account, Vector, instant, Uri).

	
transaction_to_dict(T, D) :-
	transaction_day(T, Day),
	transaction_description(T, Description),
	transaction_account(T, Account),
	transaction_vector(T, Vector),
	transaction_type(T, Type),
	D = _{
		date: Day,
		description: Description,
		account: Account,
		vector: Vector,
		type: Type
	}.


transaction_account_in_set(Accounts, Transaction, Root_Account_Id) :-
	transaction_account(Transaction, Transaction_Account_Id),
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
	sort_into_dict(transaction_account, Transactions, Dict),

	/*this should be somewhere in ledger code*/
	transactions_before_day_on_account_and_subaccounts(Accounts, Dict, 'NetIncomeLoss', Start_Date, Historical_Earnings_Transactions),

	/* ugh, we shouldnt overwrite is */
	Dict2 = Dict.put('HistoricalEarnings', Historical_Earnings_Transactions),

	transactions_in_period_on_account_and_subaccounts(Accounts, Dict, 'NetIncomeLoss', Start_Date, End_Date, Current_Earnings_Transactions),
	Transactions_By_Account = Dict2.put('CurrentEarnings', Current_Earnings_Transactions).


check_transaction_account(Accounts, Transaction) :-
	transaction_account(Transaction, Id),
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


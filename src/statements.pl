% Predicates for asserting that the fields of given transaction types have particular values

% The identifier of this transaction type
transaction_type_id(transaction_type(Id, _, _, _, _), Id).
% The units to which the transaction amount will be converted to
transaction_type_bases(transaction_type(_, Bases, _, _, _), Bases).
% The account that will receive the inverse of the transaction amount after exchanging
transaction_type_exchanged_account(transaction_type(_, _, Exchanged_Account, _, _), Exchanged_Account).
% The account that will record the gains and losses on the transaction amount
transaction_type_trading_account(transaction_type(_, _, _, Trading_Account, _), Trading_Account).
% A description of this transaction type
transaction_type_description(transaction_type(_, _, _, _, Description), Description).

% Predicates for asserting that the fields of given transactions have particular values

% The absolute day that the transaction happenned
s_transaction_day(s_transaction(Day, _, _, _), Day).
% The type identifier of the transaction
s_transaction_type_id(s_transaction(_, Type_Id, _, _), Type_Id).
% The amounts that are being moved in this transaction
s_transaction_vector(s_transaction(_, _, Vector, _), Vector).
% The account that the transaction modifies without using exchange rate conversions
s_transaction_account(s_transaction(_, _, _, Unexchanged_Account), Unexchanged_Account).

% Gets the transaction_type associated with the given transaction

transaction_type_of(Transaction_Types, S_Transaction, Transaction_Type) :-
  s_transaction_type_id(S_Transaction, Type_Id),
  transaction_type_id(Transaction_Type, Type_Id),
  member(Transaction_Type, Transaction_Types).

% Transactions using trading accounts can be decomposed into a transaction of the given
% amount to the unexchanged account, a transaction of the transformed inverse into the
% exchanged account, and a transaction of the negative sum of these into the trading
% account. This predicate takes a list of transactions and transactions using trading
% accounts and decomposes it into a list of just transactions.

preprocess_s_transactions(_, [], []).

preprocess_s_transactions(Transaction_Types, [S_Transaction | S_Transactions],
		[UnX_Transaction | [X_Transaction | [Trading_Transaction | PP_Transactions]]]) :-
	transaction_type_of(Transaction_Types, S_Transaction, Transaction_Type),
	
	% Make an unexchanged transaction to the unexchanged account
	s_transaction_day(S_Transaction, Day), transaction_day(UnX_Transaction, Day),
	transaction_type_description(Transaction_Type, Description), transaction_description(UnX_Transaction, Description),
	s_transaction_vector(S_Transaction, Vector),
	vec_inverse(Vector, Vector_Inverted),
	transaction_vector(UnX_Transaction, Vector_Inverted),
	s_transaction_account(S_Transaction, UnX_Account), transaction_account(UnX_Transaction, UnX_Account),
	
	% Make an inverse exchanged transaction to the exchanged account
	transaction_type_bases(Transaction_Type, Bases),
	vec_change_bases(Day, Bases, Vector, Vector_Transformed),
	transaction_day(X_Transaction, Day),
	transaction_description(X_Transaction, Description),
	transaction_vector(X_Transaction, Vector_Transformed),
	transaction_type_exchanged_account(Transaction_Type, X_Account), transaction_account(X_Transaction, X_Account),
	
	% Make a difference transaction to the trading account
	vec_sub(Vector, Vector_Transformed, Trading_Vector),
	transaction_day(Trading_Transaction, Day),
	transaction_description(Trading_Transaction, Description),
	transaction_vector(Trading_Transaction, Trading_Vector),
	transaction_type_trading_account(Transaction_Type, Trading_Account), transaction_account(Trading_Transaction, Trading_Account),
	
	% Make the list of preprocessed transactions
	preprocess_s_transactions(Transaction_Types, S_Transactions, PP_Transactions), !.


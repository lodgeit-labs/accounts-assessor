% Pacioli group operations
% See: On Double-Entry Bookkeeping: The Mathematical Treatment

pac_id(t_term(0, 0)).

pac_add(t_term(A, B), t_term(C, D), Res) :-
	E is A + C,
	F is B + D,
	Res = t_term(E, F).

pac_eq(t_term(A, B), t_term(C, D)) :-
	E is A + D,
	E is C + B.

pac_inv(t_term(A, B), t_term(B, A)).

pac_red(t_term(A, B), C) :-
	D is A - min(A, B),
	E is B - min(A, B),
	C = t_term(D, E).

% Isomorphisms from T-Terms to signed quantities
% See: On Double-Entry Bookkeeping: The Mathematical Treatment

credit_isomorphism(t_term(A, B), C) :- C is B - A.

debit_isomorphism(t_term(A, B), C) :- C is A - B.

% The T-Account for some hypothetical business. The schema follows:
% transaction(Date, Description, Account, T_Term).

transactions([transaction(date(17, 7, 1), invest_in_business, bank, t_term(100, 0)),
	transaction(date(17, 7, 1), invest_in_business, share_capital, t_term(0, 100)),
	transaction(date(17, 7, 2), buy_inventory, inventory, t_term(50, 0)),
	transaction(date(17, 7, 2), buy_inventory, accounts_payable, t_term(0, 50)),
	transaction(date(17, 7, 3), sell_inventory, accounts_receivable, t_term(100, 0)),
	transaction(date(17, 7, 3), sell_inventory, sales, t_term(0, 100)),
	transaction(date(17, 7, 3), sell_inventory, cost_of_goods_sold, t_term(50, 0)),
	transaction(date(17, 7, 3), sell_inventory, inventory, t_term(0, 50))]).

% T-Account predicates for asserting that the fields of given records have particular values

transaction_date(Index, Date) :-
	transactions(X), nth0(Index, X, transaction(Date, _, _, _)).

transaction_description(Index, Description) :-
	transactions(X), nth0(Index, X, transaction(_, Description, _, _)).

transaction_account(Index, Account) :-
	transactions(X), nth0(Index, X, transaction(_, _, Account, _)).

transaction_t_term(Index, T_Term) :-
	transactions(X), nth0(Index, X, transaction(_, _, _, T_Term)).

% Account types. This information was implicit in the ledger.

account_type(bank, asset).
account_type(share_capital, equity).
account_type(inventory, asset).
account_type(accounts_payable, liability).
account_type(accounts_receivable, asset).
account_type(sales, revenue).
account_type(cost_of_goods_sold, expense).

% Account isomorphisms. They are standard conventions in accounting.

account_isomorphism(asset, debit_isomorphism).
account_isomorphism(equity, credit_isomorphism).
account_isomorphism(liability, credit_isomorphism).
account_isomorphism(revenue, credit_isomorphism).
account_isomorphism(expense, debit_isomorphism).

% account_net_activity(Pred, From_Trans_Idx, To_Trans_Idx, Net_Activity)
% Adds all the T-Terms of the transactions with indicies between From_Trans_Idx and To_Trans_Idx
% (inclusive) and that satisfy the predicate Pred.

account_net_activity(_, From_Trans_Idx, To_Trans_Idx, t_term(0, 0)) :-
	To_Trans_Idx is From_Trans_Idx - 1.

account_net_activity(Pred, From_Trans_Idx, To_Trans_Idx, Net_Activity) :-
	To_Trans_Idx >= From_Trans_Idx,
	call(Pred, To_Trans_Idx, true),
	transaction_t_term(To_Trans_Idx, Curr),
	Prev_Trans_Idx is To_Trans_Idx - 1,
	account_net_activity(Pred, From_Trans_Idx, Prev_Trans_Idx, Acc),
	pac_add(Curr, Acc, Net_Activity).

account_net_activity(Pred, From_Trans_Idx, To_Trans_Idx, Net_Activity) :-
	To_Trans_Idx >= From_Trans_Idx,
	call(Pred, To_Trans_Idx, false),
	Prev_Trans_Idx is To_Trans_Idx - 1,
	account_net_activity(Pred, From_Trans_Idx, Prev_Trans_Idx, Net_Activity).

% account_balance(Pred, From_Trans_Idx, To_Trans_Idx, Bal)
% Adds all the T-Terms of the transactions with indicies between 0 and To_Trans_Idx
% (inclusive) and that satisfy the predicate Pred.

account_balance(Pred, Trans_Idx, Bal) :- account_net_activity(Pred, 0, Trans_Idx, Bal).

% The following predicates assert relationships between transaction dates and transaction
% indicies. They are useful because transactions are identified by their indicies (and not
% their dates) in other predicates.

% Predicate for asserting what the last index corresponding to a given date is.

last_index(Date, Last_Index) :-
	transaction_date(Last_Index, A),
	A @=< Date,
	After_Last_Index is Last_Index + 1,
	transactions(Transactions),
	(length(Transactions, After_Last_Index); (transaction_date(After_Last_Index, B), B @> Date)).

% Predicate for asserting what the first index corresponding to a given date is.

first_index(Date, First_Index) :-
	transaction_date(First_Index, A),
	A @>= Date,
	Before_First_Index is First_Index - 1,
	(Before_First_Index is -1; (transaction_date(Before_First_Index, B), B @< Date)).

% Now for some examples of how to use the above predicates.

% The following predicates, for example, are useful as values to be supplied to higher
% order predicates that assert things about subsets of the set of transactions.

% A predicate to indicate a transaction on an asset-typed account
asset_typed_account(Trans_Idx, true) :-
	transaction_account(Trans_Idx, Transaction_Account),
	account_type(Transaction_Account, asset).

asset_typed_account(Trans_Idx, false) :-
	transaction_account(Trans_Idx, Transaction_Account),
	account_type(Transaction_Account, Account_Type),
	Account_Type \= asset.

% A predicate to indicate a transaction on an inventory account
inventory_account(Trans_Idx, true) :-
	transaction_account(Trans_Idx, inventory).

inventory_account(Trans_Idx, false) :-
	transaction_account(Trans_Idx, Account),
	Account \= inventory.

% Let's get the balance of the inventory account after 7th transaction:
% account_balance(inventory_account, 7, Bal).
% Result should be Bal = t_term(50, 50)

% What if we want the balance as a signed quantity?
% account_balance(inventory_account, 7, Bal), debit_isomorphism(Bal, Signed_Bal).
% Result should be Bal = t_term(50, 50), Signed_Bal = 0.

% What is the isomorphism of the inventory account?
% account_type(inventory, Account_Type), account_isomorphism(Account_Type, Isomorphism).
% Result should be Account_Type = asset, Isomorphism = debit_isomorphism.

% Let's get the net activity of the asset-typed account between the 2nd and 5th transactions.
% account_net_activity(asset_typed_account, 2, 5, Net_Activity).
% Result should be Net_Activity = t_term(150, 0)

% Was the fifth transaction done on the cost_of_goods_sold account?
% transaction_account(5, cost_of_goods_sold).
% Answer is no.

% So was it done on the sales account?
% transaction_account(5, sales).
% Answer is yes.

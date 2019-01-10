% Pacioli group operations.
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
	transaction(date(17, 7, 3), sell_inventory, inventory, t_term(0, 50)),
	transaction(date(18, 7, 1), pay_creditor, accounts_payable, t_term(50, 0)),
	transaction(date(18, 7, 1), pay_creditor, bank, t_term(0, 50)),
	transaction(date(19, 6, 2), buy_stationary, stationary, t_term(10, 0)),
	transaction(date(19, 6, 2), buy_stationary, bank, t_term(0, 10))]).

% T-Account predicates for asserting that the fields of given records have particular values

transaction_date(Index, Date) :-
	transactions(X), nth0(Index, X, transaction(Date, _, _, _)).

transaction_description(Index, Description) :-
	transactions(X), nth0(Index, X, transaction(_, Description, _, _)).

transaction_account(Index, Account) :-
	transactions(X), nth0(Index, X, transaction(_, _, Account, _)).

transaction_t_term(Index, T_Term) :-
	transactions(X), nth0(Index, X, transaction(_, _, _, T_Term)).

% Account type relationships. This information was implicit in the ledger.

account_type(bank, asset).
account_type(share_capital, equity).
account_type(inventory, asset).
account_type(accounts_payable, liability).
account_type(accounts_receivable, asset).
account_type(sales, revenue).
account_type(cost_of_goods_sold, expense).
account_type(stationary, expense).

% Account isomorphisms. They are standard conventions in accounting.

account_isomorphism(asset, debit_isomorphism).
account_isomorphism(equity, credit_isomorphism).
account_isomorphism(liability, credit_isomorphism).
account_isomorphism(revenue, credit_isomorphism).
account_isomorphism(expense, debit_isomorphism).

% The following predicates are useful as values to be supplied to higher
% order predicates that assert things about subsets of the set of transactions.

% Predicates to indicate transactions on different account types.

transaction_account_type(Trans_Idx, Account_Type, true) :-
	transaction_account(Trans_Idx, Transaction_Account),
	account_type(Transaction_Account, Account_Type).

transaction_account_type(Trans_Idx, Account_Type, false) :-
	transaction_account(Trans_Idx, Transaction_Account),
	account_type(Transaction_Account, Transaction_Account_Type),
	Transaction_Account_Type \= Account_Type.

asset_transaction(Trans_Idx, Result) :- transaction_account_type(Trans_Idx, asset, Result).

revenue_transaction(Trans_Idx, Result) :- transaction_account_type(Trans_Idx, revenue, Result).

expense_transaction(Trans_Idx, Result) :- transaction_account_type(Trans_Idx, expense, Result).

% Predicate to indicate transactions on different accounts.

transaction_account(Trans_Idx, Account, true) :-
	transaction_account(Trans_Idx, Account).

transaction_account(Trans_Idx, Account, false) :-
	transaction_account(Trans_Idx, TransactionAccount),
	TransactionAccount \= Account.

inventory_transaction(Trans_Idx, Result) :- transaction_account(Trans_Idx, inventory, Result).

% Adds all the T-Terms of the transactions with indicies between From_Trans_Idx and To_Trans_Idx
% (inclusive) and that satisfy the predicate Pred.

net_activity(_, From_Trans_Idx, To_Trans_Idx, t_term(0, 0)) :-
	To_Trans_Idx is From_Trans_Idx - 1.

net_activity(Pred, From_Trans_Idx, To_Trans_Idx, Net_Activity) :-
	To_Trans_Idx >= From_Trans_Idx,
	call(Pred, To_Trans_Idx, true),
	transaction_t_term(To_Trans_Idx, Curr),
	Prev_Trans_Idx is To_Trans_Idx - 1,
	net_activity(Pred, From_Trans_Idx, Prev_Trans_Idx, Acc),
	pac_add(Curr, Acc, Net_Activity).

net_activity(Pred, From_Trans_Idx, To_Trans_Idx, Net_Activity) :-
	To_Trans_Idx >= From_Trans_Idx,
	call(Pred, To_Trans_Idx, false),
	Prev_Trans_Idx is To_Trans_Idx - 1,
	net_activity(Pred, From_Trans_Idx, Prev_Trans_Idx, Net_Activity).

% Adds all the T-Terms of the transactions with indicies up to To_Trans_Idx (inclusive)
% and that satisfy the predicate Pred.

balance(Pred, Trans_Idx, Bal) :- net_activity(Pred, 0, Trans_Idx, Bal).

% Relates the current earnings over a given period to the range of the period from
% From_Trans_Idx to To_Trans_Idx.

current_earnings(From_Trans_Idx, To_Trans_Idx, Current_Earnings) :-
	net_activity(revenue_transaction, From_Trans_Idx, To_Trans_Idx, Net_Revenue),
	net_activity(expense_transaction, From_Trans_Idx, To_Trans_Idx, Net_Expense),
	pac_add(Net_Revenue, Net_Expense, Current_Earnings).

% Relates the retained earnings just after a given transaction to the index of the
% transaction Trans_Idx.

retained_earnings(Trans_Idx, Current_Earnings) :-
	current_earnings(0, Trans_Idx, Current_Earnings).

% The following predicates relate transaction dates to transaction indicies. They are
% useful because transactions are identified by their indicies (and not their dates) in
% other predicates.

% Predicate relates date to the last transaction occuring before it ends.

last_index(Date, Last_Index) :-
	transaction_date(Last_Index, A),
	A @=< Date,
	After_Last_Index is Last_Index + 1,
	transactions(Transactions),
	(length(Transactions, After_Last_Index); (transaction_date(After_Last_Index, B), B @> Date)).

% Predicate relates date to the first transaction occuring after it starts.

first_index(Date, First_Index) :-
	transaction_date(First_Index, A),
	A @>= Date,
	Before_First_Index is First_Index - 1,
	(Before_First_Index is -1; (transaction_date(Before_First_Index, B), B @< Date)).

% Now for some examples of how to use the above predicates.

% Let's get the retained earnings as of date(17, 7, 3):
% last_index(date(17, 7, 3), Last_Index), retained_earnings(Last_Index, Retained_Earnings),
% credit_isomorphism(Retained_Earnings, Retained_Earnings_Signed).
% Result should be Last_Index = 7, Retained_Earnings = t_term(50, 100),
% Retained_Earnings_Signed = 50

% Let's get the retained earnings as of date(19, 6, 2):
% last_index(date(19, 6, 2), Last_Index), retained_earnings(Last_Index, Retained_Earnings),
% credit_isomorphism(Retained_Earnings, Retained_Earnings_Signed).
% Result should be Last_Index = 11, Retained_Earnings = t_term(60, 100),
% Retained_Earnings_Signed = 40

% Let's get the current earnings between date(17, 7, 1) and date(17, 7, 3):
% first_index(date(17, 7, 1), First_Index), last_index(date(17, 7, 3), Last_Index),
% current_earnings(First_Index, Last_Index, Current_Earnings),
% credit_isomorphism(Current_Earnings, Current_Earnings_Signed).
% Result should be First_Index = 0, Last_Index = 7, Current_Earnings = t_term(50, 100),
% Current_Earnings_Signed = 50

% Let's get the current earnings between date(18, 7, 1) and date(19, 6, 2):
% first_index(date(18, 7, 1), First_Index), last_index(date(19, 6, 2), Last_Index),
% current_earnings(First_Index, Last_Index, Current_Earnings),
% credit_isomorphism(Current_Earnings, Current_Earnings_Signed).
% Result should be First_Index = 8, Last_Index = 11, Current_Earnings = t_term(10, 0),
% Current_Earnings_Signed = -10

% Let's get the balance of the inventory account after 7th transaction:
% balance(inventory_transaction, 7, Bal).
% Result should be Bal = t_term(50, 50)

% What if we want the balance as a signed quantity?
% balance(inventory_transaction, 7, Bal), debit_isomorphism(Bal, Signed_Bal).
% Result should be Bal = t_term(50, 50), Signed_Bal = 0.

% What is the isomorphism of the inventory account?
% account_type(inventory, Account_Type), account_isomorphism(Account_Type, Isomorphism).
% Result should be Account_Type = asset, Isomorphism = debit_isomorphism.

% Let's get the net activity of the asset-typed account between the 2nd and 5th transactions.
% net_activity(asset_transaction, 2, 5, Net_Activity).
% Result should be Net_Activity = t_term(150, 0)

% Was the fifth transaction done on the cost_of_goods_sold account?
% transaction_account(5, cost_of_goods_sold).
% Answer is no.

% So was it done on the sales account?
% transaction_account(5, sales).
% Answer is yes.

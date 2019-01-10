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

transactions(transaction(0, date(17, 7, 1), invest_in_business, bank, t_term(100, 0))).
transactions(transaction(1, date(17, 7, 1), invest_in_business, share_capital, t_term(0, 100))).
transactions(transaction(2, date(17, 7, 2), buy_inventory, inventory, t_term(50, 0))).
transactions(transaction(3, date(17, 7, 2), buy_inventory, accounts_payable, t_term(0, 50))).
transactions(transaction(4, date(17, 7, 3), sell_inventory, accounts_receivable, t_term(100, 0))).
transactions(transaction(5, date(17, 7, 3), sell_inventory, sales, t_term(0, 100))).
transactions(transaction(6, date(17, 7, 3), sell_inventory, cost_of_goods_sold, t_term(50, 0))).
transactions(transaction(7, date(17, 7, 3), sell_inventory, inventory, t_term(0, 50))).
transactions(transaction(8, date(18, 7, 1), pay_creditor, accounts_payable, t_term(50, 0))).
transactions(transaction(9, date(18, 7, 1), pay_creditor, bank, t_term(0, 50))).
transactions(transaction(10, date(19, 6, 2), buy_stationary, stationary, t_term(10, 0))).
transactions(transaction(11, date(19, 6, 2), buy_stationary, bank, t_term(0, 10))).

% T-Account predicates for asserting that the fields of given records have particular values

transaction_index(transaction(Index, _, _, _, _), Index).

transaction_date(transaction(_, Date, _, _, _), Date).

transaction_description(transaction(_, _, Description, _, _), Description).

transaction_account(transaction(_, _, _, Account, _), Account).

transaction_t_term(transaction(_, _, _, _, T_Term), T_Term).

transaction_account_type(Transaction, Account_Type) :-
	transaction_account(Transaction, Transaction_Account),
	account_type(Transaction_Account, Account_Type).

transaction_between(Transaction, From_Date, To_Date) :-
	transaction_date(Transaction, Date),
	From_Date @=< Date,
	Date @=< To_Date.

transaction_before(Transaction, End_Date) :-
	transaction_date(Transaction, Date),
	Date @=< End_Date.

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

% Adds all the T-Terms of the transactions.

transaction_t_term_total([], t_term(0, 0)).

transaction_t_term_total([Hd_Transaction | Tl_Transaction], Net_Activity) :-
	transaction_t_term(Hd_Transaction, Curr),
	transaction_t_term_total(Tl_Transaction, Acc),
	pac_add(Curr, Acc, Net_Activity).

% Relates Date to the balance at that time of the given account.

balance_by_account(Account, Date, Balance) :-
	findall(Transaction,
		(transactions(Transaction),
		transaction_before(Transaction, Date),
		transaction_account(Transaction, Account)), Transactions),
	transaction_t_term_total(Transactions, Balance).

% Relates Date to the balance at that time of the given account type.

balance_by_account_type(Account_Type, Date, Balance) :-
	findall(Transaction,
		(transactions(Transaction),
		transaction_before(Transaction, Date),
		transaction_account_type(Transaction, Account_Type)), Transactions),
	transaction_t_term_total(Transactions, Balance).

% Relates the period from From_Date to To_Date to the net activity during that period of
% the given account.

net_activity_by_account(Account, From_Date, To_Date, Net_Activity) :-
	findall(Transaction,
		(transactions(Transaction),
		transaction_between(Transaction, From_Date, To_Date),
		transaction_account(Transaction, Account)), Transactions),
	transaction_t_term_total(Transactions, Net_Activity).

% Relates the period from From_Date to To_Date to the net activity during that period of
% the given account type.

net_activity_by_account_type(Account_Type, From_Date, To_Date, Net_Activity) :-
	findall(Transaction,
		(transactions(Transaction),
		transaction_between(Transaction, From_Date, To_Date),
		transaction_account_type(Transaction, Account_Type)), Transactions),
	transaction_t_term_total(Transactions, Net_Activity).

% Relates the period from From_Date to To_Date to the current earnings of that period.

current_earnings(From_Date, To_Date, Current_Earnings) :-
	findall(Transaction,
		(transactions(Transaction),
		transaction_between(Transaction, From_Date, To_Date),
		(transaction_account_type(Transaction, revenue);
		transaction_account_type(Transaction, expense))), Transactions),
	transaction_t_term_total(Transactions, Current_Earnings).

% Relates the date, To_Date, to the retained earnings at that point.

retained_earnings(To_Date, Retained_Earnings) :-
	findall(Transaction,
		(transactions(Transaction),
		transaction_before(Transaction, To_Date),
		(transaction_account_type(Transaction, revenue);
		transaction_account_type(Transaction, expense))), Transactions),
	transaction_t_term_total(Transactions, Retained_Earnings).

% Now for some examples of how to use the above predicates.

% Let's get the retained earnings as of date(17, 7, 3):
% retained_earnings(date(17, 7, 3), Retained_Earnings),
% credit_isomorphism(Retained_Earnings, Retained_Earnings_Signed).
% Result should be Retained_Earnings = t_term(50, 100), Retained_Earnings_Signed = 50

% Let's get the retained earnings as of date(19, 6, 2):
% retained_earnings(date(19, 6, 2), Retained_Earnings),
% credit_isomorphism(Retained_Earnings, Retained_Earnings_Signed).
% Result should be Retained_Earnings = t_term(60, 100), Retained_Earnings_Signed = 40

% Let's get the current earnings between date(17, 7, 1) and date(17, 7, 3):
% current_earnings(date(17, 7, 1), date(17, 7, 3), Current_Earnings),
% credit_isomorphism(Current_Earnings, Current_Earnings_Signed).
% Result should be Current_Earnings = t_term(50, 100), Current_Earnings_Signed = 50

% Let's get the current earnings between date(18, 7, 1) and date(19, 6, 2):
% current_earnings(date(18, 7, 1), date(19, 6, 2), Current_Earnings),
% credit_isomorphism(Current_Earnings, Current_Earnings_Signed).
% Result should be Current_Earnings = t_term(10, 0), Current_Earnings_Signed = -10

% Let's get the balance of the inventory account as of date(17, 7, 3):
% balance_by_account(inventory, date(17, 7, 3), Bal).
% Result should be Bal = t_term(50, 50)

% What if we want the balance as a signed quantity?
% balance_by_account(inventory, date(17, 7, 3), Bal), debit_isomorphism(Bal, Signed_Bal).
% Result should be Bal = t_term(50, 50), Signed_Bal = 0.

% What is the isomorphism of the inventory account?
% account_type(inventory, Account_Type), account_isomorphism(Account_Type, Isomorphism).
% Result should be Account_Type = asset, Isomorphism = debit_isomorphism.

% Let's get the net activity of the asset-typed account between date(17, 7, 2) and date(17, 7, 3).
% net_activity_by_account_type(asset, date(17, 7, 2), date(17, 7, 3), Net_Activity).
% Result should be Net_Activity = t_term(150, 50)


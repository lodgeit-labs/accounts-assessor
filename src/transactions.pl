% Pacioli group operations.
% See: On Double-Entry Bookkeeping: The Mathematical Treatment

pac_identity(t_term(0, 0)).

pac_add(t_term(A, B), t_term(C, D), Res) :-
	E is A + C,
	F is B + D,
	Res = t_term(E, F).

pac_equality(t_term(A, B), t_term(C, D)) :-
	E is A + D,
	E is C + B.

pac_inverse(t_term(A, B), t_term(B, A)).

pac_reduce(t_term(A, B), C) :-
	D is A - min(A, B),
	E is B - min(A, B),
	C = t_term(D, E).

% Isomorphisms from T-Terms to signed quantities
% See: On Double-Entry Bookkeeping: The Mathematical Treatment

credit_isomorphism(t_term(A, B), C) :- C is B - A.

debit_isomorphism(t_term(A, B), C) :- C is A - B.

% T-Account predicates for asserting that the fields of given records have particular values

transaction_date(transaction(Date, _, _, _), Date).

transaction_description(transaction(_, Description, _, _), Description).

transaction_account(transaction(_, _, Account, _), Account).

transaction_t_term(transaction(_, _, _, T_Term), T_Term).

transaction_account_type(Transaction, Account_Type) :-
	transaction_account(Transaction, Transaction_Account),
	account_type(Transaction_Account, Account_Type).

transaction_between(Transaction, From_Date, To_Date) :-
	transaction_date(Transaction, Date),
	From_Date =< Date,
	Date =< To_Date.

transaction_before(Transaction, End_Date) :-
	transaction_date(Transaction, Date),
	Date =< End_Date.

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

% Now for balance sheet predicates.

balance_sheet_entry(Account_Type, To_Date, Sheet_Entry) :-
	account_type(Account, Account_Type),
	balance_by_account(Account, To_Date, Balance),
	pac_reduce(Balance, Reduced_Balance),
	Sheet_Entry = (Account, Reduced_Balance).

balance_sheet_at(To_Date, Balance_Sheet) :-
	findall(Entry, balance_sheet_entry(asset, To_Date, Entry), Asset_Section),
	findall(Entry, balance_sheet_entry(equity, To_Date, Entry), Equity_Section),
	findall(Entry, balance_sheet_entry(liability, To_Date, Entry), Liability_Section),
	retained_earnings(To_Date, Retained_Earnings),
	pac_reduce(Retained_Earnings, Reduced_Retained_Earnings),
	Balance_Sheet = balance_sheet(Asset_Section, Liability_Section,
		[(retained_earnings, Reduced_Retained_Earnings) | Equity_Section]).

balance_sheet_asset_accounts(balance_sheet(Asset_Accounts, _, _), Asset_Accounts).

balance_sheet_liability_accounts(balance_sheet(_, Liability_Accounts, _), Liability_Accounts).

balance_sheet_equity_accounts(balance_sheet(_, _, Equity_Accounts), Equity_Accounts).

% Now for trial balance predicates.

trial_balance_entry(Account_Type, From_Date, To_Date, Trial_Balance_Entry) :-
	account_type(Account, Account_Type),
	net_activity_by_account(Account, From_Date, To_Date, Net_Activity),
	pac_reduce(Net_Activity, Reduced_Net_Activity),
	Trial_Balance_Entry = (Account, Reduced_Net_Activity).

trial_balance_between(From_Date, To_Date, Trial_Balance) :-
	findall(Entry, balance_sheet_entry(asset, To_Date, Entry), Asset_Section),
	findall(Entry, balance_sheet_entry(equity, To_Date, Entry), Equity_Section),
	findall(Entry, balance_sheet_entry(liability, To_Date, Entry), Liability_Section),
	findall(Entry, trial_balance_entry(revenue, From_Date, To_Date, Entry), Revenue_Section),
	findall(Entry, trial_balance_entry(expense, From_Date, To_Date, Entry), Expense_Section),
	retained_earnings(From_Date, Retained_Earnings),
	pac_reduce(Retained_Earnings, Reduced_Retained_Earnings),
	Trial_Balance = trial_balance(Asset_Section, Liability_Section,
		[(retained_earnings, Reduced_Retained_Earnings) | Equity_Section], Revenue_Section,
		Expense_Section).

% Now for movement predicates.

movement_between(From_Date, To_Date, Movement) :-
	findall(Entry, trial_balance_entry(asset, From_Date, To_Date, Entry), Asset_Section),
	findall(Entry, trial_balance_entry(equity, From_Date, To_Date, Entry), Equity_Section),
	findall(Entry, trial_balance_entry(liability, From_Date, To_Date, Entry), Liability_Section),
	findall(Entry, trial_balance_entry(revenue, From_Date, To_Date, Entry), Revenue_Section),
	findall(Entry, trial_balance_entry(expense, From_Date, To_Date, Entry), Expense_Section),
	Movement = movement(Asset_Section, Liability_Section, Equity_Section, Revenue_Section,
		Expense_Section).

movement_asset_accounts(movement(Asset_Accounts, _, _, _, _), Asset_Accounts).

movement_liability_accounts(movement(_, Liability_Accounts, _, _, _), Liability_Accounts).

movement_equity_accounts(movement(_, _, Equity_Accounts, _, _), Equity_Accounts).

movement_revenue_accounts(movement(_, _, _, Revenue_Accounts, _), Revenue_Accounts).

movement_expense_accounts(movement(_, _, _, _, Expense_Accounts), Expense_Accounts).


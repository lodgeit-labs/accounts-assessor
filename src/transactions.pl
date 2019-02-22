% The purpose of the following program is to derive the summary information of a ledger.
% That is, with the knowledge of all the transactions in a ledger, the following program
% will derive the balance sheets at given points in time, and the trial balance and
% movements over given periods of time.

% This program is part of a larger system for validating and correcting balance sheets.
% Hence the information derived by this program will ultimately be compared to values
% calculated by other means.

% Pacioli group operations. These operations operate on pairs of numbers called T-terms.
% These t-terms represent an entry in a T-table. The first element of the T-term
% represents debit and second element, credit.
% See: On Double-Entry Bookkeeping: The Mathematical Treatment

pac_identity(t_term(0, 0)).

pac_inverse(t_term(A, B), t_term(B, A)).

pac_add(t_term(A, B), t_term(C, D), Res) :-
	E is A + C,
	F is B + D,
	Res = t_term(E, F).

pac_sub(A, B, Res) :-
	pac_inverse(B, C),
	pac_add(A, C, Res).

pac_equality(t_term(A, B), t_term(C, D)) :-
	E is A + D,
	E is C + B.

pac_reduce(t_term(A, B), C) :-
	D is A - min(A, B),
	E is B - min(A, B),
	C = t_term(D, E).

% Isomorphisms from T-Terms to signed quantities
% See: On Double-Entry Bookkeeping: The Mathematical Treatment

credit_isomorphism(t_term(A, B), C) :- C is B - A.

debit_isomorphism(t_term(A, B), C) :- C is A - B.

account_type(Accounts, Account, Account_Type) :-
	member(account(Account, Account_Type), Accounts).

% T-Account predicates for asserting that the fields of given records have particular values

% The absolute day that the transaction happenned
transaction_day(transaction(Day, _, _, _), Day).
% A description of the transaction
transaction_description(transaction(_, Description, _, _), Description).
% The account that the transaction modifies
transaction_account(transaction(_, _, Account, _), Account).
% The amounts by which the account is being debited and credited
transaction_t_term(transaction(_, _, _, T_Term), T_Term).

transaction_account_type(Accounts, Transaction, Account_Type) :-
	transaction_account(Transaction, Transaction_Account),
	account_type(Accounts, Transaction_Account, Account_Type).

transaction_between(Transaction, From_Day, To_Day) :-
	transaction_day(Transaction, Day),
	From_Day =< Day,
	Day =< To_Day.

transaction_before(Transaction, End_Day) :-
	transaction_day(Transaction, Day),
	Day =< End_Day.

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

% Relates Day to the balance at that time of the given account.

balance_by_account(Transactions, Account, Day, Balance) :-
	findall(Transaction,
		(member(Transaction, Transactions),
		transaction_before(Transaction, Day),
		transaction_account(Transaction, Account)), Transactions_A),
	transaction_t_term_total(Transactions_A, Balance).

% Relates Day to the balance at that time of the given account type.

balance_by_account_type(Accounts, Transactions, Account_Type, Day, Balance) :-
	findall(Transaction,
		(member(Transaction, Transactions),
		transaction_before(Transaction, Day),
		transaction_account_type(Accounts, Transaction, Account_Type)), Transactions_A),
	transaction_t_term_total(Transactions_A, Balance).

% Relates the period from From_Day to To_Day to the net activity during that period of
% the given account.

net_activity_by_account(Transactions, Account, From_Day, To_Day, Net_Activity) :-
	findall(Transaction,
		(member(Transaction, Transactions),
		transaction_between(Transaction, From_Day, To_Day),
		transaction_account(Transaction, Account)), Transactions_A),
	transaction_t_term_total(Transactions_A, Net_Activity).

% Relates the period from From_Day to To_Day to the net activity during that period of
% the given account type.

net_activity_by_account_type(Accounts, Transactions, Account_Type, From_Day, To_Day, Net_Activity) :-
	findall(Transaction,
		(member(Transaction, Transactions),
		transaction_between(Transaction, From_Day, To_Day),
		transaction_account_type(Accounts, Transaction, Account_Type)), Transactions_A),
	transaction_t_term_total(Transactions_A, Net_Activity).

% Relates the period from From_Day to To_Day to the current earnings of that period.

current_earnings(Accounts, Transactions, From_Day, To_Day, Current_Earnings) :-
	findall(Transaction,
		(member(Transaction, Transactions),
		transaction_between(Transaction, From_Day, To_Day),
		(transaction_account_type(Accounts, Transaction, revenue);
		transaction_account_type(Accounts, Transaction, expense))), Transactions_A),
	transaction_t_term_total(Transactions_A, Current_Earnings).

% Relates the date, To_Day, to the retained earnings at that point.

retained_earnings(Accounts, Transactions, To_Day, Retained_Earnings) :-
	findall(Transaction,
		(member(Transaction, Transactions),
		transaction_before(Transaction, To_Day),
		(transaction_account_type(Accounts, Transaction, revenue);
		transaction_account_type(Accounts, Transaction, expense))), Transactions_A),
	transaction_t_term_total(Transactions_A, Retained_Earnings).

% Now for balance sheet predicates.

balance_sheet_entry(Accounts, Transactions, Account_Type, To_Day, Sheet_Entry) :-
	account_type(Accounts, Account, Account_Type),
	balance_by_account(Transactions, Account, To_Day, Balance),
	pac_reduce(Balance, Reduced_Balance),
	Sheet_Entry = (Account, Reduced_Balance).

balance_sheet_at(Accounts, Transactions, To_Day, Balance_Sheet) :-
	findall(Entry, balance_sheet_entry(Accounts, Transactions, asset, To_Day, Entry), Asset_Section),
	findall(Entry, balance_sheet_entry(Accounts, Transactions, equity, To_Day, Entry), Equity_Section),
	findall(Entry, balance_sheet_entry(Accounts, Transactions, liability, To_Day, Entry), Liability_Section),
	retained_earnings(Accounts, Transactions, To_Day, Retained_Earnings),
	pac_reduce(Retained_Earnings, Reduced_Retained_Earnings),
	Balance_Sheet = balance_sheet(Asset_Section, Liability_Section,
		[(retained_earnings, Reduced_Retained_Earnings) | Equity_Section]).

balance_sheet_asset_accounts(balance_sheet(Asset_Accounts, _, _), Asset_Accounts).

balance_sheet_liability_accounts(balance_sheet(_, Liability_Accounts, _), Liability_Accounts).

balance_sheet_equity_accounts(balance_sheet(_, _, Equity_Accounts), Equity_Accounts).

% Now for trial balance predicates.

trial_balance_entry(Accounts, Transactions, Account_Type, From_Day, To_Day, Trial_Balance_Entry) :-
	account_type(Accounts, Account, Account_Type),
	net_activity_by_account(Transactions, Account, From_Day, To_Day, Net_Activity),
	pac_reduce(Net_Activity, Reduced_Net_Activity),
	Trial_Balance_Entry = (Account, Reduced_Net_Activity).

trial_balance_between(Accounts, Transactions, From_Day, To_Day, Trial_Balance) :-
	findall(Entry, balance_sheet_entry(Accounts, Transactions, asset, To_Day, Entry), Asset_Section),
	findall(Entry, balance_sheet_entry(Accounts, Transactions, equity, To_Day, Entry), Equity_Section),
	findall(Entry, balance_sheet_entry(Accounts, Transactions, liability, To_Day, Entry), Liability_Section),
	findall(Entry, trial_balance_entry(Accounts, Transactions, revenue, From_Day, To_Day, Entry), Revenue_Section),
	findall(Entry, trial_balance_entry(Accounts, Transactions, expense, From_Day, To_Day, Entry), Expense_Section),
	retained_earnings(Accounts, Transactions, From_Day, Retained_Earnings),
	pac_reduce(Retained_Earnings, Reduced_Retained_Earnings),
	Trial_Balance = trial_balance(Asset_Section, Liability_Section,
		[(retained_earnings, Reduced_Retained_Earnings) | Equity_Section], Revenue_Section,
		Expense_Section).

% Now for movement predicates.

movement_between(Accounts, Transactions, From_Day, To_Day, Movement) :-
	findall(Entry, trial_balance_entry(Accounts, Transactions, asset, From_Day, To_Day, Entry), Asset_Section),
	findall(Entry, trial_balance_entry(Accounts, Transactions, equity, From_Day, To_Day, Entry), Equity_Section),
	findall(Entry, trial_balance_entry(Accounts, Transactions, liability, From_Day, To_Day, Entry), Liability_Section),
	findall(Entry, trial_balance_entry(Accounts, Transactions, revenue, From_Day, To_Day, Entry), Revenue_Section),
	findall(Entry, trial_balance_entry(Accounts, Transactions, expense, From_Day, To_Day, Entry), Expense_Section),
	Movement = movement(Asset_Section, Liability_Section, Equity_Section, Revenue_Section,
		Expense_Section).

movement_asset_accounts(movement(Asset_Accounts, _, _, _, _), Asset_Accounts).

movement_liability_accounts(movement(_, Liability_Accounts, _, _, _), Liability_Accounts).

movement_equity_accounts(movement(_, _, Equity_Accounts, _, _), Equity_Accounts).

movement_revenue_accounts(movement(_, _, _, Revenue_Accounts, _), Revenue_Accounts).

movement_expense_accounts(movement(_, _, _, _, Expense_Accounts), Expense_Accounts).


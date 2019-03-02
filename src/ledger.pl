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

% Predicates for asserting that the fields of given accounts have particular values

% The child in the given account link
account_link_child(account_link(Account_Link_Child, _), Account_Link_Child).
% The parent in the given account link
account_link_parent(account_link(_, Account_Link_Parent), Account_Link_Parent).
% Relates an account to a parent account
account_parent(Account_Links, Account, Parent) :-
	account_link_parent(Account_Link, Parent),
	account_link_child(Account_Link, Account),
	member(Account_Link, Account_Links).
% Relates an account to an ancestral account
account_ancestor(Account_Links, Account, Ancestor) :-
	Account = Ancestor;
	(account_parent(Account_Links, Ancestor_Child, Ancestor),
	account_ancestor(Account_Links, Account, Ancestor_Child)).

% Predicates for asserting that the fields of given transactions have particular values

% The absolute day that the transaction happenned
transaction_day(transaction(Day, _, _, _), Day).
% A description of the transaction
transaction_description(transaction(_, Description, _, _), Description).
% The account that the transaction modifies
transaction_account(transaction(_, _, Account, _), Account).
% The amounts by which the account is being debited and credited
transaction_t_term(transaction(_, _, _, T_Term), T_Term).

transaction_account_ancestor(Account_Links, Transaction, Ancestor_Account) :-
	transaction_account(Transaction, Transaction_Account),
	account_ancestor(Account_Links, Transaction_Account, Ancestor_Account).

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

transaction_t_term_total([Hd_Transaction | Tl_Transaction], Reduced_Net_Activity) :-
	transaction_t_term(Hd_Transaction, Curr),
	transaction_t_term_total(Tl_Transaction, Acc),
	pac_add(Curr, Acc, Net_Activity),
	pac_reduce(Net_Activity, Reduced_Net_Activity).

% Relates Day to the balance at that time of the given account.

balance_by_account(Accounts, Transactions, Account, Day, Balance) :-
	findall(Transaction,
		(member(Transaction, Transactions),
		transaction_before(Transaction, Day),
		transaction_account_ancestor(Accounts, Transaction, Account)), Transactions_A),
	transaction_t_term_total(Transactions_A, Balance).

% Relates the period from From_Day to To_Day to the net activity during that period of
% the given account.

net_activity_by_account(Accounts, Transactions, Account, From_Day, To_Day, Net_Activity) :-
	findall(Transaction,
		(member(Transaction, Transactions),
		transaction_between(Transaction, From_Day, To_Day),
		transaction_account_ancestor(Accounts, Transaction, Account)), Transactions_A),
	transaction_t_term_total(Transactions_A, Net_Activity).

% Now for balance sheet predicates.

balance_sheet_entry(Account_Links, Transactions, Account, To_Day, Sheet_Entry) :-
	findall(Child_Sheet_Entry, (account_parent(Account_Links, Child_Account, Account),
		balance_sheet_entry(Account_Links, Transactions, Child_Account, To_Day, Child_Sheet_Entry)), Child_Sheet_Entries),
	balance_by_account(Account_Links, Transactions, Account, To_Day, Balance),
	Sheet_Entry = entry(Account, Balance, Child_Sheet_Entries).

balance_sheet_at(Accounts, Transactions, To_Day, Balance_Sheet) :-
	balance_sheet_entry(Accounts, Transactions, asset, To_Day, Asset_Section),
	balance_sheet_entry(Accounts, Transactions, equity, To_Day, Equity_Section),
	balance_sheet_entry(Accounts, Transactions, liability, To_Day, Liability_Section),
	balance_by_account(Accounts, Transactions, earnings, To_Day, Retained_Earnings),
	Balance_Sheet = [Asset_Section, Liability_Section, entry(retained_earnings, Retained_Earnings, []),
		Equity_Section].

% Now for trial balance predicates.

trial_balance_entry(Account_Links, Transactions, Account, From_Day, To_Day, Trial_Balance_Entry) :-
	findall(Child_Sheet_Entry, (account_parent(Account_Links, Child_Account, Account),
		trial_balance_entry(Account_Links, Transactions, Child_Account, From_Day, To_Day, Child_Sheet_Entry)), Child_Sheet_Entries),
	net_activity_by_account(Account_Links, Transactions, Account, From_Day, To_Day, Net_Activity),
	Trial_Balance_Entry = entry(Account, Net_Activity, Child_Sheet_Entries).

trial_balance_between(Accounts, Transactions, From_Day, To_Day, Trial_Balance) :-
	balance_sheet_entry(Accounts, Transactions, asset, To_Day, Asset_Section),
	balance_sheet_entry(Accounts, Transactions, equity, To_Day, Equity_Section),
	balance_sheet_entry(Accounts, Transactions, liability, To_Day, Liability_Section),
	trial_balance_entry(Accounts, Transactions, revenue, From_Day, To_Day, Revenue_Section),
	trial_balance_entry(Accounts, Transactions, expense, From_Day, To_Day, Expense_Section),
	balance_by_account(Accounts, Transactions, earnings, From_Day, Retained_Earnings),
	Trial_Balance = [Asset_Section, Liability_Section, entry(retained_earnings, Retained_Earnings, []),
		Equity_Section, Revenue_Section, Expense_Section].

% Now for movement predicates.

movement_between(Accounts, Transactions, From_Day, To_Day, Movement) :-
	trial_balance_entry(Accounts, Transactions, asset, From_Day, To_Day, Asset_Section),
	trial_balance_entry(Accounts, Transactions, equity, From_Day, To_Day, Equity_Section),
	trial_balance_entry(Accounts, Transactions, liability, From_Day, To_Day, Liability_Section),
	trial_balance_entry(Accounts, Transactions, revenue, From_Day, To_Day, Revenue_Section),
	trial_balance_entry(Accounts, Transactions, expense, From_Day, To_Day, Expense_Section),
	Movement = [Asset_Section, Liability_Section, Equity_Section, Revenue_Section,
		Expense_Section].


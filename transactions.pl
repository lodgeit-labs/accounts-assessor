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

% The T-Account for some hypothetical business. The schema follows:
% transaction(Date, Description, Account, T_Term).

transactions(transaction(date(2017, 7, 1), invest_in_business, bank, t_term(100, 0))).
transactions(transaction(date(2017, 7, 1), invest_in_business, share_capital, t_term(0, 100))).
transactions(transaction(date(2017, 7, 2), buy_inventory, inventory, t_term(50, 0))).
transactions(transaction(date(2017, 7, 2), buy_inventory, accounts_payable, t_term(0, 50))).
transactions(transaction(date(2017, 7, 3), sell_inventory, accounts_receivable, t_term(100, 0))).
transactions(transaction(date(2017, 7, 3), sell_inventory, sales, t_term(0, 100))).
transactions(transaction(date(2017, 7, 3), sell_inventory, cost_of_goods_sold, t_term(50, 0))).
transactions(transaction(date(2017, 7, 3), sell_inventory, inventory, t_term(0, 50))).
transactions(transaction(date(2018, 7, 1), pay_creditor, accounts_payable, t_term(50, 0))).
transactions(transaction(date(2018, 7, 1), pay_creditor, bank, t_term(0, 50))).
transactions(transaction(date(2019, 6, 2), buy_stationary, stationary, t_term(10, 0))).
transactions(transaction(date(2019, 6, 2), buy_stationary, bank, t_term(0, 10))).
transactions(transaction(date(2019, 7, 1), buy_inventory, inventory, t_term(125, 0))).
transactions(transaction(date(2019, 7, 1), buy_inventory, accounts_payable, t_term(0, 125))).
transactions(transaction(date(2019, 7, 8), sell_inventory, accounts_receivable, t_term(100, 0))).
transactions(transaction(date(2019, 7, 8), sell_inventory, sales, t_term(0, 100))).
transactions(transaction(date(2019, 7, 8), sell_inventory, cost_of_goods_sold, t_term(50, 0))).
transactions(transaction(date(2019, 7, 8), sell_inventory, inventory, t_term(0, 50))).
transactions(transaction(date(2020, 2, 13), payroll_payrun, wages, t_term(200, 0))).
transactions(transaction(date(2020, 2, 14), payroll_payrun, super_expense, t_term(19, 0))).
transactions(transaction(date(2020, 2, 13), payroll_payrun, super_payable, t_term(0, 19))).
transactions(transaction(date(2020, 2, 13), payroll_payrun, paygw_tax, t_term(0, 20))).
transactions(transaction(date(2020, 2, 13), payroll_payrun, wages_payable, t_term(0, 180))).
transactions(transaction(date(2020, 2, 13), pay_wage_liability, wages_payable, t_term(180, 0))).
transactions(transaction(date(2020, 2, 13), pay_wage_liability, bank, t_term(0, 180))).
transactions(transaction(date(2020, 4, 1), buy_truck, motor_vehicles, t_term(3000, 0))).
transactions(transaction(date(2020, 4, 1), buy_truck, hirepurchase_truck, t_term(0, 3000))).
transactions(transaction(date(2020, 4, 1), hire_purchase_truck_repayment, hirepurchase_truck, t_term(60, 0))).
transactions(transaction(date(2020, 4, 1), hire_purchase_truck_repayment, bank, t_term(0, 60))).
transactions(transaction(date(2020, 4, 28), pay_3rd_qtr_bas, paygw_tax, t_term(20, 0))).
transactions(transaction(date(2020, 4, 28), pay_3rd_qtr_bas, bank, t_term(0, 20))).
transactions(transaction(date(2020, 4, 28), pay_super, super_payable, t_term(19, 0))).
transactions(transaction(date(2020, 4, 28), pay_super, bank, t_term(0, 19))).
transactions(transaction(date(2020, 5, 1), hire_purchase_truck_replacement, hirepurchase_truck, t_term(41.16, 0))).
transactions(transaction(date(2020, 5, 1), hire_purchase_truck_replacement, hirepurchase_interest, t_term(18.84, 0))).
transactions(transaction(date(2020, 5, 1), hire_purchase_truck_replacement, bank, t_term(0, 60))).
transactions(transaction(date(2020, 6, 2), hire_purchase_truck_replacement, hirepurchase_truck, t_term(41.42, 0))).
transactions(transaction(date(2020, 6, 3), hire_purchase_truck_replacement, hirepurchase_interest, t_term(18.58, 0))).
transactions(transaction(date(2020, 6, 1), hire_purchase_truck_replacement, bank, t_term(0, 60))).
transactions(transaction(date(2020, 6, 10), collect_accs_rec, accounts_receivable, t_term(0, 100))).
transactions(transaction(date(2020, 6, 10), collect_accs_rec, bank, t_term(100, 0))).

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
account_type(wages, expense).
account_type(super_expense, expense).
account_type(super_payable, liability).
account_type(paygw_tax, liability).
account_type(wages_payable, liability).
account_type(motor_vehicles, asset).
account_type(hirepurchase_truck, liability).
account_type(hirepurchase_interest, expense).

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

% Now for some examples of how to use the above predicates.

% Let's get the trial balance between date(18, 7, 1) and date(19, 6, 30):
% trial_balance_between(date(18, 7, 1), date(19, 6, 30), X).
% ----------------------------------------------------------------------------------------
% Result should be X = trial_balance([ (bank, t_term(40, 0)), (inventory, t_term(0, 0)),
% (accounts_receivable, t_term(100, 0)), (motor_vehicles, t_term(0, 0))],
% [ (accounts_payable, t_term(0, 0)), (super_payable, t_term(0, 0)), (paygw_tax, t_term(0, 0)),
% (wages_payable, t_term(0, 0)), (hirepurchase_truck, t_term(0, 0))],
% [ (retained_earnings, t_term(0, 50)), (share_capital, t_term(0, 100))],
% [ (sales, t_term(0, 0))], [ (cost_of_goods_sold, t_term(0, 0)), (stationary, t_term(10, 0)),
% (wages, t_term(0, 0)), (super_expense, t_term(0, 0)), (hirepurchase_interest, t_term(0, 0))]).

% Let's get the balance sheet as of date(19, 6, 30):
% balance_sheet_at(date(19, 6, 30), X).
% ----------------------------------------------------------------------------------------
% Result should be X = balance_sheet([ (bank, t_term(40, 0)), (inventory, t_term(0, 0)),
% (accounts_receivable, t_term(100, 0)), (motor_vehicles, t_term(0, 0))],
% [ (accounts_payable, t_term(0, 0)), (super_payable, t_term(0, 0)), (paygw_tax, t_term(0, 0)),
% (wages_payable, t_term(0, 0)), (hirepurchase_truck, t_term(0, 0))],
% [ (retained_earnings, t_term(0, 40)), (share_capital, t_term(0, 100))]).

% Let's get the movement between date(19, 7, 1) and date(20, 6, 30):
% movement_between(date(19, 7, 1), date(20, 6, 30), X).
% ----------------------------------------------------------------------------------------
% Result should be X = movement([ (bank, t_term(0, 299)), (inventory, t_term(75, 0)),
% (accounts_receivable, t_term(0, 0)), (motor_vehicles, t_term(3000, 0))],
% [ (accounts_payable, t_term(0, 125)), (super_payable, t_term(0, 0)), (paygw_tax, t_term(0, 0)),
% (wages_payable, t_term(0, 0)), (hirepurchase_truck, t_term(0.0, 2857.42))],
% [ (share_capital, t_term(0, 0))], [ (sales, t_term(0, 100))], [ (cost_of_goods_sold, t_term(50, 0)),
% (stationary, t_term(0, 0)), (wages, t_term(200, 0)), (super_expense, t_term(19, 0)),
% (hirepurchase_interest, t_term(37.42, 0))]).

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


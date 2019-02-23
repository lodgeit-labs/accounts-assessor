recorda(accounts,
	[account(bank, asset),
	account(share_capital, equity),
	account(inventory, asset),
	account(accounts_payable, liability),
	account(accounts_receivable, asset),
	account(sales, revenue),
	account(cost_of_goods_sold, expense),
	account(stationary, expense),
	account(wages, expense),
	account(super_expense, expense),
	account(super_payable, liability),
	account(paygw_tax, liability),
	account(wages_payable, liability),
	account(motor_vehicles, asset),
	account(hirepurchase_truck, liability),
	account(hirepurchase_interest, expense)]).

recorda(transactions,
	[transaction(735614, "invest in business", hp_account, t_term(200.47, 0)),
	transaction(735614, "invest in business a", hp_account, t_term(200.47, 0)),
	transaction(735614, "invest in business b", hp_account, t_term(200.47, 0)),
	transaction(736511, "invest in business", bank, t_term(100, 0)),
	transaction(736511, "invest in business", share_capital, t_term(0, 100)),
	transaction(736512, "buy inventory", inventory, t_term(50, 0)),
	transaction(736512, "buy inventory", accounts_payable, t_term(0, 50)),
	transaction(736513, "sell inventory", accounts_receivable, t_term(100, 0)),
	transaction(736513, "sell inventory", sales, t_term(0, 100)),
	transaction(736513, "sell inventory", cost_of_goods_sold, t_term(50, 0)),
	transaction(736513, "sell inventory", inventory, t_term(0, 50)),
	transaction(736876, "pay creditor", accounts_payable, t_term(50, 0)),
	transaction(736876, "pay creditor", bank, t_term(0, 50)),
	transaction(737212, "buy stationary", stationary, t_term(10, 0)),
	transaction(737212, "buy stationary", bank, t_term(0, 10)),
	transaction(737241, "buy inventory", inventory, t_term(125, 0)),
	transaction(737241, "buy inventory", accounts_payable, t_term(0, 125)),
	transaction(737248, "sell inventory", accounts_receivable, t_term(100, 0)),
	transaction(737248, "sell inventory", sales, t_term(0, 100)),
	transaction(737248, "sell inventory", cost_of_goods_sold, t_term(50, 0)),
	transaction(737248, "sell inventory", inventory, t_term(0, 50)),
	transaction(737468, "payroll payrun", wages, t_term(200, 0)),
	transaction(737469, "payroll payrun", super_expense, t_term(19, 0)),
	transaction(737468, "payroll payrun", super_payable, t_term(0, 19)),
	transaction(737468, "payroll payrun", paygw_tax, t_term(0, 20)),
	transaction(737468, "payroll payrun", wages_payable, t_term(0, 180)),
	transaction(737468, "pay wage liability", wages_payable, t_term(180, 0)),
	transaction(737468, "pay wage liability", bank, t_term(0, 180)),
	transaction(737516, "buy truck", motor_vehicles, t_term(3000, 0)),
	transaction(737516, "buy truck", hirepurchase_truck, t_term(0, 3000)),
	transaction(737516, "hire purchase truck repayment", hirepurchase_truck, t_term(60, 0)),
	transaction(737516, "hire purchase truck repayment", bank, t_term(0, 60)),
	transaction(737543, "pay 3rd qtr bas", paygw_tax, t_term(20, 0)),
	transaction(737543, "pay 3rd qtr bas", bank, t_term(0, 20)),
	transaction(737543, "pay super", super_payable, t_term(19, 0)),
	transaction(737543, "pay super", bank, t_term(0, 19)),
	transaction(737546, "hire purchase truck replacement", hirepurchase_truck, t_term(41.16, 0)),
	transaction(737546, "hire purchase truck replacement", hirepurchase_interest, t_term(18.84, 0)),
	transaction(737546, "hire purchase truck replacement", bank, t_term(0, 60)),
	transaction(737578, "hire purchase truck replacement", hirepurchase_truck, t_term(41.42, 0)),
	transaction(737579, "hire purchase truck replacement", hirepurchase_interest, t_term(18.58, 0)),
	transaction(737577, "hire purchase truck replacement", bank, t_term(0, 60)),
	transaction(737586, "collect accs rec", accounts_receivable, t_term(0, 100)),
	transaction(737586, "collect accs rec", bank, t_term(100, 0))]).

% Let's get the trial balance between date(2018, 7, 1) and date(2019, 6, 30):
findall(Trial_Balance,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2018, 7, 1), From_Day),
		absolute_day(date(2019, 6, 30), To_Day),
		trial_balance_between(Accounts, Transactions, From_Day, To_Day, Trial_Balance)),
	
	[trial_balance([(bank, t_term(40, 0)), (inventory, t_term(0, 0)),
		(accounts_receivable, t_term(100, 0)), (motor_vehicles, t_term(0, 0))],
		[(accounts_payable, t_term(0, 0)), (super_payable, t_term(0, 0)), (paygw_tax, t_term(0, 0)),
		(wages_payable, t_term(0, 0)), (hirepurchase_truck, t_term(0, 0))],
		[(retained_earnings, t_term(0, 50)), (share_capital, t_term(0, 100))],
		[(sales, t_term(0, 0))], [ (cost_of_goods_sold, t_term(0, 0)), (stationary, t_term(10, 0)),
		(wages, t_term(0, 0)), (super_expense, t_term(0, 0)), (hirepurchase_interest, t_term(0, 0))])]).

% Let's get the balance sheet as of date(2019, 6, 30):
findall(Balance_Sheet,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2019, 6, 30), B),
		balance_sheet_at(Accounts, Transactions, B, Balance_Sheet)),
		
	[balance_sheet([(bank, t_term(40, 0)), (inventory, t_term(0, 0)),
		(accounts_receivable, t_term(100, 0)), (motor_vehicles, t_term(0, 0))],
		[(accounts_payable, t_term(0, 0)), (super_payable, t_term(0, 0)), (paygw_tax, t_term(0, 0)),
		(wages_payable, t_term(0, 0)), (hirepurchase_truck, t_term(0, 0))],
		[(retained_earnings, t_term(0, 40)), (share_capital, t_term(0, 100))])]).

% Let's get the movement between date(2019, 7, 1) and date(2020, 6, 30):
findall(Movement,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2019, 7, 1), A), absolute_day(date(2020, 6, 30), B),
		movement_between(Accounts, Transactions, A, B, Movement)),
		
	[movement([(bank, t_term(0, 299)), (inventory, t_term(75, 0)),
		(accounts_receivable, t_term(0, 0)), (motor_vehicles, t_term(3000, 0))],
		[(accounts_payable, t_term(0, 125)), (super_payable, t_term(0, 0)), (paygw_tax, t_term(0, 0)),
		(wages_payable, t_term(0, 0)), (hirepurchase_truck, t_term(0.0, 2857.42))],
		[(share_capital, t_term(0, 0))], [(sales, t_term(0, 100))], [(cost_of_goods_sold, t_term(50, 0)),
		(stationary, t_term(0, 0)), (wages, t_term(200, 0)), (super_expense, t_term(19, 0)),
		(hirepurchase_interest, t_term(37.42, 0))])]).

% Let's get the retained earnings as of date(2017, 7, 3):
findall(Retained_Earnings_Signed,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2017, 7, 3), B),
		retained_earnings(Accounts, Transactions, B, Retained_Earnings),
		credit_isomorphism(Retained_Earnings, Retained_Earnings_Signed)),
		
	[50]).


% Let's get the retained earnings as of date(2019, 6, 2):
findall(Retained_Earnings_Signed,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2019, 6, 2), B),
		retained_earnings(Accounts, Transactions, B, Retained_Earnings),
		credit_isomorphism(Retained_Earnings, Retained_Earnings_Signed)),
		
	[40]).

% Let's get the current earnings between date(2017, 7, 1) and date(2017, 7, 3):
findall(Current_Earnings_Signed,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2017, 7, 1), A), absolute_day(date(2017, 7, 3), B),
		current_earnings(Accounts, Transactions, A, B, Current_Earnings),
		credit_isomorphism(Current_Earnings, Current_Earnings_Signed)),
		
	[50]).

% Let's get the current earnings between date(2018, 7, 1) and date(2019, 6, 2):
findall(Current_Earnings_Signed,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2018, 7, 1), A), absolute_day(date(2019, 6, 2), B),
		current_earnings(Accounts, Transactions, A, B, Current_Earnings),
		credit_isomorphism(Current_Earnings, Current_Earnings_Signed)),
		
	[-10]).

% Let's get the balance of the inventory account as of date(2017, 7, 3):
findall(Bal,
	(recorded(transactions, Transactions),
		absolute_day(date(2017, 7, 3), B),
		balance_by_account(Transactions, inventory, B, Bal)),
		
	[t_term(50, 50)]).

% What if we want the balance as a signed quantity?
findall(Signed_Bal,
	(recorded(transactions, Transactions),
		absolute_day(date(2017, 7, 3), B),
		balance_by_account(Transactions, inventory, B, Bal), debit_isomorphism(Bal, Signed_Bal)),
		
	[0]).

% What is the isomorphism of the inventory account?
findall(Isomorphism,
	(recorded(accounts, Accounts),
		member(Account, Accounts),
		account_id(Account, inventory),
		account_type(Account, Account_Type),
		account_isomorphism(Account_Type, Isomorphism)),
		
	[debit_isomorphism]).

% Let's get the net activity of the asset-typed account between date(2017, 7, 2) and date(2017, 7, 3).
findall(Net_Activity,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2017, 7, 2), A),
		absolute_day(date(2017, 7, 3), B),
		net_activity_by_account_type(Accounts, Transactions, asset, A, B, Net_Activity)),
		
	[t_term(150, 50)]).


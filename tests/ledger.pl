write("Are we now testing the general ledger subprogram?").

recorda(accounts,
	[account_link(bank, asset),
	account_link(share_capital, equity),
	account_link(inventory, asset),
	account_link(accounts_payable, liability),
	account_link(accounts_receivable, asset),
	account_link(sales, revenue),
	account_link(cost_of_goods_sold, expense),
	account_link(stationary, expense),
	account_link(wages, expense),
	account_link(super_expense, expense),
	account_link(super_payable, liability),
	account_link(paygw_tax, liability),
	account_link(wages_payable, liability),
	account_link(motor_vehicles, asset),
	account_link(hirepurchase_truck, liability),
	account_link(hirepurchase_interest, expense),
	account_link(revenue, earnings),
	account_link(expense, earnings)]).

recorda(transactions,
	[transaction(735614, "invest in business", hp_account, [t_term(aud, 200.47, 0)]),
	transaction(735614, "invest in business a", hp_account, [t_term(aud, 200.47, 0)]),
	transaction(735614, "invest in business b", hp_account, [t_term(aud, 200.47, 0)]),
	transaction(736511, "invest in business", bank, [t_term(aud, 100, 0)]),
	transaction(736511, "invest in business", share_capital, [t_term(aud, 0, 100)]),
	transaction(736512, "buy inventory", inventory, [t_term(aud, 50, 0)]),
	transaction(736512, "buy inventory", accounts_payable, [t_term(aud, 0, 50)]),
	transaction(736513, "sell inventory", accounts_receivable, [t_term(aud, 100, 0)]),
	transaction(736513, "sell inventory", sales, [t_term(aud, 0, 100)]),
	transaction(736513, "sell inventory", cost_of_goods_sold, [t_term(aud, 50, 0)]),
	transaction(736513, "sell inventory", inventory, [t_term(aud, 0, 50)]),
	transaction(736876, "pay creditor", accounts_payable, [t_term(aud, 50, 0)]),
	transaction(736876, "pay creditor", bank, [t_term(aud, 0, 50)]),
	transaction(737212, "buy stationary", stationary, [t_term(aud, 10, 0)]),
	transaction(737212, "buy stationary", bank, [t_term(aud, 0, 10)]),
	transaction(737241, "buy inventory", inventory, [t_term(aud, 125, 0)]),
	transaction(737241, "buy inventory", accounts_payable, [t_term(aud, 0, 125)]),
	transaction(737248, "sell inventory", accounts_receivable, [t_term(aud, 100, 0)]),
	transaction(737248, "sell inventory", sales, [t_term(aud, 0, 100)]),
	transaction(737248, "sell inventory", cost_of_goods_sold, [t_term(aud, 50, 0)]),
	transaction(737248, "sell inventory", inventory, [t_term(aud, 0, 50)]),
	transaction(737468, "payroll payrun", wages, [t_term(aud, 200, 0)]),
	transaction(737469, "payroll payrun", super_expense, [t_term(aud, 19, 0)]),
	transaction(737468, "payroll payrun", super_payable, [t_term(aud, 0, 19)]),
	transaction(737468, "payroll payrun", paygw_tax, [t_term(aud, 0, 20)]),
	transaction(737468, "payroll payrun", wages_payable, [t_term(aud, 0, 180)]),
	transaction(737468, "pay wage liability", wages_payable, [t_term(aud, 180, 0)]),
	transaction(737468, "pay wage liability", bank, [t_term(aud, 0, 180)]),
	transaction(737516, "buy truck", motor_vehicles, [t_term(aud, 3000, 0)]),
	transaction(737516, "buy truck", hirepurchase_truck, [t_term(aud, 0, 3000)]),
	transaction(737516, "hire purchase truck repayment", hirepurchase_truck, [t_term(aud, 60, 0)]),
	transaction(737516, "hire purchase truck repayment", bank, [t_term(aud, 0, 60)]),
	transaction(737543, "pay 3rd qtr bas", paygw_tax, [t_term(aud, 20, 0)]),
	transaction(737543, "pay 3rd qtr bas", bank, [t_term(aud, 0, 20)]),
	transaction(737543, "pay super", super_payable, [t_term(aud, 19, 0)]),
	transaction(737543, "pay super", bank, [t_term(aud, 0, 19)]),
	transaction(737546, "hire purchase truck replacement", hirepurchase_truck, [t_term(aud, 41.16, 0)]),
	transaction(737546, "hire purchase truck replacement", hirepurchase_interest, [t_term(aud, 18.84, 0)]),
	transaction(737546, "hire purchase truck replacement", bank, [t_term(aud, 0, 60)]),
	transaction(737578, "hire purchase truck replacement", hirepurchase_truck, [t_term(aud, 41.42, 0)]),
	transaction(737579, "hire purchase truck replacement", hirepurchase_interest, [t_term(aud, 18.58, 0)]),
	transaction(737577, "hire purchase truck replacement", bank, [t_term(aud, 0, 60)]),
	transaction(737586, "collect accs rec", accounts_receivable, [t_term(aud, 0, 100)]),
	transaction(737586, "collect accs rec", bank, [t_term(aud, 100, 0)])]).

% Let's check the exchange rate predicate for historical correctness:
write("Are the certain exchange rates from the API matching manually obtained ones?"),

findall(Exchange_Rate, (absolute_day(date(2015, 6, 30), E),
		(exchange_rate(E, aud, usd, Exchange_Rate);
		exchange_rate(E, aud, mxn, Exchange_Rate);
		exchange_rate(E, aud, aud, Exchange_Rate);
		exchange_rate(E, aud, hkd, Exchange_Rate);
		exchange_rate(E, aud, ron, Exchange_Rate);
		exchange_rate(E, aud, hrk, Exchange_Rate);
		exchange_rate(E, aud, chf, Exchange_Rate))),
	[0.7690034364, 12.0503092784, 1.0, 5.9615120275, 	3.0738831615, 5.2197938144, 0.7156701031]).

% Let's get the trial balance between date(2018, 7, 1) and date(2019, 6, 30):
write("Is the output for a trial balance correct?"),

findall(Trial_Balance,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2018, 7, 1), From_Day),
		absolute_day(date(2019, 6, 30), To_Day),
		absolute_day(date(2019, 6, 30), E),
		trial_balance_between(Accounts, Transactions, [], E, From_Day, To_Day, Trial_Balance)),
	
	[[entry(asset,[t_term(aud, 140,0)],
			[entry(bank,[t_term(aud, 40,0)],[]),
			entry(inventory,[t_term(aud, 0,0)],[]),
			entry(accounts_receivable,[t_term(aud, 100,0)],[]),
			entry(motor_vehicles,[],[])]),
		entry(liability,[t_term(aud, 0,0)],
			[entry(accounts_payable,[t_term(aud, 0,0)],[]),
			entry(super_payable,[],[]),
			entry(paygw_tax,[],[]),
			entry(wages_payable,[],[]),
			entry(hirepurchase_truck,[],[])]),
		entry(retained_earnings,[t_term(aud, 0,50)],[]),
		entry(equity,[t_term(aud, 0,100)],
			[entry(share_capital,[t_term(aud, 0,100)],[])]),
		entry(revenue,[],
			[entry(sales,[],[])]),
		entry(expense,[t_term(aud, 10,0)],
			[entry(cost_of_goods_sold,[],[]),
			entry(stationary,[t_term(aud, 10,0)],[]),
			entry(wages,[],[]),
			entry(super_expense,[],[]),
			entry(hirepurchase_interest,[],[])])]]).

% Let's get the balance sheet as of date(2019, 6, 30):
write("Is the output for the balance at a given date correct?"),

findall(Balance_Sheet,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2018, 7, 1), From_Day),
		absolute_day(date(2019, 6, 30), To_Day),
		absolute_day(date(2019, 6, 30), E),
		balance_sheet_at(Accounts, Transactions, [], E, From_Day, To_Day, Balance_Sheet)),
		
	[[entry(asset,[t_term(aud, 140,0)],
			[entry(bank,[t_term(aud, 40,0)],[]),
			entry(inventory,[t_term(aud, 0,0)],[]),
			entry(accounts_receivable,[t_term(aud, 100,0)],[]),
			entry(motor_vehicles,[],[])]),
		entry(liability,[t_term(aud, 0,0)],
			[entry(accounts_payable,[t_term(aud, 0,0)],[]),
			entry(super_payable,[],[]),
			entry(paygw_tax,[],[]),
			entry(wages_payable,[],[]),
			entry(hirepurchase_truck,[],[])]),
		entry(earnings,[t_term(aud, 0,40)],
			[entry(retained_earnings,[t_term(aud, 0,50)],[]),
			entry(current_earnings,[t_term(aud, 10,0)],[])]),
		entry(equity,[t_term(aud, 0,100)],
			[entry(share_capital,[t_term(aud, 0,100)],[])])]]).

% Let's get the movement between date(2019, 7, 1) and date(2020, 6, 30):
write("Is the output for a movement between the two given dates correct?"),

findall(Movement,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2019, 7, 1), A), absolute_day(date(2020, 6, 30), B),
		absolute_day(date(2020, 6, 30), E),
		movement_between(Accounts, Transactions, [], E, A, B, Movement)),
		
	[[entry(asset,[t_term(aud, 2776,0)],
			[entry(bank,[t_term(aud, 0,299)],[]),
			entry(inventory,[t_term(aud, 75,0)],[]),
			entry(accounts_receivable,[t_term(aud, 0,0)],[]),
			entry(motor_vehicles,[t_term(aud, 3000,0)],[])]),
		entry(liability,[t_term(aud, 0.0,2982.42)],
			[entry(accounts_payable,[t_term(aud, 0,125)],[]),
			entry(super_payable,[t_term(aud, 0,0)],[]),
			entry(paygw_tax,[t_term(aud, 0,0)],[]),
			entry(wages_payable,[t_term(aud, 0,0)],[]),
			entry(hirepurchase_truck,[t_term(aud, 0.0,2857.42)],[])]),
		entry(equity,[],
			[entry(share_capital,[],[])]),
		entry(revenue,[t_term(aud, 0,100)],
			[entry(sales,[t_term(aud, 0,100)],[])]),
		entry(expense,[t_term(aud, 306.42,0)],
			[entry(cost_of_goods_sold,[t_term(aud, 50,0)],[]),
			entry(stationary,[],[]),
			entry(wages,[t_term(aud, 200,0)],[]),
			entry(super_expense,[t_term(aud, 19,0)],[]),
			entry(hirepurchase_interest,[t_term(aud, 37.42,0)],[])])]]).

% Let's get the retained earnings as of date(2017, 7, 3):
write("Is the output for the retained earnings at a given date correct?"),

findall(Retained_Earnings,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2017, 7, 3), B),
		absolute_day(date(2017, 7, 3), E),
		balance_by_account(Accounts, Transactions, [], E, earnings, B, Retained_Earnings)),
		
	[[t_term(aud, 0, 50)]]).

% Let's get the retained earnings as of date(2019, 6, 2):
write("Is the output for the retained earnings at another given date correct?"),

findall(Retained_Earnings,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2019, 6, 2), B),
		absolute_day(date(2019, 6, 2), E),
		balance_by_account(Accounts, Transactions, [], E, earnings, B, Retained_Earnings)),
		
	[[t_term(aud, 0, 40)]]).

% Let's get the current earnings between date(2017, 7, 1) and date(2017, 7, 3):
write("Is the output for the current earnings between two given dates correct?"),

findall(Current_Earnings_Signed,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2017, 7, 1), A), absolute_day(date(2017, 7, 3), B),
		absolute_day(date(2017, 7, 3), E),
		net_activity_by_account(Accounts, Transactions, [], E, earnings, A, B, Current_Earnings)),
		
	[[t_term(aud, 0, 50)]]).

% Let's get the current earnings between date(2018, 7, 1) and date(2019, 6, 2):
write("Is the output for the current earnings between another two given dates correct?"),

findall(Current_Earnings_Signed,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2018, 7, 1), A), absolute_day(date(2019, 6, 2), B),
		absolute_day(date(2019, 6, 2), E),
		net_activity_by_account(Accounts, Transactions, [], E, earnings, A, B, Current_Earnings)),
		
	[[t_term(aud, 10, 0)]]).

% Let's get the balance of the inventory account as of date(2017, 7, 3):
write("Is the output for the balance of the given account at a given date correct?"),

findall(Bal,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2017, 7, 3), B), absolute_day(date(2017, 7, 3), E),
		balance_by_account(Accounts, Transactions, [], E, inventory, B, Bal)),
		
	[[t_term(aud, 0, 0)]]).

% Let's get the net activity of the asset-typed account between date(2017, 7, 2) and date(2017, 7, 3).
write("Is the output for the net activity of the given account between the given dates correct?"),

findall(Net_Activity,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2017, 7, 2), A), absolute_day(date(2017, 7, 3), B),
		absolute_day(date(2017, 7, 3), E),
		net_activity_by_account(Accounts, Transactions, [], E, asset, A, B, Net_Activity)),
		
	[[t_term(aud, 100, 0)]]).


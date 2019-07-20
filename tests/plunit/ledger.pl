:- ['../../lib/days'].
:- ['../../lib/ledger'].

/*
fixme, needs updating 
*/

:- begin_tests(ledger).


test(ledger) :-
write("Are we now testing the general ledger subprogram?").


test(record) :-
recorda(accounts,
  % The first eight accounts have predefined meanings
	[account(asset, accounts),
	account(equity, accounts),
	account(liability, accounts),
	account(earnings, accounts),
	account(retained_earnings, accounts),
	account(current_earnings, accounts),
	account(revenue, earnings),
	account(expense, earnings),
	
	% The remaining accounts descend from the above accounts
	account(bank, asset),
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
	[transaction(735614, "invest in business", hp_account, [coord('AUD', 200.47, 0)]),
	transaction(735614, "invest in business a", hp_account, [coord('AUD', 200.47, 0)]),
	transaction(735614, "invest in business b", hp_account, [coord('AUD', 200.47, 0)]),
	transaction(736511, "invest in business", bank, [coord('AUD', 100, 0)]),
	transaction(736511, "invest in business", share_capital, [coord('AUD', 0, 100)]),
	transaction(736512, "buy inventory", inventory, [coord('AUD', 50, 0)]),
	transaction(736512, "buy inventory", accounts_payable, [coord('AUD', 0, 50)]),
	transaction(736513, "sell inventory", accounts_receivable, [coord('AUD', 100, 0)]),
	transaction(736513, "sell inventory", sales, [coord('AUD', 0, 100)]),
	transaction(736513, "sell inventory", cost_of_goods_sold, [coord('AUD', 50, 0)]),
	transaction(736513, "sell inventory", inventory, [coord('AUD', 0, 50)]),
	transaction(736876, "pay creditor", accounts_payable, [coord('AUD', 50, 0)]),
	transaction(736876, "pay creditor", bank, [coord('AUD', 0, 50)]),
	transaction(737212, "buy stationary", stationary, [coord('AUD', 10, 0)]),
	transaction(737212, "buy stationary", bank, [coord('AUD', 0, 10)]),
	transaction(737241, "buy inventory", inventory, [coord('AUD', 125, 0)]),
	transaction(737241, "buy inventory", accounts_payable, [coord('AUD', 0, 125)]),
	transaction(737248, "sell inventory", accounts_receivable, [coord('AUD', 100, 0)]),
	transaction(737248, "sell inventory", sales, [coord('AUD', 0, 100)]),
	transaction(737248, "sell inventory", cost_of_goods_sold, [coord('AUD', 50, 0)]),
	transaction(737248, "sell inventory", inventory, [coord('AUD', 0, 50)]),
	transaction(737468, "payroll payrun", wages, [coord('AUD', 200, 0)]),
	transaction(737469, "payroll payrun", super_expense, [coord('AUD', 19, 0)]),
	transaction(737468, "payroll payrun", super_payable, [coord('AUD', 0, 19)]),
	transaction(737468, "payroll payrun", paygw_tax, [coord('AUD', 0, 20)]),
	transaction(737468, "payroll payrun", wages_payable, [coord('AUD', 0, 180)]),
	transaction(737468, "pay wage liability", wages_payable, [coord('AUD', 180, 0)]),
	transaction(737468, "pay wage liability", bank, [coord('AUD', 0, 180)]),
	transaction(737516, "buy truck", motor_vehicles, [coord('AUD', 3000, 0)]),
	transaction(737516, "buy truck", hirepurchase_truck, [coord('AUD', 0, 3000)]),
	transaction(737516, "hire purchase truck repayment", hirepurchase_truck, [coord('AUD', 60, 0)]),
	transaction(737516, "hire purchase truck repayment", bank, [coord('AUD', 0, 60)]),
	transaction(737543, "pay 3rd qtr bas", paygw_tax, [coord('AUD', 20, 0)]),
	transaction(737543, "pay 3rd qtr bas", bank, [coord('AUD', 0, 20)]),
	transaction(737543, "pay super", super_payable, [coord('AUD', 19, 0)]),
	transaction(737543, "pay super", bank, [coord('AUD', 0, 19)]),
	transaction(737546, "hire purchase truck replacement", hirepurchase_truck, [coord('AUD', 41.16, 0)]),
	transaction(737546, "hire purchase truck replacement", hirepurchase_interest, [coord('AUD', 18.84, 0)]),
	transaction(737546, "hire purchase truck replacement", bank, [coord('AUD', 0, 60)]),
	transaction(737578, "hire purchase truck replacement", hirepurchase_truck, [coord('AUD', 41.42, 0)]),
	transaction(737579, "hire purchase truck replacement", hirepurchase_interest, [coord('AUD', 18.58, 0)]),
	transaction(737577, "hire purchase truck replacement", bank, [coord('AUD', 0, 60)]),
	transaction(737586, "collect accs rec", accounts_receivable, [coord('AUD', 0, 100)]),
	transaction(737586, "collect accs rec", bank, [coord('AUD', 100, 0)])]).








% Let's get the trial balance between date(2018, 7, 1) and date(2019, 6, 30):
test(trial_balance) :-
write("Is the output for a trial balance correct?"),

findall(Trial_Balance,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2018, 7, 1), From_Day),
		absolute_day(date(2019, 6, 30), To_Day),
		absolute_day(date(2019, 6, 30), E),
		trial_balance_between([], Accounts, Transactions, [], E, From_Day, To_Day, Trial_Balance)),
	
	[[entry(asset,[coord('AUD', 140,0)],
			[entry(bank,[coord('AUD', 40,0)],[]),
			entry(inventory,[coord('AUD', 0,0)],[]),
			entry(accounts_receivable,[coord('AUD', 100,0)],[]),
			entry(motor_vehicles,[],[])]),
		entry(liability,[coord('AUD', 0,0)],
			[entry(accounts_payable,[coord('AUD', 0,0)],[]),
			entry(super_payable,[],[]),
			entry(paygw_tax,[],[]),
			entry(wages_payable,[],[]),
			entry(hirepurchase_truck,[],[])]),
		entry(retained_earnings,[coord('AUD', 0,50)],[]),
		entry(equity,[coord('AUD', 0,100)],
			[entry(share_capital,[coord('AUD', 0,100)],[])]),
		entry(revenue,[],
			[entry(sales,[],[])]),
		entry(expense,[coord('AUD', 10,0)],
			[entry(cost_of_goods_sold,[],[]),
			entry(stationary,[coord('AUD', 10,0)],[]),
			entry(wages,[],[]),
			entry(super_expense,[],[]),
			entry(hirepurchase_interest,[],[])])]]).







% Let's get the balance sheet as of date(2019, 6, 30):
test(balance_sheet) :-
write("Is the output for the balance at a given date correct?"),

findall(Balance_Sheet,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2018, 7, 1), From_Day),
		absolute_day(date(2019, 6, 30), To_Day),
		absolute_day(date(2019, 6, 30), E),
		balance_sheet_at([], Accounts, Transactions, [], E, From_Day, To_Day, Balance_Sheet)),
		
	[[entry(asset,[coord('AUD', 140,0)],
			[entry(bank,[coord('AUD', 40,0)],[]),
			entry(inventory,[coord('AUD', 0,0)],[]),
			entry(accounts_receivable,[coord('AUD', 100,0)],[]),
			entry(motor_vehicles,[],[])]),
		entry(liability,[coord('AUD', 0,0)],
			[entry(accounts_payable,[coord('AUD', 0,0)],[]),
			entry(super_payable,[],[]),
			entry(paygw_tax,[],[]),
			entry(wages_payable,[],[]),
			entry(hirepurchase_truck,[],[])]),
		entry(earnings,[coord('AUD', 0,40)],
			[entry(retained_earnings,[coord('AUD', 0,50)],[]),
			entry(current_earnings,[coord('AUD', 10,0)],[])]),
		entry(equity,[coord('AUD', 0,100)],
			[entry(share_capital,[coord('AUD', 0,100)],[])])]]).








% Let's get the movement between date(2019, 7, 1) and date(2020, 6, 30):
test(movement) :-
write("Is the output for a movement between the two given dates correct?"),
findall(Movement,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2019, 7, 1), A), absolute_day(date(2020, 6, 30), B),
		absolute_day(date(2020, 6, 30), E),
		movement_between([], Accounts, Transactions, [], E, A, B, Movement)),
		
	[[entry(asset,[coord('AUD', 2776,0)],
			[entry(bank,[coord('AUD', 0,299)],[]),
			entry(inventory,[coord('AUD', 75,0)],[]),
			entry(accounts_receivable,[coord('AUD', 0,0)],[]),
			entry(motor_vehicles,[coord('AUD', 3000,0)],[])]),
		entry(liability,[coord('AUD', 0.0,2982.42)],
			[entry(accounts_payable,[coord('AUD', 0,125)],[]),
			entry(super_payable,[coord('AUD', 0,0)],[]),
			entry(paygw_tax,[coord('AUD', 0,0)],[]),
			entry(wages_payable,[coord('AUD', 0,0)],[]),
			entry(hirepurchase_truck,[coord('AUD', 0.0,2857.42)],[])]),
		entry(equity,[],
			[entry(share_capital,[],[])]),
		entry(revenue,[coord('AUD', 0,100)],
			[entry(sales,[coord('AUD', 0,100)],[])]),
		entry(expense,[coord('AUD', 306.42,0)],
			[entry(cost_of_goods_sold,[coord('AUD', 50,0)],[]),
			entry(stationary,[],[]),
			entry(wages,[coord('AUD', 200,0)],[]),
			entry(super_expense,[coord('AUD', 19,0)],[]),
			entry(hirepurchase_interest,[coord('AUD', 37.42,0)],[])])]]).







% Let's get the retained earnings as of date(2017, 7, 3):
test(retained_earnings_1) :-
write("Is the output for the retained earnings at a given date correct?"),

findall(Retained_Earnings,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2017, 7, 3), B),
		absolute_day(date(2017, 7, 3), E),
		balance_by_account([], Accounts, Transactions, [], E, earnings, B, Retained_Earnings)),
		
	[[coord('AUD', 0, 50)]]).



% Let's get the retained earnings as of date(2019, 6, 2):
test(retained_earnings_2) :-
write("Is the output for the retained earnings at another given date correct?"),
findall(Retained_Earnings,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2019, 6, 2), B),
		absolute_day(date(2019, 6, 2), E),
		balance_by_account([], Accounts, Transactions, [], E, earnings, B, Retained_Earnings)),
		
	[[coord('AUD', 0, 40)]]).







% Let's get the current earnings between date(2017, 7, 1) and date(2017, 7, 3):
test(current_earnings_1) :-
write("Is the output for the current earnings between two given dates correct?"),
findall(_,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2017, 7, 1), A), absolute_day(date(2017, 7, 3), B),
		absolute_day(date(2017, 7, 3), E),
		net_activity_by_account([], Accounts, Transactions, [], E, earnings, A, B, _)),
		
	[[coord('AUD', 0, 50)]]).






% Let's get the current earnings between date(2018, 7, 1) and date(2019, 6, 2):
test(current_earnings_2) :-
write("Is the output for the current earnings between another two given dates correct?"),
findall(_,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2018, 7, 1), A), absolute_day(date(2019, 6, 2), B),
		absolute_day(date(2019, 6, 2), E),
		net_activity_by_account([], Accounts, Transactions, [], E, earnings, A, B, _)),
		
	[[coord('AUD', 10, 0)]]).






% Let's get the balance of the inventory account as of date(2017, 7, 3):
test(inventory_balance) :-
write("Is the output for the balance of the given account at a given date correct?"),

findall(Bal,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2017, 7, 3), B), absolute_day(date(2017, 7, 3), E),
		balance_by_account([], Accounts, Transactions, [], E, inventory, B, Bal)),
		
	[[coord('AUD', 0, 0)]]).









% Let's get the net activity of the asset-typed account between date(2017, 7, 2) and date(2017, 7, 3).
test(net_activity) :-
write("Is the output for the net activity of the given account between the given dates correct?"),
findall(Net_Activity,
	(recorded(accounts, Accounts),
		recorded(transactions, Transactions),
		absolute_day(date(2017, 7, 2), A), absolute_day(date(2017, 7, 3), B),
		absolute_day(date(2017, 7, 3), E),
		net_activity_by_account([], Accounts, Transactions, [], E, asset, A, B, Net_Activity)),
		
	[[coord('AUD', 100, 0)]]).

:- end_tests(ledger).




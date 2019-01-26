% The T-Account for some hypothetical business. The schema follows:
% transaction(Date, Description, Account, T_Term).
transactions(transaction(D, invest_in_business, hp_account, t_term(200.47, 0))) :- absolute_day(date(2015, 1, 16), D).
transactions(transaction(D, invest_in_businessa, hp_account, t_term(200.47, 0))) :- absolute_day(date(2015, 1, 16), D).
transactions(transaction(D, invest_in_businessb, hp_account, t_term(200.47, 0))) :- absolute_day(date(2015, 1, 16), D).
transactions(transaction(D, invest_in_business, bank, t_term(100, 0))) :- absolute_day(date(2017, 7, 1), D).
transactions(transaction(D, invest_in_business, share_capital, t_term(0, 100))) :- absolute_day(date(2017, 7, 1), D).
transactions(transaction(D, buy_inventory, inventory, t_term(50, 0))) :- absolute_day(date(2017, 7, 2), D).
transactions(transaction(D, buy_inventory, accounts_payable, t_term(0, 50))) :- absolute_day(date(2017, 7, 2), D).
transactions(transaction(D, sell_inventory, accounts_receivable, t_term(100, 0))) :- absolute_day(date(2017, 7, 3), D).
transactions(transaction(D, sell_inventory, sales, t_term(0, 100))) :- absolute_day(date(2017, 7, 3), D).
transactions(transaction(D, sell_inventory, cost_of_goods_sold, t_term(50, 0))) :- absolute_day(date(2017, 7, 3), D).
transactions(transaction(D, sell_inventory, inventory, t_term(0, 50))) :- absolute_day(date(2017, 7, 3), D).
transactions(transaction(D, pay_creditor, accounts_payable, t_term(50, 0))) :- absolute_day(date(2018, 7, 1), D).
transactions(transaction(D, pay_creditor, bank, t_term(0, 50))) :- absolute_day(date(2018, 7, 1), D).
transactions(transaction(D, buy_stationary, stationary, t_term(10, 0))) :- absolute_day(date(2019, 6, 2), D).
transactions(transaction(D, buy_stationary, bank, t_term(0, 10))) :- absolute_day(date(2019, 6, 2), D).
transactions(transaction(D, buy_inventory, inventory, t_term(125, 0))) :- absolute_day(date(2019, 7, 1), D).
transactions(transaction(D, buy_inventory, accounts_payable, t_term(0, 125))) :- absolute_day(date(2019, 7, 1), D).
transactions(transaction(D, sell_inventory, accounts_receivable, t_term(100, 0))) :- absolute_day(date(2019, 7, 8), D).
transactions(transaction(D, sell_inventory, sales, t_term(0, 100))) :- absolute_day(date(2019, 7, 8), D).
transactions(transaction(D, sell_inventory, cost_of_goods_sold, t_term(50, 0))) :- absolute_day(date(2019, 7, 8), D).
transactions(transaction(D, sell_inventory, inventory, t_term(0, 50))) :- absolute_day(date(2019, 7, 8), D).
transactions(transaction(D, payroll_payrun, wages, t_term(200, 0))) :- absolute_day(date(2020, 2, 13), D).
transactions(transaction(D, payroll_payrun, super_expense, t_term(19, 0))) :- absolute_day(date(2020, 2, 14), D).
transactions(transaction(D, payroll_payrun, super_payable, t_term(0, 19))) :- absolute_day(date(2020, 2, 13), D).
transactions(transaction(D, payroll_payrun, paygw_tax, t_term(0, 20))) :- absolute_day(date(2020, 2, 13), D).
transactions(transaction(D, payroll_payrun, wages_payable, t_term(0, 180))) :- absolute_day(date(2020, 2, 13), D).
transactions(transaction(D, pay_wage_liability, wages_payable, t_term(180, 0))) :- absolute_day(date(2020, 2, 13), D).
transactions(transaction(D, pay_wage_liability, bank, t_term(0, 180))) :- absolute_day(date(2020, 2, 13), D).
transactions(transaction(D, buy_truck, motor_vehicles, t_term(3000, 0))) :- absolute_day(date(2020, 4, 1), D).
transactions(transaction(D, buy_truck, hirepurchase_truck, t_term(0, 3000))) :- absolute_day(date(2020, 4, 1), D).
transactions(transaction(D, hire_purchase_truck_repayment, hirepurchase_truck, t_term(60, 0))) :- absolute_day(date(2020, 4, 1), D).
transactions(transaction(D, hire_purchase_truck_repayment, bank, t_term(0, 60))) :- absolute_day(date(2020, 4, 1), D).
transactions(transaction(D, pay_3rd_qtr_bas, paygw_tax, t_term(20, 0))) :- absolute_day(date(2020, 4, 28), D).
transactions(transaction(D, pay_3rd_qtr_bas, bank, t_term(0, 20))) :- absolute_day(date(2020, 4, 28), D).
transactions(transaction(D, pay_super, super_payable, t_term(19, 0))) :- absolute_day(date(2020, 4, 28), D).
transactions(transaction(D, pay_super, bank, t_term(0, 19))) :- absolute_day(date(2020, 4, 28), D).
transactions(transaction(D, hire_purchase_truck_replacement, hirepurchase_truck, t_term(41.16, 0))) :- absolute_day(date(2020, 5, 1), D).
transactions(transaction(D, hire_purchase_truck_replacement, hirepurchase_interest, t_term(18.84, 0))) :- absolute_day(date(2020, 5, 1), D).
transactions(transaction(D, hire_purchase_truck_replacement, bank, t_term(0, 60))) :- absolute_day(date(2020, 5, 1), D).
transactions(transaction(D, hire_purchase_truck_replacement, hirepurchase_truck, t_term(41.42, 0))) :- absolute_day(date(2020, 6, 2), D).
transactions(transaction(D, hire_purchase_truck_replacement, hirepurchase_interest, t_term(18.58, 0))) :- absolute_day(date(2020, 6, 3), D).
transactions(transaction(D, hire_purchase_truck_replacement, bank, t_term(0, 60))) :- absolute_day(date(2020, 6, 1), D).
transactions(transaction(D, collect_accs_rec, accounts_receivable, t_term(0, 100))) :- absolute_day(date(2020, 6, 10), D).
transactions(transaction(D, collect_accs_rec, bank, t_term(100, 0))) :- absolute_day(date(2020, 6, 10), D).

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


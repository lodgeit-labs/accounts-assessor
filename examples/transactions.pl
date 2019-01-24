% Let's get the trial balance between date(2018, 7, 1) and date(2019, 6, 30):
trial_balance_between(date(2018, 7, 1), date(2019, 6, 30), X).
% ----------------------------------------------------------------------------------------
% Result should be X = trial_balance([ (bank, t_term(40, 0)), (inventory, t_term(0, 0)),
% (accounts_receivable, t_term(100, 0)), (motor_vehicles, t_term(0, 0))],
% [ (accounts_payable, t_term(0, 0)), (super_payable, t_term(0, 0)), (paygw_tax, t_term(0, 0)),
% (wages_payable, t_term(0, 0)), (hirepurchase_truck, t_term(0, 0))],
% [ (retained_earnings, t_term(0, 50)), (share_capital, t_term(0, 100))],
% [ (sales, t_term(0, 0))], [ (cost_of_goods_sold, t_term(0, 0)), (stationary, t_term(10, 0)),
% (wages, t_term(0, 0)), (super_expense, t_term(0, 0)), (hirepurchase_interest, t_term(0, 0))]).

% Let's get the balance sheet as of date(2019, 6, 30):
balance_sheet_at(date(2019, 6, 30), X).
% ----------------------------------------------------------------------------------------
% Result should be X = balance_sheet([ (bank, t_term(40, 0)), (inventory, t_term(0, 0)),
% (accounts_receivable, t_term(100, 0)), (motor_vehicles, t_term(0, 0))],
% [ (accounts_payable, t_term(0, 0)), (super_payable, t_term(0, 0)), (paygw_tax, t_term(0, 0)),
% (wages_payable, t_term(0, 0)), (hirepurchase_truck, t_term(0, 0))],
% [ (retained_earnings, t_term(0, 40)), (share_capital, t_term(0, 100))]).

% Let's get the movement between date(2019, 7, 1) and date(2020, 6, 30):
movement_between(date(2019, 7, 1), date(2020, 6, 30), X).
% ----------------------------------------------------------------------------------------
% Result should be X = movement([ (bank, t_term(0, 299)), (inventory, t_term(75, 0)),
% (accounts_receivable, t_term(0, 0)), (motor_vehicles, t_term(3000, 0))],
% [ (accounts_payable, t_term(0, 125)), (super_payable, t_term(0, 0)), (paygw_tax, t_term(0, 0)),
% (wages_payable, t_term(0, 0)), (hirepurchase_truck, t_term(0.0, 2857.42))],
% [ (share_capital, t_term(0, 0))], [ (sales, t_term(0, 100))], [ (cost_of_goods_sold, t_term(50, 0)),
% (stationary, t_term(0, 0)), (wages, t_term(200, 0)), (super_expense, t_term(19, 0)),
% (hirepurchase_interest, t_term(37.42, 0))]).

% Let's get the retained earnings as of date(2017, 7, 3):
retained_earnings(date(2017, 7, 3), Retained_Earnings),
credit_isomorphism(Retained_Earnings, Retained_Earnings_Signed).
% Result should be Retained_Earnings = t_term(50, 100), Retained_Earnings_Signed = 50

% Let's get the retained earnings as of date(2019, 6, 2):
retained_earnings(date(2019, 6, 2), Retained_Earnings),
credit_isomorphism(Retained_Earnings, Retained_Earnings_Signed).
% Result should be Retained_Earnings = t_term(60, 100), Retained_Earnings_Signed = 40

% Let's get the current earnings between date(2017, 7, 1) and date(2017, 7, 3):
current_earnings(date(2017, 7, 1), date(2017, 7, 3), Current_Earnings),
credit_isomorphism(Current_Earnings, Current_Earnings_Signed).
% Result should be Current_Earnings = t_term(50, 100), Current_Earnings_Signed = 50

% Let's get the current earnings between date(2018, 7, 1) and date(2019, 6, 2):
current_earnings(date(2018, 7, 1), date(2019, 6, 2), Current_Earnings),
credit_isomorphism(Current_Earnings, Current_Earnings_Signed).
% Result should be Current_Earnings = t_term(10, 0), Current_Earnings_Signed = -10

% Let's get the balance of the inventory account as of date(2017, 7, 3):
balance_by_account(inventory, date(2017, 7, 3), Bal).
% Result should be Bal = t_term(50, 50)

% What if we want the balance as a signed quantity?
balance_by_account(inventory, date(2017, 7, 3), Bal), debit_isomorphism(Bal, Signed_Bal).
% Result should be Bal = t_term(50, 50), Signed_Bal = 0.

% What is the isomorphism of the inventory account?
account_type(inventory, Account_Type), account_isomorphism(Account_Type, Isomorphism).
% Result should be Account_Type = asset, Isomorphism = debit_isomorphism.

% Let's get the net activity of the asset-typed account between date(2017, 7, 2) and date(2017, 7, 3).
net_activity_by_account_type(asset, date(2017, 7, 2), date(2017, 7, 3), Net_Activity).
% Result should be Net_Activity = t_term(150, 50)


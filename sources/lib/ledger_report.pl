
% Now for balance sheet predicates. These build up a tree structure that corresponds to the account hierarchy, with balances for each account.


 balance_sheet_entry(Static_Data, Account_Id, Entry) :-
	balance_sheet_entry2(Static_Data, Account_Id, Entry).

%:- table balance_sheet_entry2/3.

 balance_sheet_entry2(Static_Data, Account_Id, Entry) :-
	% find all direct children sheet entries
	% fixme:  If Key is unbound, all associations in Dict are returned on backtracking. The order in which the associations are returned is undefined. (in doc.pl). This leads to random order of entries in the report.
	account_direct_children(Account_Id, Child_Accounts),
	maplist(!balance_sheet_entry2(Static_Data), Child_Accounts, Child_Entries),
	% find child balances
	maplist(!report_entry_total_vec,Child_Entries,Child_Balances),
	maplist(!report_entry_transaction_count,Child_Entries,Child_Counts),
	% balance for this account including subaccounts (sum all transactions from beginning of time)

	account_own_transactions_sum(Static_Data.exchange_rates, Static_Data.end_date, Static_Data.report_currency, Account_Id, Static_Data.end_date, Static_Data.transactions_by_account, Own_Sum, Own_Transactions_Count),
	
	vec_sum([Own_Sum | Child_Balances], Balance),
	%format(user_error, 'balance_sheet_entry2: ~q :~n~q~n', [Account_Id, Balance]),
	sum_list(Child_Counts, Children_Transaction_Count),
	Transactions_Count is Children_Transaction_Count + Own_Transactions_Count,

	!account_name(Account_Id, Account_Name),
	!account_normal_side(Account_Id, Normal_side),
	make_report_entry(Account_Name, Child_Entries, Entry),
	set_report_entry_total_vec(Entry, Balance),
	set_report_entry_normal_side(Entry, Normal_side),
	set_report_entry_transaction_count(Entry, Transactions_Count),
	set_report_entry_gl_account(Entry, Account_Id).

activity_entry(Static_Data, Account_Id, Entry) :-
	account_direct_children(Account_Id, Child_accounts),
	maplist(!activity_entry(Static_Data), Child_accounts,Child_Sheet_Entries),
	net_activity_by_account(Static_Data, Account_Id, Net_Activity, Transactions_Count),
	account_name(Account_Id, Account_Name),
	account_normal_side(Account_Id, Normal_side),
	make_report_entry(Account_Name, Child_Sheet_Entries, Entry),
	set_report_entry_total_vec(Entry, Net_Activity),
	set_report_entry_normal_side(Entry, Normal_side),
	set_report_entry_transaction_count(Entry, Transactions_Count),
	set_report_entry_gl_account(Entry, Account_Id).

balance_until_day2(Sd, Report_Currency, Date, Account, balance(Balance, Tx_Count)) :-
	!balance_until_day(Sd.exchange_rates, Sd.transactions_by_account, Report_Currency, Date, Account, Date, Balance, Tx_Count).

balance_by_account2(Sd, Report_Currency, Date, Account, balance(Balance, Tx_Count)) :-
	!balance_by_account(Sd.exchange_rates, Sd.transactions_by_account, Report_Currency, Date, Account, Date, Balance, Tx_Count).


/*accounts_report(Static_Data, Accounts_Report) :-
	balance_sheet_entry(Static_Data, $>account_by_role_throw(rl('Accounts')), Entry),
	Entry = entry(_,_,Accounts_Report,_,[]).*/

 balance_sheet_at(Static_Data, [Net_Assets_Entry, Equity_Entry]) :-
	balance_sheet_entry(Static_Data, $>abrlt('Net_Assets'), Net_Assets_Entry),
	balance_sheet_entry(Static_Data, $>abrlt('Equity'), Equity_Entry).

 balance_sheet_delta(Static_Data, [Net_Assets_Entry, Equity_Entry]) :-
	!activity_entry(Static_Data, $>abrlt('Net_Assets'), Net_Assets_Entry),
	!activity_entry(Static_Data, $>abrlt('Equity'), Equity_Entry).

 trial_balance_between(
 	Exchange_Rates,
 	Transactions_By_Account,
 	Report_Currency,
 	Exchange_Date,
 	End_Date,
 	[Trial_Balance_Section]
) :-
	balance_by_account(Exchange_Rates, Transactions_By_Account, Report_Currency, Exchange_Date, $>abrlt('Net_Assets'), End_Date, Net_Assets_Balance, Net_Assets_Count),
	balance_by_account(Exchange_Rates, Transactions_By_Account, Report_Currency, Exchange_Date, $>abrlt('Equity'), End_Date, Equity_Balance, Equity_Count),

	vec_sum([Net_Assets_Balance, Equity_Balance], Trial_Balance),
	Transactions_Count is Net_Assets_Count + Equity_Count,

	% too bad there isnt a trial balance concept in the taxonomy yet, but not a problem
	make_report_entry('Trial_Balance', [], Trial_Balance_Section),
	set_report_entry_total_vec(Trial_Balance_Section, Trial_Balance),
	set_report_entry_transaction_count(Trial_Balance_Section, Transactions_Count),

	(	(	trial_balance_ok(Trial_Balance_Section)
		;	Report_Currency = [])
	->	true
	;	(	term_string(trial_balance(Trial_Balance_Section), Tb_Str),
			add_alert('SYSTEM_WARNING', Tb_Str))).



profitandloss_between(Static_Data, [ProftAndLoss]) :-
	!activity_entry(Static_Data, $>abrlt('Comprehensive_Income'), ProftAndLoss).



'with current and historical earnings equity balances'(
	Txs_by_acct,
	Start_Date,
	End_Date,
	Txs_by_acct2
) :-

	/* add past comprehensive income to Historical_Earnings */

	transactions_before_day_on_account_and_subaccounts(Txs_by_acct, $>abrlt('Comprehensive_Income'), Start_Date, Historical_Earnings_Transactions),
	transactions_before_day_on_account_and_subaccounts(Txs_by_acct, $>abrlt('Historical_Earnings'), Start_Date, Historical_Earnings_Transactions2),
	append(Historical_Earnings_Transactions, Historical_Earnings_Transactions2, Historical_Earnings_Transactions_All),
	Txs_by_acct1 = Txs_by_acct.put($>abrlt('Historical_Earnings'), Historical_Earnings_Transactions_All),

	/* copy current Comprehensive_Income txs into Current_Earnings */

	transactions_in_period_on_account_and_subaccounts(Txs_by_acct, $>abrlt('Comprehensive_Income'), Start_Date, End_Date, Current_Earnings_Transactions),
	Txs_by_acct2 = Txs_by_acct1.put($>abrlt('Current_Earnings'), Current_Earnings_Transactions).


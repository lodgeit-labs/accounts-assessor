
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

 balance_sheet_at(Static_Data, Dict) :-
 	Dict = x{start_date: Start_date, end_date: End_date, exchange_date: Exchange_date, entries:  [Net_Assets_Entry, Equity_Entry]},
	dict_vars(Static_Data, [Start_date, End_date, Exchange_date]),
	balance_sheet_entry(Static_Data, $>abrlt('Net_Assets'), Net_Assets_Entry),
	balance_sheet_entry(Static_Data, $>abrlt('Equity'), Equity_Entry).

 balance_sheet_delta(Static_Data, Dict) :-
 	Dict = x{start_date: Start_date, end_date: End_date, exchange_date: Exchange_date, entries: [Net_Assets_Entry, Equity_Entry]},
	dict_vars(Static_Data, [Start_date, End_date, Exchange_date]),
	!activity_entry(Static_Data, $>abrlt('Net_Assets'), Net_Assets_Entry),
	!activity_entry(Static_Data, $>abrlt('Equity'), Equity_Entry).

 trial_balance_report(
 	Exchange_Rates,
 	Transactions_By_Account,
 	Report_Currency,
 	Exchange_Date,
 	End_Date,
 	[Trial_Balance_Section]
) :-
	push_format('trial_balance_report(end_date:~q, exchange_date:~q)',[End_Date,Exchange_Date]),
	balance_by_account(Exchange_Rates, Transactions_By_Account, Report_Currency, Exchange_Date, $>abrlt('Net_Assets'), End_Date, Net_Assets_Balance, Net_Assets_Count),
	balance_by_account(Exchange_Rates, Transactions_By_Account, Report_Currency, Exchange_Date, $>abrlt('Equity'), End_Date, Equity_Balance, Equity_Count),

	vec_sum([Net_Assets_Balance, Equity_Balance], Trial_Balance),
	Transactions_Count is Net_Assets_Count + Equity_Count,

	% too bad there isnt a trial balance concept in the taxonomy yet, but not a problem
	c(make_report_entry('Trial_Balance', [], Trial_Balance_Section)),
	set_report_entry_total_vec(Trial_Balance_Section, Trial_Balance),
	set_report_entry_transaction_count(Trial_Balance_Section, Transactions_Count),

	(	Report_Currency = []
	->	check_trial_balance_section(Trial_Balance_Section)
	;	true),
	pop_format.



 profitandloss_between(Static_Data, Dict) :-
  	Dict = x{start_date: Start_date, end_date: End_date, exchange_date: Exchange_date, entries:  [ProftAndLoss]},
	dict_vars(Static_Data, [Start_date, End_date, Exchange_date]),
	!activity_entry(Static_Data, $>abrlt('Comprehensive_Income'), ProftAndLoss).



 'with current and historical earnings equity balances'(
	S0,
	Start_date,
	End_date,
	S2
) :-
	add_days(Start_date, -1, Before_start),
	'past comprehensive income tx'(
		S0,
		date(1,1,1),
		Before_start,
		Start_date,
		'Historical_Earnings',
		Start_date,
		Tx0
	),
	/*

	Historical_Earnings are posted including the value gains of the start date.

	*/

	'past comprehensive income tx'(
		S0,
		Start_date,
		End_date,
		End_date,
		'Current_Earnings',
		End_date,
		Tx1
	),
	/*

	^ ok, historical report's posted Current_Earnings are computed with the report's End_date values. Does non-historical start with previous day's values? Does doing a single-day report post the day's gains against the previous day?

	*/

	handle_txs(S0, [Tx0,Tx1], S2).


'past comprehensive income tx'(
	State,
	Start_date,
	End_date,
	Exchange_date,
	Tx_acct,
	Tx_date,
	Tx0
) :-
	!transactions_in_period_on_account_and_subaccounts(
		$>!transactions_dict_from_state(State),
		$>abrlt('Comprehensive_Income'),
		Start_date,
		End_date,
		Txs0
	),
	!txs_vec_converted_sum(
		Exchange_date,
		Txs0,
		Sum
	),
	!make_transaction(
		closing_books,
		Tx_date,
		closing_books,
		$>abrlt(Tx_acct),
		Sum,
		Tx0
	).



 txs_vec_converted_sum(Exchange_Date, Transactions, Balance) :-
 	result_property(l:exchange_rates, Exchange_rates),
 	result_property(l:report_currency, Report_currency),
	txs_vec_converted_sum2(Exchange_rates, Exchange_Date, Report_currency, Transactions, Balance),
	(	vec_is_just_report_currency(Balance)
	->	true
	;	txs_vec_converted_sum_err(Exchange_Date, Transactions, Balance)
	).

txs_vec_converted_sum_err(Exchange_Date, Transactions, Balance) :-
	add_alert(
		check,
		$>format(string(<$),
			'could not convert ~q to report currency at ~q, txs: ~q',
			[$>round_term(Balance),$>round_term(Exchange_Date), Transactions]
		)
	).


txs_vec_converted_sum2(Exchange_Rates, Exchange_Date, Report_Currency, Transactions, Balance) :-
	transaction_vectors_total(Transactions, Totals),
	vec_change_bases(Exchange_Rates, Exchange_Date, Report_Currency, Totals, Balance).



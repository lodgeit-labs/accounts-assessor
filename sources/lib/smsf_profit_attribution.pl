/*
wip: go through all GL sheets in excel
	automatize or
	set non-default phase (smsf_...)





*/


basic_reports(Prefix, Static_Data, Sr) :-
	/* we should have:
	Static_Data.transactions
	Static_Data.exchange_rates
	Static_Data.transactions_by_account
	Static_Data.report_currency
	Static_Data.end_date
	Static_Data.start_date
	*/
	!balance_entries(Static_Data, Sr),
	!other_reports2(Prefix, Static_Data, Sr),



smsf_rollover(Static_Data, Txs) :-

	basic_reports('before_smsf_rollover_', Static_Data, Sr),
	Bs = Sr.bs.current,
	'check that smsf_equity_Opening_Balance is zero',
	findall(
		Acc,
		(
			account_by_role(rl(smsf_equity/Distinction/_Phase/_Taxability), Acc),
			dif(Distinction, 'Opening_Balance')
		),
		Non_ob_accounts),
	maplist(roll_over,Non_ob_accounts, Txs0),
	flatten(Txs0, Txs),
	'check that smsf_equity_except_Opening_Balance is zero'.


roll_over(Acc, Txs) :-
	findall(
		Child,
		% Child is specific for a member
		account_parent(Acc, Child),
		Children
	),
	maplist(roll_over2,Children,Txs).

roll_over2(Member_src_acc,Txs) :-
	accounts_report_entry_by_account_id(Bs,Member_src_acc,Balance),
	tx(
		Balance,
		Src=Member_src_acc,
		Dst=$>abrlt(smsf_equity/'Opening_Balance'/Phase/Taxability)

	!doc_new_uri(rollover_st, St),
	!doc_add_value(St, transactions:description, "rollover", transactions),
	!vector_of_coords_vs_vector_of_values(kb:debit, Tax_vec, $>!evaluate_fact2(aspects([concept - smsf/income_tax/'Tax on Taxable Income @ 15%']))),
	!make_dr_cr_transactions(
		St,
		$>result_has_property(l:end_date),
		Sheet_name,
		$>abrlt('Income_Tax_Expenses'),
		$>abrlt('Income_Tax_Payable'),
		Tax_vec,
		Txs0).





















%smsf_profit_attribution(Txs) :-

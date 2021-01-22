/*
wip: go through all GL sheets in excel
	automatize or
	set non-default phase (smsf_...)

*/




basic_reports(Prefix, State, Sr) :-
	doc(State, l:has_transactions, Transactions),
	!transactions_by_account_v2(Transactions,Transactions_By_Account),
 	!result_property(l:report_currency, Report_Currency),
 	!result_property(l:exchange_rates, Exchange_Rates),
	!result_property(l:start_date, Start_Date),
 	!result_property(l:end_date, End_Date),
	dict_from_vars(Static_Data, [Transactions, Exchange_Rates, Transactions_By_Account, Report_Currency, Start_Date, End_Date]).
	!balance_entries(Static_Data, Sr),
	!other_reports2(Prefix, Static_Data, Sr),

% doc(Uri, accounts:smsf_phase, Phase, accounts)
% error: account hierarchy must specify taxability of ~q

smsf_rollover0(State_in, State_out) :-

	basic_reports('before_smsf_rollover_', State_in, Sr),
	smsf_rollover(Sr, Txs),

	new_state_with_appended_(State_in, [
		op(l:has_transactions,append,Txs)
	], State_out).


smsf_rollover(Sr, Txs) :-
	Bs = Sr.bs.current,
	cf('check that smsf_equity_Opening_Balance is zero'),
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

'check that smsf_equity_Opening_Balance is zero'(Sr) :-
	findall(
		Acc,
		account_by_role(rl(smsf_equity/'Opening_Balance'/_Phase/_Taxability), Acc),
		Ob_accounts),
	maplist(


check_account_is_zero(Sr, Path) :-
	Crosscheck = equality(
		account_balance(reports/bs/current, 'Equity_Aggregate_Historical'),
		[]
	),
	evaluate_equality(_{reports:Sr}), Crosscheck, Result),
	crosscheck_output(Result, _).

smsf_equity!Opening_Balance!Preserved!Taxable

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
		$>result_property(l:end_date),
		Sheet_name,
		$>abrlt('Income_Tax_Expenses'),
		$>abrlt('Income_Tax_Payable'),
		Tax_vec,
		Txs0).





















%smsf_profit_attribution(Txs) :-

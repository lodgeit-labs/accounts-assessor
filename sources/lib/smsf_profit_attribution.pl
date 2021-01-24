/*
wip: go through all GL sheets in excel
	automatize or
	set non-default phase (smsf_...)

*/



% doc(Uri, accounts:smsf_phase, Phase, accounts)
% error: account hierarchy must specify taxability of ~q

 smsf_rollover0(State_in, State_out) :-

	bs_pl_reports_from_state('before_smsf_rollover_', State_in, Sr),
	smsf_rollover(Sr, Txs),

	new_state_with_appended_(State_in, [
		op(l:has_transactions,append,Txs)
	], State_out),

	bs_pl_reports_from_state('after_smsf_rollover_', State_out, Sr2),
	'check that smsf_equity_equals_equity_Opening_Balance'(Sr2).


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
	maplist(roll_over,Non_ob_accounts, Txs).

 'check that smsf_equity_Opening_Balance is zero'(Sr) :-
	findall(_,(
			account_exists(A),
			doc(A, accounts:is_smsf_equity_opening_balance, "true", accounts),
			!check_account_is_zero(Sr, account_balance(reports/bs/current, uri(A)))
	),_).

 'check that smsf_equity equals smsf_equity_Opening_Balance'(Sr) :-
 	true. /*
		quiet_crosscheck(
			Sr,
			equality(
				account_balance(reports/bs/current, all_accounts_with_pog(accounts:is_smsf_equity_opening_balance, "true", accounts),
				account_balance(reports/bs/current, all_accounts_with_pog(accounts:is_smsf_equity_opening_balance, "false", accounts),*/
				/* it would be a lot easier if they each had an exact role, lets say smsf_equity/Specifier/IsOb/Phase/Taxability/Member? */


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

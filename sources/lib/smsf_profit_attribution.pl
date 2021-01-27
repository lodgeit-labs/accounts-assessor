% error: account hierarchy must specify taxability of ~q


 smsf_rollover0(State_in, State_out) :-
	bs_pl_reports_from_state('before_smsf_rollover_', State_in, Sr),
	cf('check that smsf_equity_Opening_Balance is zero'(Sr)),
	smsf_rollover(Sr.bs.current, Txs),
	new_state_with_appended_(State_in, [op(l:has_transactions,append,Txs)], State_out),
	bs_pl_reports_from_state('after_smsf_rollover_', State_out, Sr2),
	'check that smsf_equity equals smsf_equity_Opening_Balance'(Sr2).

 'check that smsf_equity_Opening_Balance is zero'(Sr) :-
 	smsf_equity_leaf_accounts(All),
	include(is_smsf_equity_opening_balance_account, All, Accts),
	maplist([A]>>(!check_account_is_zero(_{reports:Sr}, account_balance(reports/bs/current, uri(A)))),Accts).

 smsf_rollover(Bs, Txs) :-
 	smsf_equity_leaf_accounts(All),
	exclude(is_smsf_equity_opening_balance_account, All, Accts),
	maplist(roll_over(Bs), Accts, Txs).

roll_over(Bs, Src, Txs) :-
	%accounts_report_entry_by_account_id(Bs,Src,Entry),
	!doc_new_uri(rollover_st, St),
	!doc_add_value(St, transactions:description, "rollover", transactions),
	vector_of_coords_vs_vector_of_values(kb:debit, $>report_entry_normal_side_values(Bs, Src), Vec),
	!make_dr_cr_transactions(
		St,
		$>result_property(l:end_date),
		"rollover",
		Src,
		$>!rollover_dst_acc(Src),
		Vec,
		Txs
	).

rollover_dst_acc(Src,Dst) :-
	smsf_equity_leaf_account(Dst),
	doc(Src, accounts:smsf_phase, Phase, accounts),
	doc(Src, accounts:smsf_member, Member, accounts),
	doc(Src, accounts:smsf_taxability, Taxability, accounts),
	doc(Dst, accounts:smsf_phase, Phase, accounts),
	doc(Dst, accounts:smsf_member, Member, accounts),
	doc(Dst, accounts:smsf_taxability, Taxability, accounts).


%smsf_profit_attribution(Txs) :-




 is_smsf_equity_opening_balance_account(A) :-
	doc(A, accounts:is_smsf_equity_opening_balance, "true", accounts).

 smsf_equity_leaf_account(Account) :-
	account_in_set(Account, $>abrlt(rl(smsf_equity))),
	is_leaf_account(Account).

 find_all(Unary_callable, Instantiations) :-
	findall(X, call(Unary_callable,X), Instantiations).

 smsf_equity_leaf_accounts(Accounts) :-
	find_all(smsf_equity_leaf_account, Accounts).

 'check that smsf_equity equals smsf_equity_Opening_Balance'(_Sr) :-
 	gtrace,
 	true. /*
		quiet_crosscheck(
			Sr,
			equality(
				account_balance(reports/bs/current, all_accounts_with_pog(accounts:is_smsf_equity_opening_balance, "true", accounts),
				account_balance(reports/bs/current, all_accounts_with_pog(accounts:is_smsf_equity_opening_balance, "false", accounts),*/
				/* it would be a lot easier if they each had an exact role, lets say smsf_equity/Specifier/IsOb/Phase/Taxability/Member? */

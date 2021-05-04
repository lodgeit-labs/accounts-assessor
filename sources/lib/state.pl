

 initial_state(State) :-
 	doc_new_(l:state, State),
 	doc_add(State, l:has_transactions, []),
 	doc_add(State, l:has_s_transactions, []),
 	doc_add(State, l:has_outstanding, ([],[])),
 	true.


 new_state_with_appended_(S0, Ops, S2) :-
	doc_new_(l:state, S2),
 	doc_add(S2, l:has_previous_state, S0),
 	maplist(handle_field(S0,S2, Ops), [
 		l:has_s_transactions,
 		l:has_transactions,
 		l:has_outstanding
 	]).

 handle_field(S0,S2,Ops,Field) :-
	(	nth0(I,Ops,change(Field,Action1,Args1))
	->	(
			dif(I,J),
			(	nth0(J,Ops,change(Field,_,_))
			->	throw_string('cannot handle multiple actions on one field at once')
			;	true),
			!handle_op(S0,Action1,Field,Args1,S2)
		)
	;	(
			/* no op specified, so the default action here is pass-through, just copy from the old structure to the new structure */
			!doc(S0, Field, X),
			!doc_add(S2, Field, X)
		)
	).

handle_op(_,set,Field,New,S2) :-
	doc_add(S2, Field, New).

handle_op(S0,append,Field,Tail,S2) :-
	doc(S0, Field, Old),
	flatten([Old,Tail],New),
	doc_add(S2, Field, New).




 handle_sts(S0, S_Transactions0, S2) :-
 	flatten(S_Transactions0, S_Transactions),
	doc(S0, l:has_outstanding, Outstanding_old),
 	result_property(l:end_date, End_Date),

	!s_transactions_up_to(End_Date, S_Transactions, S_Transactions2),
	!sort_s_transactions(S_Transactions2,S_Transactions4),
	!cf('pre-preprocess source transactions'(S_Transactions4, Prepreprocessed_S_Transactions)),

	cf(preprocess_s_transactions(
		Prepreprocessed_S_Transactions,
		Preprocessed_S_Transactions,
		Transactions,
		Outstanding_old,
		Outstanding_new)),

	(	(($>length(Preprocessed_S_Transactions)) == ($>length(Prepreprocessed_S_Transactions)))
	->	true
	;	add_alert('warning', 'not all source transactions processed, proceeding with reports anyway..')),

	new_state_with_appended_(
		S0,
		[
			change(l:has_s_transactions,append,Preprocessed_S_Transactions),
			change(l:has_transactions,append,Transactions),
			change(l:has_outstanding,set,Outstanding_new)
		],
		S2
	).

 handle_txs(S, [], S) :-
 	!.

 handle_txs(S, _, S) :-
	is_cutoff,
	!.

 handle_txs(S, _, S) :-
	cutoff.

 handle_txs(S0, Txs0, S2) :-
	is_not_cutoff,
	bump_ic_n_sts_processed,
	new_state_with_appended_(S0, [
		change(l:has_transactions, append, Txs0)
	], S2).


 check_phase(Expected_phase, Subject, Predicate) :-
 	(?doc_value(Subject, Predicate, Actual_phase)),
 	(	var(Expected_phase)
 	->	var(Actual_phase)
 	;	\+var(Actual_phase)).


 bs_pl_reports_from_state(Prefix, State, Sr) :-
	throw(!current_reports(State, Sr)), % todo, we make an abstract concept out of creating html report from an entry tree, so that there can be an abstract html_reports taking a reportset uri and doing its thing.
	% and here, we only need 	!cf(balance_sheet_at(Static_Data_with_eq, Balance_Sheet)),
	% and !cf(profitandloss_between(Static_Data_with_eq, ProfitAndLoss)),
	!html_reports(Prefix, Sr).

 transactions_dict_from_state(State,Transactions_By_Account) :-
 	doc(State, l:has_transactions, Transactions),
	transactions_dict_by_account_v2(Transactions,Transactions_By_Account).


 static_data_from_state(State, Static_Data) :-
	doc(State, l:has_transactions, Transactions),
	doc(State, l:has_outstanding, Outstanding),
	!transactions_dict_by_account_v2(Transactions,Transactions_By_Account),
 	!result_property(l:report_currency, Report_Currency),
 	!result_property(l:exchange_rates, Exchange_Rates),
	!result_property(l:start_date, Start_Date),
 	!result_property(l:end_date, End_Date),
 	!result_property(l:end_date, Exchange_Date),
	dict_from_vars(Static_Data, [Transactions, Exchange_Rates, Transactions_By_Account, Report_Currency, Start_Date, End_Date, Exchange_Date, Outstanding]).


 add_cutoff_alert :-
	add_alert(cutoff, $>fs('not processing more source transactions due to cutoff of ~q transactions', $>read_ic_n_sts_processed)).


 cutoff :-
 	assertion(is_not_cutoff),
 	(	/*b_current(step_by_step, true)*/ false
 	->	(
 			b_setval(cutoff, true),
 			add_cutoff_alert
 		)
 	;	false).



 is_cutoff :-
	b_current(cutoff, true).
 is_not_cutoff :-
 	\+is_cutoff.

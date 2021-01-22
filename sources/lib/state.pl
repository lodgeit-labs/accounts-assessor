%state_fields([day, type_id, vector, account, exchanged, misc]).

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
 	dif(I,J),
	(	nth0(I,Ops,do(Field,Action1,Args1))
	->	(
			(	nth0(J,Ops,do(Field,_,_))
			->	throw_string('duplicate actions')
			;	true),
			handle_op(S0,Action1,Field,Args1,S2)
		)
	;	(
			doc(S0, Field, X),
			doc_add(S2, Field, X)
		)
	).

handle_op(_,set,Field,New,S2) :-
	doc_add(S2, Field, New).

handle_op(S0,append,Field,Tail,S2) :-
	doc(S0, Field, Old),
	append(Old,Tail,New),
	doc_add(S2, Field, New).




 handle_sts(S0, S_Transactions, S2) :-
	doc(S0, l:has_outstanding, Outstanding_old),
 	result_property(l:end_date, End_Date),

	!s_transactions_up_to(End_Date, S_Transactions, S_Transactions2),
	!sort_s_transactions(S_Transactions2,S_Transactions4),
	!cf('pre-preprocess source transactions'(S_Transactions4, Prepreprocessed_S_Transactions)),

	!cf(preprocess_s_transactions(
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
			op(l:has_s_transactions,append,Preprocessed_S_Transactions),
			op(l:has_transactions,append,Transactions),
			op(l:has_outstanding,set,Outstanding_new)
		],
		S2).


 process_sheets(S0, Phase, S4) :-
	!cf(extract_gl_inputs(Phase, Gl_input_txs)),
	new_state_with_appended_(S0, [
		op(l:has_transactions,append,Gl_input_txs)
	], S4).


 check_phase(Expected_phase, Subject, Predicate) :-
 	?doc_value(Subject, Predicate, Actual_phase),
 	(	var(Expected_phase)
 	->	var(Actual_phase)
 	;  	\+var(Actual_phase)).



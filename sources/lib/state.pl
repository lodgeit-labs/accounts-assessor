
 initial_state(State) :-
 	doc_new_(l:state, State),
 	doc_add(State, l:has_transactions, []),
 	doc_add(State, l:has_s_transactions, []),
 	doc_add(State, l:has_outstanding, ([],[])),
 	true.


 new_state_with_appended_(S0, Sts, Txs, Ops, S2) :-
	doc_new_(l:state, S2),
 	doc_add(S2, l:has_previous_state, S0),
 	check_ops(Ops),
 	maplist(handle_field(S0,S2, Ops), [
 		l:has_s_transactions,
 		l:has_transactions,
 		l:has_outstanding]).

check_ops(Ops) :-
	% check that no field is mentioned twice
	findall(_,
		(	nth0(I,Ops,Op1),
			Op1 =.. [Action1,Field|_],
		_).

 handle_field(S0,S2,Ops,Field) :-
	nth0(I,Ops,Op1),
	Op1 =.. [Action1,Field|_],
	dif(I,J),
	nth0(J,Ops,Op2),
	(	Op2 =.. [Action2,Field|_]
	->	throw_string('duplicate actions')
	;	true),



	maplist(handle_field2(S0,S2,Field),Ops).



% default is to copy

 handle_field2(S0,S2,Field,Field=X) :-
 	doc_add(S2, Field, X).

 handle_field2(S0,S2,Field1,Field2=X) :-




 handle_sts(S0, S_Transactions, S2) :-

	doc(S0, l:has_outstanding, Outstanding_old),

 	/*
 	result_has_property(l:report_currency, Report_Currency),
 	result_has_property(l:exchange_rates, Exchange_Rates),
	result_has_property(l:start_date, Start_Date),
	*/
 	result_has_property(l:end_date, End_Date),


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

	new_state_with_appended_(S0, Preprocessed_S_Transactions, Transactions, [l:has_outstanding=Outstanding_new], S2).


 process_sheets(S0, Phase, S4) :-
	!cf(extract_gl_inputs(Phase, Gl_input_txs)),
	new_state_with_appended_(S0, [], Gl_input_txs, S4).


 check_phase(Expected_phase, Subject, Predicate) :-
 	?doc_value(Subject, Predicate, Actual_phase),
 	(	var(Expected_phase)
 	->	var(Actual_phase)
 	;  	\+var(Actual_phase)).



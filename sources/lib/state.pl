
 initial_state(State) :-
 	doc_new_(l:state, State),
 	doc_add(State, l:has_transactions, []),
 	doc_add(State, l:has_s_transactions, []),
 	todo outstanding
 	true.


 new_state_with_appended_(S0, Txs, Sts, S2) :-
	doc(S0, l:has_transactions, Txs_old),
	doc(S0, l:has_s_transactions, Sts_old),

	append(Txs_old, Txs, Txs_new),
	append(Sts_old, Sts, Sts_new),

	doc_new_(l:state, S2),
 	doc_add(S2, l:has_transactions, Txs_new),
 	doc_add(S2, l:has_s_transactions, Sts_new),
 	doc_add(S2, l:has_previous_state, S0),
 	true.


 handle_sts(S0, S_Transactions, S2) :-

	doc(S0, l:has_outstanding, Outstanding_old),

 	result_has_property(l:report_currency, Report_Currency),
 	result_has_property(l:exchange_rates, Exchange_Rates),
	result_has_property(l:start_date, Start_Date),
 	result_has_property(l:end_date, End_Date),

	chain([
		!s_transactions_up_to(End_Date, S_Transactions)
		!sort_s_transactions,
		!cf('pre-preprocess source transactions'(S_Transactions4)),
	], Prepreprocessed_S_Transactions),

	dict_from_vars(Static_Data0, [Report_Currency, Start_Date, End_Date, Exchange_Rates, Cost_Or_Market]),

	!cf(preprocess_s_transactions(
		Static_Data0,
		Prepreprocessed_S_Transactions,
		Preprocessed_S_Transactions,
		Transactions,
		Outstanding_old,
		Outstanding_new)),

	(	(($>length(Processed_S_Transactions)) == ($>length(Prepreprocessed_S_Transactions)))
	->	true
	;	add_alert('warning', 'not all source transactions processed, proceeding with reports anyway..')),

	new_state_with_appended_(S0, Transactions, Preprocessed_S_Transactions, Sts, S2),
	doc_add(S2, l:has_outstanding, Outstanding_new).


 process_sheets(S0, Phase, S4) :-
	!cf(extract_gl_inputs(Phase, Gl_input_txs)),
	new_state_with_appended_(S0, Txs, Sts, S2)

 check_phase(Expected_Phase, Input_Cell) :-
 	?(	var(Expected_Phase)
 	->	\+doc(Input_Cell, rdf:value, _)
 	;  	\+(\+doc_value(Gl, ic:phase, Phase))).



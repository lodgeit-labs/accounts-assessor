 preprocess_s_transactions2(
	[S_Transaction|S_Transactions],
	Processed_S_Transactions,
	Transactions_Out,
	Outstanding_In,
	Outstanding_Out
) :-
	!pretty_st_string(S_Transaction, S_Transaction_str),
	push_format(
		'processing source transaction:~n ~w~n', [S_Transaction_str]),
	(	current_prolog_flag(die_on_error, true)
	->	E = something_that_doesnt_unify_with_any_error
	;	true),

	catch_with_backtrace(
		!preprocess_s_transaction3(
			S_Transaction,
			Outstanding_In,
			Outstanding_Mid,
			Transactions_Out_Tail,
			Processed_S_Transactions,
			Processed_S_Transactions_Tail,
			Transactions_Out
		),
		E,
		(
		/* watch out: this re-establishes doc to the state it was before the exception */
			!handle_processing_exception(E)
		)
	),

	pop_context,

	(	(var(E);E = something_that_doesnt_unify_with_any_error)
	->	(
			% recurse
			preprocess_s_transactions(
				S_Transactions,
				Processed_S_Transactions_Tail,
				Transactions_Out_Tail,
				Outstanding_Mid,
				Outstanding_Out
			)
		)
	;	(
			% give up
			Outstanding_In = Outstanding_Out,
			Transactions_Out = [],
			Processed_S_Transactions = []
		)
	).


===>


preprocess_s_transactions2(
		[S_Transaction|S_Transactions],
		Processed_S_Transactions,
		Transactions_Out,
		Outstanding_In,
		Outstanding_Out)
:-


	!pretty_st_string(S_Transaction, S_Transaction_str),
	push_format(
		'processing source transaction:~n ~w~n', [S_Transaction_str]),



if die_on_error:



	!preprocess_s_transaction3(
		S_Transaction,
		Outstanding_In,
		Outstanding_Mid,
		Transactions_Out_Tail,
		Processed_S_Transactions,
		Processed_S_Transactions_Tail,
		Transactions_Out
	),
	pop_context,
	% recurse
	preprocess_s_transactions(
		S_Transactions,
		Processed_S_Transactions_Tail,
		Transactions_Out_Tail,
		Outstanding_Mid,
		Outstanding_Out
	)



else



	catch_with_backtrace(
		!preprocess_s_transaction3(
			S_Transaction,
			Outstanding_In,
			Outstanding_Mid,
			Transactions_Out_Tail,
			Processed_S_Transactions,
			Processed_S_Transactions_Tail,
			Transactions_Out
		),
		E,
		(
		/* watch out: this re-establishes doc to the state it was before the exception */
			!handle_processing_exception(E),
			Outstanding_In = Outstanding_Out,
			Transactions_Out = [],
			Processed_S_Transactions = []
		)
	),
	pop_context,
	/* recursion ends here. we pretend that this was the last transaction to process, so that we can go on to generate reports, which can be useful for figuring out what was wrong with the offending transaction. */
	


endif


===>


preprocess_s_transactions2(
		[S_Transaction|S_Transactions],
		Processed_S_Transactions,
		Transactions_Out,
		Outstanding_In,
		Outstanding_Out)
:-


	!pretty_st_string(S_Transaction, S_Transaction_str),
	push_format(
		'processing source transaction:~n ~w~n', [S_Transaction_str]),
	Process_item_goal = !preprocess_s_transaction3(
		S_Transaction,
		Outstanding_In,
		Outstanding_Mid,
		Transactions_Out_Tail,
		Processed_S_Transactions,
		Processed_S_Transactions_Tail,
		Transactions_Out
	),



if die_on_error:



	call(Process_item_goal),
	pop_context,
	% recurse
	preprocess_s_transactions(
		S_Transactions,
		Processed_S_Transactions_Tail,
		Transactions_Out_Tail,
		Outstanding_Mid,
		Outstanding_Out
	)



else



	catch_with_backtrace(
		call(Process_item_goal),
		E,
		(
			/* watch out: this re-establishes doc to the state it was before the exception */
			!handle_processing_exception(E),
			/* recursion ends here. we pretend that this was the last transaction to process, so that we can go on to generate reports, which can be useful for figuring out what was wrong with the offending transaction. */
				Outstanding_In = Outstanding_Out,
			Transactions_Out = [],
			Processed_S_Transactions = []
		)
	),
	pop_context.
	


endif



preprocess_s_transactions2(
		[S_Transaction|S_Transactions],
		Processed_S_Transactions,
		Transactions_Out,
		Outstanding_In,
		Outstanding_Out)
:-


	!pretty_st_string(S_Transaction, S_Transaction_str),
	push_format(
		'processing source transaction:~n ~w~n', [S_Transaction_str]),
	Process_item_goal = !preprocess_s_transaction3(
		S_Transaction,
		Outstanding_In,
		Outstanding_Mid,
		Transactions_Out_Tail,
		Processed_S_Transactions,
		Processed_S_Transactions_Tail,
		Transactions_Out
	),



:- if die_on_error:



	call(Process_item_goal),
	pop_context,
	% recurse
	preprocess_s_transactions(
		S_Transactions,
		Processed_S_Transactions_Tail,
		Transactions_Out_Tail,
		Outstanding_Mid,
		Outstanding_Out
	)



else



	catch_with_backtrace(
		call(Process_item_goal),
		E,
		(
			/* watch out: this re-establishes doc to the state it was before the exception */
			!handle_processing_exception(E),
			/* recursion ends here. we pretend that this was the last transaction to process, so that we can go on to generate reports, which can be useful for figuring out what was wrong with the offending transaction. */
				Outstanding_In = Outstanding_Out,
			Transactions_Out = [],
			Processed_S_Transactions = []
		)
	),
	pop_context.
	


endif


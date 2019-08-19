:- ['../../lib/transactions'].
:- ['../../lib/accounts'].


:- begin_tests(transactions).


test(0, true(Dict =@= account_txs{'a': A_Ts, 'b': B_Ts})) :-
	Accounts = [A, B, C],
	account_id(A, a),
	account_id(B, b),
	account_id(C, c),
	transaction_account_id(T0, a),
	A_Ts = [T0],
	transaction_account_id(T1, b),
	transaction_account_id(T2, b),
	B_Ts = [T1, T2],
	append(A_Ts, B_Ts, Ts),
	transactions_by_account(Ts, Accounts, Dict).
	

:- end_tests(transactions).



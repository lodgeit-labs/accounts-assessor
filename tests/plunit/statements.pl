:- ['../../lib/statements'].

:- begin_tests(statements).

test(0) :-
	write("Are we now testing the statements subprogram?"),
	write("Are transactions where only the exchanged amount units are known and that uses a trading account preprocessed correctly?"),

	findall(Transactions,
	preprocess_s_transactions(
	  % no exchange rates
	  [], 
	  
	  [transaction_type(foreign_purchase, aud_account, trading_account, "Some foreign income.")],
	  [s_transaction(731125, foreign_purchase, [coord('USD',100,0)], usd_account, bases(['AUD']))], Transactions),
	
	[[
	% now we owe 100USD to the business owner
	transaction(731125, "Some foreign income.", usd_account, [coord('USD', 0, 100)]),
	% but we owe him 183AUD less
	transaction(731125, "Some foreign income.", aud_account, [coord('AUD', 183.83689999999999, 0.0)]),
	% this is on our trading account with the broker
	transaction(731125, "Some foreign income.", trading_account, [coord('USD', 100, 0), coord('AUD', 0.0, 183.83689999999999)])
	]]
	
	).

test(0) :-
	% Let's preprocess a transaction where the exchanged amount is known and that uses a trading account.
	write("Are transactions where the exchanged amount is known and that uses a trading account preprocessed correctly?"),

	findall(Transactions,
	(preprocess_s_transactions(
	  [], [transaction_type(foreign_purchase, aud_account, trading_account, "Some foreign income.")],
		[s_transaction(731125, foreign_purchase, [coord('USD',100,0)], usd_account, vector([coord('AUD',180,0)]))], Transactions)),
	
	[[transaction(731125, "Some foreign income.", usd_account, [coord('USD', 0, 100)]),
	transaction(731125, "Some foreign income.", aud_account, [coord('AUD', 180, 0)]),
	transaction(731125, "Some foreign income.", trading_account, [coord('USD', 100, 0), coord('AUD', 0, 180)])]]).

:- end_tests(statements).

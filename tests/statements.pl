write("Are we now testing the statements subprogram?").

% Let's preprocess a transaction that uses a trading account.
write("Are transactions that use a trading account preprocessed correctly?"),

findall(Transactions,
	(preprocess_s_transactions(
	  [], [transaction_type(foreign_purchase, ['AUD'], aud_account, trading_account, "Some foreign income.")],
		[s_transaction(731125, foreign_purchase, [coord('USD',100,0)], usd_account)], Transactions)),
	
	[[transaction(731125, "Some foreign income.", usd_account, [coord('USD', 0, 100)]),
	transaction(731125, "Some foreign income.", aud_account, [coord('AUD', 183.70106761565833, 0.0)]),
	transaction(731125, "Some foreign income.", trading_account, [coord('USD', 100, 0), coord('AUD', 0.0, 183.70106761565833)])]]).


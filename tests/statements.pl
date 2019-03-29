write("Are we now testing the statements subprogram?").

% Let's preprocess a transaction that uses a trading account.
write("Are transactions that use a trading account preprocessed correctly?"),

findall(Transactions,
	(preprocess_s_transactions(
	  [transaction_type(foreign_purchase, [aud], aud_account, trading_account, "Some foreign income.")],
		[s_transaction(731125, foreign_purchase, [coord(usd,100,0)], usd_account)], Transactions)),
	
	[[transaction(731125, "Some foreign income.", usd_account, [coord(usd, 0, 100)]),
	transaction(731125, "Some foreign income.", aud_account, [coord(aud, 183.70106762, 0.0)]),
	transaction(731125, "Some foreign income.", trading_account, [coord(usd, 100, 0), coord(aud, 0.0, 183.70106762)])]]).


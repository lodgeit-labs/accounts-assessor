:- ['../../lib/bank_statement'].

/* fixme, needs updating */

:- begin_tests(bank_statement).

test(0) :-
	write("Are we now testing the bank_statement subprogram?").

test(1) :-
	write("Are transactions where only the exchanged amount units are known and that uses a trading account preprocessed correctly?"),


/*preprocess-s-transactions takes a whole list of s_transactions, and preprocess-s-transaction handles just one. 
there has been many changes since these tests were written, mainly the function expects several more parameters.
it is used in the simplest way in investment calculator endpoint code, that's a good starting point to go see how to fix this here*/


	/*
	findall(Template, Goal, Result) runs goal, when it succeeds, it puts Template into Result
	*/
	findall(
		% we are collecting this template. it can contain a variable that could be bound by the Goal expression
		Result,

		/*Static_Data = (Account_Hierarchy, Report_Currency, Action_Taxonomy, End_Days, Exchange_Rates), S_Transactions, Transactions1, Transaction_Transformation_Debug),*/
	
		% on each yield of this goal
		preprocess_s_transactions(
			 % no exchange rates
			[], 
			% transaction types aka action taxonomy
			[transaction_type(foreign_purchase, aud_account, trading_account, "Some foreign income.")],
			% s_transactions, this is the input to preprocess_s_transactions
			[s_transaction(731125, foreign_purchase, [coord('USD',100,0)], usd_account, bases(['AUD']))], 
			% this should be the output
			Result,
			_),
		
		Results
	),

	% then unifying the resulting list with this
	Results = [[
	% now we owe 100USD to the business owner
	transaction(731125, "Some foreign income.", usd_account, [coord('USD', 0, 100)]),
	% but we owe him 183AUD less
	transaction(731125, "Some foreign income.", aud_account, [coord('AUD', 183.83689999999999, 0.0)]),
	% this is on our trading account with the broker
	transaction(731125, "Some foreign income.", trading_account, [coord('USD', 100, 0), coord('AUD', 0.0, 183.83689999999999)])
	]].


test(2) :-
	% Let's preprocess a transaction where the exchanged amount is known and that uses a trading account.
	write("Are transactions where the exchanged amount is known and that uses a trading account preprocessed correctly?"),

	findall(Transactions,
	(preprocess_s_transactions(
	  [], [transaction_type(foreign_purchase, aud_account, trading_account, "Some foreign income.")],
		[s_transaction(731125, foreign_purchase, [coord('USD',100,0)], usd_account, vector([coord('AUD',180,0)]))], Transactions)),
	
	[[transaction(731125, "Some foreign income.", usd_account, [coord('USD', 0, 100)]),
	transaction(731125, "Some foreign income.", aud_account, [coord('AUD', 180, 0)]),
	transaction(731125, "Some foreign income.", trading_account, [coord('USD', 100, 0), coord('AUD', 0, 180)])]]).

	

test(3) :-
	In = [ s_transaction(736542,
			'Borrow',
			[coord('AUD',0,100)],
			'NationalAustraliaBank',
			bases(['AUD'])),
	s_transaction(736704,
			'Dispose_Of',
			[coord('AUD',0.0,1000.0)],
			'NationalAustraliaBank',
			vector([coord('TLS',0,11)])),
	s_transaction(736511,
			'Introduce_Capital',
			[coord('USD',0,200)],
			'WellsFargo',
			bases(['USD'])),
	s_transaction(736704,
			'Invest_In',
			[coord('USD',50,0)],
			'WellsFargo',
			vector([coord('TLS',10,0)])),
	s_transaction(736520,
			'Invest_In',
			[coord('USD',100.0,0.0)],
			'WellsFargo',
			vector([coord('TLS',10,0)])),
	s_transaction(736704,
			'Dispose_Of',
			[coord('USD',0.0,420.0)],
			'WellsFargo',
			vector([coord('TLS',0,4)]))
	],

	Out = [ s_transaction(736511,
			'Introduce_Capital',
			[coord('USD',0,200)],
			'WellsFargo',
			bases(['USD'])),
	s_transaction(736520,
			'Invest_In',
			[coord('USD',100.0,0.0)],
			'WellsFargo',
			vector([coord('TLS',10,0)])),
	s_transaction(736542,
			'Borrow',
			[coord('AUD',0,100)],
			'NationalAustraliaBank',
			bases(['AUD'])),
	s_transaction(736704,
			'Invest_In',
			[coord('USD',50,0)],
			'WellsFargo',
			vector([coord('TLS',10,0)])),
	s_transaction(736704,
			'Dispose_Of',
			[coord('USD',0.0,420.0)],
			'WellsFargo',
			vector([coord('TLS',0,4)])),
	s_transaction(736704,
			'Dispose_Of',
			[coord('AUD',0.0,1000.0)],
			'NationalAustraliaBank',
			vector([coord('TLS',0,11)]))
	],
	sort_s_transactions(In, Out).

	
:- end_tests(bank_statement).


preprocess_s_transactions(Static_Data, Exchange_Rates, 
	[], 
	[]
).


preprocess_s_transactions(Static_Data, 
	Exchange_Rates_In, Exchange_Rates_Out,
	[S_Transaction|S_Transactions], 
	[Transactions_Out|Transactions_Out_Tail]
) :-
	Static_Data = Accounts, Report_Currency, End_Date, Transaction_Types,
	check_that_s_transaction_account_exists(S_Transaction, Accounts),
	preprocess_s_transaction1(
		Static_Data, 
		Exchange_Rates_In, Exchange_Rates_Out,
		S_Transaction, Transactions_Out),


	

filtered_and_flattened(Txs0. Txs1) :-
	...

		

			vec_sub(Vector_Bank, Vector_Goods, Trading_Vector),
			transaction_day(Trading_Transaction, Day),
			transaction_description(Trading_Transaction, Description),
			transaction_vector(Trading_Transaction, Trading_Vector),
			transaction_account_id(Trading_Transaction, Trading_Account_Id)


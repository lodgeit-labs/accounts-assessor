:- record cf_item0(account, category, own_transactions).


gl_tx_vs_cashflow_category(T, Cat) :-
	transaction_reason(T, Reason),
	(	s_transaction_by_uid(Reason, St)
	->	(	s_transaction_verb(St, Verb_Uri),
			doc(Verb_Uri, l:has_id, Verb),
			(	member(V, ['Invest_In'])
			->	Cat = ('Investing activities', '-')
			;(	member(V, [


cf_items0(Sd, Cf_Items) :-
	account_by_role(Sd.Accounts, ('Accounts'/'CashAndCashEquivalents'), Root),
	findall(Cf_Item, cashflow_entry(Root, Cf_Item), Cf_Items).

cashflow_entry(Account, Item) :-
	transactions_in_period_on_account(Sd.Accounts, Sd.Transactions, Account, Sd.Start_Date, Sd.End_Date, Filtered_Transactions),
	sort_into_dict_on_success(gl_tx_vs_cashflow_category, Filtered_Transactions, By_Category),
	dict_pairs(By_Category, _, By_Category2),
	(
		member((Category-Transactions_In_Category), By_Category2),
		/* yield one cf_item for each category on this account */
		Item = cf_item0(Account, Category, Transactions)
	)
	;
		Item = currency movement entry?.

cashflow_entry(Account, Entry) :-
	account_child_parent(Sd.Accounts, Child, Account)
	cashflow_entry(Child, Entry).

sort_into_dict_on_success
/* like sort_into_dict, but keep going if the predicate fails */


/*

by now we should have:
	Items0 = [
		cf_item0('BanksCHF_Bank', ('Investing activities', '-'), [
			{
				/* transaction term, not dict, but like this: */
				"account":"BanksCHF_Bank",
				"date":"date(2018.0,10.0,1.0)",
				"description":"Invest_In - outgoing money",
				"vector": [ {"credit":10.0, "debit":0.0, "unit":"CHF"} ],
			},
			...
			]),
		cf_item0('BanksCHF_Bank', ('Investing activities', '+'), [......
*/

now we can walk accounts from Root again, on leaf accounts do for each category and each corresponding '+'/'-':
	create 'entry' term like for balance sheet, converting each tx vector at tx date,



finally, we can walk either by account and categorizations or by categorizations and account, and
	create entry, or
	create entry with child account cf sums
	





*/
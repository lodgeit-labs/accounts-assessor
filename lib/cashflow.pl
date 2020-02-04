:- record cf_item0(account, category, own_transactions).
/* probably it should be "categorization" and subsume account? */

/* well the high-level idea is that different methods of presentation will be required, ie first by account secondary by category, and also the other way around, so, i'd first create a table where each item is a set of categories + corresponding transactions, and then possibly sum+present that in different ways */


cashflow_category(Verb, Category) :-
	cashflow_category_helper(Verbs, Category),
	member(Verb, Verbs). % can cut outside if we don't want more than one

cashflow_category_helper(['Invest_in',...], ('Investing activities', '-')).
cashflow_category_helper(['Dispose_of',...], ('Investing activities', '+')).



gl_tx_vs_cashflow_category(T, Cat) :-
	transaction_reason(T, Reason),
	(	
		s_transaction_by_uid(Reason, St)
	->	s_transaction_verb(St, Verb_Uri),
		doc(Verb_Uri, l:has_id, Verb),
		cashflow_category(Verb, Cat)
	;
		fail
	).

	


cf_items0(Sd, Cf_Items) :-
	account_by_role(Sd.Accounts, ('Accounts'/'CashAndCashEquivalents'), Root),
	findall(Cf_Item, cashflow_item0(Root, Cf_Item), Cf_Items).




% yield transactions by account + cashflow category

cashflow_item0s(Account, Item) :-
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


/*
now we can walk accounts from Root again, on leaf accounts do for each category and each corresponding '+'/'-':
	create 'entry' term like for balance sheet, converting each tx vector at tx date,
*/
cf_entries(CF_Items, Account, CF_Entry) :-
cf_entries(CF_Items, Account, CF_Entry) :-
	(	account_child_parent(...,Child, Account),
	->	cf_entries(CF_Items, Child,   
	;	cf_entry_by_categories(CF_Items, Account, ...)
	).

cf_entry_by_categories(CF_Items, Account, ...) :-
	member(cf_item0(Account, Category, Transactions), CF_Items),
	% make category entry
	entry(Account_Id, Balance, Child_Sheet_Entries, Transactions_Count).

/*
finally, we can walk either by account and categorizations or by categorizations and account, and
	create entry, or
	create entry with child account cf sums
*/




cashflow(Sd, E2) :-
	cf_entries(E0), /* with lists of transactions, maybe also with own_total's, since it will know to convert normal transactions and currencymovement differently */
	sum_entries(E1, E2),/* just simple addition of own_totals, and leave transactions in for json explorer */
	account_by_role(Sd.Accounts, ('Accounts'/'CashAndCashEquivalents'), Root),
	balance(Sd, Root, Sd.start_date, Start_Balance, _),
	balance(Sd, Root, Sd.end_date, End_Balance, _),
	Entries = [
		entry($>format(string(<$), 'CashAndCashEquivalents on ~s', [Sd.Start_Date]), Start_Balance, [], _),
		E2,
		entry($>format(string(<$), 'CashAndCashEquivalents on ~s', [Sd.End_Date]), End_Balance, [], _)].
	/* 


cf_page(Static_Data, Entries) :-
	/*this goes into ledger_html_reports.pl*/
	dict_vars(Static_Data, [Accounts, Start_Date, End_Date, Report_Currency]),
	format_date(Start_Date, Start_Date_Atom),
	format_date(End_Date, End_Date_Atom),
	report_currency_atom(Report_Currency, Report_Currency_Atom),
	atomic_list_concat(['cash flow from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ', Report_Currency_Atom], Title_Text),
	pesseract_style_table_rows(Accounts, Report_Currency, Entries, Report_Table_Data),
	Header = tr([th('Account'), th([End_Date_Atom, ' ', Report_Currency_Atom])]),
	flatten([Header, Report_Table_Data], Tbl),
	add_report_page_with_table(Title_Text, Tbl, loc(file_name,'cashflow.html'), 'cashflow_html').





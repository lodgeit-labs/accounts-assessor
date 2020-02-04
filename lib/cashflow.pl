:- record cf_item0(account, category, own_transactions).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper predicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



/*
sum_by_pred(
	P,			% pred(Item, Numeric)
	Input,		% List Item
	Sum			% Numeric = sum {X | Item in Input, P(Item,X)}
).
*/
sum_by_pred(P, Input, Sum) :-
	convlist(P, Input, Intermediate),
	sumlist(Intermediate, Sum).


/*
vec_sum_by_pred(
	P,			% pred(Item, List record:coord)
	Input,		% List Item
	Sum			% List record:coord = vec_sum {X | Item in Input, P(Item, X)}
).
*/
vec_sum_by_pred(P, Input, Sum) :-
	convlist(P, Input, Intermediate),
	vec_sum(Intermediate, Sum).

/*
sort_into_dict_on_success/3(
	P,			% pred(Item,Key)
	Input,		% List Item
	Output		% Dict Item = {Key:[Value | Value in Input, P(Value,Key)] | Value in Input, P(Value, Key)}
  
).

*/
/* like sort_into_dict, but keep going if the predicate fails */
sort_into_dict_on_success(P, Input, Output) :-
	sort_into_dict_on_success(P, Input, _{}, Output).


/*
sort_into_dict_on_success/4(
	P,			% pred(Item,Key)
	Input,		% List Item
	Current,	% Dict Item (accumulator)
	Output		% Dict Item
).

*/
sort_into_dict_on_success(_, [], Output, Output).
sort_into_dict_on_success(P, [I|Is], D, Output) :-
	(
		% should probably be wrapped in try/catch since sometimes it fails by error
		call(P,I,Key)
	->
		New_Value = [Key-[I | D.Key]],
		dict_pairs(New_Key_Value, _, New_Value),
		Next_D = D.put(New_Key_Value)
	;	Next_D = D
	),
	sort_into_dict_on_success(P, Is, Next_D, Output).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Start main code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



/* probably it should be "categorization" and subsume account? */

/* well the high-level idea is that different methods of presentation will be required, ie first by account secondary by category, and also the other way around, so, i'd first create a table where each item is a set of categories + corresponding transactions, and then possibly sum+present that in different ways */


/*
type Cashflow Category = (
	Category,		% atom:{'Investing activities', 'Operating activities', 'Financing activities'}
	PlusMinus		% atom:{'+','-'}
)
*/



/*
cashflow_category(
	Verb			% atom:Transaction Verb
	Category		% Cashflow Category
).
*/

cashflow_category(Verb, Category) :-
	cashflow_category_helper(Verbs, Category),
	member(Verb, Verbs). % can cut outside if we don't want more than one




/*
cashflow_category_helper(
	Verbs,			% List atom:Transaction Verb
	Category		% Cashflow Category
).
*/

% later: derive this from input data

cashflow_category_helper(
	[
		'Dispose_of',
		'Interest_Income'
	], 
	('Investing activities', '+')
).

cashflow_category_helper(
	[
		'Invest_in'
	], 
	('Investing activities', '-')
).

cashflow_category_helper(
	[
		'Borrow'
	], 
	('Financing activities', '+')
).

cashflow_category_helper(
	[
		'Dividends'
	],
	('Financing activities', '-')
).

cashflow_category_helper(['Dispose_of'], ('Operating activities', '+')).
cashflow_category_helper(['Bank_Charges','Accountancy_Fees'], ('Operating activities', '-')).






/*
gl_tx_vs_cashflow_category(
	Transaction,	% record:transaction,
	Category		% Cashflow Category
).

*/

gl_tx_vs_cashflow_category(T, Cat) :-
	transaction_reason(T, Reason),
	(
		doc(Reason, a, s_transaction),
	->
		doc(Reason, s_transaction:type_id, uri(Verb_URI)),
		doc(Verb_URI, l:has_id, Verb),
		cashflow_category(Verb, Cat)
	).

	

/*
cf_items0(
	Sd,			% Dict:Static Data
	Root,		% atom:Account ID
	Cf_Items	% List record:cf_item0
).

*/
cf_items0(Sd, Root, Cf_Items) :-
	findall(Cf_Item, cashflow_item0(Sd, Root, Cf_Item), Cf_Items).




/*
cashflow_item0(
	Static_Data,		% Dict:Static Data
	Account,			% atom:Account ID
	Item				% record:cf_item0
).

Yield transactions by account + cashflow category
*/

cashflow_item0(Sd, Account, Item) :-
	transactions_in_period_on_account(Sd.accounts, Sd.transactions, Account, Sd.start_Date, Sd.end_Date, Filtered_Transactions),
	sort_into_dict_on_success(gl_tx_vs_cashflow_category, Filtered_Transactions, By_Category),
	dict_pairs(By_Category, _, By_Category2),
	(
		member((Category-Transactions), By_Category2),
		/* yield one cf_item for each category on this account */
		Item = cf_item0(Account, Category, Transactions)
	).
	/*
	;
		Item = currency movement entry?.
	*/


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
/*
cf_entries(
	Static_Data,		% Static Data
	CF_Items,			% List Cashflow Item
	Account,			% atom:Account ID
	CF_Entry			% entry
).
*/
cf_entries(Sd, Account, CF_Items, entry(Account, Balance, Child_Entries, _)) :-
	account_child_parent(Sd.accounts, _, Account),
	findall(
		Child_Entry,
		(
			account_child_parent(Sd.accounts, Child, Account),
			cf_entries(Sd, Child, CF_Items, Child_Entry)
		),
		Child_Entries
	),
	sum_by_pred(entry_balance, Child_Entries, Balance).

cf_entries(Sd, Account, CF_Items, Entry) :-
	\+account_child_parent(Sd.accounts, _, Account),
	cf_entry_by_categories(CF_Items, Account, Entry).



/*
cf_entry_by_categories(
	CF_Items,		% List record:cf_item0
	Account,		% atom:Account ID
	Entry			% record:entry
).
*/
cf_entry_by_categories(CF_Items, Account, Entry) :-
	findall(
		CF_Item,
		(
			member(CF_Item, CF_Items),
			CF_Item = cf_item0(Account, _, _)
		),
		Account_Items
	),
	sort_into_dict_on_success([CF_Item, Category]>>(CF_Item = cf_item0(_,(Category,_),_)), Account_Items, Account_Items_By_Category),
	dict_pairs(Account_Items_By_Category, _, Account_Items_By_Category_Pairs),
	findall(
		Category_Entry,
		(
			member(Category-CF_Items, Account_Items_By_Category_Pairs),
			cf_entry_by_category(Category, CF_Items, Category_Entry)
		),
		Category_Entries
	),
	sum_by_pred(entry_balance, Category_Entries, Balance),
	Entry = entry(Account, Balance, Category_Entries, _).


/*
cf_entry_by_category(
	Category,				% atom:Category ID
	CF_Items,				% List record:cf_item0
	Category_Entry			% record:entry
).
*/
cf_entry_by_category(Category, CF_Items, Category_Entry) :-
	sort_into_dict_on_success([CF_Item, Plus_Minus]>>(CF_Item = cf_item0(_,(_,Plus_Minus),_)), CF_Items, Transactions_By_PlusMinus),

	cf_item0(_,(_,_),Plus_Transactions) = Transactions_By_PlusMinus.'+',
	transaction_vectors_total(Plus_Transactions, Plus_Balance),
	% 
	Plus_Entry = entry('+', Plus_Balance, [], _),

	cf_item0(_,(_,_),Minus_Transactions) = Transactions_By_PlusMinus.'-',
	transaction_vectors_total(Minus_Transactions, Minus_Balance),
	Minus_Entry = entry('-', Minus_Balance, [], _),

	PlusMinus_Entries = [Plus_Entry, Minus_Entry],
	sum_by_pred(entry_balance, PlusMinus_Entries, Balance),	
	Category_Entry = entry(Category, Balance, PlusMinus_Entries, _).

/*
finally, we can walk either by account and categorizations or by categorizations and account, and
	create entry, or
	create entry with child account cf sums
*/



cashflow(
	Sd,				% Static Data
	Entries			% List entry
) :-

	account_by_role(Sd.accounts, ('Accounts'/'CashAndCashEquivalents'), Root),
	cf_items0(Sd, Root, CF_Items),
	cf_entries(Sd, Root, CF_Items, Sub_Entries), /* with lists of transactions, maybe also with own_total's, since it will know to convert normal transactions and currencymovement differently */
	%sum_entries(E1, E2),/* just simple addition of own_totals, and leave transactions in for json explorer */

	balance(Sd, Root, Sd.start_date, Start_Balance, _),
	balance(Sd, Root, Sd.end_date, End_Balance, _),
	Entries = [
		entry($>format(string(<$), 'CashAndCashEquivalents on ~s', [Sd.start_Date]), Start_Balance, [], _),
		Sub_Entries,
		entry($>format(string(<$), 'CashAndCashEquivalents on ~s', [Sd.end_Date]), End_Balance, [], _)
	].

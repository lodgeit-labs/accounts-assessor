:- record cf_item0(account, category, own_transactions).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper predicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

/*
sum_by_pred(
	P,			% pred(Item, Numeric)
	Input,		% List<Item>
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
		% should probably be wrapped in try/catch since sometimes it fails by error % mm i'd let that propagate
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

/* the high-level idea is that different methods of presentation will be required, ie first by account secondary by category, and also the other way around, so, i'd first create a table where each item is a set of categories + corresponding transactions, and then possibly sum+present that in different ways */


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
	doc(T, transactions:origin, Origin),
	(
		doc(Origin, rdf:type, s_transaction)
	->
		doc(Origin, s_transactions:type_id, uri(Verb_URI)),
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
/*cf_items0(Sd, Root, Cf_Items) :-
	findall(Cf_Item, cashflow_item0(Sd, Root, Cf_Item), Cf_Items).*/


tag_gl_transactions_with_cf_data(Ts) :-
	maplist(tag_gl_transaction_with_cf_data, Ts).

tag_gl_transaction_with_cf_data(T) :-
	(	gl_tx_vs_cashflow_category(T, (Cat, PlusMinus))
	->	(
			doc_add(T, l:cf_category, Cat),
			doc_add(T, l:cf_plusminus, PlusMinus)
		)
	;	true).

*/

/*
cashflow_item0(
	Static_Data,		% Dict:Static Data
	Account,			% atom:Account ID
	Item				% record:cf_item0
).

Yield transactions by account + cashflow category
*/

make_cf_instant_txs(Sd) :-
	account_by_role(Sd.accounts, ('Accounts'/'CashAndCashEquivalents'), Root),
	transactions_in_period_on_account_and_subaccounts(Sd.accounts, Sd.transactions, Root, Sd.start_date, Sd.end_date, Filtered_Transactions),
	maplist(cf_instant_tx, Filtered_Transactions).

make_cf_instant_tx(T) :-
	(doc(T, l:cf_category, Cat)->true;Cat = 'unknown'),
	(doc(T, l:cf_plusminus, PlusMinus)->true;PlusMinus = '?')
	doc_new_uri(U),
	doc_add(U, rdf:type, l:cf_instant_tx),
	doc_add(U, l:account, $>transaction_account_id(T)),
	doc_add(U, l:category, Cat),
	doc_add(U, l:plusminus, PlusMinus),
	doc_add(U, l:transaction, T).


cf_instant_tx(Account, Cat, PlusMinus, T) :-
	doc(U, rdf:type, l:cf_instant_tx),
	doc_add(U, l:category, Cat),
	doc_add(U, l:plusminus, PlusMinus),
	doc(U, l:transaction, T).

cf_instant_txs(Account, Cat, PlusMinus, Txs) :-
	findall(T, cf_instant_tx(Account, Cat, PlusMinus, T), Txs).

/*
now we can walk accounts from Root, on leaf accounts do for each category and each corresponding '+'/'-':
	create 'entry' term like for balance sheet, converting each tx vector at tx date,
*/
/*
cf_entries(
	Static_Data,		% Static Data
	Account,			% atom:Account ID
	CF_Entry			% entry
).
*/

cf_scheme_0_root_entry(Sd, Entry) :-
	cf_scheme_0_entries_helper_for_accounts(Sd, $>account_by_role(Sd.accounts, ('Accounts'/'CashAndCashEquivalents')), Entry).

cf_scheme_0_entry_for_account(Sd, Account, Entry) :-
	account_children(Sd, Account, Children),
	dif(Children, []),
	Entry = entry0(Account, [], $>maplist(cf_scheme_0_entry_for_account, Children)).

/*
cf_scheme_0_entry_for_account(
	Account,		% atom:Account ID
	Entry			% record:entry0
).
*/

cf_scheme_0_entry_for_account(Sd, Account, Entry) :-
	account_children(Sd, Account, []),
	findall(
		CF_Item,
		(
			cf_instant_txs(Account, Cat, PlusMinus, Txs),
			CF_Item = cf_item0(Account, Cat, PlusMinus, Txs)
		),
		Account_Items
	),
	sort_into_dict_on_success([CF_Item, Category]>>(CF_Item = cf_item0(_,Category,_,_)), Account_Items, Account_Items_By_Category),
	dict_pairs(Account_Items_By_Category, _, Account_Items_By_Category_Pairs),
	findall(
		Category_Entry,
		(
			member(Category-CF_Items, Account_Items_By_Category_Pairs),
			cf_entry_by_category(Category, CF_Items, Category_Entry)
		),
		Category_Entries0
	),
	cf_scheme_0_bank_account_currency_movement_entry(Sd, Account, Currency_Movement_Entry),
	Entry = entry0(Account, [], $>append(Category_Entries0, [Currency_Movement_Entry])).

cf_scheme_0_bank_account_currency_movement_entry(Sd, Account, Currency_Movement_Entry) :-
	bank_account_currency_movement_account(Sd.accounts, Account, Currency_Movement_Account),
	net_activity_by_account(Sd, Account, Vec, _),
	Currency_Movement_Entry = entry0('Currency movement', Vec, []).

/*
cf_entry_by_category(
	Category,				% atom:Category ID
	CF_Items,				% List record:cf_item0
	Category_Entry			% record:entry
).
*/
cf_entry_by_category(Category, CF_Items, Category_Entry) :-
	sort_into_dict_on_success([CF_Item, Plus_Minus]>>(CF_Item = cf_item0(_,_,Plus_Minus,_)), CF_Items, Cf_Items_By_PlusMinus),
	dict_pairs(Cf_Items_By_PlusMinus, _, Pairs),
	maplist(cf_scheme0_plusminus_entry, Pairs, Child_Entries),
	Category_Entry = entry0(Category, [], Child_Entries).

cf_scheme0_plusminus_entry((Pm-Item), Entry) :-
	[cf_item0(_,_,_,Transactions)] = Item,
	maplist(cf_instant_tx_vector_conversion, Transactions, Converted_Vecs),
	Entry = entry(Pm, Converted_Vecs, []).




entry0_to_entry1(Entry0, Entry1) :-
	Entry0 = entry0(Title, Own_Vecs, []),
	vec_sum_with_proof(Own_Vecs,Sum_Vec).
entry0_to_entry1(Entry0, Entry1) :-
	Entry0 = entry0(Title, [], Children),
	Children \= [],
	maplist(entry0_to_entry1
	vec_sum_with_proof(Own_Vecs,Sum_Vec).



/*
	Vec: [a rdf:value]
	Sum: [a rdf:value]
*/
vec_sum_with_proof(Vec, Sum) :-
	maplist([Uri, Lit]>>(doc(Uri, rdf:value, Lit)), Vec, Vec_Lits),
	vec_sum(Vec_Lits, Sum_Lit),
	doc_new_(rdf:value, Sum),
	doc_add(Sum, rdf:value, Sum_Lit),
	doc_add(Sum, l:source, Vec).


cf_instant_tx_vector_conversion(Sd, Tx, Vec) :-
	/*very crude metadata for now*/
	doc_new_(rdf:value, Uri),
	doc_add(Uri, rdf:value, Vec),
	Source = vec_change_bases(Sd.exchange_rates, $>transaction_day(Tx), Sd.report_currency, $>transaction_vector(Tx), Vec),
	doc_add(Uri, l:source, Source),
	call(Source).


/*
finally, we can generically walk the entry tree with own vectors, and create sums
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

%:- record cf_item0(account, category, pm, own_transactions).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Start main code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


/* the high-level idea is that different methods of presentation will be required, ie first by account secondary by category, and also the other way around, so, i'd first create a table where each item is a set of categories + corresponding transactions, and then possibly sum+present that in different ways

data flow:
	tag_gl_transaction_with_cf_data
		enrich relevant gl transactions with categorization
	make_cf_instant_tx


*/


/*

	cashflow report category by action verb

*/

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

cashflow_category(Category, Verb) :-
	cashflow_category_helper(Category,Verbs),
	member(Verb, Verbs). % can cut outside if we don't want more than one

/*
cashflow_category_helper(
	Verbs,			% List atom:Transaction Verb
	Category		% Cashflow Category
).
*/

% later: derive this from input data

cashflow_category_helper(('Investing activities', '+'),
	[
		'Dispose_Of','Dispose_Off',
		'Interest_Income'
	]
).

cashflow_category_helper(
	('Investing activities', '-'),
	[
		'Invest_In'
	]
).

cashflow_category_helper(
	('Financing activities', '+'),
	[
		'Borrow',
		'Introduce_Capital'
	]
).

cashflow_category_helper(
	('Financing activities', '-'),
	[
		'Dividends'
	]
).

cashflow_category_helper(
	('Operating activities', '-'),
	[
		'Bank_Charges',
		'Accountancy_Fees'
	]
).


/*
gl_tx_vs_cashflow_category(
	Transaction,	% record:transaction,
	Category		% Cashflow Category
).
*/

gl_tx_vs_cashflow_category(T, Cat) :-
%gtrace,
	doc(T, transactions:origin, Origin, transactions),
	(
		doc(Origin, rdf:type, l:s_transaction, transactions)
	->
		doc(Origin, s_transactions:type_id, uri(Verb_URI), transactions),
		doc(Verb_URI, l:has_id, Verb),
		cashflow_category((Cat,_Dir), Verb)
	).



/*
cf_items0(
	Sd,			% Dict:Static Data
	Root,		% atom:Account ID
	Cf_Items	% List record:cf_item0
).
*/


tag_gl_transaction_with_cf_data(T) :-
	transaction_vector(T, V),
	(	is_debit(V)
	->	PlusMinus0 = '+'
	;	PlusMinus0 = '-'),
	PlusMinus = _{'-':decreases,'+':increases}.get(PlusMinus0),
	(	gl_tx_vs_cashflow_category(T, (Cat/*, PlusMinus0*/))
	->	true
	;	(
			Cat = 'no category'
			%PlusMinus = 'unknown direction'
		)
	),
	doc_add(T, l:cf_category, Cat, cf_stuff),
	doc_add(T, l:cf_plusminus, PlusMinus, cf_stuff).


/* collect all relevant transactions, return a list of pairs (Categorization, Tx) */
cf_categorization_uri_tx_pairs(Account, Cat, PlusMinus, Categorization_Tx_Pairs) :-
	findall(
		(cat(Account, Cat, PlusMinus), T),
		(
			docm(T, rdf:type, l:transaction, transactions),
			doc(T, transactions:account, Account, transactions),
			doc(T, l:cf_category, Cat, cf_stuff),
			doc(T, l:cf_plusminus, PlusMinus, cf_stuff)
		),
		Pairs
	),
	maplist([(C,T),ct(Uri,T)]>>categorization_to_uri(C,Uri), Pairs, Categorization_Tx_Pairs).

/* put each categorization tuple into doc, so we can use the uris as keys in dicts */
categorization_to_uri(cat(Account, Cat, PlusMinus), U) :-
	(	(
			docm(U, rdf:type, l:cf_categorization, cf_stuff),
			docm(U, l:account, Account, cf_stuff),
			docm(U, l:category, Cat, cf_stuff),
			docm(U, l:plusminus, PlusMinus, cf_stuff)
		)
	->	true
	;	(
			doc_new_uri(U),
			doc_add(U, rdf:type, l:cf_categorization, cf_stuff),
			doc_add(U, l:account, Account, cf_stuff),
			doc_add(U, l:category, Cat, cf_stuff),
			doc_add(U, l:plusminus, PlusMinus, cf_stuff)
		)
	).

/*
	cf scheme 0: account -> category -> plusminus -> transactions

	walk accounts from Root, on leaf accounts do for each category and each corresponding '+'/'-':
		create 'entry' term like for balance sheet, converting each tx vector at tx date
*/

/*
cf_scheme_0_entry_for_account(
	Account,		% atom:Account ID
	Entry			% record:entry0
).
*/
cf_scheme_0_root_entry(Sd, Entry) :-
	cf_scheme_0_entry_for_account(Sd, $>account_by_role(Sd.accounts, ('Accounts'/'CashAndCashEquivalents')), Entry).

cf_scheme_0_entry_for_account(Sd, Account, Entry) :-
	dif(Children, []),
	account_children(Sd, Account, Children),
	/* collect entries of child accounts */
	Entry = entry0(Account, [], $>maplist(cf_scheme_0_entry_for_account(Sd), Children)).

cf_scheme_0_entry_for_account(Sd, Account, Entry) :-
	account_children(Sd, Account, []),
	cf_categorization_uri_tx_pairs(Account, _Cat, _PlusMinus, Account_Items),
	gu(l:category, LCategory),
	sort_into_dict({LCategory}/[ct(Cat_Uri,_), Category]>>doc(Cat_Uri, LCategory, Category, cf_stuff), Account_Items, Account_Items_By_Category),
	dict_pairs(Account_Items_By_Category, _, Account_Items_By_Category_Pairs),
	maplist(cf_entry_by_category(Sd), Account_Items_By_Category_Pairs, Category_Entries0),
	cf_scheme_0_bank_account_currency_movement_entry(Sd, Account, Currency_Movement_Entry),
	Entry = entry0(Account, [], $>append(Category_Entries0, [Currency_Movement_Entry])).

cf_scheme_0_bank_account_currency_movement_entry(Sd, Account, Currency_Movement_Entry) :-
	bank_account_currency_movement_account(Sd.accounts, Account, Currency_Movement_Account),
	net_activity_by_account(Sd, Currency_Movement_Account, Vec0, _),
	vec_inverse(Vec0, Vec),
	doc_new_(rdf:value, Vec_Uri),
	doc_add(Vec_Uri, rdf:value, Vec),
	doc_add(Vec_Uri, l:source, net_activity_by_account(Account, Vec, _)),
	Currency_Movement_Entry = entry0('Currency movement', Vec_Uri, []).
/*
cf_entry_by_category(
	Category,				% atom:Category ID
	CF_Items,				% List<(Categorization, Tx)>
	Category_Entry			% record:entry0
).
*/
cf_entry_by_category(Sd, Category-CF_Items, Category_Entry) :-
	sort_into_dict([ct(Cat,_),Plus_Minus]>>doc(Cat, l:plusminus, Plus_Minus, cf_stuff), CF_Items, Cf_Items_By_PlusMinus),
	dict_pairs(Cf_Items_By_PlusMinus, _, Pairs),

	maplist(cf_scheme0_plusminus_entry(Sd), Pairs, Child_Entries),
	Category_Entry = entry0(Category, [], Child_Entries).

cf_scheme0_plusminus_entry(Sd, (PlusMinus-CF_Items), Entry) :-
	maplist(cf_instant_tx_entry0(Sd), CF_Items, Tx_Entries),
	Entry = entry0(PlusMinus, [], Tx_Entries).

cf_instant_tx_entry0(Sd, ct(_,Tx), Entry) :-
	cf_instant_tx_vector_conversion(Sd, Tx, Vec),
	Entry = entry0([
		$>term_string($>transaction_day(Tx)),
		$>term_string($>transaction_description(Tx)),
		$>link(Tx)
	], Vec, []).

link(Uri, Link) :-
	Link = a(href=Uri, [small('⍰')]).

cf_instant_tx_vector_conversion(Sd, Tx, Uri) :-
	/*very crude metadata for now*/
	doc_new_(rdf:value, Uri),
	doc_add(Uri, rdf:value, Vec),
	Source = vec_change_bases(Sd.exchange_rates, $>transaction_day(Tx), Sd.report_currency, $>transaction_vector(Tx), Vec),
	doc_add(Uri, l:source, Source),
	call(Source).


/*
	walk the entry0 tree with own vectors, and create entry terms.
*/
entry0_to_entry(Entry0, Entry1) :-
	Entry0 = entry0(Title, Own_Vec, []),
	Entry1 = entry(Title, Own_Vec, [], 123456789).
entry0_to_entry(Entry0, Entry1) :-
	Entry0 = entry0(Title, [], Children0),
	Children0 \= [],
	maplist(entry0_to_entry, Children0, Children1),
	maplist(entry_balance, Children1, Vecs),
	vec_sum_with_proof(Vecs,Sum),
	Entry1 = entry(Title, Sum, Children1, 123456789).


cashflow(
	Sd,				% Static Data
	Entries			% List entry
) :-
	account_by_role(Sd.accounts, ('Accounts'/'CashAndCashEquivalents'), Root),
	transactions_in_period_on_account_and_subaccounts(Sd.accounts, Sd.transactions_by_account, Root, Sd.start_date, Sd.end_date, Filtered_Transactions),
	maplist(tag_gl_transaction_with_cf_data, Filtered_Transactions),
	cf_scheme_0_root_entry(Sd, Entry0),
	entry0_to_entry(Entry0, Entry),
/*	balance(Sd, Root, Sd.start_date, Start_Balance, C1),
	balance(Sd, Root, Sd.end_date, End_Balance, C2),*/
	balance_by_account(Sd.exchange_rates, Sd.accounts, Sd.transactions_by_account, Sd.report_currency, Sd.start_date, Root, Sd.start_date, Start_Balance, C1),
	balance_by_account(Sd.exchange_rates, Sd.accounts, Sd.transactions_by_account, Sd.report_currency, Sd.end_date, Root, Sd.end_date, End_Balance, C2),
	Entries = [
		entry($>format(string(<$), 'CashAndCashEquivalents at ~q', [Sd.start_date]), Start_Balance, [], C1),
		Entry,
		entry($>format(string(<$), 'CashAndCashEquivalents at ~q', [Sd.end_date]), End_Balance, [], C2)
	].

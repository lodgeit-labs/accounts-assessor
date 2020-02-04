cf_by_account :-
	...Root..,
	cf_entry_for_account(Root)


% we can maybe experiment w/ type inference, but
% expected types might not always be able to be inferred from the body goals or from calls to the predicate
% due to polymorphism and possibly high complexity in terms of how the choice of type is arrived at in these cases.
/*
would be nice but i still havent even learned how to parse prolog code, well we already sort of can w/ the meta-interpreter stuff
mostly just noting here why the types would need to be written out explicitly w/ the signature, i.e. it's not always obvious, even
to a computer
*/

cf_entry_for_account(
	Account,			% atom:Account ID
	Entry				% Entry
) :-
	cf_child_account_entries(Account, Child_Entries),
	cf_category_entries(Account, Category_Entries),
	append(Child_Entries, Category_Entries, Entries),
	Entry = entry(Account, [], Entries).


cf_child_account_entries(
	Account,			% atom:Account ID
	Child_Entries		% List Entry
) :-
	/* one entry for each child account */
	findall(
		Child_Entry,
		(
			account_child_parent(Sd.Accounts, Child, Account),
			cf_entry_for_account(Child, Child_Entry)
		),
		Child_Entries
	).


cf_category_entries(
	Account,			% atom:Account ID
	Category_Entries	% List Entry
) :-
	/* one entry for each cf category */
	findall(
		Category_Entry,
		(
			cashflow_category(Verb, Category),
			transactions_on_account_and_cf_category(Account, Category, Account_And_Category_Txs),
			cf_entry_for_category(Account, Category, Account_And_Category_Txs, Category_Entry)
		),
		Category_Entries
	).
		

child_entries_by_predicate(
	Pred,			% Pred(Transaction, atom:Group)
	Transactions,	% List record:transaction
	Entries			% List (non-nested) Entry
) :-
	sort_into_dict(Pred, Transactions, Dict),
	dict_pairs(Dict, _, Pairs),
	findall(
		Entry,
		(
			member((Group-Group_Transactions), Pairs),
			Entry = entry(Group, Group_Transactions, [])
		),
		Entries
	).


cf_entry_for_category(
	Category,		% Cashflow Category +/-
	Transactions,	% List record:transaction
	Entry			% Entry
) :-
	child_entries_by_predicate('cf_+-', Transactions, PlusMinus_Entries),
	Entry = entry(Category, [], PlusMinus_Entries).



'cf_+-'(
	Tx,				% record:transaction
	X				% atom:{'+','-'}
) :-
	transaction_uid(Tx, Uid),
	doc(Tx, 'cf_+-', X).


transactions_on_account_and_cf_category(
	Account,					% atom:Account ID
	Category,					% Cashflow Category +/-
	Account_And_Category_Txs	% List record:transaction
) :-
	transactions_on_account(Sd, Account, .., , Account_Txs),
	filter(Account_Txs, transaction_cf_category(Category), Account_And_Category_Txs).

% already have higher-level combinations of filters/selections/whatever in terms of logical connectives applied to
% filter preds, i.e. filter and filter2 = filter1_and_2
/*
filter(
	All_Txs, 
	[Transaction]>>(
		transaction_account(Transaction, Account),
		transaction_cf_category(Transaction, Category)
	),
	Account_And_Category_Txs
)
*/

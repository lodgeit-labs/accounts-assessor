
'extract action verbs' :-
	(	get_optional_singleton_sheet_data(ic_ui:action_verbs_sheet, Data)
	->	maplist(!'extract action verb', $>doc_list_items($>value(Data)))
	;	true),
	!add_builtin_action_verbs.


'extract action verb'(Item) :-
	push_format('extract action verb from: ~w', [$>sheet_and_cell_string(Item)]),
	doc_new_(l:action_verb, Uri),

	atom_string(Name, $>rpv(Item,av:name)),
	doc_add(Uri, l:has_id, Name),

	maplist(optional_atom(Item, Uri), [
		(av:description, l:has_description),
		(av:exchanged_account, l:has_counteraccount),
		(av:trading_account, l:has_trading_account),
		(av:gst_receivable_account, l:has_gst_receivable_account),
		(av:gst_payable_account, l:has_gst_payable_account)
	]),

	/* account specifiers would have to be resolved here, but then in other places, we'd have to start expecting account uris as opposed to names everywhere downstream, like in ensure_financial_investments_accounts_exist or anywhere where l:has_counteraccount etc is used */ 
	/*maplist(optional_account(Item, Uri), [
	]),*/

	optional_decimal(Item, Uri, (av:gst_rate_percent, l:has_gst_rate)),
	pop_context.

/*
optional_account(Old_item,New_item,(Src,Dst)) :-
	(	doc(Old_item, Src, Str)
	->	(	find_account_by_specification(Str, [], Account),
			doc_add(New_item, Dst, Account))
	;	true).
*/

/* if Old_item has Src, convert it to atom, and add it to New_item as Dst */
optional_atom(Old_item,New_item,(Src,Dst)) :-
	(	doc_value(Old_item, Src, Str)
	->	(	atom_string(Atom, Str),
			doc_add(New_item, Dst, Atom))
	;	true).

optional_decimal(Old_item,New_item,(Src,Dst)) :-
	(	doc_value(Old_item, Src, D)
	->	doc_add(New_item, Dst, D)
	;	true).


add_builtin_action_verbs :-
	/*fixme*/
	doc_add(l:livestock_sale, rdf:type, l:action_verb),
	doc_add(l:livestock_sale, l:has_id, 'Livestock_Sale'),
	doc_add(l:livestock_purchase, rdf:type, l:action_verb),
	doc_add(l:livestock_purchase, l:has_id, 'Livestock_Purchase').

action_verb(Action_Verb) :-
	*doc(Action_Verb, rdf:type, l:action_verb).




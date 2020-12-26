% transaction types aka action verbs


'extract action verbs' :-
	!doc_value($>request_data, ic:action_verbs, X),
 	maplist(!'extract action verb', $>doc_list_items(X)),
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

	optional_decimal(Item, Uri, (av:gst_rate_percent, l:has_gst_rate)).


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
	docm(Action_Verb, rdf:type, l:action_verb).

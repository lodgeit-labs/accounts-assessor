 extract_smsf_distribution(Txs) :-
  	!request_data(Rd),
 	(	doc(Rd, smsf:distribution, D)
 	->	!extract_smsf_distribution2(D, Txs)
 	;	Txs=[]).

 extract_smsf_distribution2(Distribution, Txs) :-
	!doc_value(Distribution, smsf_distribution_ui:default_currency, Default_currency0),
	!atom_string(Default_currency, Default_currency0),
	!doc_value(Distribution, smsf_distribution_ui:items, D),
	!doc_list_items(D, Items),
	!maplist(extract_smsf_distribution3(Default_currency), Items, Txs0),
 	!flatten(Txs0, Txs).

extract_smsf_distribution3(Default_currency, Item, Txs) :-
	doc_value(Item, smsf_distribution_ui:name, Unit_name_str),
	trim_string(Unit_name_str, Unit_name_str2),
	extract_smsf_distribution4(Default_currency, Item, Unit_name_str2, Txs).

extract_smsf_distribution4(_, _, "Dr/Cr", []) :- !.
extract_smsf_distribution4(_, _, "Total", []) :- !.

extract_smsf_distribution4(Default_currency, Item, Unit_name_str, Txs) :-
	!atom_string(Unit, Unit_name_str),
	!traded_units($>request_has_property(l:bank_s_transactions), Traded_Units),
	(	member(Unit, Traded_Units)
	->	true
	;	throw_string(['smsf distribution sheet: unknown unit: ', Unit])),
	distribution_txs(Default_currency, Item, Unit, Txs),
	assert_smsf_distribution_facts(Default_currency, Unit, Item).

assert_smsf_distribution_facts(Default_currency, Unit, Item) :-
	maplist(
		optionally_assert_doc_value_as_unit_fact(Default_currency, Unit, Item),
		[	smsf_distribution_ui:franking_credit,
			smsf_distribution_ui:foreign_credit,
			smsf_distribution_ui:non_primary_production_income,
			smsf_distribution_ui:franked_divis_distri_including_credits,
			smsf_distribution_ui:assessable_foreign_source_income]).

distribution_txs(Default_currency, Item, Unit, Txs) :-
	!request_has_property(l:end_date, End_Date),
	!maplist(!smsf_distribution_tx(Default_currency, End_Date, Item),
		[dist{
			prop: smsf_distribution_ui:accrual,
			a:'Distribution Received'/Unit,
			dir:crdr,
			b:'Distribution Receivable'/Unit,
			desc:"Distributions Accrual entry as per Annual tax statements"},
		dist{
			prop: smsf_distribution_ui:foreign_credit,
			a:'Distribution Received'/Unit,
			dir:crdr,
			b:'Foreign And Other Tax Credits',
			desc:"Tax offset entry against distribution"},
		dist{
			prop: smsf_distribution_ui:franking_credit,
			a:'Distribution Received'/Unit,
			dir:crdr,
			b:'Imputed Credits',
			desc:"Tax offset entry against distribution"}
		],
		Txs).



smsf_distribution_tx(Default_currency, Date, Item, Dist, Txs) :-
	Dist = dist{prop:Prop, a:A, b:B, dir: crdr, desc:Desc},
	(	read_coord_vector_from_doc_string(Item, Prop, Default_currency, kb:credit, VectorA)
	->	(
			!vec_inverse(VectorA, VectorB),
			!doc_new_uri(distributions_input_st, St),
			!doc_add_value(St, transactions:description, Desc, transactions),
			!doc_add_value(St, transactions:input_sheet_item, Item, transactions),
			Txs = [
				($>make_transaction(St, Date, Desc, $>!abrlt(A), VectorA)),
				($>make_transaction(St, Date, Desc, $>!abrlt(B), VectorB))
			]
		)
	;	Txs = []).


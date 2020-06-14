 extract_smsf_distribution(Txs) :-
  	!request_data(Rd),
 	(	doc(Rd, smsf:distribution, D)
 	->	!extract_smsf_distribution2(D, Txs)
 	;	Txs=[]).

 extract_smsf_distribution2(Distribution, Txs) :-
	!doc_value(Distribution, smsf_distribution_ui:default_currency, Default_currency0),
	!atom_string(Default_currency, Default_currency0),
	!doc_list_items($>!doc_value(Distribution, smsf_distribution_ui:items), Items),
	!maplist(extract_smsf_distribution3(Default_currency), Items, Txs0),
 	!flatten(Txs0, Txs).

extract_smsf_distribution3(Default_currency, Item, Txs) :-
	trim_string($>!doc_value(Item, smsf_distribution_ui:name), Unit_name_str2),
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

/*
┏━╸┏━┓┏━╸╺┳╸┏━┓
┣╸ ┣━┫┃   ┃ ┗━┓
╹  ╹ ╹┗━╸ ╹ ┗━┛
*/
assert_smsf_distribution_facts(Default_currency, Unit, Item) :-
	/* assert the facts we want to use */
	maplist(
		optionally_assert_doc_value_as_unit_fact(Default_currency, Unit, Item),
		[	smsf_distribution_ui:net,
			smsf_distribution_ui:bank,
			smsf_distribution_ui:franking_credit,
			smsf_distribution_ui:foreign_credit,
			smsf_distribution_ui:amit_decrease,
			smsf_distribution_ui:amit_increase,
			smsf_distribution_ui:non_primary_production_income,
			smsf_distribution_ui:franked_divis_distri_including_credits,
			smsf_distribution_ui:assessable_foreign_source_income
		]
	),

	computed_unit_fact(
		smsf_distribution_ui:accrual
		=
		smsf_distribution_ui:net
		-
		smsf_distribution_ui:bank),

	check_entered_unit_fact_matches_computed(Default_currency, Unit, Item, smsf_distribution_ui:accrual, smsf_distribution_ui:entered_accrual),

	computed_unit_fact(
		smsf_distribution_ui:amit_net
		=
		smsf_distribution_ui:amit_decrease
		+
		smsf_distribution_ui:amit_increase),

	check_entered_unit_fact_matches_computed(Default_currency, Unit, Item, smsf_distribution_ui:amit_net, smsf_distribution_ui:entered_amit_net),

	computed_unit_fact(
		smsf_distribution_ui:distribution_income
		=
		smsf_distribution_ui:net
		+
		smsf_distribution_ui:franking_credit
		+
		smsf_distribution_ui:foreign_credit
		+
		smsf_distribution_ui:amit_net),

	check_entered_unit_fact_matches_computed(Default_currency, Unit, Item, smsf_distribution_ui:distribution_income, smsf_distribution_ui:entered_distribution_income),

	computed_unit_fact(
		smsf_distribution_ui:net_trust_distribution_income
		=
		smsf_distribution_ui:non_primary_production_income
		+
		smsf_distribution_ui:franked_divis_distri_including_credits
		+
		smsf_distribution_ui:assessable_foreign_source_income),

	check_entered_unit_fact_matches_computed(Default_currency, Unit, Item, smsf_distribution_ui:net_trust_distribution_income, smsf_distribution_ui:entered_net_trust_distribution_income).
	/*
	todo:
Capital Gains/Losses Calculations from Annual Tax Statements
Capital Losses
Discount Capital Gains (Net)
Other Capital Gains
1/3rd Capital Gain Discount Amount
	*/


check_entered_unit_fact_matches_computed(Default_currency, Unit, Item, Prop, Entered) :-
	(	assert_doc_value_as_fact_with_concept(Default_currency, Unit, Item, Prop, Entered)
	->	soft_crosscheck(
			aspects([
				unit - Unit,
				concept - Entered])
			=
			aspects([
				unit - Unit,
				concept - Prop]))
	;	true).

soft_crosscheck(A = B) :-
	exp_eval(A, A2),
	exp_eval(B, B2),
	(	vecs_are_almost_equal(A, B)
	->	true
	;	(	format(string(Err), '~q ≠ ~q', [A2, B2]),
			add_alert(warning, Err))).


/*
┏━┓┏━╸┏━┓┏━┓┏━┓╺┳╸
┣┳┛┣╸ ┣━┛┃ ┃┣┳┛ ┃
╹┗╸┗━╸╹  ┗━┛╹┗╸ ╹
*/
smsf_distribution_report :-
	


/*
╺┳╸╻ ╻┏━┓
 ┃ ┏╋┛┗━┓
 ╹ ╹ ╹┗━┛
*/
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

/*
-----------
*/

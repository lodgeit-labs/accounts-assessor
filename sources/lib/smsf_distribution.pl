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
	trim_string($>!doc_value(Item, smsf_distribution_ui:name), Unit_name_str),
	!extract_smsf_distribution4(Default_currency, Item, Unit_name_str, Txs).

extract_smsf_distribution4(_, _, "Dr/Cr", []) :- !.
extract_smsf_distribution4(_, _, "Total", []) :- !.

extract_smsf_distribution4(Default_currency, Item, Unit_name_str, Txs) :-
	!atom_string(Unit, Unit_name_str),
	% todo: we should be doing smsf_distribution_ui and smsf_distribution, using smsf_distribution_ui to get data, clean them up, then assert a new smsf_distribution object, rather than having both "name" and "unit_type" and having "entered_..." props.
	!check_duplicate_distribution_unit(Item, Unit),
	!doc_add_value(Item, smsf_distribution_ui:unit_type, Unit),
	!traded_units($>request_has_property(l:bank_s_transactions), Traded_Units),
	(	member(Unit, Traded_Units)
	->	true
	;	throw_string(['smsf distribution sheet: unknown unit: ', Unit])),
	!distribution_txs(Default_currency, Item, Unit, Txs),
	!assert_smsf_distribution_facts(Default_currency, Unit, Item).

check_duplicate_distribution_unit(Item, Unit) :-
	/*this check doesn't actually work, due to a bug in doc or dicts i guess*/
	(	doc(_, smsf_distribution_ui:unit_type, Unit)
	->	(
			doc(Item, excel:sheet_name, Sheet_name),
			throw_string(['duplicate unit types in ', Sheet_name])
		)
	;	true).


/*
┏━╸┏━┓┏━╸╺┳╸┏━┓
┣╸ ┣━┫┃   ┃ ┗━┓
╹  ╹ ╹┗━╸ ╹ ┗━┛
*/
assert_smsf_distribution_facts(Default_currency, Unit, Item) :-
	/* assert the facts we want to use */
	maplist(
		!optionally_assert_doc_value_as_unit_fact(Default_currency, Unit, Item),
		[	smsf_distribution_ui:net,
			smsf_distribution_ui:bank,
			% smsf_distribution_ui:accrual
			smsf_distribution_ui:franking_credit,
			smsf_distribution_ui:foreign_credit,
			smsf_distribution_ui:amit_decrease,
			smsf_distribution_ui:amit_increase,
			% smsf_distribution_ui:amit_net
			smsf_distribution_ui:non_primary_production_income,
			smsf_distribution_ui:franked_divis_distri_including_credits,
			smsf_distribution_ui:assessable_foreign_source_income,
			% smsf_distribution_ui:net_trust_distribution_income
			smsf_distribution_ui:capital_losses,
			smsf_distribution_ui:discount_capital_gains_net,
			smsf_distribution_ui:other_capital_gains,
			smsf_distribution_ui:one_third_capital_gain_discount_amount
			% smsf_distribution_ui:total_capital_gains_losses
		]
	),

	!computed_unit_fact(Unit,
		(smsf_distribution_ui:accrual)
		=
		(smsf_distribution_ui:net)
		-
		(smsf_distribution_ui:bank)),

	!check_entered_unit_fact_matches_computed(Default_currency, Unit, Item, smsf_distribution_ui:accrual, smsf_distribution_ui:entered_accrual),

	!computed_unit_fact(Unit,
		(smsf_distribution_ui:amit_net)
		=
		(smsf_distribution_ui:amit_decrease)
		+
		(smsf_distribution_ui:amit_increase)),

	!check_entered_unit_fact_matches_computed(Default_currency, Unit, Item, smsf_distribution_ui:amit_net, smsf_distribution_ui:entered_amit_net),

	!computed_unit_fact(Unit,
		(smsf_distribution_ui:distribution_income)
		=
		(smsf_distribution_ui:net)
		+
		(smsf_distribution_ui:franking_credit)
		+
		(smsf_distribution_ui:foreign_credit)
		+
		(smsf_distribution_ui:amit_net)),

	!check_entered_unit_fact_matches_computed(Default_currency, Unit, Item, smsf_distribution_ui:distribution_income, smsf_distribution_ui:entered_distribution_income),

	!computed_unit_fact(Unit,
		(smsf_distribution_ui:net_trust_distribution_income)
		=
		(smsf_distribution_ui:non_primary_production_income)
		+
		(smsf_distribution_ui:franked_divis_distri_including_credits)
		+
		(smsf_distribution_ui:assessable_foreign_source_income)),

	!check_entered_unit_fact_matches_computed(Default_currency, Unit, Item, smsf_distribution_ui:net_trust_distribution_income, smsf_distribution_ui:entered_net_trust_distribution_income),

	!computed_unit_fact(Unit,
		(smsf_distribution_ui:total_capital_gains_losses)
		=
		(smsf_distribution_ui:capital_losses)
		+
		(smsf_distribution_ui:discount_capital_gains_net)
		+
		(smsf_distribution_ui:other_capital_gains)
		+
		(smsf_distribution_ui:one_third_capital_gain_discount_amount)),

	!check_entered_unit_fact_matches_computed(Default_currency, Unit, Item, smsf_distribution_ui:total_capital_gains_losses, smsf_distribution_ui:entered_total_capital_gains_losses)

	.
	/*
	todo:
also soft-check totals
	*/


check_entered_unit_fact_matches_computed(Default_currency, Unit, Item, Prop, Entered) :-
	(	read_value_from_doc_string(Item, Prop, Default_currency, Entered_value)
	->	(
			!make_fact(Entered_value, aspects([
				concept - ($>rdf_global_id(Entered)),
				unit - Unit
			])),
			!entered_computed_soft_crosscheck(
				aspects([
					unit - Unit,
					concept - ($>rdf_global_id(Entered))])
				=
				aspects([
					unit - Unit,
					concept - ($>rdf_global_id(Prop))]))
		)
	;	true).

entered_computed_soft_crosscheck(A = B) :-
	!exp_eval(A, A2),
	!exp_eval(B, B2),
	(	vecs_are_almost_equal(A2, B2)
	->	true
	;	(
			!format(string(Err), 'entered: ~q ≠ computed: ~q', [A2, B2]),
			!add_alert(warning, Err))).


/*
┏━┓┏━╸┏━┓┏━┓┏━┓╺┳╸
┣┳┛┣╸ ┣━┛┃ ┃┣┳┛ ┃
╹┗╸┗━╸╹  ┗━┛╹┗╸ ╹
*/
smsf_distributions_report(Tbl_dict) :-
	Title_Text = "Distributions",

	Columns = [
		column{
			id:($>rdf_global_id(smsf_distribution_ui:unit_type)),
			title:"Unit Type",
			options:options{}},
		column{
			title:"Accounting Distribution as per P/L:",
			options:options{}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:net)),
			title:"Net Cash Distribution",
			options:options{implicit_report_currency:true}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:bank)),
			title:"Cash Distribution as per bank",
			options:options{implicit_report_currency:true}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:accrual)),
			title:"Resolved Accrual",
			options:options{implicit_report_currency:true}},
		column{
			title:"",
			options:options{}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:franking_credit)),
			title:"Add: Franking Credit",
			options:options{implicit_report_currency:true}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:foreign_credit)),
			title:"Add: Foreign Credit",
			options:options{implicit_report_currency:true}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:amit_decrease)),
			title:"AMIT cost base net amount - excess (decrease)",
			options:options{implicit_report_currency:true}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:amit_increase)),
			title:"AMIT cost base net amount - shortfall (increase)",
			options:options{implicit_report_currency:true}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:amit_net)),
			title:"Add: AMIT cost base net amount - net increase",
			options:options{implicit_report_currency:true}},
		column{
			title:"",
			options:options{}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:distribution_income)),
			title:"Distribution Income",
			options:options{implicit_report_currency:true}},
		column{
			title:"",
			options:options{}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:non_primary_production_income)),
			title:"Non-primary Production Income",
			options:options{implicit_report_currency:true}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:franked_divis_distri_including_credits)),
			title:"Franked Divis/Distri (Including Credits)",
			options:options{implicit_report_currency:true}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:assessable_foreign_source_income)),
			title:"Assessable Foreign Source Income (Inc Credits)",
			options:options{implicit_report_currency:true}},
		column{
			title:"",
			options:options{}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:net_trust_distribution_income)),
			title:"Net Trust distribution Income",
			options:options{implicit_report_currency:true}},
		column{
			title:"",
			options:options{}},
		column{
			title:"Capital Gains/Losses Calculations from Annual Tax Statements:",
			options:options{}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:capital_losses)),
			title:"Capital Losses",
			options:options{implicit_report_currency:true}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:discount_capital_gains_net)),
			title:"Discount Capital Gains (Net)",
			options:options{implicit_report_currency:true}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:other_capital_gains)),
			title:"Other Capital Gains",
			options:options{implicit_report_currency:true}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:one_third_capital_gain_discount_amount)),
			title:"1/3rd Capital Gain Discount Amount",
			options:options{implicit_report_currency:true}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:total_capital_gains_losses)),
			title:"Total Capital Gains/Losses",
			options:options{implicit_report_currency:true}}
		],
	maplist(col_concept_to_id, Columns, Columns2),
	maplist(!doc_item_to_tbl_row_dict(Columns2), $>smsf_distribution_items, Rows),
	findall(
		Concept,
		(
			member(Col, Columns2),
			_{concept:Concept} :< Col
		),
		Total_Keys),
	!table_totals(Rows, Total_Keys, Totals),
	flatten([Rows, Totals], Rows2),

	Tbl_dict = table{title:Title_Text, columns:Columns2, rows:Rows2},
	!table_html([highlight_totals - true], Tbl_dict, Table_Html),
	!page_with_table_html(Title_Text, Table_Html, Html),
	!add_report_page(0, Title_Text, Html, loc(file_name,'distributions.html'), distributions).

col_concept_to_id(X, Y) :-
	(	get_dict(concept, X, Concept)
	->	Y = X.put(id, Concept)
	;	Y = X).

doc_item_to_tbl_row_dict(Cols, Item, Row) :-
	findall(
		Row_kv,
		(
			member(Col, Cols),
			get_dict(concept, Col, _),
			!col_to_tbl_row_dict(Item, Col, Row_kv)
		),
		Row_kvs),
	doc_value(Item, smsf_distribution_ui:unit_type, Unit),
	rdf_global_id(smsf_distribution_ui:unit_type, Uri),
	append(Row_kvs, [Uri - Unit], Row_kvs2),
	!dict_pairs(Row, row, Row_kvs2).

col_to_tbl_row_dict(Item, Col, Id - Val) :-
	get_dict(id, Col, Id),
	doc_value(Item, smsf_distribution_ui:unit_type, Unit),
	evaluate_fact2(
		aspects(
			[
				unit - Unit,
				concept - Id
			]
		),
		Val
	).

smsf_distribution_items(Items) :-
	findall(Item, doc(Item, smsf_distribution_ui:unit_type, _), Items).


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
			a:'Distribution Received'/Unit/'Resolved Accrual',
			dir:crdr,
			b:'Distribution Receivable'/Unit,
			desc:"Distributions Accrual entry as per Annual tax statements"},
		dist{
			prop: smsf_distribution_ui:foreign_credit,
			a:'Distribution Received'/Unit/'Foreign Credit',
			dir:crdr,
			b:'Foreign And Other Tax Credits',
			desc:"Tax offset entry against distribution"},
		dist{
			prop: smsf_distribution_ui:franking_credit,
			a:'Distribution Received'/Unit/'Franking Credit',
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

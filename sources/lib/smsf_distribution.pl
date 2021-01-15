 extract_smsf_distribution(Txs) :-
  	!request_data(Rd),
 	(	doc(Rd, smsf:distribution, D)
 	->	!extract_smsf_distribution2(D, Txs)
 	;	Txs=[]).

 extract_smsf_distribution2(Distribution, Txs) :-
 	push_context($>format(string(<$), 'extract SMSF distribution from: ~w', [$>sheet_and_cell_string(Distribution)])),
	!doc_value(Distribution, smsf_distribution_ui:default_currency, Default_currency0),
	!atom_string(Default_currency, Default_currency0),
	!doc_list_items($>!doc_value(Distribution, smsf_distribution_ui:items), Items),
	!maplist(extract_smsf_distribution3(Default_currency), Items, Txs0),
 	!flatten(Txs0, Txs),
 	pop_context.

extract_smsf_distribution3(Default_currency, Item, Txs) :-
	push_context($>format(string(<$), 'extract SMSF distribution from: ~w', [$>sheet_and_cell_string(Item)])),
	trim_string($>!doc_value(Item, smsf_distribution_ui:name), Unit_name_str),
	!extract_smsf_distribution4(Default_currency, Item, Unit_name_str, Txs),
	pop_context.

extract_smsf_distribution4(_, _, "Dr/Cr", []) :- !.
extract_smsf_distribution4(_, _, "Total", []) :- !.

extract_smsf_distribution4(Default_currency, Item, Unit_name_str, Txs) :-
	!atom_string(Unit, Unit_name_str),
	% todo: we should be doing smsf_distribution_ui and smsf_distribution, using smsf_distribution_ui to get data, clean them up, then assert a new smsf_distribution object, rather than having both "name" and "unit_type" and having "entered_..." props.
	!check_duplicate_distribution_unit(Item, Unit),
	!doc_add_value(Item, smsf_distribution_ui:unit_type, Unit),

	!traded_units($>!rrrrrrresult_has_property(l:bank_s_transactions), Traded_Units),
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
	doc_add(smsf_distribution_ui:entered_discount_capital_gains_net, rdfs:label, "Discount Capital Gains (Net) (As entered in excel)"),
	doc_add(smsf_distribution_ui:entered_one_third_capital_gain_discount_amount, rdfs:label, "1/3rd Capital Gain Discount Amount (As entered in excel)"),
	doc_add(smsf_distribution_ui:entered_total_capital_gains_losses, rdfs:label, "Total Capital Gains/Losses (As entered in excel)"),


	/* assert the facts we want to use */
	maplist(
		!optionally_assert_doc_value_as_unit_fact(Default_currency, Unit, Item),
		[	smsf_distribution_ui:net_cash_distribution,
			smsf_distribution_ui:bank,
			% smsf_distribution_ui:accrual
			smsf_distribution_ui:franking_credit,
			smsf_distribution_ui:foreign_credit,
			smsf_distribution_ui:amit_decrease,
			smsf_distribution_ui:amit_increase,
			% smsf_distribution_ui:amit_net
			smsf_distribution_ui:afn_abn_withholding_tax,
			smsf_distribution_ui:non_primary_production_income,
			smsf_distribution_ui:franked_divis_distri_including_credits,
			smsf_distribution_ui:assessable_foreign_source_income,
			% smsf_distribution_ui:net_trust_distribution_income
			smsf_distribution_ui:capital_gains,
			smsf_distribution_ui:capital_losses,
			%smsf_distribution_ui:discount_capital_gains_net,
			smsf_distribution_ui:other_capital_gains
			%smsf_distribution_ui:one_third_capital_gain_discount_amount
			% smsf_distribution_ui:total_capital_gains_losses
		]
	),

	!computed_unit_fact(Unit,
		(smsf_distribution_ui:accrual)
		=
		(smsf_distribution_ui:net_cash_distribution)
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
		(smsf_distribution_ui:net_cash_distribution)
		+
		(smsf_distribution_ui:franking_credit)
		+
		(smsf_distribution_ui:foreign_credit)
		+
		(smsf_distribution_ui:amit_net)
		+
		(smsf_distribution_ui:afn_abn_withholding_tax)
	),

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
		(smsf_distribution_ui:discount_capital_gains_net)
		=
		(smsf_distribution_ui:capital_gains)
		*
		($>rat(2 rdiv 3))),

	!check_entered_unit_fact_matches_computed(Default_currency, Unit, Item, smsf_distribution_ui:discount_capital_gains_net, smsf_distribution_ui:entered_discount_capital_gains_net),

	!computed_unit_fact(Unit,
		(smsf_distribution_ui:one_third_capital_gain_discount_amount)
		=
		(smsf_distribution_ui:capital_gains)
		*
		($>rat(1 rdiv 3))),

	!check_entered_unit_fact_matches_computed(Default_currency, Unit, Item, smsf_distribution_ui:one_third_capital_gain_discount_amount, smsf_distribution_ui:entered_one_third_capital_gain_discount_amount),

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
			Err = html(div(
			[
				div("entered value does not match computed:"),
				div([
					"entered: ",
					$>!format_string('~q of:', [$>round_term(A2)]),
					$>!aspects_to_html(A)]),
				div([
					"computed: ",
					$>!format_string('~q of:', [$>round_term(B2)]),
					$>!aspects_to_html(B)])
			])),
			!add_alert(warning, Err))).

format_string(Format, Values, Str) :-
	format(string(Str), Format, Values).

aspects_to_html(aspects(Aspectses), ul(Items)) :-
	aspects_to_html2(Aspectses, Items).

aspects_to_html2([Ah|At], [Hh|Ht]) :-
	aspect_value_html(Ah, Value_html),
	Ah = Name - _,
	atomics_to_string([Name, ': ' , Value_html], Item),
	Hh = li([Item]),
	aspects_to_html2(At, Ht).

aspects_to_html2([], []).

aspect_value_html(concept - Value, Value_html) :-
	doc(Value, rdfs:label, Label),
	!,
	atomics_to_string([Label, " (",Value,")"], Value_html).

aspect_value_html(_ - Value, Value).


/*
┏━┓┏━╸┏━┓┏━┓┏━┓╺┳╸
┣┳┛┣╸ ┣━┛┃ ┃┣┳┛ ┃
╹┗╸┗━╸╹  ┗━┛╹┗╸ ╹
*/
smsf_distributions_report(Tbl_dict, Html) :-
	% todo: group{id:.., title:"..", members:Columns0..},
	Columns = [
		column{
			id:($>rdf_global_id(smsf_distribution_ui:unit_type)),
			title:"Unit Type",
			options:options{}},
		column{
			title:"Accounting Distribution as per P/L:",
			options:options{}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:net_cash_distribution)),
			title:"Net Cash Distribution",
			options:options{implicit_report_currency:true}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:bank)),
			title:"Cash Distribution as per bank",
			options:options{implicit_report_currency:true}},
		column{
			concept:($>rdf_global_id(smsf_distribution_ui:accrual)),
			title:"Resolved_Accrual",
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
	Title_Text = "Distributions:",
	Tbl_dict = table{title:Title_Text, columns:Columns2, rows:Rows2},
	Table_Html = table([border="1"], $>table_html([highlight_totals - true], Tbl_dict)),
	Html = [p([Title_Text]),Table_Html].


smsf_distributions_totals_report(Tbl_dict, Html) :-
	Rows0 = [
		[text('Total Current Year Capital Gains'),
			aspects([concept - ($>rdf_global_id(smsf_distribution_ui:total_capital_gains_losses))])]],
	Rows1 = [
		[text('Less: Current Year Capital Losses'),
			aspects([concept - ($>rdf_global_id(smsf_distribution_ui:capital_losses))])]],
	!rows_total(Rows0, Rows0_vec),
	!rows_total(Rows1, Rows1_vec),
	vec_sub(Rows0_vec,Rows1_vec,Vec0),
	!make_fact(Vec0,
		aspects([concept - ($>rdf_global_id(smsf_computation:taxable_net_capital_gains))])),
	Rows2 = [
		[text('Taxable Net Capital Gains'),
			aspects([concept - ($>rdf_global_id(smsf_computation:taxable_net_capital_gains))])
	]],
	split_vector_by_percent(Rows0_vec, ($>rat(100 rdiv 3)), Vec2, _),
	!make_fact(Vec2,
		aspects([concept - ($>rdf_global_id(smsf_computation:taxable_net_capital_gains_discount))])),
	vec_sub(Rows0_vec, Vec2, Vec3),
	!make_fact(Vec3,
		aspects([concept - ($>rdf_global_id(smsf_computation:taxable_net_capital_gains_discounted))])),
	Rows4 = [
		[text('Discount 1/3'),
			aspects([concept - ($>rdf_global_id(smsf_computation:taxable_net_capital_gains_discount))])],
		[text('Taxable Net Capital Gains After Discount'),
			aspects([concept - ($>rdf_global_id(smsf_computation:taxable_net_capital_gains_discounted))])]
	],
	Title_Text = "Totals:",
	Columns = [
		column{id:label, title:"Description", options:options{}},
		column{id:value, title:"Amount in $", options:options{implicit_report_currency:true}}],
	Tbl_dict = table{title:Title_Text, columns:Columns, rows:Row_dicts},
	append([Rows0, Rows1, Rows2, Rows4], Rows),
	assertion(ground(Rows)),
	!evaluate_fact_table(Rows, Rows_evaluated),
	assertion(ground(Rows_evaluated)),
	maplist(!label_value_row_to_dict, Rows_evaluated, Row_dicts),
	Table_Html = table([border="1"], $>table_html([highlight_totals - true], Tbl_dict)),
	Html = [p([Title_Text]),Table_Html].




smsf_distributions_reports(repoorts{distributions:Tbl1,totals:Tbl2}) :-
	!smsf_distributions_report(Tbl1, Html1),
	!smsf_distributions_totals_report(Tbl2, Html2),
	flatten([Html1, Html2], Body),
	Title_Text = "Distributions",
	!page_with_body(Title_Text, Body, Html),
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
	!result_has_property(l:end_date, End_Date),
	!maplist(!smsf_distribution_tx(Default_currency, End_Date, Item),
		[dist{
			prop: smsf_distribution_ui:accrual,
			a:'Distribution_Revenue'/Unit/'Resolved_Accrual',
			dir:crdr,
			b:'Distribution_Receivable'/Unit,
			desc:"Distributions Accrual entry as per Annual tax statements"},
		dist{
			prop: smsf_distribution_ui:foreign_credit,
			a:'Distribution_Revenue'/Unit/'Foreign_Credit',
			dir:crdr,
			b:'Foreign_and_Other_Tax_Credits',
			desc:"Tax offset entry against distribution"},
		dist{
			prop: smsf_distribution_ui:franking_credit,
			a:'Distribution_Revenue'/Unit/'Franking_Credit',
			dir:crdr,
			b:'Imputed_Credits',
			desc:"Tax offset entry against distribution"},
		dist{
			prop: smsf_distribution_ui:afn_abn_withholding_tax,
			a:'Distribution_Revenue'/Unit/'TFN/ABN_Withholding_Tax',
			dir:crdr,
			b:'TFN/ABN_Withholding_Tax',
			desc:"TFN/ABN_Withholding_Tax"}
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
				($>(make_transaction(St, Date, Desc, $>!abrlt(A), VectorA))),
				($>(make_transaction(St, Date, Desc, $>!abrlt(B), VectorB)))
			]
		)
	;	Txs = []).

/*
=============

 Goal is to automate the construct of the journal that allocates the components of net profit amongst the members based on the attributes of members i.e. age, tax rates, if they are using a pension account, etc.

Max 4 members.

Fund Profit is allocated among Members Equity

 possibility for members to have multiple accounts i.e. accumulation account, pension account/s.

 Segregated assets for members i.e. member a has a rental property & member b has 100 Google shares.

 While for a company, tax calculations are all about the company, for a superannuation fund, tax calcs are all about tax on the members.


*/

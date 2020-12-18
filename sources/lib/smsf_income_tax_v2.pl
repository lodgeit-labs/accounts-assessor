 smsf_income_tax_reports_v2(Reports) :-
	smsf_income_tax_reports_v2_2(Reports, stable_html),
	smsf_income_tax_reports_v2_2(Reports, rich_html).

 smsf_income_tax_reports_v2_2(reports{report:Tbl1,reconcilliation:Tbl2}, Mode) :-
	!smsf_income_tax_report_v2(Tbl1, Mode),
	!smsf_income_tax_reconcilliation(Tbl2, Mode),
	Title_Text = "Statement of Taxable Income",
	!page_with_body(Title_Text, [
		p(["Statement of Taxable Income:"]),
		table([border="1"], $>table_html([highlight_totals - true], Tbl1)),
		p(["Tax Workings Reconciliation:"]),
		table([border="1"], $>table_html([highlight_totals - true], Tbl2))
	], Html),
	$>atomic_list_concat(['statement_of_taxable_income_v2_',Mode], Key),
	!add_report_page(
		0,
		Title_Text,
		Html,
		loc(file_name, $>atomic_list_concat([Key,'.html'])),
		statement_of_taxable_income
	).

 smsf_income_tax_report_v2(Tbl_dict, Mode) :-
	% todo unify concept names with uris/namespaces

	Rules0 = [
		aspects([concept - (smsf/income_tax/'Taxable Trust Distributions (Inc Foreign Income & Credits)')])
		=
		sum(
			[
				aspects([concept - ($>rdf_global_id(smsf_distribution_ui:non_primary_production_income))]),
				aspects([concept - ($>rdf_global_id(smsf_distribution_ui:franked_divis_distri_including_credits))]),
				aspects([concept - ($>rdf_global_id(smsf_distribution_ui:assessable_foreign_source_income))])
			]
		)
	],

	Rows0 = [
		[text('Benefits Accrued as a Result of Operations before Income Tax'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Comprehensive_Income'])],
		[text('Less:'), text('')]
	],

	Rules1 = [
		sum($>rows_aspectses(Rows0), aspects([concept - smsf/income_tax/'Rows0'])),
		make_fact(aspects([concept - smsf/income_tax/'Rows0']))
	],

	Subtraction_rows = [
		[text('Change in Market Value'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Trading_Accounts'/'Capital_Gain/(Loss)'])],
		[text('Accounting Trust Distribution'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Distribution_Revenue'])],
		[text('Non Concessional Contribution'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Contribution_Received'])]
	],

%the semantics is that all relevant facts exist beforehand. So, each formula comes down to: filtering the db by a given 'aspects' list, and creating a static equation system off that.

	Rules2 = [
		aspects([concept - smsf/income_tax/'Total subtractions'])
		=
		sum($>rows_aspectses(Subtraction_rows)),

		% assert two facts with unbound vars for values. Hoist this.
		make_fact(aspects([concept - smsf/income_tax/'Total subtractions'])),
		make_fact(aspects([concept - smsf/income_tax/'subtotal0'])),

		aspects([concept - smsf/income_tax/'subtotal0'])
		=
		smsf_income_tax_intermediate__vec_0
		-
		aspects([concept - smsf/income_tax/'Total subtractions'])
	],

	Rows2 = [
		[text(''),
			text('')],
		[text('subtotal'),
			aspects([
				concept - smsf/income_tax/'subtotal0'])],
		[text(''),
			text('')],
		[text('Add:'),
			text('')]
	],

	Addition_rows = [
		[text('Taxable Trust Distributions'),
			aspects([
				concept - smsf/income_tax/'Taxable Trust Distributions (Inc Foreign Income & Credits)'])],
		[text('WriteBack of Deferred Tax'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Writeback_of_Deferred_Tax'])],
		[text('Taxable Capital Gain'),
			aspects([
				concept - ($>rdf_global_id(smsf_computation:taxable_net_capital_gains_discounted))])]],

	Rules3 = [
		aspects([concept - smsf/income_tax/'Additions_vec'])
		=
		sum($>rows_aspectses(Addition_rows),

		make_fact(aspects([concept - smsf/income_tax/'Additions_vec'])),

		aspects([concept - smsf/income_tax/'Rows0'])
		-
		aspects([concept - smsf/income_tax/'Total subtractions'])
		=
		aspects([concept - smsf/income_tax/'After_subtractions']),

		make_fact(aspects([concept - smsf/income_tax/'After_subtractions'])),

		aspects([concept - smsf/income_tax/'After_subtractions'])
		+
		aspects([concept - smsf/income_tax/'Additions_vec'])
		=
		aspects([concept - smsf/income_tax/'Taxable_income'])

		make_fact(aspects([concept - smsf/income_tax/'Taxable_income'])),
		make_fact(aspects([concept - smsf/income_tax/'Tax on Taxable Income @ 15%'])),

		aspects([concept - smsf/income_tax/'Tax on Taxable Income @ 15%'])
		=
		aspects([concept - smsf/income_tax/'Taxable_income'])
		*
		0.15
	],

	Rows3 = [
		[text(''),
			text('')],
		[text('Taxable income'),
			aspects([
				concept - smsf/income_tax/'Taxable_income'])],
		[text('Tax on Taxable Income @ 15%'),
			aspects([
				concept - smsf/income_tax/'Tax on Taxable Income @ 15%'])],
		[text(''),
			text('')]
	],

	Subtractions2_rows = [
		[text('Less:'),
			text('')],
		/*[text('PAYG Instalment'),
			aspects([
				concept - smsf/income_tax/'PAYG Instalment'])],
		[text('Franking Credits on dividends'),
			aspects([
				concept - smsf/income_tax/'Franking Credits on dividends'])],
		*/
		[text('Franking Credits'),
			aspects([concept - ($>rdf_global_id(smsf_distribution_ui:franking_credit))])],
		[text('Foreign Credit'),
			aspects([concept - ($>rdf_global_id(smsf_distribution_ui:foreign_credit))])]
	],

	Rules4 = [
		aspects([concept - smsf/income_tax/'Subtractions2_vec'])
		=
		sum($>rows_aspectses(Subtractions2_rows)),

		make_fact(aspects([concept - smsf/income_tax/'Income_Tax_Payable/(Refund)'])),

		aspects([concept - smsf/income_tax/'Income_Tax_Payable/(Refund)'])
		=
		aspects([concept - smsf/income_tax/'Tax on Taxable Income @ 15%'])
		-
		aspects([concept - smsf/income_tax/'Subtractions2_vec']),

		aspects([concept - smsf/income_tax/'Income_Tax_Payable/(Refund)'])
		+
		aspects([concept - smsf/income_tax/'ATO_Supervisory_Levy'])
		=
		aspects([concept - smsf/income_tax/'to pay']),

		make_fact(aspects([concept - smsf/income_tax/'to pay']))
	],

	Rows4 = [
		[text('Income_Tax_Payable/(Refund)'),
			aspects([concept - smsf/income_tax/'Income_Tax_Payable/(Refund)'])],
		[text('Add: Supervisory Levy'),
			aspects([concept - smsf/income_tax/'ATO_Supervisory_Levy'])],
		[text('Total Mount Due or Refundable:'),
			aspects([concept - smsf/income_tax/'to pay'])]
	],

	append([Rows0, Subtraction_rows, Rows2, Addition_rows, Rows3, Subtractions2_rows, Rows4], Rows),
	assertion(ground(Rows)),

	solve_rules($>append([Rules0, Rules1, Rules2, Rules3, Rules4]),

	!evaluate_fact_table(Rows, Rows_evaluated),
	assertion(ground(Rows_evaluated)),
	maplist(!label_value_row_to_dict, Rows_evaluated, Row_dicts),
	Columns = [
		column{id:label, title:"Description", options:options{}},
		column{id:value, title:"Amount in $", options:options{implicit_report_currency:true}}],
	Tbl_dict = table{title:"Statement of Taxable Income", columns:Columns, rows:Row_dicts}.


solve_rules(Rules) :-
	!hoist_rules(Rules, Hoisted, Rest),
	!solve_rules2(Hoisted),
	!solve_rules2(Rest).

solve_rules2(Rules) :-
	!maplist(solve_rule, Rules).

solve_rule(make_fact(Aspects)) :-
	!make_fact(_, Aspects).

solve_rule('='(X, Y)) :-
/*
1) all the rules have to be represented in RDF
2) we already got the inputs in doc



*/




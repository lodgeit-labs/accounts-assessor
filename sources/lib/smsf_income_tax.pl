
smsf_income_tax_stuff(Static_Data0, Txs) :-
	!request_data(Rd),
	(	doc(Rd, smsf:income_tax_info, Input)
	->	(
			!process_ato_supervisory_levy(Input, Ato_levy_txs),
			!update_static_data_with_transactions(Static_Data0,	Ato_levy_txs, Static_Data1),
			!balance_entries(Static_Data1, Sr0),
			Json_reports = _{before_smsf_income_tax:Sr0},
			!add_smsf_income_tax_report_facts(Json_reports),
			!'check Income Tax Expenses are zero',
			!smsf_income_tax_reports(_),
			!smsf_income_tax_txs(Input, Tax_expense_txs),
			!flatten([Ato_levy_txs,Tax_expense_txs], Txs)
		)
	;	true).

process_ato_supervisory_levy(Input, Txs) :-
	!doc_value(Input, excel:has_sheet_name, Sheet_name),
	!doc_new_uri(income_tax_st, St),
	!doc_add_value(St, transactions:description, Sheet_name, transactions),
	!request_has_property(l:report_currency, [Report_currency]),
	!doc_value(Input, smsf:ato_supervisory_levy, Levy_str),
	!value_from_string(Report_currency, Levy_str, Levy),
	!make_fact(
		Levy,
		aspects([concept - smsf/income_tax/'ATO Supervisory Levy']),
		_),
	vector_of_coords_vs_vector_of_values(kb:debit, Levy_vec, $>!evaluate_fact2(aspects([concept - smsf/income_tax/'ATO Supervisory Levy']))),
	!make_dr_cr_transactions(
		St,
		$>request_has_property(l:end_date),
		Sheet_name,
		$>abrlt('ATO Supervisory Levy'),
		$>abrlt('Income Tax Payable'),
		Levy_vec,
		Txs).

 add_smsf_income_tax_report_facts(Json_reports) :-
	Aspectses = [
		aspects([
			report - before_smsf_income_tax/pl/current,
			account_role - 'Audit Fees']),
		aspects([
			report - before_smsf_income_tax/pl/current,
			account_role - 'Accountancy Fees']),
		aspects([
			report - before_smsf_income_tax/pl/current,
			account_role - 'Interest Received - control']),
		aspects([
			report - before_smsf_income_tax/pl/current,
			account_role - 'Filling Fees']),
		aspects([
			report - before_smsf_income_tax/pl/current,
			account_role - 'Investment Expenses']),
		aspects([
			report - before_smsf_income_tax/pl/current,
			account_role - 'ATO Supervisory Levy']),
		aspects([
			report - before_smsf_income_tax/pl/current,
			account_role - 'Other Income']),
		aspects([
			report - before_smsf_income_tax/pl/current,
			account_role - 'ComprehensiveIncome']),
		aspects([
			report - before_smsf_income_tax/pl/current,
			account_role - 'Income Tax Expenses']),
		aspects([
			report - before_smsf_income_tax/pl/current,
			account_role - 'TradingAccounts'/'Capital GainLoss']),
		aspects([
			report - before_smsf_income_tax/pl/current,
			account_role - 'Contribution Received']),
		aspects([
			report - before_smsf_income_tax/pl/current,
			account_role - 'Distribution Received']),
		aspects([
			report - before_smsf_income_tax/pl/current,
			account_role - 'Writeback Of Deferred Tax'])
	],
	!maplist(add_fact_by_account_role(Json_reports), Aspectses),
	!add_summation_fact([
		aspects([concept - ($>rdf_global_id(smsf_distribution_ui:non_primary_production_income))]),
		aspects([concept - ($>rdf_global_id(smsf_distribution_ui:franked_divis_distri_including_credits))]),
		aspects([concept - ($>rdf_global_id(smsf_distribution_ui:assessable_foreign_source_income))])],
		aspects([concept - (smsf/income_tax/'Taxable Trust Distributions (Inc Foreign Income & Credits)')])).


smsf_income_tax_report(Tbl_dict) :-

	Rows0 = [
		[text('Benefits Accrued as a Result of Operations before Income Tax'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'ComprehensiveIncome'])],
		[text('Less:'), text('')]],

	!rows_total(Rows0, Rows0_vec),

	Subtraction_rows = [
		/*[text('Distributed Capital Gain'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - ''])],*/
		[text('Change in Market Value'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'TradingAccounts'/'Capital GainLoss'])],
		[text('Accounting Trust Distribution Income Received'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Distribution Received'])],
		[text('Non Concessional Contribution'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Contribution Received'])]/*,
		[text('Accounting Capital Gain'),
			text('not implemented')]*/],

	!rows_total(Subtraction_rows, Subtractions_vec),
	!make_fact(Subtractions_vec,
		aspects([
			concept - smsf/income_tax/'Total subtractions'])),
	!make_fact($>!vec_sub(Rows0_vec,Subtractions_vec),
		aspects([
			concept - smsf/income_tax/'subtotal0'])),

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
		[text('Taxable Trust Distributions (Inc Foreign Income & Credits)'),
			aspects([
				concept - smsf/income_tax/'Taxable Trust Distributions (Inc Foreign Income & Credits)'])],
		[text('WriteBack of Deferred Tax'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Writeback Of Deferred Tax'])],
		[text('Taxable Net Capital Gain'),
			aspects([
				concept - ($>rdf_global_id(smsf_computation:taxable_net_capital_gains_discounted))])]],

	!rows_total(Addition_rows, Additions_vec),
	!vec_sub(Rows0_vec, Subtractions_vec, After_subtractions),
	!vec_add(After_subtractions, Additions_vec, Taxable_income),
	!make_fact(Taxable_income, aspects([concept - smsf/income_tax/'Taxable income'])),
	!split_vector_by_percent(Taxable_income, 15, Tax, _),
	!make_fact(Tax, aspects([concept - smsf/income_tax/'Tax on Taxable Income @ 15%'])),

	Rows3 = [
		[text(''),
			text('')],
		[text('Taxable income'),
			aspects([
				concept - smsf/income_tax/'Taxable income'])],
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
		[text('Franking Credits on distributions'),
			aspects([concept - ($>rdf_global_id(smsf_distribution_ui:franking_credit))])],
		[text('Foreign Credit'),
			aspects([concept - ($>rdf_global_id(smsf_distribution_ui:foreign_credit))])]
	],

	!rows_total(Subtractions2_rows, Subtractions2_vec),
	!vec_sub(Tax, Subtractions2_vec, After_subtractions2),
	!make_fact(After_subtractions2, aspects([concept - smsf/income_tax/'Net Tax refundable/payable'])),
	!evaluate_fact2(aspects([concept - smsf/income_tax/'ATO Supervisory Levy']), Ato),
	!vec_add(After_subtractions2,Ato,To_pay),
	!make_fact(To_pay, aspects([concept - smsf/income_tax/'to pay'])),

	Rows4 = [
		[text('Net Tax refundable/payable'),
			aspects([concept - smsf/income_tax/'Net Tax refundable/payable'])],
		[text('Add: ATO Supervisory Levy'),
			aspects([concept - smsf/income_tax/'ATO Supervisory Levy'])],
		[text('to pay/refund:'),
			aspects([concept - smsf/income_tax/'to pay'])]
	],

	append([Rows0, Subtraction_rows, Rows2, Addition_rows, Rows3, Subtractions2_rows, Rows4], Rows),
	assertion(ground(Rows)),
	!evaluate_fact_table(Rows, Rows_evaluated),
	assertion(ground(Rows_evaluated)),
	maplist(!label_value_row_to_dict, Rows_evaluated, Row_dicts),
	Columns = [
		column{id:label, title:"Description", options:options{}},
		column{id:value, title:"Amount in $", options:options{implicit_report_currency:true}}],
	Tbl_dict = table{title:"Statement of Taxable Income", columns:Columns, rows:Row_dicts}.

smsf_income_tax_reconcilliation(Tbl_dict) :-
	Rows0 = [
		[text('Other Income'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Other Income'])],
		[text('Taxable Net Capital Gain'),
			aspects([concept - ($>rdf_global_id(smsf_computation:taxable_net_capital_gains_discounted))])],
		[text('Taxable Trust Distributions (Inc Foreign Income & Credits)'),
			aspects([
				concept - smsf/income_tax/'Taxable Trust Distributions (Inc Foreign Income & Credits)'])],
		[text('Interest Income'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Interest Received - control'])]],
	!rows_total(Rows0, Rows0_vec),
	!make_fact(Rows0_vec,
		aspects([
			concept - smsf/income_tax/reconcilliation/'Total Income'])),

	Rows0b = [
		[text('Total Income'),
			aspects([
				concept - smsf/income_tax/reconcilliation/'Total Income'])]],

	Rows1 = [
		[text('Expenses:'),text('')],
		[text('Filling Fees'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Filling Fees'])],
		[text('ATO Supervisory Levy'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'ATO Supervisory Levy'])],
		[text('Investment Expenses'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Investment Expenses'])],
		[text('Audit Fees'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Audit Fees'])],
		[text('Accountancy Fees'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Accountancy Fees'])]
	],
	!rows_total(Rows1, Rows1_vec),
	!make_fact(Rows1_vec,
		aspects([concept - smsf/income_tax/reconcilliation/'Total Expenses'])),

	Rows2 = [
		[text('Less: Total Expenses'),
			aspects([
				concept - smsf/income_tax/reconcilliation/'Total Expenses'])]],

	!exp_compute(
		aspects([concept - smsf/income_tax/reconcilliation/'Net Taxable Income'])
		=
		aspects([concept - smsf/income_tax/reconcilliation/'Total Income'])
		-
		aspects([concept - smsf/income_tax/reconcilliation/'Total Expenses'])),

	Rows4 = [
		[text('Net Taxable Income'),
			aspects([
				concept - smsf/income_tax/reconcilliation/'Net Taxable Income'])]],

	!exp_compute(
		aspects([concept - smsf/income_tax/reconcilliation/'Tax 15%'])
		=
		aspects([concept - smsf/income_tax/reconcilliation/'Net Taxable Income'])
		*
		(1 rdiv 15)),

	Rows6 = [
		[text('Tax 15%'),
			aspects([
				concept - smsf/income_tax/reconcilliation/'Tax 15%'])]],

	Rows8 = [
		[text('Less: Franking Credits on distributions'),
			aspects([concept - ($>rdf_global_id(smsf_distribution_ui:franking_credit))])],
		[text('Less: Foreign Credit'),
			aspects([concept - ($>rdf_global_id(smsf_distribution_ui:foreign_credit))])]],

	!rows_total(Rows8, Rows8_vec),

	!exp_compute(
		aspects([concept - smsf/income_tax/reconcilliation/'Net Tax refundable/payable'])
		=
		aspects([concept - smsf/income_tax/reconcilliation/'Tax 15%'])
		-
		Rows8_vec),

	!exp_compute(
		aspects([concept - smsf/income_tax/reconcilliation/'Total'])
		=
		aspects([concept - smsf/income_tax/reconcilliation/'Net Tax refundable/payable'])
		-
		aspects([
			report - before_smsf_income_tax/pl/current,
			account_role - 'ATO Supervisory Levy'])),

	Rows10 = [
		[text('Net Tax refundable/payable'),
			aspects([concept - smsf/income_tax/reconcilliation/'Net Tax refundable/payable'])],
		[text('Add: ATO Supervisory Levy'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'ATO Supervisory Levy'])],
		[text('Total'),
			aspects([concept - smsf/income_tax/reconcilliation/'Total'])]],

	append([Rows0, Rows0b, Rows1, Rows2, Rows4, Rows6, Rows8, Rows10], Rows),
	assertion(ground(Rows)),
	!evaluate_fact_table(Rows, Rows_evaluated),
	assertion(ground(Rows_evaluated)),
	maplist(!label_value_row_to_dict, Rows_evaluated, Row_dicts),
	Columns = [
		column{id:label, title:"Description", options:options{}},
		column{id:value, title:"Amount in $", options:options{implicit_report_currency:true}}],
	Tbl_dict = table{title:"Tax Workings Reconciliation", columns:Columns, rows:Row_dicts}.

smsf_income_tax_reports(reports{report:Tbl1,reconcilliation:Tbl2}) :-
	!smsf_income_tax_report(Tbl1),
	!smsf_income_tax_reconcilliation(Tbl2),
	Title_Text = "Statement of Taxable Income",
	!page_with_body(Title_Text, [
		p(["Statement of Taxable Income:"]),
		table([border="1"], $>table_html([highlight_totals - true], Tbl1)),
		p(["Tax Workings Reconciliation:"]),
		table([border="1"], $>table_html([], Tbl2))
	], Html),
	!add_report_page(
		0,
		Title_Text,
		Html,
		loc(file_name, 'statement_of_taxable_income.html'),
		statement_of_taxable_income
	).


 row_aspectses(Rows, Aspectses) :-
	!maplist(nth0(1), Rows, Aspectses0),
	findall(X,(X = aspects(_), member(X, Aspectses0)), Aspectses).

 rows_total(Rows, Rows_vec) :-
	evaluate_fact_table3($>row_aspectses(Rows), Tbl0),
	flatten(Tbl0, Tbl),
	findall(Value,member(with_metadata(Value, _), Tbl), Values0),
	flatten(Values0, Values),
	vec_reduce(Values, Rows_vec).


 smsf_income_tax_txs(Input, Txs0) :-
	!doc_value(Input, excel:has_sheet_name, Sheet_name),
	!doc_new_uri(income_tax_st, St),
	!doc_add_value(St, transactions:description, Sheet_name, transactions),
	vector_of_coords_vs_vector_of_values(kb:debit, Tax_vec, $>!evaluate_fact2(aspects([concept - smsf/income_tax/'Tax on Taxable Income @ 15%']))),
	!make_dr_cr_transactions(
		St,
		$>request_has_property(l:end_date),
		Sheet_name,
		$>abrlt('Income Tax Expenses'),
		$>abrlt('Income Tax Payable'),
		Tax_vec,
		Txs0).



'check Income Tax Expenses are zero' :-
	!evaluate_fact2(
		aspects([
			report - before_smsf_income_tax/pl/current,
			account_role - 'Income Tax Expenses']),
		Value),
	(	Value = []
	->	true
	;	throw_string('Income Tax Expenses PL account for current year should be zero, income tax will be computed')).







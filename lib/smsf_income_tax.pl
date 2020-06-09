
smsf_income_tax_stuff(Static_Data, Txs) :-
	!balance_entries(Static_Data, Sr),
	'check Income Tax Expenses are zero',
	!request_data(Rd),
	(	doc(Rd, smsf:income_tax_info, Input)
	->	(
			doc(Input, smsf:taxable_net_capital_gain, Cg),
			make_fact(
				[value(Cg)],
				aspects([concept - smsf/income_tax/'Taxable Net Capital Gain'])),
			doc(Input, smsf:ato_supervisory_levy, Levy),
			make_fact(
				[value(Levy)],
				aspects([concept - smsf/income_tax/'ATO Supervisory Levy'])),
			smsf_income_tax_report(Sr),
			smsf_income_tax_txs(Input, Txs)
		)
	;	true).


smsf_income_tax_report(Sr) :-

	Rows0 = [
		[text('Benefits Accrued as a Result of Operations before Income Tax'),
			aspects([
				report - pl/current,
				account_role - 'ComprehensiveIncome'])],
		[text('Less:'), text('')],

	rows_total(Rows0, Rows0_vec),

	Subtraction_rows = [
		[text('Distributed Capital Gain'),
			aspects([
				report - pl/current,
				account_role - 'Distribution Received'])],
		[text('Change in Market Value',
			aspects([
				report - pl/current,
				account_role - 'TradingAccounts/Capital GainLoss'])],
		[text('Accounting Trust Distribution Income Received',
			aspects([
				report - pl/current,
				account_role - 'Distribution Received'])],
		[text('Non Concessional Contribution',
			aspects([
				report - pl/current,
				account_role - 'Contribution Received'])],
		[text('Accounting Capital Gain'),
			text('not implemented')]],

	!rows_total(Subtraction_rows, Subtractions_vec),
	!make_fact(Subtractions_vec,
		aspects([
			concept - smsf/income_tax/'Total subtractions'])),

	Rows2 = [
		[text(''),
			text('')],
		[text('Total subtractions'),
			aspects([
				concept - smsf/income_tax/'Total subtractions'])],
		[text(''),
			text('')],
		[text('Add:'),
			text('')]
	],

	Addition_rows = [
		[text('Taxable Trust Distributions (Inc Foreign Income & Credits)'),
			aspects([
%todo:
				concept - smsf/income_tax/'Taxable Trust Distributions (Inc Foreign Income & Credits)'])],
		[text('WriteBack of Deferred Tax'),
			aspects([
				report - pl/current,
				account_role - 'Writeback Of Deferred Tax'])],
		[text('Taxable Net Capital Gain'),
			aspects([
				concept - smsf/income_tax/'Taxable Net Capital Gain'])]],

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
			text('')],

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
			aspects([concept - smsf/income_tax/'Franking Credits on distributions'])],
		[text('Foreign Credit'),
			aspects([concept - smsf/income_tax/'Foreign Credit'])]
	],

	!rows_total(Subtractions2_rows, Subtractions2_vec),
	!vec_sub(Tax, Subtractions2_vec, After_subtractions2),
	!make_fact(After_subtractions2, aspects([concept - smsf/income_tax/'after deductions'])),
	!evaluate_fact2(aspects([concept - smsf/income_tax/'ATO Supervisory Levy']), Ato),
	!vec_add(After_subtractions2,Ato,To_pay),
	!make_fact(To_pay, aspects([concept - smsf/income_tax/'to pay'])),

	Rows4 =
		[text('after deduction:'),
			aspects([concept - smsf/income_tax/'after deductions'])],
% todo input
		[text('Add: ATO Supervisory Levy'),
			aspects([concept - smsf/income_tax/'ATO Supervisory Levy'])],
		[text('to pay:'),
			aspects([concept - smsf/income_tax/'to pay'])],
	].


row_aspectses(Rows, Aspectses) :-
	!maplist(nth0(1), Rows, Aspectses),
	findall(X,(X = aspects(_), member(X, Aspectses)), Aspectses).

rows_total(Rows, Rows_vec) :-
	vec_sum($>evaluate_fact_table3($>row_aspectses(Rows)), Rows_vec).


smsf_income_tax_txs(Input, [Txs0, Txs1]) :-
	!doc_value(Input, excel:has_sheet_name, Sheet_name),
	!doc_new_uri(income_tax_st, St1),
	!doc_add_value(St1, transactions:description, Sheet_name, transactions),

	!make_dr_cr_transactions(
		St,
		$>request_has_property(l:end_date),
		Sheet_name,
		$>abrlt('Income Tax Expenses'),
		$>abrlt('Income Tax Payable'),
		[coord(
			$>request_has_property(l:report_currency),
			$>!evaluate_fact2(aspects([concept - smsf/income_tax/'Taxable Net Capital Gain'])))],
		Txs0),
	!make_dr_cr_transactions(
		St,
		$>request_has_property(l:end_date),
		Sheet_name,
		$>abrlt('ATO Supervisory Levy'),
		$>abrlt('Income Tax Payable'),
		[coord(
			$>request_has_property(l:report_currency),
			$>!evaluate_fact2(aspects([concept - smsf/income_tax/'ATO Supervisory Levy'])))],
		Txs1).

/*

a subset of these declarations could be translated into a proper xbrl taxonomy.

value_formula(equals(
	aspects([concept - smsf/income_tax/'Benefits Accrued as a Result of Operations before Income Tax']),
	aspects([
		report - pl/current,
		account_role - 'ComprehensiveIncome']))),

value_formula(x_is_sum_of_y(
	aspects([concept - smsf/income_tax/'total subtractions from PL']),
	[
		aspects([
			report - pl/current,
			account_role - 'Distribution Received'])
		aspects([
			report - pl/current,
			account_role - 'TradingAccounts/Capital GainLoss']),
		aspects([
			report - pl/current,
			account_role - 'Distribution Received']),
		aspects([
			report - pl/current,
			account_role - 'Contribution Received'])
	])).

/*
	evaluate expressions:
		aspecses with report and account_role aspects are taken from reports. They are forced into a single value. This allows us to do clp on it without pyco. Previously unseen facts are asserted.

*/

/*
% Sr - structured reports
evaluate_value_formulas(Sr) :-
	findall(F, value_formula(F), Fs),
	evaluate_value_formulas(Sr, Fs).

evaluate_value_formulas(Sr, [F|Rest]) :-
	evaluate_value_formula(Sr, F),
	evaluate_value_formulas(Sr, Rest).

evaluate_value_formula(Sr, equals(X, Y)) :-
	evaluate_value(X, Xv)



evaluate_value(X, Xv) :-




asserted:
	aspects([concept - smsf/income_tax/'total subtractions from PL']),
equals(X,aspects([
	concept - smsf/income_tax/'total subtractions from PL'
	memeber - xxx
]),



xbrl:
	fact:
		concept
		context:
			period
			dimension1
*/

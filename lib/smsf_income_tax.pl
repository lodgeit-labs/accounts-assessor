
smsf_income_tax_stuff(Static_Data, Txs) :-
	!add_smsf_income_tax_report_facts(Static_Data),
	'check Income Tax Expenses are zero',
	!request_data(Rd),
	(	doc(Rd, smsf:income_tax_info, Input)
	->	(
			!request_has_property(l:report_currency, [Report_currency]),
			!doc_value(Input, smsf:ato_supervisory_levy, Levy_str),
			!value_from_string(Report_currency, Levy_str, Levy),
			!make_fact(
				Levy,
				aspects([concept - smsf/income_tax/'ATO Supervisory Levy']),
				_),
			!smsf_income_tax_report(_),
			!smsf_income_tax_txs(Input, Txs0),
			!flatten(Txs0, Txs)
		)
	;	true).

add_smsf_income_tax_report_facts(Sd) :-
	!balance_entries(Sd, Sr0),
	Json_reports = _{before_smsf_income_tax:Sr0},
	Aspectses = [
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
			account_role - 'Writeback Of Deferred Tax'])
	],
	!maplist(add_fact_by_account_role(Json_reports), Aspectses).


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
				report - before_smsf_income_tax/pl/current,
				account_role - 'Writeback Of Deferred Tax'])],
		[text('Taxable Net Capital Gain'),
			aspects([
				concept - smsf/income_tax/franking_credit])]],

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
			aspects([concept - smsf/distribution/franking_credit])],
		[text('Foreign Credit'),
			aspects([concept - smsf/income_tax/foreign_credit])]
	],

	!rows_total(Subtractions2_rows, Subtractions2_vec),
	!vec_sub(Tax, Subtractions2_vec, After_subtractions2),
	!make_fact(After_subtractions2, aspects([concept - smsf/income_tax/'after deductions'])),
	!evaluate_fact2(aspects([concept - smsf/income_tax/'ATO Supervisory Levy']), Ato),
	!vec_add(After_subtractions2,Ato,To_pay),
	!make_fact(To_pay, aspects([concept - smsf/income_tax/'to pay'])),

	Rows4 = [
		[text('after deduction:'),
			aspects([concept - smsf/income_tax/'after deductions'])],
		[text('Add: ATO Supervisory Levy'),
			aspects([concept - smsf/income_tax/'ATO Supervisory Levy'])],
		[text('to pay:'),
			aspects([concept - smsf/income_tax/'to pay'])]
	],

	append([Rows0, Subtraction_rows, Rows2, Addition_rows, Rows3, Subtractions2_rows, Rows4], Rows),
	assertion(ground(Rows)),
	!evaluate_fact_table(Rows, Rows_evaluated),
	assertion(ground(Rows_evaluated)),
	maplist(!label_value_row_to_dict, Rows_evaluated, Rows_dict),
	Columns = [
		column{id:label, title:"Description", options:options{}},
		column{id:value, title:"Amount in $", options:options{implicit_report_currency:true}}],
	Title_Text = "Statement of Taxable Income",
	Tbl_dict = table{title:Title_Text, columns:Columns, rows:Rows_dict},
	!table_html([highlight_totals - true], Tbl_dict, Table_Html),
	!page_with_table_html(Title_Text, Table_Html, Html),
	!add_report_page(0, Title_Text, Html, loc(file_name,'statement_of_taxable_income.html'), statement_of_taxable_income).



 row_aspectses(Rows, Aspectses) :-
	!maplist(nth0(1), Rows, Aspectses0),
	findall(X,(X = aspects(_), member(X, Aspectses0)), Aspectses).

 rows_total(Rows, Rows_vec) :-
	evaluate_fact_table3($>row_aspectses(Rows), Tbl0),
	flatten(Tbl0, Tbl),
	findall(Value,member(with_metadata(Value, _), Tbl), Values0),
	flatten(Values0, Values),
	vec_reduce(Values, Rows_vec).


 smsf_income_tax_txs(Input, [Txs0, Txs1]) :-
	!doc_value(Input, excel:has_sheet_name, Sheet_name),
	!doc_new_uri(income_tax_st, St1),
	!doc_add_value(St1, transactions:description, Sheet_name, transactions),
	vector_of_coords_vs_vector_of_values(kb:debit, Tax_vec, $>!evaluate_fact2(aspects([concept - smsf/income_tax/'Tax on Taxable Income @ 15%']))),
	vector_of_coords_vs_vector_of_values(kb:debit, Levy_vec, $>!evaluate_fact2(aspects([concept - smsf/income_tax/'ATO Supervisory Levy']))),
	!make_dr_cr_transactions(
		St,
		$>request_has_property(l:end_date),
		Sheet_name,
		$>abrlt('Income Tax Expenses'),
		$>abrlt('Income Tax Payable'),
		Tax_vec,
		Txs0),
	!make_dr_cr_transactions(
		St,
		$>request_has_property(l:end_date),
		Sheet_name,
		$>abrlt('ATO Supervisory Levy'),
		$>abrlt('Income Tax Payable'),
		Levy_vec,
		Txs1).



'check Income Tax Expenses are zero' :-
	!evaluate_fact2(
		aspects([
			report - before_smsf_income_tax/pl/current,
			account_role - 'Income Tax Expenses']),
		Value),
	(	Value = []
	->	true
	;	throw_string('Income Tax Expenses should be zero, income tax will be computed')).







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
*/
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
/*

fact1:
concept - contribution
taxation - taxable
phase - preserved
fact2:
concept - contribution
taxation - tax-free
phase - preserved
effect - addition

get(concept - contribution):
		get exact match
	or
		get the set of subdividing aspects:
			taxation, phase, effect
		pick first aspect present in all asserted facts
		get([concept - contribution, taxation - _]):
			get the set of subdividing aspects:
				phase, effect
			pick first aspect present in all asserted facts
			get([concept - contribution, taxation - _]):
*/

/*

open problems:
	unreliability of clp - run a sicstus clp service?
	vectors for fact values - would require pyco to solve
*/


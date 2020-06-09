
smsf_income_tax_stuff(Static_Data) :-
	!balance_entries(Static_Data, Sr),
	'check Income Tax Expenses are zero',

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
%todo:
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





Total
Less:
PAYG Instalment
Franking Credits on dividends
Franking Credits on distributions
Foreign Credit

Add: ATO Supervisory Levy


	extract_aspectses(Subtraction_rows, Subtraction_aspectses),
	extract_aspectses(Addition_rows, Addition_aspectses),




row_aspectses(Rows, Aspectses) :-
	!maplist(nth0(1), Rows, Aspectses),
	findall(X,(X = aspects(_), member(X, Aspectses)), Aspectses).

rows_total(Rows, Rows_vec) :-
	vec_sum($>evaluate_fact_table3($>row_aspectses(Rows)), Rows_vec).





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

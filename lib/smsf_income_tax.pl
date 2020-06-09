
smsf_income_tax_stuff(Static_Data) :-
	!balance_entries(Static_Data, Sr),
	'check Income Tax Expenses are zero',

	Rows0 = [
		[text('Benefits Accrued as a Result of Operations before Income Tax'),
			aspects([
				report - pl/current,
				account_role - 'ComprehensiveIncome'])],
		[text('Less:'), text('')],

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
				concept - smsf/income_tax/'Taxable Trust Distributions (Inc Foreign Income & Credits)'])],
		[text('WriteBack of Deferred Tax'),
			aspects([
				report - pl/current,
				account_role - 'Writeback Of Deferred Tax'])],
		[text('Taxable Net Capital Gain'),
			aspects([
				concept - smsf/income_tax/'Taxable Net Capital Gain'])]],

	Rows3 = [
		[text(''),
			text('')],
		[text('Taxable income'),
			aspects([
				concept - smsf/income_tax/'Taxable income'])],

	],



Tax on Taxable Income @ 15%

Total
Less:
PAYG Instalment
Franking Credits on dividends
Franking Credits on distributions
Foreign Credit

Add: ATO Supervisory Levy


	extract_aspectses(Subtraction_rows, Subtraction_aspectses),
	extract_aspectses(Addition_rows, Addition_aspectses),


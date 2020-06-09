'check Income Tax Expenses are zero' :-
	evaluate_fact2(
		aspects([
			report - pl/current,
			account_role - 'Income Tax Expenses']),
		Value),
	(	Value = []
	->	true
	;	throw_string('Income Tax Expenses should be zero, income tax will be computed')).


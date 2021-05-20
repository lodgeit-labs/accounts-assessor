
 smsf_income_tax_reports_v2(reports{report:Tbl1,reconcilliation:Tbl2}) :-
	!smsf_income_tax_report_v2(Tbl1),
	!smsf_income_tax_reconcilliation_v2(Tbl2),
	Title_Text = "Statement of Taxable Income",

	!page_with_body(Title_Text, [
		p(["Statement of Taxable Income:"]),
		table([border="1"], $>table_html([highlight_totals - true], Tbl1)),
		p(["Tax Workings Reconciliation:"]),
		table([border="1"], $>table_html([highlight_totals - true], Tbl2))
	], Html),
	'statement_of_taxable_income_v2' = Key,
	!add_report_page(
		0,
		Title_Text,
		Html,
		loc(file_name, $>atomic_list_concat([Key,'.html'])),
		statement_of_taxable_income
	),
	true.

 smsf_income_tax_report_v2(Tbl_dict) :-
	% todo unify concept names with uris/namespaces

	Rows0 = [
		[text('Benefits Accrued as a Result of Operations before Income Tax'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Comprehensive_Income'])],
		[text('Less:'), text('')]
	],

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

	Rules1 = [
		aspects([concept - smsf/income_tax/'Rows0']) = sum($>row_aspectses(Rows0)),
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
		[text('Non Concessional Contribution *'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Contribution_Received'])]
	],

%the semantics is that all relevant facts exist beforehand. So, each formula comes down to: filtering the db by a given 'aspects' list, and creating a static equation system off that.

	Rules2 = [
		aspects([concept - smsf/income_tax/'Total subtractions'])
		=
		sum($>row_aspectses(Subtraction_rows)),

		% assert two facts with unbound vars for values. Hoist this.
		make_fact(aspects([concept - smsf/income_tax/'Total subtractions'])),
		make_fact(aspects([concept - smsf/income_tax/'subtotal0'])),

		aspects([concept - smsf/income_tax/'subtotal0'])
		=
		aspects([concept - smsf/income_tax/'Rows0'])
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
		sum($>row_aspectses(Addition_rows)),

		make_fact(aspects([concept - smsf/income_tax/'Additions_vec'])),

		aspects([concept - smsf/income_tax/'After_subtractions'])
		=
		aspects([concept - smsf/income_tax/'Rows0'])
		-
		aspects([concept - smsf/income_tax/'Total subtractions']),

		make_fact(aspects([concept - smsf/income_tax/'After_subtractions'])),

		aspects([concept - smsf/income_tax/'Taxable_income'])
		=
		aspects([concept - smsf/income_tax/'After_subtractions'])
		+
		aspects([concept - smsf/income_tax/'Additions_vec']),


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
		sum($>row_aspectses(Subtractions2_rows)),

		make_fact(aspects([concept - smsf/income_tax/'Income_Tax_Payable/(Refund)'])),

		aspects([concept - smsf/income_tax/'Income_Tax_Payable/(Refund)'])
		=
		aspects([concept - smsf/income_tax/'Tax on Taxable Income @ 15%'])
		-
		aspects([concept - smsf/income_tax/'Subtractions2_vec']),

		aspects([concept - smsf/income_tax/'to pay'])
		=
		aspects([concept - smsf/income_tax/'Income_Tax_Payable/(Refund)'])
		+
		aspects([concept - smsf/income_tax/'ATO_Supervisory_Levy']),

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

	solve_rules($>append([Rules0, Rules1, Rules2, Rules3, Rules4])),

	/* retrieve values from doc, and display */
	!v2_evaluate_fact_table(Rows, Rows_evaluated),
	assertion(ground(Rows_evaluated)),
	maplist(!label_value_row_to_dict, Rows_evaluated, Row_dicts),
	Columns = [
		column{id:label, title:"Description", options:options{}},
		column{id:value, title:"Amount in $", options:options{implicit_report_currency:true}}],
	Tbl_dict = table{title:"Statement of Taxable Income", columns:Columns, rows:Row_dicts}.





smsf_income_tax_reconcilliation_v2(Tbl_dict) :-
	Rows0 = [
		[text('Other_Income'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Other_Income'])],
		[text('Taxable Capital Gain'),
			aspects([concept - ($>rdf_global_id(smsf_computation:taxable_net_capital_gains_discounted))])],
		[text('Taxable Trust Distributions'),
			aspects([
				concept - smsf/income_tax/'Taxable Trust Distributions (Inc Foreign Income & Credits)'])],
		[text('Interest Income'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Interest_Received_-_Control'])]],
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
		[text('Filing_Fees'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Filing_Fees'])],
		[text('Supervisory Levy'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'ATO_Supervisory_Levy'])],
		[text('Investment_Expenses'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Investment_Expenses'])],
		[text('Audit_Fees'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Audit_Fees'])],
		[text('Accountancy_Fees'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'Accountancy_Fees'])]
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
		($>rat(15 rdiv 100))),

	Rows6 = [
		[text('Tax 15%'),
			aspects([
				concept - smsf/income_tax/reconcilliation/'Tax 15%'])]],

	Rows8 = [
		[text('Less: Franking Credits'),
			aspects([concept - ($>rdf_global_id(smsf_distribution_ui:franking_credit))])],
		[text('Less: Foreign Credit'),
			aspects([concept - ($>rdf_global_id(smsf_distribution_ui:foreign_credit))])]],

	!rows_total(Rows8, Rows8_vec),

	!exp_compute(
		aspects([concept - smsf/income_tax/reconcilliation/'Income_Tax_Payable/(Refund)'])
		=
		aspects([concept - smsf/income_tax/reconcilliation/'Tax 15%'])
		-
		Rows8_vec),

	!exp_compute(
		aspects([concept - smsf/income_tax/reconcilliation/'Total'])
		=
		aspects([concept - smsf/income_tax/reconcilliation/'Income_Tax_Payable/(Refund)'])
		+
		aspects([
			report - before_smsf_income_tax/pl/current,
			account_role - 'ATO_Supervisory_Levy'])),

	Rows10 = [
		[text('Income_Tax_Payable/(Refund)'),
			aspects([concept - smsf/income_tax/reconcilliation/'Income_Tax_Payable/(Refund)'])],
		[text('Add: Supervisory Levy'),
			aspects([
				report - before_smsf_income_tax/pl/current,
				account_role - 'ATO_Supervisory_Levy'])],
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




 solve_rules(Rules) :-
	!maplist(solve_rule, Rules).

 solve_rule(make_fact(_Aspects)) :-
	true.

 solve_rule('='(X, Y)) :-
	X = aspects(X_aspects),
	v2_exp_eval(Y, Y_val, Evaluation),
	make_fact(Y_val, X_aspects, Uri),
	doc_add(Uri, l:formula, Y),
	doc_add(Uri, l:evaluation, Evaluation).

 v2_exp_eval(X, X, Str) :-
	is_list(X), % a vector
 	term_string(X,Str).

 v2_exp_eval(X, X2, Uri) :-
	X = aspects(_),
	v2_evaluate_fact2(X, X2, Uri).

 v2_exp_eval(sum(Summants), Result, Uri) :-
	!maplist(v2_exp_eval,Summants,Results,Uris),
	!vec_sum(Results, Result),
	doc_new_(l:eval, Uri),
	doc_add(Uri, l:constituents, Results),
	maplist(doc_add(Uri, l:constituent), Uris),
	doc_add(Uri, l:result, Result).

 v2_exp_eval(B, B, Str) :-
	((rational(B),!);(number(B),!)),
	term_string(B,Str).

 v2_exp_eval(Op, C, Uri) :-
 	Op =.. [Binop, A, B],
	v2_exp_eval(A, A2, A2_uri),
	v2_exp_eval(B, B2, B2_uri),
	v2_binop(Binop, A2, B2, C),
	doc_new_(l:eval, Uri),
	doc_add(Uri, l:op1_value, A2),
	doc_add(Uri, l:op2_value, B2),
	doc_add(Uri, l:op1, A2_uri),
	doc_add(Uri, l:op2, B2_uri),
	doc_add(Uri, l:result, C).

 v2_binop('+', A2, B2, C) :-
	vec_add(A2, B2, C).

 v2_binop('-', A2, B2, C) :-
	vec_sub(A2, B2, C).

 v2_binop('*', A2, B2, C) :-
	((rational(B2),!);(number(B2),!)),
	{B3 = 2 * 100},
	split_vector_by_percent(A2, B3, C, _).




/*
1) all the rules have to be represented in RDF
2) we already got the inputs in doc
*/


/*
input: 2d matrix of aspect terms and other stuff.
replace aspect(..) terms with values
*/

 v2_evaluate_fact_table(Pres, Tbl) :-
	maplist(v2_evaluate_fact_table3, Pres, Tbl).

 v2_evaluate_fact_table3(Row_in, Row_out) :-
	maplist(v2_evaluate_fact, Row_in, Row_out).

 v2_evaluate_fact(X, X) :-
	X \= aspects(_).

 v2_evaluate_fact(In, with_metadata(Values,In,Uri)) :-
	v2_evaluate_fact2(In, Values, Uri).

 v2_evaluate_fact2(In,Sum, Uri) :-
	In = aspects(_),
	!facts_by_aspects(In, Facts),
	!v2_facts_vec_sum(Facts, Sum),
 	doc_new_(l:fact_evaluation, Uri),
 	doc_add(Uri, l:filter, In),
 	doc_add(Uri, l:facts, Facts),
 	doc_add(Uri, l:sum, Sum).

 v2_facts_vec_sum(Facts, Sum) :-
	!maplist(fact_vec, Facts, Vecs),
	!vec_sum(Vecs, Sum).




	/* keep in mind the semantics of facts. A fact with given aspects represents a real-world value. From this follows that: Every fact has a unique aspect set.*/

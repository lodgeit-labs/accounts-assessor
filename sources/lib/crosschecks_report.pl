%:- rdet(report/4).
%:- rdet(crosschecks_report/4).

crosschecks_report0(Sd, Json) :-
	% getting a list of _{check:Check, evaluation:Evaluation, status:Status} dicts:
	crosschecks_report(Sd, Json),
	maplist(crosscheck_output, Json.results, Html),
	add_report_page_with_body(9, 'crosschecks', Html, loc(file_name,'crosschecks.html'), 'crosschecks_html').

crosscheck_output(Result, Html) :-
	Html = p([span([Status]), ':', br([]), span([Check_Str]), ':', br([]), span([Evaluation_Str])]),
	round_term(Result, _{check:Check, evaluation:Evaluation, status:Status}),
	format(
		   string(Check_Str),
		   '~q ~w ~q',
		   [Check.a, Check.op, Check.b]),
	format(
		   string(Evaluation_Str),
		   '~q ~w ~q',
		   [Evaluation.a, Evaluation.op, Evaluation.b]),
	(	Status == 'ok'
	->	true
	;	add_alert('crosscheck failed', Evaluation_Str)).


crosschecks_report(Sd, Json) :-
	/* account balances at normal sides here */
	Crosschecks = [
		equality(
			account_balance(reports/bs/current, 'NetAssets'),
			account_balance(reports/bs/current, 'Equity')),
		equality(
			account_balance(reports/pl/current, 'TradingAccounts'/_/realized/withoutCurrencyMovement),
			report_value(reports/ir/current/totals/gains/rea/market_converted)),
		equality(
			account_balance(reports/pl/current, 'TradingAccounts'/_/realized/onlyCurrencyMovement),
			report_value(reports/ir/current/totals/gains/rea/forex)),
		equality(
			account_balance(reports/pl/current, 'TradingAccounts'/_/unrealized/withoutCurrencyMovement),
			report_value(reports/ir/current/totals/gains/unr/market_converted)),
		equality(
			account_balance(reports/pl/current, 'TradingAccounts'/_/unrealized/onlyCurrencyMovement),
			report_value(reports/ir/current/totals/gains/unr/forex)),
		equality(
			account_balance(reports/pl/current, 'TradingAccounts'/_),
			report_value(reports/ir/current/totals/gains/total)),
		equality(
			account_balance(reports/pl/current, 'TradingAccounts'/_/unrealized),
			report_value(reports/ir/current/totals/gains/unrealized_total)),
		equality(
			account_balance(reports/pl/current, 'TradingAccounts'/_/realized),
			report_value(reports/ir/current/totals/gains/realized_total)),
		equality(
			account_balance(reports/bs/current, 'FinancialInvestments'/_),
			report_value(reports/ir/current/totals/closing/total_cost_converted)),
		equality(
			account_balance(reports/bs/current, 'HistoricalEarnings'),
			account_balance(reports/pl/historical, 'ComprehensiveIncome'))
	],

	/*
	smsf:

	pl/current/Distribution Received = smsf_distribution_ui:distribution_income

	possibly:

	for crosschecking accrual, foreign and franking credits, i think it'll be best if i subcategorize each PL 'Distribution Received'/Unit into 'Distribution Received'/Unit/accrual etc, to make sure the txs posted there add up to the distribution sheet facts


	tax statement:
		Benefits Accrued as a Result of Operations before Income Tax:
			this one is taken directly from PL, it's the total PL before adding tax txs
		from PL:
			Change in Market Value
			Accounting Trust Distribution Income Received
			Non Concessional Contribution
		total from distributions facts:
			Taxable Trust Distributions (Inc Foreign Income & Credits)
		from PL:
			WriteBack of Deferred Tax
		Taxable Net Capital Gain
			aspects([concept - (smsf_distribution_ui:franking_credit
		Franking Credits on distributions
			aspects([concept - (smsf_distribution_ui:franking_credit
		Foreign Credit
			aspects([concept - (smsf_distribution_ui:foreign_credit
		Add: ATO Supervisory Levy
			input in tax sheet

	these are all references to various points in PL report or points displayed in distributions report, so it would have to be a low level coding error to introduce any mismatch there, but i'll put those crosschecks in anyway.

	Tax Workings Reconciliation:

		this mostly checks that our PL has incomes in exactly these categories and no other

		Other Income:
			PL
		Taxable Net Capital Gain
			aspects([concept - (smsf_distribution_ui:franking_credit
		Taxable Trust Distributions (Inc Foreign Income & Credits)
			computed in smsF_income_tax as smsf/income_tax/'Taxable Trust Distributions (Inc Foreign Income & Credits)'
		Interest Received
			PL Interest Received - control






		Net Tax refundable/payable
			=



	*/


	maplist(evaluate_equality(Sd), Crosschecks, Results),
	Json = _{
		 results: Results
	}.

evaluate_equality(Sd, equality(A, B), _{check:Check, evaluation:Evaluation, status:Status}) :-
	evaluate(Sd, A, A2),
	evaluate(Sd, B, B2),
	(
	 crosscheck_compare(A2, B2)
	->
	 (
	  Equality_Str = '=',
	  Status = 'ok'
	 )
	;
	 (
	  Equality_Str = '≠',
	  Status = 'error'
	 )
	),
	Check = check{op: Equality_Str, a:A, b:B},
	Evaluation = evaluation{op: Equality_Str, a:A2, b:B2}.
	

crosscheck_compare(A, B) :-
	vecs_are_almost_equal(A, B).
	

evaluate(Sd, Term, Value) :-
	(
	 evaluate2(Sd, Term, Value)
	->
	 true
	;
	 Value = evaluation_failed(Term, $>gensym(evaluation_failure))
	).

evaluate2(Sd, report_value(Key), Values_List) :-
	path_get_dict(Key, Sd, Values_List).
		
/* get vector of values in normal side, of an account, as provided by tree of entry(..) terms. Return [] if not found. */
evaluate2(Sd, account_balance(Report_Id, Role), Values_List) :-
	path_get_dict(Report_Id, Sd, Report),
	findall(
		Values_List,
		(
			accounts_report_entry_by_account_role_nothrow(Sd, Report, rl(Role), Entry),
			entry_normal_side_values(Sd, Entry, Values_List)
		),
		Values_List0
	),
	vec_sum(Values_List0, Values_List).

entry_normal_side_values(_Sd, Entry, Values_List) :-
	!report_entry_total_vec(Entry, Balance),
	!report_entry_gl_account(Entry, Account),
	!vector_of_coords_to_vector_of_values_by_account_normal_side(Account, Balance, Values_List).

accounts_report_entry_by_account_role_nothrow(_Sd, Report, Role, Entry) :-
	account_by_role(Role, Id),
	accounts_report_entry_by_account_id(Report, Id, Entry).

accounts_report_entry_by_account_id(Report, Id, Entry) :-
	find_thing_in_tree(
			   Report,
			   ([Entry1]>>(report_entry_gl_account(Entry1, Id))),
			   ([Entry2, Child]>>(report_entry_children(Entry2, Children), member(Child, Children))),
			   Entry).
	
	
	


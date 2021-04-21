
crosschecks_report0(Sd, Json) :-
	% getting a list of _{check:Check, evaluation:Evaluation, status:Status} dicts:
	%assertion(ground(Sd)),
	crosschecks_report(Sd, Json),
	next_nondet_report_fn('crosschecks.html', Fn),
	maplist(crosscheck_output(Fn), Json.results, Html),
	add_report_page_with_body__singleton(9, 'crosschecks', Html, loc(file_name,Fn), 'crosschecks_html').

crosscheck_output(Fn, Result, Html) :-
	round_term(Result, _{check:Check, evaluation:Evaluation, status:Status}),
	Html0 = [span([Status]), ':', br([]), span([Check_Str]), ':', br([]), span([Evaluation_Str])],
	(	Status == ok
	->	Html = p(Html0)
	;	Html = p([b(Html0)])),
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
	;	(
			add_alert('crosscheck failed', Evaluation_Str, Alert_uri),
			doc_add(
				Alert_uri,
				l:has_html,
				p(
					[
						h4(
							["crosscheck failed:"]
						),
						pre(
							[
								a(
									[href=Fn],
									[Evaluation_Str]
								)
							]
						)
					]
				)
			)
		)
	).


crosschecks_report(Sd, Json) :-
	/* account balances at normal sides here */
	Crosschecks0 = [
		equality(
			account_balance(reports/bs/current, rl('Net_Assets')),
			account_balance(reports/bs/current, rl('Equity'))),
		equality(
			account_balance(reports/pl/current, rl('Trading_Accounts'/_/realized/withoutCurrencyMovement)),
			report_value(reports/ir/current/totals/gains/rea/market_converted)),
		equality(
			account_balance(reports/pl/current, rl('Trading_Accounts'/_/realized/onlyCurrencyMovement)),
			report_value(reports/ir/current/totals/gains/rea/forex)),
		equality(
			account_balance(reports/pl/current, rl('Trading_Accounts'/_/unrealized/withoutCurrencyMovement)),
			report_value(reports/ir/current/totals/gains/unr/market_converted)),
		equality(
			account_balance(reports/pl/current, rl('Trading_Accounts'/_/unrealized/onlyCurrencyMovement)),
			report_value(reports/ir/current/totals/gains/unr/forex)),
		equality(
			account_balance(reports/pl/current, rl('Trading_Accounts'/_)),
			report_value(reports/ir/current/totals/gains/total)),
		equality(
			account_balance(reports/pl/current, rl('Trading_Accounts'/_/unrealized)),
			report_value(reports/ir/current/totals/gains/unrealized_total)),
		equality(
			account_balance(reports/pl/current, rl('Trading_Accounts'/_/realized)),
			report_value(reports/ir/current/totals/gains/realized_total)),
		equality(
			account_balance(reports/bs/current, rl('Financial_Investments'/_)),
			report_value(reports/ir/current/totals/closing/total_cost_converted)),
		equality(
			account_balance(reports/bs/current, rl('Current_Earnings')),
			account_balance(reports/pl/current, rl('Comprehensive_Income'))),
		equality(
			account_balance(reports/bs/current, rl('Historical_Earnings')),
			account_balance(reports/pl/historical, rl('Comprehensive_Income')))
	],

	Smsf_crosschecks = [
		equality(
			account_balance(reports/bs/current, rl('Equity_Aggregate_Historical')),
			[]
		),
		equality(
			account_balance(reports/bs/current, rl('Bank_Opening_Balances')),
			[]
		),
		equality(
			fact_value(aspects([concept - smsf/income_tax/'Net Tax refundable/payable'])),
			fact_value(aspects([concept - smsf/income_tax/reconcilliation/'Net Tax refundable/payable']))),
		equality(
			fact_value(aspects([concept - smsf/income_tax/reconcilliation/'Total'])),
			fact_value(aspects([concept - smsf/income_tax/'to pay']))),
		equality(
			account_balance(reports/pl/current, rl('Distribution_Revenue')),
			fact_value(aspects([concept - ($>rdf_global_id(smsf_distribution_ui:distribution_income))]))),
		equality(
			account_balance(reports/pl/current, rl('Distribution_Revenue'/Unit/'Resolved_Accrual')),
			fact_value(aspects([concept - ($>rdf_global_id(smsf_distribution_ui:accrual))]))),
		equality(
			account_balance(reports/pl/current, rl('Distribution_Revenue'/Unit/'Distribution_Cash')),
			fact_value(aspects([concept - ($>rdf_global_id(smsf_distribution_ui:bank))]))),
		equality(
			account_balance(reports/pl/current, rl('Distribution_Revenue'/Unit/'Foreign_Credit')),
			fact_value(aspects([concept - ($>rdf_global_id(smsf_distribution_ui:foreign_credit))]))),
		equality(
			account_balance(reports/pl/current, rl('Distribution_Revenue'/Unit/'Franking_Credit')),
			fact_value(aspects([concept - ($>rdf_global_id(smsf_distribution_ui:franking_credit))])))
	],
/*
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
		Foreign_Credit
			aspects([concept - (smsf_distribution_ui:foreign_credit
		Add: ATO_Supervisory_Levy
			input in tax sheet

	these are all references to various points in PL report or points displayed in distributions report, so it would have to be a low level coding error to introduce any mismatch there, but i'll put those crosschecks in anyway.

	Tax Workings Reconciliation:

		this mostly checks that our PL has incomes in exactly these categories and no other

		Other_Income:
			PL
		Taxable Net Capital Gain
			aspects([concept - (smsf_distribution_ui:franking_credit
		Taxable Trust Distributions (Inc Foreign Income & Credits)
			computed in smsF_income_tax as smsf/income_tax/'Taxable Trust Distributions (Inc Foreign Income & Credits)'
		Interest Received
			PL Interest_Received_-_Control
	*/

	(	account_by_role(rl(smsf_equity), _)
	->	append(Crosschecks0, Smsf_crosschecks, Crosschecks)
	;	Crosschecks = Crosschecks0),

	gtrace,
	
	maplist(evaluate_equality(Sd), Crosschecks, Results),
	Json = _{
		 results: Results
	}.

evaluate_equality(Sd, equality(A, B), crosscheck{check:Check, evaluation:Evaluation, status:Status}) :-
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
	(	evaluate2(Sd, Term, Value)
	->	true
	;	Value = evaluation_failed(Term, $>gensym(evaluation_failure))).

evaluate2(Sd, report_value(Key), Values_List) :-
	path_get_dict(Key, Sd, Values_List).
		
/* get vector of values in normal side, of an account, as provided by tree of entry(..) terms. Return [] if not found. */

evaluate2(Sd, account_balance(Report_Id, Acct), Values_List) :-
	/* get report out of static data */
	path_get_dict(Report_Id, Sd, Report),
	findall(
		Values_List,
		report_report_entry_normal_side_values_by_acct(Report, Acct, Values_List),
		Values_List0
	),
	vec_sum(Values_List0, Values_List).

evaluate2(_, fact_value(Aspects), Values_List) :-
	evaluate_fact2(Aspects, Values_List).

evaluate2(_, Vec, Vec) :-
	is_list(Vec).

report_report_entry_normal_side_values_by_acct(Report, Acct, Values_List) :-
	(	Acct = uri(Uri)
	->	true
	;	(
			assertion(Acct = rl(_)),
			account_by_role(Acct, Uri)
		)
	),
	report_entry_normal_side_values(Report, Uri, Values_List).


entry_normal_side_values(Entry, Values_List) :-
	!report_entry_total_vec(Entry, Balance),
	!report_entry_gl_account(Entry, Account),
	!vector_of_coords_to_vector_of_values_by_account_normal_side(Account, Balance, Values_List).

 accounts_report_entry_by_account_role_nothrow(_Sd, Report, Role, Entry) :-
	account_by_role(Role, Id),
	accounts_report_entry_by_account_uri(Report, Id, Entry).

 accounts_report_entry_by_account_uri(Report, Id, Entry) :-
	find_thing_in_tree(
			   Report,
			   ([Entry1]>>(report_entry_gl_account(Entry1, Id))),
			   ([Entry2, Child]>>(report_entry_children(Entry2, Children), member(Child, Children))),
			   Entry).
	
	

 check_account_is_zero(Sr, Specifier) :-
	Crosscheck = equality(
		Specifier,
		[]
	),
	quiet_crosscheck(Sr,Crosscheck).

 quiet_crosscheck(Sr,Crosscheck) :-
	evaluate_equality(_{reports:Sr}, Crosscheck, Result),
	crosscheck_output('./', Result, _).



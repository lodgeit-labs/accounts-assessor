%:- rdet(report/4).
%:- rdet(crosschecks_report/4).

crosschecks_report0(Sd, Json) :-
	crosschecks_report(Sd, Json),
	maplist(crosscheck_output, Json.results, Html),
	add_report_page_with_body('crosschecks', Html, loc(file_name,'crosschecks.html'), 'crosschecks_html').

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
	Crosschecks = [
		equality(
			account_balance(reports/pl/current, 'InvestmentIncomeRealized'/withoutCurrencyMovement), 
			report_value(reports/ir/current/totals/gains/rea/market_converted)),
		equality(
			account_balance(reports/pl/current, 'InvestmentIncomeRealized'/onlyCurrencyMovement), 
			report_value(reports/ir/current/totals/gains/rea/forex)),
		equality(
			account_balance(reports/pl/current, 'InvestmentIncomeUnrealized'/withoutCurrencyMovement), 
			report_value(reports/ir/current/totals/gains/unr/market_converted)),
		equality(
			account_balance(reports/pl/current, 'InvestmentIncomeUnrealized'/onlyCurrencyMovement), 
			report_value(reports/ir/current/totals/gains/unr/forex)),
		equality(
			account_balance(reports/pl/current, 'Accounts'/'InvestmentIncome'), 
			report_value(reports/ir/current/totals/gains/total)),
		equality(
			account_balance(reports/pl/current, 'InvestmentIncome'/'unrealized'), 
			report_value(reports/ir/current/totals/gains/unrealized_total)),
		equality(
			account_balance(reports/pl/current, 'InvestmentIncome'/'realized'), 
			report_value(reports/ir/current/totals/gains/realized_total)),
		equality(
			account_balance(reports/bs/current, 'Accounts'/'FinancialInvestments'),
			report_value(reports/ir/current/totals/closing/total_cost_converted)),
		equality(
			account_balance(reports/bs/current, 'Accounts'/'HistoricalEarnings'),
			account_balance(reports/pl/historical, 'Accounts'/'NetIncomeLoss')),
		equality(
			account_balance(reports/bs/current, 'Accounts'/'NetAssets'),
			account_balance(reports/bs/current, 'Accounts'/'Equity'))
	],
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
	(
		accounts_report_entry_by_account_role(Sd, Report, Role, Entry)
	->
		(
			entry_balance(Entry, Balance),
			entry_account_id(Entry, Account_Id),
			vector_of_coords_to_vector_of_values(Sd, Account_Id, Balance, Values_List)
		)
	;
		Values_List = []
	).

accounts_report_entry_by_account_role(Sd, Report, Role, Entry) :-
	account_by_role_nothrow(Sd.accounts, Role, Id),
	accounts_report_entry_by_account_id(Report, Id, Entry).

accounts_report_entry_by_account_id(Report, Id, Entry) :-
	find_thing_in_tree(
			   Report,
			   ([Entry1]>>(entry_account_id(Entry1, Id))),
			   ([Entry2, Child]>>(entry_child_sheet_entries(Entry2, Children), member(Child, Children))),
			   Entry).
	
	
	


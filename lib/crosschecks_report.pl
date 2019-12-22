:- module(_, []).
:- asserta(user:file_search_path(library, '../prolog_xbrl_public/xbrl/prolog')).
:- use_module('report_page').
:- use_module(library(xbrl/utils), [find_thing_in_tree/4]).
:- use_module('pacioli').
:- use_module('accounts').
:- use_module('ledger_report').
:- use_module(library(rdet)).
:- use_module(library(yall)).

:- rdet(report/4).
:- rdet(crosschecks_report/4).

report(Sd, Json) :-
	crosschecks_report(Sd, Json),
	findall(
		p([p([Check]), p([Evaluation]), p([Status])]),
		member([Check, Evaluation, Status], Json.results),
		Html),
	/*dict_json_text(Json, Json_Text),
	report_item('crosschecks.json', Json_Text, Json_Url),
	report_entry('crosschecks.json', Json_Url, crosschecks_json, Json_File_Info),*/
	report_page:report_page('crosschecks', Html, 'crosschecks.html', 'crosschecks_html').

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
		       
       equality(account_balance(reports/bs/current, 'Accounts'/'FinancialInvestments'), report_value(reports/ir/current/totals/closing/total_cost_converted)),

       equality(account_balance(reports/bs/current, 'Accounts'/'HistoricalEarnings'), account_balance(reports/pl/historical, 'Accounts'/'NetIncomeLoss')),
		       
		equality(account_balance(reports/bs/current, 'Accounts'/'NetAssets'), account_balance(reports/bs/current, 'Accounts'/'Equity'))
	],
	maplist(evaluate_equality(Sd), Crosschecks, Results, Errors),
	exclude(var, Errors, Errors2),
	Json = _{
		 results: Results,
		 errors: Errors2
	}.

evaluate_equality(Sd, E, [Check, Evaluation, Status], Error) :-
	E = equality(A, B),
	evaluate(Sd, A, A2),
	evaluate(Sd, B, B2),
	(
	 crosscheck_compare(A2, B2)
	->
	 (
	  Equality_Str = '=',
	  Status = 'ok',
	  Error = _
	 )
	;
	 (
	  Equality_Str = '≠',
	  Status = 'error',
	  Error = ('crosscheck':Check)
	 )
	),
	term_string(A, A_Str),
	term_string(B, B_Str),
	utils:dict_json_text(A2, A2_Str),
	utils:dict_json_text(B2, B2_Str),
	format(
	       string(Check),
	       '~w ~w ~w',
	       [A_Str, Equality_Str, B_Str]),
	format(
	       string(Evaluation),
	       '~w ~w ~w',
	       [A2_Str, Equality_Str, B2_Str]).
	

crosscheck_compare(A, B) :-
	pacioli:vecs_are_almost_equal(A, B).
	

evaluate(Sd, Term, Value) :-
	(
	 evaluate2(Sd, Term, Value)
	->
	 true
	;
	 Value = evaluation_failed(Term)
	).

evaluate2(Sd, report_value(Key), Values_List) :-
	utils:path_get_dict(Key, Sd, Values_List).
		
/* get vector of values in normal side, of an account, as provided by tree of entry(..) terms. Return [] if not found. */
evaluate2(Sd, account_balance(Report_Id, Role), Values_List) :-
	utils:path_get_dict(Report_Id, Sd, Report),
	(
		accounts_report_entry_by_account_role(Sd, Report, Role, Entry)
	->
		(
			ledger_report:entry_balance(Entry, Balance),
			ledger_report:entry_account_id(Entry, Account_Id),
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
			   [Entry1]>>(ledger_report:entry_account_id(Entry1, Id)),
			   [Entry2, Child]>>(entry_child_sheet_entries(Entry2, Children), member(Child, Children)),
			   Entry).
	
	
	


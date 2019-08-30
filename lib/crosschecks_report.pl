:- module(_, []).
:- use_module('report_page', [report_page/4]).
:- use_module('utils').
:- use_module('pacioli').
:- use_module('accounts').
:- use_module('ledger_report').
:- use_module(library(rdet)).

:- rdet(report/4).
:- rdet(crosschecks_report/4).

report(Sd, Reports, File_Info, Json) :-
	%gtrace,
	crosschecks_report(Sd.put(reports,Reports), Json),
	findall(
		p([p([Check]), p([Evaluation]), p([Status])]),
		member([Check, Evaluation, Status], Json.results),
		Html),
	report_page('crosschecks', Html, 'crosschecks.html', File_Info).

crosschecks_report(Sd, Json) :-
	Crosschecks = [
		       equality(account_balance(reports/pl/current, 'Accounts'/'InvestmentIncome'), report_value(reports/ir/current/totals/gains/total)),
		       equality(account_balance(reports/bs/current, 'Accounts'/'FinancialInvestments'), report_value(reports/ir/current/totals/closing/total_cost_converted)),
		       equality(account_balance(reports/bs/current, 'Accounts'/'HistoricalEarnings'), account_balance(reports/pl/historical, 'Accounts'/'NetIncomeLoss'))
		      ],
	maplist(evaluate_equality(Sd), Crosschecks, Results, Errors),
	Json = _{
		 results: Results,
		 errors: Errors
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
	  Error = ''
	 )
	;
	 (
	  Equality_Str = '≠',
	  Status = 'error',
	  Error = Check
	 )
	),
	term_string(A, A_Str),
	term_string(B, B_Str),
	term_string(A2, A2_Str),
	term_string(B2, B2_Str),
	format(
	       string(Check),
	       '~w = ~w',
	       [A_Str, B_Str]),
	format(
	       string(Evaluation),
	       '~w ~w ~w',
	       [A2_Str, Equality_Str, B2_Str]).
	

crosscheck_compare(A, B) :-
	vecs_are_almost_equal(A, B).
	
report_entry_by_role(Sd, Report, Role, Entry) :-
	
	account_by_role(Sd.accounts, Role, Id),
	find_thing_in_tree(
			   Report,
			   [Entry1]>>(ledger_report:entry_account_id(Entry1, Id)),
			   [Entry2, Child]>>(entry_child_sheet_entries(Entry2, Children), member(Child, Children)),
			   Entry).
		
:- meta_predicate find_thing_in_tree(?, 2, 3, ?).

find_thing_in_tree(Root, Matcher, _, Root) :-
	call(Matcher, Root).
						 
find_thing_in_tree([Entry|_], Matcher, Children_Yielder, Thing) :-
	find_thing_in_tree(Entry, Matcher, Children_Yielder, Thing).
	
find_thing_in_tree([_|Entries], Matcher, Children_Yielder, Thing) :-
	find_thing_in_tree(Entries, Matcher, Children_Yielder, Thing).	
				 
find_thing_in_tree(Root, Matcher, Children_Yielder, Thing) :-
	call(Children_Yielder, Root, Child),
	find_thing_in_tree(Child, Matcher, Children_Yielder, Thing).
	
						 

evaluate(Sd, Term, Value) :-
	(
	 evaluate2(Sd, Term, Value)
	->
	 true
	;
	 Value = evaluation_failed(Term)
	).

evaluate2(Sd, account_balance(Report_Id, Role), Values_List) :-
	path_get_dict(Report_Id, Sd, Report),
	report_entry_by_role(Sd, Report, Role, Entry),
	entry_balance(Entry, Balance),
	entry_account_id(Entry, Account_Id),
	vector_of_coords_to_vector_of_values(Sd, Account_Id, Balance, Values_List).

evaluate2(Sd, report_value(Key), Values_List) :-
	path_get_dict(Key, Sd, Values_List).


:- module(_, []).
:- use_module('report_page', [report_page/4]).
:- use_module('utils').

report(Pl, Bs, Ir, File_Info, Json) :-
	Json = _{errors: Errors},
	crosschecks_report(Pl, Bs, Ir, Results, Errors),
	findall(
		p([Result]),
		member(Result, Results),
		Html),
	report_page('crosschecks', Html, 'crosschecks.html', File_Info).
	

/*
Totals = _{
  gains: _{
     rea: _{market:, forex: },
     unr: _{market:, forex: },
    market: ,
    forex: ,
    total:
  },
  closing:_{total_converted: },
  }
*/
crosschecks_report(Pl, Bs, Ir, Results, Errors) :-
	dict_vars(Sd, [Pl, Bs, Ir]),
	Crosschecks = [
		       equality(account_balance(pl, 'Accounts'/'InvestmentIncome'), report_value(ir/totals/gains)),
		       equality(account_balance(bs, 'Accounts'/'FinancialInvestments'), report_value(ir/totals/closing/total_converted))],
	crosschecks_evaluate(Sd, Crosschecks, Results, Errors).
	

evaluate(Sd, X, Balance) :-
	X = account_balance(Report_Id, Role),
	report_entry_by_role(Sd.Report_Id, Role, Entry),
	entry_balance(Entry, Balance).

evaluate(Sd, X, Value) :-
	X = report_value(Key),
	path_get_dict(Key, Sd, Value).
	
evaluate_equality(Sd, E, Result, Error) :-
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
	  Equality_Str = 'does not equal',
	  Status = 'error',
	  Error = Result
	 )
	),
	term_string(A, A_Str),
	term_string(B, B_Str),
	format(
	       string(Result),
	       '~w ~w ~w ... ~w',
	       [A_Str, Equality_Str, B_Str, Status]).
	

crosscheck_compare(A, B) :-
	vecs_are_almost_equal(A, B).
	
	
/*crosschecks_html :-*/


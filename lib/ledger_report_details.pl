:- module(ledger_report_details, [
		investment_report_1/2,
		bs_report/3,
		pl_report/4,
		investment_report_2/4
		]).

:- use_module('system_accounts', [
		trading_account_ids/2]).

:- use_module('accounts', [
		account_child_parent/3,
		account_in_set/3,
		account_by_role/3,
		account_role_by_id/3,
		account_exists/2]).

:- use_module('ledger_report', [
		balance_by_account/9,
		balance_until_day/9,
		format_report_entries/11,
		pesseract_style_table_rows/4]).

:- use_module('pacioli', [
		vec_add/3,
	    number_vec/3,
	    value_subtract/3,
	    value_multiply/3,
		value_convert/3,
		vecs_are_almost_equal/2]).
		
:- use_module('utils', [
		get_indentation/2,
		pretty_term_string/2,
		throw_string/1]).

:- use_module('days', [
		format_date/2]).

:- use_module('files', [
		my_tmp_file_name/2,
		request_tmp_dir/1,
		server_public_url/1]).

:- use_module('exchange_rates', [
		exchange_rate/5,
		exchange_rate_throw/5]).

:- use_module('pricing', [
		outstanding_goods_count/2]).

:- use_module('exchange', [
		vec_change_bases/5]).
		
:- use_module(library(http/html_write)).
:- use_module(library(rdet)).


:- rdet(ir2_forex_gain/8).
:- rdet(ir2_market_gain/10).
:- rdet(clip_investments/4).
:- rdet(filter_investment_sales/3).
:- rdet(clip_investment/3).
:- rdet(optional_converted_value/3).
:- rdet(format_conversion/3).
:- rdet(optional_currency_conversion/5).
:- rdet(format_money_precise/3).
:- rdet(format_money/3).
:- rdet(format_money2/4).
:- rdet(ir2_row_to_html/3).
:- rdet(investment_report_2_unrealized/3).
:- rdet(investment_report_2_sale_lines/4).
:- rdet(investment_report_2_sales/3).
:- rdet(investment_report_2/4).
:- rdet(check_investment_totals/4).
:- rdet(units_traded_on_trading_account/3).
:- rdet(investment_report3_balance/7).
:- rdet(investment_report3_lines/6).
:- rdet(strip_unit_costs/2).
:- rdet(investment_report3/6).
:- rdet(investment_report2/3).
:- rdet(investment_report1/2).
:- rdet(investment_report_to_html/2).
:- rdet(investment_report_1/2).
:- rdet(bs_report/3).
:- rdet(pl_report/4).
:- rdet(report_page/4).
:- rdet(report_currency_atom/2).
:- rdet(report_section/3).
:- rdet(html_tokenlist_string/2).
:- rdet(report_file_path/3).



:- [investment_report_1].
:- [investment_report_2].
:- [tables].



html_tokenlist_string(Tokenlist, String) :-
	new_memory_file(X),
	open_memory_file(X, write, Mem_Stream),
	print_html(Mem_Stream, Tokenlist),
	close(Mem_Stream),
	memory_file_to_string(X, String).

report_section(File_Name, Html_Tokenlist, Url) :-
	report_file_path(File_Name, Url, File_Path),
	html_tokenlist_string(Html_Tokenlist, Html_String),
	write_file(File_Path, Html_String).

report_currency_atom(Report_Currency_List, Report_Currency_Atom) :-
	(
		Report_Currency_List = [Report_Currency]
	->
		atomic_list_concat(['(', Report_Currency, ')'], Report_Currency_Atom)
	;
		Report_Currency_Atom = ''
	).

report_page(Title_Text, Tbl, File_Name, Info) :-
	Body_Tags = [Title_Text, ':', br([]), table([border="1"], Tbl)],
	Page = page(
		title([Title_Text]),
		Body_Tags),
	phrase(Page, Page_Tokenlist),
	report_section(File_Name, Page_Tokenlist, Url),
	Info = Title_Text:url(Url).
	

pl_html(Static_Data, ProftAndLoss2, Filename_Suffix, Report) :-
	dict_vars(Static_Data, [Accounts, Start_Date, End_Date, Report_Currency]),
	format_date(Start_Date, Start_Date_Atom),
	format_date(End_Date, End_Date_Atom),
	report_currency_atom(Report_Currency, Report_Currency_Atom),
	atomic_list_concat(['profit&loss from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ', Report_Currency_Atom], Title_Text),
	pesseract_style_table_rows(Accounts, Report_Currency, ProftAndLoss2, Report_Table_Data),
	Header = tr([th('Account'), th(['Value', Report_Currency_Atom])]),
	flatten([Header, Report_Table_Data], Tbl),
	atomic_list_concat(['profit_and_loss', Filename_Suffix, '.html'], Filename),
	report_page(Title_Text, Tbl, Filename, Report).
		
bs_html(Static_Data, Balance_Sheet, Report) :-
	dict_vars(Static_Data, [Accounts, Start_Date, End_Date, Report_Currency]),
	format_date(Start_Date, Start_Date_Atom),
	format_date(End_Date, End_Date_Atom),
	report_currency_atom(Report_Currency, Report_Currency_Atom),
	atomic_list_concat(['balance sheet from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ', Report_Currency_Atom], Title_Text),
	pesseract_style_table_rows(Accounts, Report_Currency, Balance_Sheet, Report_Table_Data),
	Header = tr([th('Account'), th(['Balance', Report_Currency_Atom])]),
	flatten([Header, Report_Table_Data], Tbl),
	report_page(Title_Text, Tbl, 'balance_sheet.html', Report).
/*
Totals = _{
  gains: _{
    rea: _{market:, forex: },
    unr: _{market:, forex: },
    market: ,
    forex: ,
    gains:
  },
  closing:_{total_converted: },
  }
*/
crosschecks_report(Pl, Bs, Ir, Report) :-
	dict_vars(Sd, [Pl, Bs, Ir]),
	Crosschecks = [
		       equality(account_balance(pl, 'Accounts'/'InvestmentIncome'), report_value(ir, totals/gains)),
		       equality(account_balance(bs, 'Accounts'/'FinancialInvestments'), report_value(ir, totals/closing/total_converted))],
	crosschecks_evaluate(Sd, Crosschecks, Results),
	do we want to generate more json here? i guess yes.

evaluate(Sd, X, Balance) :-
	X = account_balance(Report, Role),
	report_entry_by_role(Sd, Report, Role, Entry),
	entry_balance(Entry, Balance).

evaluate(Sd, X, Value) :-
	X = report_value(Report, Key),
	path_get_dict(Key, Report, Value).
	
evaluate_equality(Sd, E, Result) :-
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
	format(
	       string(Result),
	       '~w ~w ~w ... ~w',
	       [A_Str, Equality_Str, B_Str, Status]).
	

crosscheck_compare(A, B) :-
	vecs_are_almost_equal(A, B)
	
	
crosschecks_html :-


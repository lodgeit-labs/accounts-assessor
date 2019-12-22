:- module(_, []).

:- use_module('ledger_report', []).
:- use_module(library(xbrl/utils)).
:- use_module('days', []).
:- use_module(library(xbrl/files), []).
:- use_module('report_page', []).
:- use_module('fact_output', []).

:- use_module(library(http/html_write)).
:- use_module(library(rdet)).

:- rdet(optional_converted_value/3).
:- rdet(format_conversion/3).
:- rdet(optional_currency_conversion/5).
:- rdet(format_money_precise/3).
:- rdet(format_money/3).
:- rdet(format_money2/4).


pl_page(Static_Data, ProftAndLoss2, Filename_Suffix) :-
	dict_vars(Static_Data, [Accounts, Start_Date, End_Date, Report_Currency]),
	days:format_date(Start_Date, Start_Date_Atom),
	days:format_date(End_Date, End_Date_Atom),
	utils:report_currency_atom(Report_Currency, Report_Currency_Atom),
	atomic_list_concat(['profit&loss from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ', Report_Currency_Atom], Title_Text),
	fact_output:pesseract_style_table_rows(Accounts, Report_Currency, ProftAndLoss2, Report_Table_Data),
	Header = tr([th('Account'), th(['Value', Report_Currency_Atom])]),
	flatten([Header, Report_Table_Data], Tbl),
	atomic_list_concat(['profit_and_loss', Filename_Suffix, '.html'], Filename),
	atomic_list_concat(['profit_and_loss', Filename_Suffix, '_html'], Id),
	report_page:report_page_with_table(Title_Text, Tbl, Filename, Id).
		
bs_page(Static_Data, Balance_Sheet) :-
	dict_vars(Static_Data, [Accounts, Start_Date, End_Date, Report_Currency]),
	days:format_date(Start_Date, Start_Date_Atom),
	days:format_date(End_Date, End_Date_Atom),
	utils:report_currency_atom(Report_Currency, Report_Currency_Atom),
	atomic_list_concat(['balance sheet from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ', Report_Currency_Atom], Title_Text),
	fact_output:pesseract_style_table_rows(Accounts, Report_Currency, Balance_Sheet, Report_Table_Data),
	Header = tr([th('Account'), th(['Balance', Report_Currency_Atom])]),
	flatten([Header, Report_Table_Data], Tbl),
	report_page:report_page_with_table(Title_Text, Tbl, 'balance_sheet.html', 'balance_sheet_html').


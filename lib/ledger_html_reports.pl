
% EFFECTS: write profit & loss report html
pl_page(
	Static_Data,
	ProftAndLoss2,
	Filename_Suffix
) :-
	dict_vars(Static_Data, [Start_Date, End_Date, Report_Currency]),
	format_date(Start_Date, Start_Date_Atom),
	format_date(End_Date, End_Date_Atom),
	report_currency_atom(Report_Currency, Report_Currency_Atom),
	atomic_list_concat(['profit&loss from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ', Report_Currency_Atom], Title_Text),
	pesseract_style_table_rows(Report_Currency, ProftAndLoss2, Report_Table_Data),
	Header = tr([th('Account'), th(['Value', Report_Currency_Atom])]),
	flatten([Header, Report_Table_Data], Tbl),
	atomic_list_concat(['profit_and_loss', Filename_Suffix, '.html'], Filename),
	atomic_list_concat(['profit_and_loss', Filename_Suffix, '_html'], Id),
	add_report_page_with_table(0, Title_Text, Tbl, loc(file_name,Filename), Id).
		
% EFFECTS: write balance_sheet.html
 bs_page(
	Static_Data,
	Balance_Sheet
) :-
	dict_vars(Static_Data, [Start_Date, End_Date, Report_Currency]),
	format_date(Start_Date, Start_Date_Atom),
	format_date(End_Date, End_Date_Atom),
	report_currency_atom(Report_Currency, Report_Currency_Atom),
	atomic_list_concat(['balance sheet from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ', Report_Currency_Atom], Title_Text),
	pesseract_style_table_rows(Report_Currency, Balance_Sheet, Report_Table_Data),
	Header = tr([th('Account'), th(['Balance', Report_Currency_Atom])]),
	flatten([Header, Report_Table_Data], Tbl),
	add_report_page_with_table(0,Title_Text, Tbl, loc(file_name,'balance_sheet.html'), 'balance_sheet_html').


% EFFECTS: write cashflow.html
cf_page(
	Static_Data,
	Entries
) :-
	dict_vars(Static_Data, [Start_Date, End_Date, Report_Currency]),
	format_date(Start_Date, Start_Date_Atom),
	format_date(End_Date, End_Date_Atom),
	report_currency_atom(Report_Currency, Report_Currency_Atom),
	atomic_list_concat(['cash flow from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ', Report_Currency_Atom], Title_Text),
	pesseract_style_table_rows(Report_Currency, Entries, Report_Table_Data),
	Header = tr([th('Account'), th([End_Date_Atom, ' ', Report_Currency_Atom])]),
	flatten([Header, Report_Table_Data], Tbl),
	add_report_page_with_table(0,Title_Text, Tbl, loc(file_name,'cashflow.html'), 'cashflow_html').
/*
write_entries_html(
	Static_Data,
	Entries,
	Title_Text,
	Filename,
	File_ID
) :-
	dict_vars(Static_Data, [Accounts, Start_Date, End_Date, Report_Currency]),
	format_date(Start_Date, Start_Date_Atom),
	format_date(End_Date, End_Date_Atom),
	report_currency_atom(Report_Currency, Report_Currency_Atom),
	pesseract_style_table_rows(Accounts, Report_Currency, Entries, Report_Table_Data),
	Header = tr([th('Account'), th([End_Date_Atom, ' ', Report_Currency_Atom])]),
	flatten([Header, Report_Table_Data], Tbl),
	add_report_page_with_table(Title_Text, Tbl, loc(file_name,Filename), File_ID).
*/

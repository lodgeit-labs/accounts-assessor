
% EFFECTS: write profit & loss report html
report_entry_tree_html_page(
	Report_prefix,
	Static_Data,
	Root_entry,
	Title,
	Filename
) :-
	dict_vars(Static_Data, [Start_Date, End_Date, Report_Currency]),
	format_date(Start_Date, Start_Date_Atom),
	format_date(End_Date, End_Date_Atom),
	report_currency_atom(Report_Currency, Report_Currency_Atom),
	atomic_list_concat([Title, ' from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ', Report_Currency_Atom], Title_Text),
	pesseract_style_table_rows(Report_Currency, Root_entry, Report_Table_Data),
	Header = tr([th('Account'), th(['Balance', Report_Currency_Atom])]),
	flatten([Header, Report_Table_Data], Tbl),
	Id = Filename,
	add_report_page_with_table(0, Title_Text, Tbl, loc(file_name,$>atomic_list_concat([Report_prefix, Filename])), Id).
		
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

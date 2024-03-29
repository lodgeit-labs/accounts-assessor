
 report_details_text(T) :-
	result_property(l:cost_or_market, C),
	(	at_cost
	->	Str = 'at cost'
	;	(
			assertion2(e(ic:market,C)),
			Str = 'at market'
		)
	),
	T = [' - ', Str].


% EFFECTS: write profit & loss report html
 report_entry_tree_html_page(
	Report_prefix,
	Dict,
	Title,
	Filename
) :-
	Dict = x{start_date: Start_date, end_date: End_date, exchange_date: _Exchange_date, entries:  Entries},

	!result_property(l:report_currency, Report_Currency),
	!format_date(Start_date, Start_Date_Atom),
	!format_date(End_date, End_Date_Atom),
	!report_currency_atom(Report_Currency, Report_Currency_Atom),
	!atomics_to_string($>flatten([Title, ' from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ', Report_Currency_Atom, $>report_details_text]), Title_Text),
	!pesseract_style_table_rows(Report_Currency, Entries, Report_Table_Data),
	Header = tr([th('Account'), th(['Balance', Report_Currency_Atom])]),
	flatten([Header, Report_Table_Data], Tbl),
	Id = Filename,
	!add_report_page_with_table(0, Title_Text, Tbl, loc(file_name,$>atomic_list_concat([Report_prefix, Filename])), Id).
		
% EFFECTS: write cashflow.html
cf_page(
	Static_Data,
	Entries
) :-
	dict_vars(Static_Data, [Start_Date, End_Date, Report_Currency]),
	format_date(Start_Date, Start_Date_Atom),
	format_date(End_Date, End_Date_Atom),
	report_currency_atom(Report_Currency, Report_Currency_Atom),
	atomics_to_string(['cash flow from ', Start_Date_Atom, ' to ', End_Date_Atom, ' ', Report_Currency_Atom], Title_Text),
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

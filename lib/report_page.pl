:- module(_, [report_page/4, report_item/3, report_entry/3]).

:- use_module('files').

:- use_module(library(http/html_write)).
:- use_module(library(rdet)).

:- rdet(report_page/4).
:- rdet(report_section/3).
:- rdet(html_tokenlist_string/2).
:- rdet(report_file_path/3).


html_tokenlist_string(Tokenlist, String) :-
	new_memory_file(X),
	open_memory_file(X, write, Mem_Stream),
	print_html(Mem_Stream, Tokenlist),
	close(Mem_Stream),
	memory_file_to_string(X, String).

/*TODO rename*/
report_item(File_Name, Text, Url) :-
	files:report_file_path(File_Name, Url, File_Path),
	write_file(File_Path, Text).

report_section(File_Name, Html_Tokenlist, Url) :-
	html_tokenlist_string(Html_Tokenlist, Html_String),
	report_item(File_Name, Html_String, Url).

report_page(Title_Text, Tbl, File_Name, Info) :-
	Body_Tags = [Title_Text, ':', br([]), table([border="1"], Tbl)],
	Page = page(
		title([Title_Text]),
		Body_Tags),
	phrase(Page, Page_Tokenlist),
	report_section(File_Name, Page_Tokenlist, Url),
	report_entry(Title_Text, Url, Info).
	
report_entry(Title_Text, Url, Info) :-
	Info = Title_Text:url(Url).


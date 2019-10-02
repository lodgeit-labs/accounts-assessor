:- module(_, [report_page_with_table/5, report_page/5, report_item/3, report_entry/4]).

:- use_module('files').

:- use_module(library(http/html_write)).
:- use_module(library(rdet)).

:- rdet(report_page/4).
:- rdet(report_page_with_table/4).
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

report_page_with_table(Title_Text, Tbl, File_Name, Id, Info) :-
%report_page_with_table(Title_Text, Tbl, File_Name, Info) :-
	report_page(Title_Text, [Title_Text, ':', br([]), table([border="1"], Tbl)], File_Name, Id, Info).
	%report_page(Title_Text, [Title_Text, ':', br([]), table([border="1"], Tbl)], File_Name, Info).
	
report_page(Title_Text, Body_Tags, File_Name, Id, Info) :-
%report_page(Title_Text, Body_Tags, File_Name, Info) :-
	Page = page(
		title([Title_Text]),
		link([
			type('text/css'),
			rel('stylesheet'),
			href('../../static/report_stylesheet.css')
		]),
		Body_Tags),
	phrase(Page, Page_Tokenlist),
	report_section(File_Name, Page_Tokenlist, Url),
	report_entry(Title_Text, Url, Id, Info).
	%report_entry(Title_Text, Url, Info).
	
report_entry(Title_Text, Url, Id, _{key:Title_Text, val:_{url:Url}, id:Id}).
%report_entry(Title_Text, Url, Info) :-
	%Info = Title_Text:url(Url).


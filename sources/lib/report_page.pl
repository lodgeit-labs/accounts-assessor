:- use_module(library(http/html_write)).

/* write file and return Url */
 write_report_file(File_Name, Text, Url, Final_fn) :-
	report_file_path(File_Name, Url, File_Path, Final_fn),
	write_file(File_Path, Text).
 write_report_file__singleton(File_Name, Text, Url) :-
	report_file_path__singleton(File_Name, Url, File_Path),
	write_file(File_Path, Text).

 make_json_report(Dict, Fn) :-
	make_json_report(Dict, Fn, _).

 make_json_report(Dict, Fn, Final_fn) :-
	catch_with_backtrace(
		make_json_report2(Dict, Fn, Final_fn),
		E,
		add_alert('error', E)
	).

 make_json_report2(Dict, Fn, Final_fn) :-
	dict_json_text(Dict, Json_Text),
	Title = Fn,
	atomic_list_concat([Fn, '_json'], Key), 
	atomic_list_concat([Fn, '.json'], Fn2_Value),
	Fn2 = loc(file_name, Fn2_Value),
	write_report_file(Fn2, Json_Text, Report_File_URL, Final_fn),
	add_report_file(-10, Key, Title, Report_File_URL).


 make_same_named_symlinked_json_report(Json, Name) :-
/* make a json report (with Name + an increasing id), and make a symlink to the last version */
	make_symlinked_json_report(Json, Name, Name).

 make_symlinked_json_report(Json, Base, Symlink_name) :-
	!make_json_report(Json,	Base, Final_fn),
	% get the symlink path
	report_file_path__singleton(
		loc(file_name, Symlink_name),
		_,
		loc(absolute_path, Link)
	),
	% make the symlink
	!shell4(
		[
			'ln', '-s', '-n', '-f',
			Final_fn,
			Link
		],
		0
	).


 html_tokenlist_string(Tokenlist, String) :-
	setup_call_cleanup(
		new_memory_file(X),
		(
			open_memory_file(X, write, Mem_Stream),
			print_html(Mem_Stream, Tokenlist),
			close(Mem_Stream),
			memory_file_to_string(X, String)
		),
		free_memory_file(X)).

 page_with_body(Title_Text, Body_Tags, Html) :-
 	atomics_to_string([Title_Text], Title_atom),
	Html = page(
		[
			title(Title_atom),
			link([
				type('text/css'),
				rel('stylesheet'),
				href('/static/report_stylesheet.css')
			])
		],
		Body_Tags).

 error_page_html(Msg, Html) :-
	term_string(Msg, Msg2),
	page_with_body('error', [Msg2], Html).

  page_with_table_html(Title, Tbl, Html) :-
	page_with_body(Title, [Title, ':', br([]), table([border="1"], Tbl)], Html).

 add_report_page_with_body__singleton(Priority, Title, Body_Html, File_Name, Key) :-
	page_with_body(Title, Body_Html, Page_Html),
	add_report_page__singleton(Priority, Title, Page_Html, File_Name, Key).
 add_report_page_with_body(Priority, Title, Body_Html, File_Name, Key) :-
	page_with_body(Title, Body_Html, Page_Html),
	add_report_page(Priority, Title, Page_Html, File_Name, Key).

% todo refactor, pass loc(file_name, singleton('xxx')) ?
 add_report_page__singleton(Priority, Title, Page_Html, File_Name, Key) :-
	phrase(Page_Html, Tokenlist),
	html_tokenlist_string(Tokenlist, String),
	write_report_file__singleton(File_Name, String, Url),
	add_report_file(Priority, Key, Title, Url).
 add_report_page(Priority, Title, Page_Html, File_Name, Key) :-
	phrase(Page_Html, Tokenlist),
	html_tokenlist_string(Tokenlist, String),
	write_report_file(File_Name, String, Url, _),
	add_report_file(Priority, Key, Title, Url).


 add_report_page_with_table(Priority, Title, Tbl, File_Name, Key) :-
	page_with_table_html(Title, Tbl, Html),
	add_report_page(Priority, Title, Html, File_Name, Key).

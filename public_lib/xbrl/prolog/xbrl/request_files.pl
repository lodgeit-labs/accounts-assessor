:- thread_local user:my_request_tmp_dir/1.
:- thread_local asserted_server_public_url/1.

:- initialization(generate_unique_tmp_directory_prefix).

/*
  assert a base for tmp directory names that should be unique for each run of the server (current time)
  det.
*/
generate_unique_tmp_directory_prefix :-
   get_time(Current_Time),
   %format("generate_unique_tmp_directory_prefix:get_time(~w)~n", [Current_Time]),
   atomic_list_concat([Current_Time, '.'], Base),
   %format("generate_unique_tmp_directory_prefix:atomic_list_concat(~w, ~w)~n", [[Current_Time, '.'], Base]),
   asserta(session_tmp_directory_base(tmp_directory_name_prefix(Base))),
   %format("generate_unique_tmp_directory_prefix:asserta(session_tmp_directory_base(tmp_directory_name_prefix(~w)))~n",[Base]).
   true.

/*
  create a new unique directory under my_tmp
*/
bump_tmp_directory_id :-
	generate_unique_tmp_directory_name(Dir_Name),
	create_tmp_directory(Dir_Name).

generate_unique_tmp_directory_name(Name) :-
	Name = loc(tmp_directory_name, Dir),
	session_tmp_directory_base(tmp_directory_name_prefix(Base)),
	gensym(Base, Dir),
	set_unique_tmp_directory_name(Name).

set_unique_tmp_directory_name(Name) :-
	retractall(my_request_tmp_dir(_)),
	asserta(my_request_tmp_dir(Name)).

create_tmp_directory(Dir_Name) :-
	Dir_Name = loc(tmp_directory_name, Dir_Name_Value),
	resolve_specifier(loc(specifier, my_tmp(Dir_Name_Value)), Path),
	%Path = loc(absolute_path, Path_Value),
	ensure_directory_exists(Path),
	symlink_last_to_current(Path).

symlink_last_to_current(loc(absolute_path, Path)) :-
	resolve_specifier(loc(specifier, my_tmp('last')), loc(_, Last)),
	shell4(['rm', '-f', Last], _),
	shell4(['ln', '-s', Path, Last], _).

/*
  to be used instead of absolute_file_name for request-specific tmp files
*/
absolute_tmp_path(loc(file_name, File_Name), Absolute_File_Name) :-
	my_tmp_file_path(loc(file_name, File_Name), loc(path_relative_to_tmp, File_Path_Relative_To_Tmp)),
	resolve_specifier(loc(specifier,my_tmp(File_Path_Relative_To_Tmp)), Absolute_File_Name).

/* this is for the case that an empty file field is coming from the upload form */
/* not needed anymore */
/*http_post_save_file(_, ignored_empty_file_entry, Options) :-
	option(filename(User_File_Path), Options),
	User_File_Path = '',
	!.

http_post_save_file(Stream, file(loc(absolute_path, Tmp_File_Path)), Options) :-
	option(filename(User_File_Path_Value), Options),
	User_File_Path = loc(unknown, User_File_Path_Value),
	% (for Internet Explorer/Microsoft Edge)
	tmp_file_path_from_something(User_File_Path, loc(absolute_path, Tmp_File_Path)),
	setup_call_cleanup(open(Tmp_File_Path, write, Out), copy_stream_data(Stream, Out), close(Out)).
*/
make_zip :-
	resolve_specifier(loc(specifier, my_tmp('')), loc(absolute_path, Tmp)),
	my_request_tmp_dir(loc(tmp_directory_name,Tmp_Dir)),
	resolve_specifier(loc(specifier, my_tmp(Tmp_Dir)), loc(absolute_path, Tmp_Dir_Path)),
	atomic_list_concat([Tmp_Dir_Path, '.zip'], Zip_Fn),
	atomic_list_concat([Tmp_Dir_Path, '/'], Tmp_Dir_With_Slash),
	archive_create(Zip_Fn, [Tmp_Dir_With_Slash], [format(zip), directory(Tmp)]),
	shell4(['mv', Zip_Fn, Tmp_Dir_With_Slash], _).

copy_request_files_to_tmp(Paths, Names) :-
	maplist(copy_request_file_to_tmp, Paths, Names).

copy_request_file_to_tmp(Path, Name) :-
	exclude_file_location_from_filename(Path, Name),
	absolute_tmp_path(Name, Tmp_Request_File_Path),
	copy_file_loc(Path, Tmp_Request_File_Path).

replace_request_with_response(Atom, Response) :-
	atom_string(Atom, String),
	(
		(
			re_replace('request', 'response', String, Response);
			re_replace('Request', 'Response', String, Response);
			re_replace('REQUEST', 'RESPONSE', String, Response)
		),
		String \= Response
	).

write_tmp_file(Name, Text) :-
	absolute_tmp_path(Name, Path),
	write_file(Path, Text).

write_tmp_json_file(Name, Json) :-
	dict_json_text(Json, Text),
	write_tmp_file(Name, Text).


/* my_tmp_file_url? */
report_file_path(loc(file_name, FN), loc(absolute_url,Url), Path) :-
	my_request_tmp_dir(loc(tmp_directory_name, Tmp_Dir_Value)),
	debug(tmp_files, "report_file_path:my_request_tmp_dir(loc(tmp_directory_name, ~w))~n", [Tmp_Dir_Value]),
	server_public_url(Server_Public_Url),
	debug(tmp_files, "report_file_path:server_public_url(~w)~n",[Server_Public_Url]),
	atomic_list_concat([Server_Public_Url, '/tmp/', Tmp_Dir_Value, '/', FN], Url),
	absolute_tmp_path(loc(file_name, FN), Path).


server_public_url(Url) :-
	asserted_server_public_url(Url).

set_server_public_url(Url) :-
	asserted_server_public_url(Url), !.

set_server_public_url(Url) :-
	(	asserted_server_public_url(Old)
	->	format(user_error, 'old Server_Public_Url: ~qw\n', [Old])
	;	true),
	%format(user_error, 'Server_Public_Url: ~q\n', [Url]),
	retractall(asserted_server_public_url(_)),
	assert(asserted_server_public_url(Url)).

my_tmp_file_path(loc(file_name,File_Name), loc(path_relative_to_tmp, File_Path_Relative_To_Tmp)) :-
	my_request_tmp_dir(loc(tmp_directory_name,Tmp_Dir)),
	atomic_list_concat([Tmp_Dir, '/', File_Name], File_Path_Relative_To_Tmp).

tmp_file_url(File_Name, Url) :-
	server_public_url(Server),
	my_tmp_file_path(File_Name, loc(path_relative_to_tmp, File_Path_Relative_To_Tmp)),
	atomic_list_concat([Server, '/tmp/', File_Path_Relative_To_Tmp], Url).

tmp_file_path_from_something(FileName, Path) :-
	exclude_file_location_from_filename(FileName, FileName2),
	FileName2 = loc(file_name, FileName2_Value),
	http_safe_file(FileName2_Value, []),
	absolute_tmp_path(FileName2, Path).

tmp_file_path_to_url(Path, Url) :-
	exclude_file_location_from_filename(Path, Fn),
	debug(tmp_files, "tmp_file_path_to_url:exclude_file_location_from_filename(~w, ~w)~n", [Path,Fn]),
	report_file_path(Fn, Url, _),
	debug(tmp_files, "tmp_file_path_to_url:report_file_path(~w, ~w, ~w)~n", [Fn, Url, _]).

loc_icase_endswith(loc(_, Fn), Suffix) :-
	icase_endswith(Fn, Suffix).

add_xml_result(Result_XML) :-
	add_xml_report('response', 'response', Result_XML).

add_xml_report(Key, Title, XML) :-
	atomics_to_string([Key, '.xml'], Fn_value),
	Fn = loc(file_name, Fn_value),
	report_file_path(Fn, Url, loc(absolute_path, Path)),
	setup_call_cleanup(
		open(Path, write, Stream),
		sane_xml_write(Stream, XML),
		close(Stream)
	),
	add_report_file(Key, Title, Url). % (_{name:Name,format:'xml'}

add_report_file(Key, Title, Url) :-
	result(R),
	doc_new_uri(Uri, report_file),
	doc_add(R, l:report, Uri, files),
	doc_add(Uri, l:key, Key, files),
	doc_add(Uri, l:title, Title, files),
	doc_add(Uri, l:url, Url, files).

get_report_file(Key, Title, Url) :-
	result(R),
	docm(R, l:report, Uri, files),
	doc(Uri, l:key, Key, files),
	doc(Uri, l:title, Title, files),
	doc(Uri, l:url, Url, files).

add_result_file_by_filename(Name) :-
	report_file_path(Name, Url, _),
	add_report_file('result', 'result', Url).

add_result_file_by_path(Path) :-
	tmp_file_path_to_url(Path, Url),
	add_report_file('result', 'result', Url).


:- module(files, [
		generate_unique_tmp_directory_base/0, 
		bump_tmp_directory_id/0, 
		absolute_tmp_path/2,
		request_tmp_dir/1,
		server_public_url/1
		,set_server_public_url/1
		,write_file/2
		,replace_request_with_response/2
		,tmp_file_url/2,
		write_tmp_json_file/2
		]).

:- use_module('utils').
:- use_module(library(http/http_dispatch), [http_safe_file/2]).

:- dynamic user:file_search_path/2.
:- multifile user:file_search_path/2.
:- dynamic user:my_request_tmp_dir, [thread(local)].
:- dynamic user:asserted_server_public_url/1.


request_tmp_dir(Dir) :-
	my_request_tmp_dir(Dir).

set_search_path(Alias, Path_From_This_Source_File) :-
	prolog_load_context(directory, Here),
	atomic_list_concat([Here, Path_From_This_Source_File, '/'], Dir),
	asserta(user:file_search_path(Alias, Dir)).


:- set_search_path(my_static, '/../prolog_server/static').
:- set_search_path(my_taxonomy, '/../prolog_server/taxonomy').
:- set_search_path(my_schemas, '/../prolog_server/schemas').
:- set_search_path(my_tests, '/../tests').
:- set_search_path(my_cache, '/../cache').
:- set_search_path(my_tmp, '/../prolog_server/tmp').

/*
  to be used instead of absolute_file_name for request-specific tmp files
*/
absolute_tmp_path(File_Name, Absolute_File_Name) :-
	my_tmp_file_path(File_Name, File_Path_Relative_To_Tmp),
	absolute_whatever(my_tmp(File_Path_Relative_To_Tmp), Absolute_File_Name).

/* my_tmp_file_url? */
report_file_path(FN, Url, Path) :-
	request_tmp_dir(Tmp_Dir),
	server_public_url(Server_Public_Url),
	atomic_list_concat([Server_Public_Url, '/tmp/', Tmp_Dir, '/', FN], Url),
	absolute_tmp_path(FN, Path).

my_tmp_file_path(File_Name, File_Path_Relative_To_Tmp) :-
	my_request_tmp_dir(Tmp_Dir),
	atomic_list_concat([Tmp_Dir, '/', File_Name], File_Path_Relative_To_Tmp).

tmp_file_url(File_Name, Url) :-
	server_public_url(Server),
	my_tmp_file_path(File_Name, File_Path_Relative_To_Tmp),
	atomic_list_concat([Server, '/tmp/', File_Path_Relative_To_Tmp], Url).
/*
  create a new unique directory under my_tmp and assert my_request_tmp_dir
*/
bump_tmp_directory_id :-
	session_tmp_directory_base(Base),
	gensym(Base, Dir),
	retractall(my_request_tmp_dir(_)),
	asserta(my_request_tmp_dir(Dir)),
	absolute_tmp_path('', Path),
	make_directory(Path),
	absolute_whatever(my_tmp('last'), Last),
	atomic_list_concat(['rm -f ', Last], Rm_Cmd),
	shell(Rm_Cmd, _),
	atomic_list_concat(['ln -s ', Path, ' ', Last], Cmd),
	shell(Cmd, 0).

absolute_whatever(Path_Specifier, Absolute) :-
	(
		(absolute_file_name(Path_Specifier, Absolute, [access(none), file_errors(fail)]),!)
	;
		absolute_file_name(Path_Specifier, Absolute, [file_type(directory)])
	).


/*
  assert a base for tmp directory names that should be unique for each run of the server (current time)
*/
generate_unique_tmp_directory_base :-
   get_time(Current_Time),
   atomic_list_concat([Current_Time, '.'], Base),
   asserta(session_tmp_directory_base(Base)),
   bump_tmp_directory_id.

   
server_public_url(Url) :-
	asserted_server_public_url(Url).
		
set_server_public_url(Url) :-
	format(user_error, 'Server_Public_Url: ~w\n', [Url]),
	retractall(asserted_server_public_url(_)),
	assert(asserted_server_public_url(Url)).
	

% -------------------------------------------------------------------
% write_file/2
% -------------------------------------------------------------------
/*fixme : its not xml-specific*/
write_file(Path, Text) :-
   open(Path, write, Stream),
   write(Stream, Text),
   close(Stream).

write_tmp_file(Name, Text) :-
	absolute_tmp_path(Name, Path),
	write_file(Path, Text).

write_tmp_json_file(Name, Json) :-
	utils:dict_json_text(Json, Text),
	write_tmp_file(Name, Text).
		
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


% -------------------------------------------------------------------
% save_file/3
% -------------------------------------------------------------------

%:- public save_file/3.

save_file(In, file(User_File_Path, Tmp_File_Path), Options) :-
	option(filename(User_File_Path), Options),
	% (for Internet Explorer/Microsoft Edge)
	tmp_file_path_from_url(User_File_Path, Tmp_File_Path),
	setup_call_cleanup(open(Tmp_File_Path, write, Out), copy_stream_data(In, Out), close(Out)).

tmp_file_path_from_url(FileName, Path) :-
	exclude_file_location_from_filename(FileName, FileName2),
	http_safe_file(FileName2, []),
	absolute_tmp_path(FileName2, Path).

exclude_file_location_from_filename(Name_In, Name_Out) :-
   atom_chars(Name_In, Name1),
   utils:remove_before('\\', Name1, Name2),
   utils:remove_before('/', Name2, Name3),
   atomic_list_concat(Name3, Name_Out).


   
:- initialization(generate_unique_tmp_directory_base).


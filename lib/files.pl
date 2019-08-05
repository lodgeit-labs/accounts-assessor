:- module(files, [
		generate_unique_tmp_directory_base/0, 
		bump_tmp_directory_id/0, 
		my_tmp_file_name/2,
		request_tmp_dir/1,
		server_public_url/1
		,set_server_public_url/1
		]).


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
my_tmp_file_name(File_Name, Absolute_File_Name) :-
	my_request_tmp_dir(Tmp_Dir),
	atomic_list_concat([Tmp_Dir, '/', File_Name], Path),
	absolute_file_name(my_tmp(Path), Absolute_File_Name, []).

/*
  create a new unique directory under my_tmp and assert my_request_tmp_dir
*/
bump_tmp_directory_id :-
   session_tmp_directory_base(Base),
   gensym(Base, Dir),
   retractall(my_request_tmp_dir(_)),
   asserta(my_request_tmp_dir(Dir)),
   my_tmp_file_name('', Path),
   make_directory(Path),
   (
      (absolute_file_name(my_tmp('last'), Last, [access(none), file_errors(fail)]),!)
      ;
      absolute_file_name(my_tmp('last'), Last, [file_type(directory)])
   ),
   atomic_list_concat(['rm -f ', Last], Rm_Cmd),
   shell(Rm_Cmd, _),
   atomic_list_concat(['ln -s ', Path, ' ', Last], Cmd),
   shell(Cmd, 0).

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
	retractall(asserted_server_public_url(_)),
	assert(asserted_server_public_url(Url)).
	

   
   
   
:- initialization(generate_unique_tmp_directory_base).


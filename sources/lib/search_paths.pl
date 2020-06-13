:- dynamic user:file_search_path/2.
:- multifile user:file_search_path/2.

set_search_path(Alias, Path_From_Repo_Root) :-
	prolog_load_context(directory, Here),
	atomic_list_concat([Here, '/../', Path_From_Repo_Root, '/'], Dir),
	asserta(user:file_search_path(Alias, Dir)).

:- set_search_path(my_static, 'static').
:- set_search_path(my_taxonomy, 'static/taxonomy').
:- set_search_path(my_schemas, 'static/schemas').
:- set_search_path(my_tmp, 'server_root/tmp').
:- set_search_path(my_tests, 'tests').
:- set_search_path(my_cache, 'cache').


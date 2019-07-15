:- module(files, []).

% use dynamic/2 to set multifile option when setting dynamic
:- dynamic user:file_search_path/2.
:- multifile user:file_search_path/2.

set_search_path(Alias, Path_From_This_Source_File) :-
	prolog_load_context(directory, Here),
	atomic_list_concat([Here, Path_From_This_Source_File, '/'], Dir),
	asserta(user:file_search_path(Alias, Dir)).

:- set_search_path(my_tmp, '/../prolog_server/tmp').
:- set_search_path(my_static, '/../prolog_server/static').
:- set_search_path(my_taxonomy, '/../prolog_server/taxonomy').
:- set_search_path(my_schemas, '/../prolog_server/schemas').
:- set_search_path(my_tests, '/../tests').

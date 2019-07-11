:- module(files, []).


:- dynamic user:file_search_path/2.
:- multifile user:file_search_path/2.

set_search_path(Alias, Path_From_This_Source_File) :-
	prolog_load_context(directory, Here),
	atomic_list_concat([Here, Path_From_This_Source_File, '/'], Dir),
	asserta(user:file_search_path(Alias, Dir)).

:- set_search_path(my_tmp, '/../prolog_server/tmp').
:- set_search_path(my_static, '/../prolog_server/static').
:- set_search_path(my_taxonomy, '/../prolog_server/taxonomy').
:- set_search_path(my_tests, '/../tests').
:- set_search_path(my_cache, '/../cache').

test0 :-
    absolute_file_name(my_static('account_hierarchy.xml'), _,
                       [ access(read) ]),
    absolute_file_name(my_static('default_action_taxonomy.xml'), _,
                       [ access(read) ]),
    absolute_file_name(my_tests('endpoint_tests/ledger/ledger-request.xml'), _,
                       [ access(read) ]),
	catch(
		(
			absolute_file_name(my_tests('non_existent_file.which_really_should_not_exist'), _, [ access(read) ]),
			false
		),
        _,
        true).

:- test0.

:- ['../../lib/files'].

:- begin_tests(files).

test(0) :-
    absolute_file_name(my_static('default_account_hierarchy.xml'), _,
                       [ access(read) ]),
    absolute_file_name(my_static('default_action_taxonomy.xml'), _,
                       [ access(read) ]),
    absolute_file_name(my_tests('endpoint_tests'), _,
                       [ file_type(directory) ]),
	catch(
		(
			absolute_file_name(my_tests('non_existent_file.which_really_should_not_exist'), _, [ access(read) ]),
			false
		),
        _,
        true).

:- end_tests(files).

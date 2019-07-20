:- ['../../lib/files'].

:- begin_tests(files).

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

:- end_tests(files).


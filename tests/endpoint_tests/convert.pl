:- use_module('../lib/files.pl').

find_test_directories(Paths) :-
    Top_Level_Directory = 'endpoint_tests',
    absolute_file_name(my_tests(Top_Level_Directory), Endpoint_Tests_Path, [file_type(directory)]),
    directory_files(Endpoint_Tests_Path, Entries),
    findall(Relative_Path,
        (
            member(Directory, Entries),
            \+sub_atom_icasechk(Directory, _Start, '.'),
            atomic_list_concat([Top_Level_Directory, '/', Directory], Relative_Path),
            atomic_list_concat([Endpoint_Tests_Path, '/', Directory], Absolute_Path),
            exists_directory(Absolute_Path)
        ),
        Paths
    ).

generate_new_directory(Atom, Response) :-
	atom_string(Atom, String),
	(
		(
			re_replace('request','', String, Response0);
			re_replace('Request','', String, Response0);
			re_replace('REQUEST','', String, Response0)
		),
		String \= Response0,
		atom_concat(Response1,'.xml',Response0),
		re_replace('(-|_)+$','', Response1, Response)
		% remove trailing punctuation...

	).

find_requests(Path, Testcases) :-
    absolute_file_name(my_tests(Path), Full_Path, [file_type(directory)]),
    directory_files(Full_Path, Entries),
    include(is_request_file, Entries, Requests0),
    sort(Requests0, Requests),
    findall(
        (Request_Path, Response_Path),
        (
            member(Request, Requests),
            atomic_list_concat([Path, '/', Request], Request_Path),
            response_file(Request_Path, Response_Path)
        ),
        Testcases
    ).

is_request_file(Atom) :-
    atom_concat(_,'.xml',Atom),
    sub_atom_icasechk(Atom, _Start2, 'request').

response_file(Atom, Response) :-
    replace_request_with_response(Atom, Response),
    absolute_file_name(my_tests(Response),_,[ access(read), file_errors(fail) ]).


:-
    find_test_directories(Paths),
	writeln(Paths),
	findall(
		_,
		(	
			member(Path, Paths),
			absolute_file_name(my_tests(Path), Full_Path, [file_type(directory)]),
			directory_files(Full_Path, Entries),
			include(is_request_file, Entries, Requests0),
			sort(Requests0, Requests),
			findall(
				_,
				(
					member(Request, Requests),
					format("Request0: ~w~n",[Request]),
					atomic_list_concat([Full_Path, '/', Request], Full_Request_Path),
					atomic_list_concat([Path, '/', Request], Request_Path),
					generate_new_directory(Request, New_Directory),
					atomic_list_concat([Full_Path, New_Directory], "/", New_Directory_Path),
					atomic_list_concat([New_Directory_Path,"responses"],"/", Response_Directory_Path),
					format("Request: ~w~n", [Full_Request_Path]),
					format("Directory: ~w~n", [New_Directory_Path]),
					format("Response directory: ~w~n",[Response_Directory_Path]),
					make_directory(New_Directory_Path),
					make_directory(Response_Directory_Path),
					atomic_list_concat(['git', 'mv', Full_Request_Path, New_Directory_Path], " ", Request_Mv_Command),
					writeln(Request_Mv_Command),
					shell(Request_Mv_Command),
					(
						response_file(Request_Path, Response_Path)
					->
						(
							absolute_file_name(my_tests(Response_Path),Full_Response_Path,[]),
							format("Response: ~w~n", [Full_Response_Path]),
							%process_create('git',['mv',Full_Response_Path,Response_Directory_Path],[])
							atomic_list_concat(['git', 'mv', Full_Response_Path, Response_Directory_Path], " ", Response_Mv_Command),
							writeln(Response_Mv_Command),
							shell(Response_Mv_Command)
						)
					;
						writeln("No response file.")
					),
					writeln("")
				),
				_
			)
		),
		_
	).

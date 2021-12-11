


testcase(Params_dict) :-
	saved_testcase(Testcase),

	member(Mode, ['remote', 'subprocess']),

	(	Mode == 'subprocess'
	->	member(Die_on_error, [true, false])
	;	/*Die_on_error = na*/true),

	Vars = [
		type-robust_endpoint_test,
		testcase-Testcase,
		mode-Mode,
		die_on_error-Die_on_error,
		priority=0
		/*
		alter dates, try different st count limits? this could be declared in the testcase directory in a json or pl file
		*/
	],
	foldl(add_ground_parameter_to_dict, Vars, params{}, Params_dict).


testcase([
	type-json_endpoint_test,
	api_uri-'/sbe',
	post_data-_{current_state:[]},
	result_text-'{"result": {"question": "Are you a Sole trader, Partnership, Company or Trust?", "state": [{"question_id": 0, "response": -1}]}}'
	]).

testcase([
	type-json_endpoint_test,
	api_uri-'/residency',
	post_data-_{current_state:[]},
	result_text-'{"result": {"question": "Do you live in Australia?", "state": [{"question_id": 1, "response": -1}]}}'
	]).





add_ground_parameter_to_dict(Name-Var, In, Out) :-
	ground(Var),
	Out = In.put(Name,Var).

add_ground_parameter_to_dict(_-Var, In, In) :-
	var(Var).





saved_testcase(Testcase) :- find_test_cases_in('endpoint_tests' ,Testcase).




/*
if there's a request file, it's a testcase directory, so yield it, otherwise recurse over subdirectories
*/

find_test_cases_in(Current_Directory, Test_Case) :-
	Current_Directory_Absolute = loc(absolute_path, Current_Directory_Absolute_Value),
	resolve_specifier(loc(specifier,(my_tests(Current_Directory))), Current_Directory_Absolute),
	exists_directory(Current_Directory_Absolute_Value),
	directory_entries(Current_Directory_Absolute_Value, Entries),
	(	(member('request.xml',Entries);member('request.n3',Entries))
	->	Test_Case = Current_Directory
	;	find_test_cases_in_recurse(Current_Directory, Entries, Test_Case)).

find_test_cases_in_recurse(Current_Directory, Entries, Test_Case) :-
	member(Subdirectory, Entries),
	\+member(Subdirectory, ['.','..']),
	atomic_list_concat([Current_Directory, Subdirectory], '/', Subdirectory_Relative_Path),
	catch(
		(
			absolute_file_name(my_tests(Subdirectory_Relative_Path), Subdirectory_Absolute_Path, [file_type(directory)]),
			exists_directory(Subdirectory_Absolute_Path),
			find_test_cases_in(Subdirectory_Relative_Path, Test_Case)
		),
		_,
		fail
	).



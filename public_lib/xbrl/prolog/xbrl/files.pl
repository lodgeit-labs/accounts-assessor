
resolve_specifier(loc(specifier, Path_Specifier), loc(absolute_path, Absolute)) :-
	/*
	absolute_file_name will not fail if the file doesnt exist, but will fail if it is a directory.
	this pred succeeds in all cases, just resolves the path specifier
	*/
	(
		(absolute_file_name(Path_Specifier, Absolute, [access(none), file_errors(fail)]),!)
	;
		absolute_file_name(Path_Specifier, Absolute, [file_type(directory)])
	).

exclude_file_location_from_filename(loc(_,Name_In), loc(file_name, Name_Out)) :-
   atom_chars(Name_In, Name1),
   remove_before('\\', Name1, Name2),
   remove_before('/', Name2, Name3),
   atomic_list_concat(Name3, Name_Out).

print_file(loc(absolute_path, Path)) :-
	setup_call_cleanup(
		open(Path, write, Out),
		copy_stream_data(Out, user_output),
		close(Out)).

write_file(loc(absolute_path, Path), Text) :-
	setup_call_cleanup(
		open(Path, write, Stream),
		write(Stream, Text),
		close(Stream)).

directory_entries_with_full_paths(loc(absolute_path, Directory_Path), File_Paths) :-
	directory_entries(Directory_Path,Files0),
	findall(
		File_Path,
		(
			member(File_Name, Files0),
			atomic_list_concat([Directory_Path, File_Name], '/', File_Path0),
			resolve_specifier(loc(specifier, File_Path0), File_Path)
		),
		File_Paths
	).

directory_real_files(Directory_Path, File_Paths) :-
	directory_entries_with_full_paths(Directory_Path, Files0),
	include(([loc(absolute_path,F)]>>exists_file(F)), Files0, File_Paths).

/* swipl directory_files actually returns all entries so let's name it so */
directory_entries(Directory_Path, Entries) :-
	directory_files(Directory_Path, Entries).

copy_file_loc(loc(absolute_path, X), loc(absolute_path, Y)) :-
	copy_file(X, Y).

ensure_directory_exists(loc(absolute_path, Path_Value)) :-
	catch(
		make_directory(Path_Value),
		error(existence_error(directory,_),context(system:make_directory/1,'File exists')),
		true
		).

directory_file_path_loc(loc(absolute_path,D), loc(file_name,F), loc(absolute_path,P)) :-
	directory_file_path(D, F, P).

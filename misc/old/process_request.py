#!/usr/bin/env python3

#from frontend_server.lib import invoke_rpc_cmdline

import sys, subprocess, shlex
argv = sys.argv

FILEPATH = argv[-1]
args = argv[1:-1]
cmd = shlex.split("swipl -s ../lib/dev_runner.pl --problem_lines_whitelist ../misc/problem_lines_whitelist -s ../lib/debug1.pl") + args + ["-g lib:process_request_cmdline('" + FILEPATH + "')"]
print(' '.join(cmd))
subprocess.run(cmd)



/*
/* takes either a xml request file, or a directory expected to contain a xml request file, an n3 file, or both */
process_request_cmdline(Path_Value0) :-
	set_server_public_url('http://localhost:7778'),
	format(user_error, "Path_Value0: ~w~n", [Path_Value0]),
	resolve_specifier(loc(specifier, Path_Value0), Path),
	format(user_error, "Path: ~w~n", [Path]),
	bump_tmp_directory_id,
	resolve_directory(Path, File_Paths),
	format(user_error, "File_Paths: ~w~n", [File_Paths]),
	copy_request_files_to_tmp(File_Paths, _),
	process_request([], File_Paths).
*/

/*
process_request_http(Options, Parts) :-
	findall(F1,	member(_=file(F1), Parts), File_Paths),
	process_request(Options, File_Paths).
*/

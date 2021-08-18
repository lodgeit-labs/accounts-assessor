# debugging checklist:

## `./run.sh` flags:
	
	* `--mount_host_sources_dir true` - this ensures that all source etc directories are mounted rather than copied. This means that you can always just modify any prolog source file and re-run a request.
	
	* `--django_noreload false` - applies only to some services, makes django watch for and reload files on modification.

## exceptions
there are two general cases:
	* our code calls `throw_string`/`throw_value`. `DONT_GTRACE` and `DISPLAY` applies.
	* something else throws and exception, like a division by zero: `DIE_ON_ERROR` applies.


## `sources/config/worker_config.json`:
	this is loaded by call_prolog on every request.
    
    * "DEBUG_OVERRIDE" : force passing `debug` goal to prolog. If unset:
		* run_last_request_in_docker scripts have debugging on
		* internal-workers as a service has debugging off

    * "DONT_GTRACE" : invoke (gui)tracer when throw_string is called? (if $DISPLAY is available)
    
    * "DIE_ON_ERROR" : 
		* true: let exceptions propagate so that gtrace pops up
		* false: catch exceptions and convert them into alerts


## gtrace	

configuration: `sources/swipl/xpce/Defaults`: adjust font size as needed.

gtrace is useful, although it gets confused often. In some swipl versions it's better than in others. Are we still on V8.1.15?
	* https://github.com/SWI-Prolog/swipl-devel/issues/757#

gtrace is enabled by running 'guitracer'. Robust does this if 'have_display' succeeds.
	
'have_display' succeds if DISPLAY env var is set and nonempty. 
	
take care of prolog 'debug' flag. This is set by '--debug' parameter on swipl command line. It's set to true when running requests on the command line (`invoke_rpc_cmdline.py`), but not when running in the webserver. 
	
if 'guitracer' was previously invoked, 'gtrace' will kick in when the repl catches an uncaught exception. Unfortunately, 'process_request' catches exceptions to produce alerts and return response to client instead. This means that normal exceptions (not thrown with `throw_string`) in Robust code dont cause gtrace to run - unless you set the debugging flag 'die_on_error'. But it could be done with prolog_exception_hook, which we already use anyway.
	
Running things in docker, you can also run into the issue: ```Failed to connect to X-server at `:0.0 ```. This is a permission error, because docker is running under its own user. Run `xhost +local:docker` to fix this for a session.

If gtrace shows up on `process_multifile_request`, do a redo followed by a skip and you'll get a readable stack trace in terminal. (?)
	

## network

	* watch http trafic from and to endpoint:
```sudo tcpdump -A -s 0 'tcp port 7778 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'```

## git

	* given you are on a commit with some tests failing, find last commit with no tests failing:
		(tests need fixing right now)
```git bisect start; git bisect bad HEAD; git bisect good master; git bisect run ./bisect_helper.sh```


## test requests/responses

overwrite differing response files:
swipl -s ../tests/endpoint_tests/endpoint_tests.pl  -g "set_flag(overwrite_response_files, true), run_tests."



/*
Demonstrating how to properly call Python scripts under the virtual environment and deal with their exit status.
Run this from the prolog_server directory.

note that this does not properly activate the virtualenv, namely, PATH is not changed
note that I/O in swipl is tedious in general, we've already ran into bugs with shell/2, not sure about process_create,
but it is advisable to stick to using rpc calls to internal_services instead.
*/

:-
	% this one returns exit status 1, i.e. failure and will trigger the exception-handler:
	%Instance_File = '../tests/endpoint_tests/investment/investment-combined-request1.xml',

	% this one returns exit status 0, i.e. success
	Instance_File = '../tests/endpoint_tests/ledger/ledger-request.xml',

	% avoids shell injections
	%Instance_File = '; echo \"arbitrary shell command execution\"',

	Schema_File = 'schemas/bases/Reports.xsd',
	catch(
		setup_call_cleanup(
			process_create('../python/venv/bin/python3',['../python/src/xmlschema_runner.py',Instance_File,Schema_File],[]),
			writeln("Success..."),
			writeln("Done...")
		),
		Catcher,
		format("Caught exception: ~w~n",[Catcher])
	).

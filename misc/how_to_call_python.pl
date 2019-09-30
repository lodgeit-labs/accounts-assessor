/*
Demonstrating how to properly call Python scripts under the virtual environment and deal with their exit status.

Run this from the misc directory.
*/

:-
	% this one returns exit status 1, i.e. failure and will trigger the exception-handler:
	Instance_File = '../../tests/endpoint_tests/investment/investment-combined-request1.xml',

	% this one returns exit status 0, i.e. success
	%Instance_File = '../tests/endpoint_tests/ledger/ledger-request.xml',

	% avoids shell injections
	%Instance_File = '; echo \"arbitrary shell command execution\"',

	Schema_File = '../prolog_server/schemas/bases/Reports.xsd',
	catch(
		setup_call_cleanup(
			process_create('../xbrl/account_hierarchy/venv/bin/python3',['../xbrl/account_hierarchy/src/xmlschema_runner.py',Instance_File,Schema_File],[]),
			writeln("Success..."),
			writeln("Done...")
		),
		Catcher,
		format("Caught exception: ~w~n",[Catcher])
	).

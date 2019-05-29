This directory contains a SWI Prolog server (prolog_server_simple.pl) that:

accepts a endpoint_tests/loan/loan-request.xml and generates a endpoint_tests/loan/loan-response.xml
accepts a endpoint_tests/ledger/ledger-request.xml and generates a endpoint_tests/ledger/ledger-response.xml 

Note that this code relies on Murisi's Prolog code.

To use the server download and install SWI Prolog available at:

   http://www.swi-prolog.org/Download.html

To run the server double click on the file: prolog_server_simple.pl.

Open a web browser at: http://localhost:8080/

This directory has following sub-directories:
- loan: contains prolog code that process loan request.
- ledger: contains prolog code that process ledger request.
- taxonomy: contains all taxonomy files.
Sample request and response files are available in endpoint_tests/ directory.

This directory also contains a file prolog_server_unix_daemon.pl to run the http server as a daemon process.

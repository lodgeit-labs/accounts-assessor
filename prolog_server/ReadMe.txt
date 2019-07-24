#introduction

This directory contains a SWI Prolog server (prolog_server.pl) that serves several xml endpoints from a common url,
and some chat endpoints.

#getting started

To use the server download and install SWI Prolog available at:

   http://www.swi-prolog.org/Download.html

To run the server double click on the file: run_simple_server.pl.

Open a web browser at: http://localhost:8080/

#endpoint
most endpoints should have some documentation in doc/. Introductions to individual concepts can be found on dropbox.

##xml endpoints

a request POST-ed to the /upload url is first handled in prolog_server, where the payload xml request file is saved into tmp/. A filename is handed to process_data, which loads it and let's each endpoint try to handle it. The endpoint that is successful will eventually write it's output directly to stdout, which is redirected by the http server.

###loan endpoint:
accepts a tests/endpoint_tests/loan/loan-request.xml and generates a tests/endpoint_tests/loan/loan-response.xml

###ledger endpoint:
accepts a tests/endpoint_tests/ledger/ledger-request.xml and generates a tests/endpoint_tests/ledger/ledger-response.xml 
Ledger endpoint is currently the most complex one, spanning most of the files in lib/.


#directories

This directory has following sub-directories:
- tmp: for storing request and response files for debugging
- loan: contains prolog code that process loan request.
- ledger: contains prolog code that process ledger request.
- taxonomy: contains all xbrl taxonomy files.
- schemas: xsd schemas

...
Sample request and response files are available in endpoint_tests/ directory.

This directory also contains a file run_daemon.pl to run the http server as a daemon process.

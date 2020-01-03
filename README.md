






# Accounts Assessor

This repository hosts a program that derives, validates, and corrects the financial information that it is given. The program uses redundancy to carry out its validations and corrections. By this it is meant that knowledge of parts of a company's financial data imposes certain constraints on the company's other financial data. If the program is given a company's ledger, then it knows what the balance sheet should look like. If the program is given a company's balance sheet, then it has a rough idea of what the ledger should look like.

## Getting Started
Fetch submodules:
* `git submodule update --init`

Install SWIPL 8.1.14
* http://www.swi-prolog.org/Download.html

How to run it:
* Change directory to server_root/

Install SWIPL dependencies:
* ```../lib/init.sh```

Run the tests:
`swipl -s ../tests/run_tests.pl -g halt`

Run a single xml request:
`../lib/cli_process_request_xml.py  --problem_lines_whitelist problem_lines_whitelist -c true ../lib/debug1.pl tests/endpoint_tests/ledger/ledger-livestock-0/request.xml`

Run a single testcase:
`swipl -s ../lib/endpoint_tests.pl -g "set_prolog_flag(grouped_assertions,true),setup,run_endpoint_test(ledger, 'endpoint_tests/ledger/ledger-livestock-5')."`

Run the server:
`swipl -s ../lib/run_simple_server.pl`

Run the daemon:
`../lib/update_demo-fast.sh`

Open a web browser at: http://localhost:8080/
* upload a request.xml file from tests/endpoint_tests/
* you should get back a json with links to individual report files

## Directory Structure

* lib - prolog source code and utility scripts
** prolog_server.pl that serves several xml endpoints from a common url, and some chat endpoints.
** run_daemon.pl to run the http server as a daemon process.
* tests
** plunit - contains queries that test the functionality of the main Prolog program
** endpoint_tests - contains test requests for the web endpoint as well as expected reponses
* docs - contains correspondences and resources on accounting that I have been finding useful in making this program
* misc - contains the stuff that does not yet clearly fit into a category
* server_root - this directory is served by the prolog server
** tmp - each request gets its own directory here
** taxonomy - contains all xbrl taxonomy files.
** schemas - xsd schemas




## Current Functionality (needs updating)

The functionality of the program at present:
* Given a bank statement, it can derive balance sheets, trial balances, investment report
* Given a hire purchase arrangement, it can track the balance of a hire purchase account through time
* Given a hire purchase arrangement, it can derive the total payment and the total interest
* Given a hire purchase arrangement and ledger, it can guess what the erroneous transactions are
* Given a hire purchase arrangement and ledger, it can generate correction transactions to fix the erroneous transactions
json-based endpoints:
* It can determine tax residency by carrying out a dialog with the user
* It can determine small business entity status by carrying out a dialog with the user





## endpoints
most endpoints should have some documentation in doc/. Introductions to individual concepts can be found on dropbox.

##xml endpoints
a request POST-ed to the /upload url is first handled in prolog_server, where the payload xml request file is saved into tmp/. A filename is handed to process_data, which loads it and let's each endpoint try to handle it. The endpoint that is successful will eventually write it's output directly to stdout, which is redirected by the http server.

###loan endpoint:
accepts a tests/endpoint_tests/loan/loan-request.xml and generates a tests/endpoint_tests/loan/loan-response.xml

###ledger endpoint:
accepts a tests/endpoint_tests/ledger/ledger-request.xml and generates a tests/endpoint_tests/ledger/ledger-response.xml 
Ledger endpoint is currently the most complex one, spanning most of the files in lib/.

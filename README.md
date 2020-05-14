# Accounts Assessor

This repository hosts a program that derives, validates, and corrects the financial information that it is given. The program uses redundancy to carry out its validations and corrections. By this it is meant that knowledge of parts of a company's financial data imposes certain constraints on the company's other financial data. If the program is given a company's ledger, then it knows what the balance sheet should look like. If the program is given a company's balance sheet, then it has a rough idea of what the ledger should look like.

## documentation
most endpoints should have some documentation in doc/. Introductions to individual concepts can be found in videos on dropbox.

videos:
https://www.dropbox.com/sh/prgubjzoo9zpkhp/AACd6YmoWxf9IUi5CriihKlLa?dl=0
https://www.dropbox.com/sh/o5ck3qm79zwgpc5/AABD9jUcWiNpWMb2fxsmeVfia?dl=0

wiki:
https://github.com/LodgeiT/labs-accounts-assessor/wiki/

doc/:
https://github.com/LodgeiT/labs-accounts-assessor/tree/master/doc

## architecture
there are 4 components:
### internal_services
various helper functions that prolog invokes over http/rpc
### internal_workers
a celery worker that:
* wraps prolog and spawns prolog on request
* talks to the triplestore
### frontend_server
lets users upload request files and triggers internal_workers. Django provides a development http server which serves static/tmp files, but for production, this has to be augmented with
### http server
on demo server, this is a system-wide apache set up with mod_wsgi. I have not found a standalone wsgi/asgi server that also serves files like apache does, so it's not clear how to handle this more flexibly.

## Getting Started
Fetch submodules:
* `git submodule update --init`
(currently there are no submodules)

Install SWIPL 8.1.14
* see https://github.com/LodgeiT/labs-accounts-assessor/wiki/SWIPL-and-prolog-notes

Install dependencies:
* install RabbitMQ as specified here: http://docs.celeryproject.org/en/latest/getting-started/first-steps-with-celery.html#celerytut-broker
* install python3 and python3-pip
* ```./init.sh```

set up virtualenv for servicemanager:
* ```cd servicemanager; ./init_local_venv.sh```

Run all services:
```./servicemanager/run_in_local_venv.sh  --log_file ../sm.log  -a -g demo7788```

optional, run the triplestore (this is a command line from demo server):
`/home/sfi/ag/bin/agraph-control --config /home/sfi/ag/lib/agraph.cfg start`

configure secrets/credentials: add two json files above repo directory. see demo server for details.

Open a web browser at: http://localhost:7788/
* upload a request file from tests/endpoint_tests/
* you should get back a json with links to individual report files

Run the tests:
`cd server_root; reset;echo -e "\e[3J";   swipl -s ../lib/dev_runner.pl   --problem_lines_whitelist=../misc/problem_lines_whitelist  --script ../lib/endpoint_tests.pl  -g "set_flag(overwrite_response_files, false), set_flag(add_missing_response_files, false), set_prolog_flag(grouped_assertions,true), run_tests"`

Run one testcase:
`cd server_root; reset;echo -e "\e[3J";   swipl -s ../lib/dev_runner.pl   --problem_lines_whitelist=../misc/problem_lines_whitelist  --script ../lib/endpoint_tests.pl  -g "set_flag(overwrite_response_files, false), set_flag(add_missing_response_files, false), set_prolog_flag(grouped_assertions,false), set_prolog_flag(testcase,(ledger,'endpoint_tests/ledger/ledger-2')), run_tests(endpoints:testcase)"`

Run a single request from command line:
1) `cd server_root`
2) `. ../venv/bin/activate`
3) `env CELERY_QUEUE_NAME=q7788 ../internal_workers/invoke_rpc_cmdline.py --debug true --halt true --prolog_flags "set_prolog_flag(services_server,'http://localhost:17788')" endpoint_tests/ledger/Copy_Of_BankDemo2`


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





## endpoints (needs updating)

##xml endpoints
a request POST-ed to the /upload url is first handled in prolog_server, where the payload xml request file is saved into tmp/. A filename is handed to process_data, which loads it and let's each endpoint try to handle it. The endpoint that is successful will eventually write it's output directly to stdout, which is redirected by the http server.

###loan endpoint:
accepts a tests/endpoint_tests/loan/loan-request.xml and generates a tests/endpoint_tests/loan/loan-response.xml

###ledger endpoint:
accepts a tests/endpoint_tests/ledger/ledger-request.xml and generates a tests/endpoint_tests/ledger/ledger-response.xml 
Ledger endpoint is currently the most complex one, spanning most of the files in lib/.

# Accounts Assessor

This repository hosts a program that derives, validates, and corrects the financial information that it is given. The program uses redundancy to carry out its validations and corrections. By this it is meant that knowledge of parts of a company's financial data imposes certain constraints on the company's other financial data. If the program is given a company's ledger, then it knows what the balance sheet should look like. If the program is given a company's balance sheet, then it has a rough idea of what the ledger should look like.

## Getting Started
Fetch submodules:
* `git submodule update --init`

Install SWIPL 8.1.14

How to run it:
* Change directory to prolog_server/

Install SWIPL dependencies:
* ```./init.sh```

Run the tests:
`swipl -s ../tests/run_tests.pl -g halt`

Run a single xml request:
`../lib/cli_process_request_xml.py  --problem_lines_whitelist problem_lines_whitelist -c true ../lib/debug1.pl tests/endpoint_tests/ledger/ledger-livestock-0/request.xml`

Run a single testcase:
`swipl -s ../lib/endpoint_tests.pl -g "set_prolog_flag(grouped_assertions,true),setup,run_endpoint_test(ledger, 'endpoint_tests/ledger/ledger-livestock-5')."`

Run the server:
`swipl -s ../lib/run_simple_server.pl`

Run the demo server:
`../lib/update_demo-fast.sh`

## Directory Structure

Outline of the directory structure of this repository:
* [lib](lib) prolog source code and utility scripts
* [tests/plunit](tests/plunit) contains queries that test the functionality of the main Prolog program
* [tests/endpoint_tests](tests/endpoint_tests) contains test XML requests for the web endpoint as well as expected XML reponses
* [docs](docs) contains correspondences and resources on accounting that I have been finding useful in making this program
* [misc](misc) contains the stuff that does not yet clearly fit into a category
* [prolog_server](prolog_server) this serves as a root of the prolog web server, some folders with static data are served from here
* [prolog_server/tmp](prolog_server/tmp) each request xml processed gets it's own directory here

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

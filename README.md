# Accounts Assessor

This repository hosts a program that derives, validates, and corrects the financial information that it is given. The program uses redundancy to carry out its validations and corrections. By this it is meant that knowledge of parts of a company's financial data imposes certain constraints on the company's other financial data. If the program is given a company's ledger, then it knows what the balance sheet should look like. If the program is given a company's balance sheet, then it has a rough idea of what the ledger should look like.

## Getting Started

Install SWIPL dependencies:
* ```swipl -g "pack_install(tap), pack_install(regex), pack_install(xsd), pack_install('https://github.com/rla/rdet.git')."```

Install Arelle:
* ```git clone https://github.com/Arelle/Arelle``` into some path PATH_TO_ARELLE_DIR
* Set up a virtual environment in PROJECT_DIR/xbrl/account_hierarchy:
	* ```cd PROJECT_DIR/xbrl/account_hierarchy```
	* ```python3 -m venv venv```
* Install Arelle into virtual environment
	* If using bash: ```source venv/bin/activate```
	* ```pip install PATH_TO_ARELLE_DIR```
	* ```deactivate```

How to run it:
* Change directory to prolog_server/

Run the tests:
* Enter `swipl -s ../tests/run_tests.pl -g halt`

Run the server:
* Enter `swipl -s run_simple_server.pl`

## Directory Structure

Outline of the directory structure of this repository:
* [lib](lib) contains most of the source code
* [tests](tests) contains queries that test the functionality of the main Prolog program
** [tests/endpoint_tests](tests/endpoint_tests) contains test XML requests for the web endpoint as well as expected XML reponses
* [docs](docs) contains correspondences and resources on accounting that I have been finding useful in making this program
* [misc](misc) contains the stuff that does not yet clearly fit into a category

## Current Functionality (fixme)

The functionality of the program at present:
* Given a ledger it can derive balance sheets, trial balances, and movements
* Given a hire purchase arrangement, it can track the balance of a hire purchase account through time
* Given a hire purchase arrangement, it can derive the total payment and the total interest
* Given a hire purchase arrangement and ledger, it can guess what the erroneous transactions are
* Given a hire purchase arrangement and ledger, it can generate correction transactions to fix the erroneous transactions
* It can determine tax residency by carrying out a dialog with the user

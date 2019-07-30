# Accounts Assessor

This repository hosts a program that derives, validates, and corrects the financial information that it is given. The program uses redundancy to carry out its validations and corrections. By this it is meant that knowledge of parts of a company's financial data imposes certain constraints on the company's other financial data. If the program is given a company's ledger, then it knows what the balance sheet should look like. If the program is given a company's balance sheet, then it has a rough idea of what the ledger should look like.

## Getting Started

dependencies:

```swipl -g "pack_install(tap), pack_install(regex), pack_install(xsd)."```

How to run the server:
* Change directory to prolog_server/
* Enter `swipl -s run_simple_server.pl`

How to run the program tests:
* Change to the tests/ directory
* Enter `swipl -s run_tests.pl -g halt`

## Directory Structure

Outline of the directory structure of this repository:
* [lib](lib) contains most of the source code
* [tests](tests) contains queries that test the functionality of the main Prolog program
** [tests/endpoint_tests](tests/endpoint_tests) contains test XML requests for the web endpoint as well as expected XML reponses
* [docs](docs) contains correspondences and resources on accounting that I have been finding useful in making this program
* [misc](misc) contains the stuff that does not yet clearly fit into a category

## Current Functionality

The functionality of the program at present:
* Given a ledger it can derive balance sheets, trial balances, and movements
* Given a hire purchase arrangement, it can track the balance of a hire purchase account through time
* Given a hire purchase arrangement, it can derive the total payment and the total interest
* Given a hire purchase arrangement and ledger, it can guess what the erroneous transactions are
* Given a hire purchase arrangement and ledger, it can generate correction transactions to fix the erroneous transactions
* It can determine tax residency by carrying out a dialog with the user

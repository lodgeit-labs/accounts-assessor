# Accounts Assessor

This repository hosts a program that derives, validates, and corrects the financial information that it is given. The program uses redundancy to carry out its validations and corrections. By this it is meant that knowledge of parts of a company's financial data imposes certain constraints on the company's other financial data. If the program is given a company's ledger, then it knows what the balance sheet should look like. If the program is given a company's balance sheet, then it has a rough idea of what the ledger should look like.

## Getting Started

How to run the program:
* Change directory to the root of the project
* Enter `swipl -s src/main.pl`

How to run the tests:
* Change directory to the root of the project
* Enter `./tests/main.sh`

## Directory Structure

Outline of the directory structure of this repository:
* [src](src) contains the Prolog source for the program
* [examples](examples) contains examples of how Prolog can be embedded in other languages
* [tests](tests) contains queries that test the functionality of the main Prolog program
* [docs](docs) contains correspondences and resources on accounting that I have been finding useful in making this program
* [misc](misc) contains the stuff that does not yet clearly fit into a category

## Current Functionality

The functionality of the program at present:
* Given a ledger it can derive balance sheets, trial balances, and movements
* Given a hire purchase arrangement, it can track the balance of a hire purchase account through time
* Given a hire purchase arrangement, it can derive the total payment and the total interest
* Given a hire purchase arrangement and ledger, it can guess what the erroneous transactions are
* Given a hire purchase arrangement and ledger, it can generate correction transactions to fix the erroneous transactions

#!/usr/bin/env bash

# Runs various tests on the loan calculator programs. This script works by sending the
# queries in the test file to the Prolog top level in such a way that they appear to come
# from stdin. I could not figure out a way to do this from within Prolog, hence the Bash
# script.

cat tests/loans.pl | swipl -s src/main.pl
cat tests/ledger.pl | swipl -s src/main.pl
cat tests/hirepurchase.pl | swipl -s src/main.pl


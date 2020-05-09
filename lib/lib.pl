
:- use_module(library(xsd)).
:- use_module(library(xpath)).
:- use_module(library(record)).
:- use_module(library(yall)).
:- use_module(library(rdet)).
:- use_module(library(clpq)).
:- use_module(library(clpfd)).
:- use_module(library(http/http_open)).
:- use_module(library(http/http_client)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(semweb/rdf11),except(['{}'/1])).

:- [search_paths].

:- ['../public_lib/xbrl/prolog/xbrl/utils'].

:- ['../public_lib/xbrl/prolog/xbrl_output/fact_output'].
:- ['../public_lib/xbrl/prolog/xbrl_output/xbrl_contexts'].
:- ['../public_lib/xbrl/prolog/xbrl_output/xbrl_output'].



:- [accounts_extract].
:- [accounts].
:- [action_verbs].
:- [bank_accounts].
:- [bank_statement].
:- [cashflow].
:- [crosschecks_report].
:- [days].
:- [detail_accounts].
:- [doc].
:- [event_calculus].
:- [exchange].
:- [exchange_rates].
:- [extract_bank_accounts].
:- [fetch_file].
:- [german_bank_csv].
:- [gl_export].
:- [gl_input].
:- [investment_report_2].
:- [investments_accounts].
:- [invoices].
:- [ledger_html_reports].
:- [ledger].
:- [ledger_report].
:- [livestock_adjustment_transactions].
:- [livestock_average_cost].
:- [livestock_calculator].
%:- [livestock_crosscheck].
:- [livestock_extract].
:- [livestock_misc].
:- [livestock].
:- [loans].
:- [pacioli].
:- [pricing].
:- [process_request].
:- [report_page].
:- [request_files].
:- [residency].
:- [s_transaction].
:- [system_accounts].
:- [tables].
:- [trading].
:- [transactions].
:- [vector_string].

% :- ['../misc/chr_hp'].

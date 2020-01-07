:- module(_,[]).

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

:- use_module(library(fnotation)).
:- fnotation_ops($>,<$).
:- op(900,fx,<$).

:- [search_paths].

:- ['../prolog_xbrl_public/xbrl/prolog/xbrl/utils.pl'].

:- [accounts_extract].
:- [accounts].
:- [action_verbs].
:- [bank_statement].
:- [crosschecks_report].
:- [days].
:- [detail_accounts].
:- [event_calculus].
:- [exchange].
:- [exchange_rates].
:- [fact_output].
:- [investment_report_2].
:- [invoices].
:- [ledger_html_reports].
:- [ledger].
:- [ledger_report].
:- [livestock_accounts].
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
:- [residency].
:- [s_transaction].
:- [system_accounts].
:- [tables].
:- [trading].
:- [transactions].
:- [xbrl_contexts].
:- [xbrl_output].


:- use_module(library(xpath)).
:- use_module(library(record)).
:- use_module(library(yall)).
:- use_module(library(clpq)).
% https://github.com/SWI-Prolog/swipl-devel/issues/715#issuecomment-731019516
:- use_module(library(clpq), []).
:- use_module(library(clpfd)).
:- use_module(library(http/http_open)).
:- use_module(library(http/http_client)).
:- use_module(library(http/http_dispatch)).

:- [search_paths].

:- ['../public_lib/lodgeit_solvers/prolog/utils/utils'].

:- ['../public_lib/prolog_xbrl/instance_output/fact_output'].
:- ['../public_lib/prolog_xbrl/instance_output/xbrl_contexts'].
:- ['../public_lib/prolog_xbrl/instance_output/xbrl_output'].



:- [accounts_extract].
:- [accounts].
:- [action_verbs].
:- [bank_accounts].
:- [bank_statement].
:- [cashflow].
:- [crosschecks_report].
:- [days].
:- [detail_accounts].
:- [event_calculus].
:- [exchange].
:- [exchange_rates].
:- [extract_bank_accounts].
:- [facts].
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
:- [pacioli_rdf].
:- [pricing].
:- [process_request].
:- [report_page].
:- [residency].
:- [s_transaction].
:- [smsf].
:- [smsf_distribution].
:- [smsf_facts].
:- [smsf_income_tax].
:- [smsf_income_tax_v2].
:- [smsf_member_reports].
:- [smsf_member_report_checks].
:- [smsf_member_report_presentation].
:- [state].
:- [system_accounts].
:- [tables].
:- [term_dict].
:- [trading].
:- [transactions].
:- [vector_string].
% :- ['../misc/chr_hp'].

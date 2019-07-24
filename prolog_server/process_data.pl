% ===================================================================
% Project:   LodgeiT
% File:      process_data.pl
% Author:    Rolf Schwitter
% Date:      2019-06-08
% ===================================================================

% -------------------------------------------------------------------
% Modules
% -------------------------------------------------------------------

:- use_module(library(xpath)).
:- use_module('../lib/files', [bump_tmp_directory_id/0]).
:- use_module(loan/process_xml_loan_request, [process_xml_loan_request/2]).
:- use_module(ledger/process_xml_ledger_request, [process_xml_ledger_request/2]).
:- use_module(livestock/process_xml_livestock_request, [process_xml_livestock_request/2]).
:- use_module(investment/process_xml_investment_request, [process_xml_investment_request/2]).
:- use_module(depreciation/process_xml_depreciation_request, [process_xml_depreciation_request/2]).
:- use_module('../lib/utils', [throw_string/1]).

% -------------------------------------------------------------------
% process_data/2
% -------------------------------------------------------------------

process_data(FileName, Path) :-
   format('Content-type: text/xml~n~n'),
   process_data1(FileName, Path).
   % writeq(DOM),
   % write(FileName),
   % write(Path).

process_data1(FileName, Path) :-
   load_xml(Path, DOM, []),
   process_xml_request(FileName, DOM).

process_data2(FileName, Path) :-
	bump_tmp_directory_id,
	process_data1(FileName, Path).
   
% -------------------------------------------------------------------
% process_xml_request/2
% -------------------------------------------------------------------

process_xml_request(FileName, DOM) :-
   (
      xpath(DOM, //reports, _)
   ->
      true
   ;
      throw_string('<reports> tag not found')
   ),
   (process_xml_loan_request(FileName, DOM) -> true;
   (process_xml_ledger_request(FileName, DOM) -> true;
   (process_xml_livestock_request(FileName, DOM) -> true;
   (process_xml_investment_request(FileName, DOM) -> true;
   (process_xml_depreciation_request(FileName, DOM) -> true))))).


% -------------------------------------------------------------------
% store_xml_document/2
% -------------------------------------------------------------------

store_xml_document(FileName, XML) :-
   open(FileName, write, Stream),
   write(Stream, XML),
   close(Stream).

:- locale_create(Locale, "en_AU.utf8", []), set_locale(Locale).

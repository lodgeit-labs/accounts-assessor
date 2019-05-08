% ===================================================================
% Project:   LodgeIT
% Module:    main.pl
% Author:    Abdus Salam and Rolf Schwitter
% Date:      2019-05-06
% ===================================================================

:- style_check([-discontiguous, -singleton]).

% :- module('main.pl', [process_data/1]).

:- use_module(library(xpath)).

:- ['helper.pl'].

:- ['process_xml_request.pl'].


%--------------------------------------------------------------------
% Load files --- needs to be turned into modules
%--------------------------------------------------------------------

% The program entry point. Run the program using swipl -s main.pl .

% Loads up calendar related predicates
:- ['./../src/days.pl'].

% Loads up predicates pertaining to hire purchase arrangements
:- ['./../src/hirepurchase.pl'].

% Loads up predicates for summarizing transactions
:- ['./../src/ledger.pl'].

% Loads up predicates pertaining to loan arrangements
:- ['./../src/loans.pl'].

% Loads up predicates pertaining to determining residency
:- ['./../src/residency.pl'].

% Loads up predicates pertaining to bank statements
:- ['./../src/statements.pl'].


% -------------------------------------------------------------------
% process_data/1
% -------------------------------------------------------------------

process_data(Data) :-
   parse_data(Data, FileName, XML),
   store_xml_document(FileName, XML),
   process_xml_document(FileName).


% -------------------------------------------------------------------
% parse_data/3
% -------------------------------------------------------------------

parse_data(Data, FileName, XML) :-
   split_header_body(Data, Header, Body), 
   extract_file_name(Header, FileName),
   extract_xml_data(Body, XML).

split_header_body(Data, Header, Body) :-
   string_chars(Data, Chars),
   append(Header, ['<', '?', x, m, l|Rest], Chars),
   Body = ['<', '?', x, m, l|Rest].

extract_file_name(Header, FileName) :-
   append(_, [f, i, l, e, n, a, m, e, '=', '"'|Rest1], Header),   
   append(Name, ['.', x, m, l, '"'|Rest2], Rest1),
   % exclude file location from the filename 
   % (for Internet Explorer/Microsoft Edge)
   (   
     memberchk('\\', Name)
     ->  
     reverse(Name, RName),
     append(RFName, ['\\'|R1], RName),
     reverse(RFName, FName)
   ;   
     FName = Name
   ),
   append(FName, ['.', x, m, l], FileNameChars),
   atomic_list_concat(FileNameChars, FileName).

extract_xml_data(Body, XMLString) :-
   reverse(Body, RBody),
   append(_, ['>'|Rest], RBody),
   reverse(['>'|Rest], XMLChars),
   string_chars(XMLString, XMLChars).


% -------------------------------------------------------------------
% store_xml_document/2
% -------------------------------------------------------------------

store_xml_document(FileName, XML) :-
   open(FileName, write, Stream),
   write(Stream, XML),
   close(Stream).


% -------------------------------------------------------------------
% process_xml_document/1
% -------------------------------------------------------------------

process_xml_document(FileName) :-
   load_xml(FileName, DOM, []),
   process_xml_request(FileName, DOM).


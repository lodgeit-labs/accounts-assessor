% The program entry point. Run the program using swipl -s main.pl .

% Loads up calendar related predicates
:- ['days.pl'].
% Loads up predicates pertaining to hire purchase arrangements
:- ['hirepurchase.pl'].
% Loads up predicates for summarizing transactions
:- ['ledger.pl'].
% Loads up predicates pertaining to loan arrangements
:- ['loans.pl'].

% Appropriate queries to type into the ensuing prompt can be found in examples
% directory.


% The program entry point. Run the program using swipl -s main.pl .

% Loads up calendar related predicates
:- ['src/days.pl'].
% Loads up predicates pertaining to hire purchase arrangements
:- ['src/hirepurchase.pl'].
% Loads up predicates for summarizing transactions
:- ['src/transactions.pl'].
% Loads up predicates pertaining to loan arrangements
:- ['src/loans.pl'].

% Appropriate queries to type into the ensuing prompt can be found in examples
% directory.


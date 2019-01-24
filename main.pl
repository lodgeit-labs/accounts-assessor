% The program entry point. Run the program using swipl -s main.pl .

% Loads up calendar related predicates
:- ['src/days.pl'].
% Loads up predicates pertaining to hire purchase arrangements
:- ['src/hirepurchase.pl'].
% Loads up a ledger for the transaction predicates to operate on
:- ['examples/ledger.pl'].
% Loads up predicates for summarizing transactions
:- ['src/transactions.pl'].

% Appropriate queries to type into the ensuing prompt can be found in examples
% directory.


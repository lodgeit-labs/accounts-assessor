:- writeln("todo: run the python stuff from prolog here").
:- ['all_prolog_tests'].
:- (run_tests, halt(0)) ; halt(1).


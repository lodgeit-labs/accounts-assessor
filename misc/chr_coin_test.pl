:- use_module(library(chr)).

:- chr_constraint coin/0, heads/0, tails/0, foo/0.

coin ==> heads.
coin ==> tails.

:- use_module(library(clpq)).
run :- {B =:= A*C}, {D =:= A + B - 50}, {63 =:= A}, !.

% bug seems to actually not trigger here but when you run this in swipl repl it returns false
% ?-  {B =:= A*C}, {D =:= A + B - 50}, {63 =:= A}.
% false
%
% it's also returned false on other examples

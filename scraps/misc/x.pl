:-  op(  1,  xfx,  [  \ ]). 
:-  op(  1,  xfx,  [  .. ]). 
c(X) :- write_canonical(user_output, X).
%:- HP=x,c(HP..total_payments = ((HP\xxx * HP\yyy) + HP\zzzzzz - HP\aaaa) * 7).
% =(\(x,total_payments),*(-(+(*(\(x,xxx),\(x,yyy)),\(x,zzzzzz)),\(x,aaaa)),7))

*(X) :- writeq(X).

:- *(a).


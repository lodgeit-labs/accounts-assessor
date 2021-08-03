/*
we will assume and ensure that range(X,Y) has X and Y always ordered such that X <= Y.
*/

/*
this file is just a little exploration into how values might be represented.
inspired by https://www.bkent.net/Doc/mdarchiv.pdf


*/


op(add(
        value(dimension(fungible), unit(Unit), range(X1,X2)),
        value(dimension(fungible), unit(Unit), range(Y1,Y2))
    ),
    value(dimension(fungible), unit(Unit), range(Z1,Z2))
) :-
    {Z1 = X1 + Y1,
    Z2 = X2 + Y2}.

...


eval(Op, Result) :- 
    op(Op,Result0),
    order_range(Result0, Result).


/*
we will assume that range(X,Y) has X and Y always ordered such that X is < or = Y.


*/




op(add(
        value(dimension(fungible), unit(Unit), range(X1,X2)),
        value(dimension(fungible), unit(Unit), range(Y1,Y2))
    ),
    value(dimension(fungible), unit(Unit), range(Z1,Z2))
) :-
    {Z1 = X1 + Y1,
    Z2 = X2 + Y2}.

op(mult(
        value(dimension(fungible), unit(Unit), range(X1,X2)),
        value(dimension(none), unit(none), range(Y1,Y2))
    ),
    value(dimension(fungible), unit(Unit), range(Z1,Z2))
) :-
    {Z1 = X1 * Y1,
    Z2 = X2 * Y2}.



eval(Op, Result) :- 
    op(Op,Result0),
    order_range(Result0, Result).


x :-     
    As = [
        (-10,-10),
        (-10,-9),
        (-10,9),
        (-1,10),
        (5,10)      
    ],
    maplist('test As1'(As), As).

'test As1'(As, A) :-
    maplist('test As2'(A), As).
    
'test As2'(B, A) :-
    Term = A * B,
    A = (Al,Au),
    B = (Bl,Bu),
    Resultl is Al * Bl,
    Resultu is Au * Bu,
    Result = (Resultl,Resultu),
    %writeq([Term,Result]),nl.
    format(user_error, '~q  =  ~q~n', [Term,Result]).
    
    
    
    


op('interval multiplication', [Al, Au] * [Bl, Bu], [Rl, Ru]) :-
    {R1 = Au * Bu},
    {R2 = Au * Bl},
    {R3 = Al * Bu},
    {R4 = Al * Bl},
    {Rl = min(R1, min(R2, min(R3, R4)))},
    {Ru = max(R1, max(R2, max(R3, R4)))}.

op('interval addition', [Al, Au] + [Bl, Bu], [Rl, Ru]) :-
    {Rl = Al + Bl},
    {Ru = Au + Bu}.

op('interval subtraction', [Al, Au] - [Bl, Bu], [Rl, Ru]) :-
    {Rl = Al - Bu},
    {Ru = Au - Bl}.


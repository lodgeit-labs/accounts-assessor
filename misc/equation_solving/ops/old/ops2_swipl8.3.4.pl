:- use_module(library(clpq)).

/*
ops2 with new syntax, same results 
*/


op('interval multiplication', (Al, Au) * (Bl, Bu) = (Rl, Ru)) :-
    {R1 = Au * Bu},
    {R2 = Au * Bl},
    {R3 = Al * Bu},
    {R4 = Al * Bl},
    {Rl = min(R1, min(R2, min(R3, R4)))},
    {Ru = max(R1, max(R2, max(R3, R4)))}.

op('interval multiplication2', Op) :-
    Op = ((Al, Au) * (Bl, Bu) = (Rl, Ru)),
    format(user_error, '~q:~n', [Op]),
    {Al * Bl = R1},
    {Al * Bu = R2},
    {Au * Bl = R3},
    {Au * Bu = R4},
    {Al =< Au},
    {Bl =< Bu},
    {Rl =< Ru},
    (
        {R1 =< R2, R1 =< R3, R1 =< R4, Rl = R1}
        ;
        {R2 =< R1, R2 =< R3, R2 =< R4, Rl = R2}
        ;
        {R3 =< R1, R3 =< R2, R3 =< R4, Rl = R3}
        ;
        {R4 =< R1, R4 =< R2, R4 =< R3, Rl = R4}
    ),
    (
        {R1 >= R2, R1 >= R3, R1 >= R4, Ru = R1}
        ;
        {R2 >= R1, R2 >= R3, R2 >= R4, Ru = R2}
        ;
        {R3 >= R1, R3 >= R2, R3 >= R4, Ru = R3}
        ;
        {R4 >= R1, R4 >= R2, R4 >= R3, Ru = R4}
    ),
    write('Rs:  '),
    write_term(R1,[attributes(portray)]),write('  '),
    write_term(R2,[attributes(portray)]),write('  '),
    write_term(R3,[attributes(portray)]),write('  '),
    write_term(R4,[attributes(portray)]),write('  '),nl.

op('interval subtraction', (Al, Au) - (Bl, Bu) = (Rl, Ru)) :-
    {Rl = Al - Bu},
    {Ru = Au - Bl}.


    
x :-     
    As = [
        (-10,-10),
        (-10,-9),
        (-10,9),
        (-1,10),
        ((-1r10),10),
        (5,10)     
    ],
    maplist('test As1'(As), As).

'test As1'(As, A) :-
    maplist('test As2'(A), As).
    
'test As2'(A, B) :-
    findall(_,('test As3'(A, B)),_),
    nl.

'test As3'(A, B) :-
    Term = (A * (Xl,Xu) = B),
    %format(user_error, '~q:~n', [Term]),
    op('interval multiplication2', Term),
    %format(user_error, '~q~n', [Term]),
    write('(Xl,Xu):'),
    write_term((Xl,Xu),[attributes(portray)]),
    nl.
    
        
        

    
%:- x.

t1 :- 'test As2'((5,10), ((-1r10), 10)).
/* i dont know how clpq comes up with Xu = 1 (wrong afaict) */

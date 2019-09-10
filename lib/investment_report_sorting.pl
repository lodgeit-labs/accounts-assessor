:- module(dict_sort, []).

run :-
    My_List = [
        _{sale:1, purchase:_{date:date(2000,1,3)}},
        _{sale:2, purchase:_{}},
        _{sale:0, purchase:_{date:date(2000,1,4)}},
        _{sale:4, purchase:_{date:date(2000,1,2)}},
        _{sale:3, purchase:_{}},
        _{sale:5, purchase:_{date:date(2000,1,2)}}
    ],
    print_term(My_List, []),
    writeln(""),
    writeln(""),

    predsort(my_pred, My_List, Sorted),
    print_term(Sorted, []),
    writeln("").

my_pred(Delta, Item1, Item2) :-
    get_date(Item1, Date1),
    get_date(Item2, Date2),
    compare(Delta, Date1, Date2).

get_date(Item, Date) :-
    (
        get_dict(purchase, Item, Purchase)
    ->
        (
            get_dict(date, Purchase, Date)
        ->
            true
        ;
            Date = date(2000,1,1)
        )
    ;
        Date = date(2000,1,1)
    ).

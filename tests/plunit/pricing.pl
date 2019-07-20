:- ['../../lib/pricing'].


:- begin_tests(pricing).

test(0) :-
	Pricing_Method = lifo,
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('AUD', 5), date(2000, 1, 1)), 
		[], Outstanding_Out),
	find_items_to_sell(Pricing_Method, 'TLS', 2, Outstanding_Out, _Outstanding_Out2, Cost_Of_Goods),
	%print_term(Cost_Of_Goods, []).
	Cost_Of_Goods = [outstanding('CZK', 'TLS', 2, value('AUD',10), date(2000, 1, 1))].
	
test(1) :-
	Pricing_Method = lifo,
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('AUD', 5), date(2000, 1, 1)), 
		[], Outstanding_Out),
	\+find_items_to_sell(Pricing_Method, 'TLS', 6, Outstanding_Out, _Outstanding_Out2, _Cost_Of_Goods).

test(2) :-
	Pricing_Method = lifo,
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('AUD', 5), date(2000, 1, 1)), 
		[], Outstanding_Out),
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('AUD', 50), date(2000, 1, 2)), 
		Outstanding_Out, Outstanding_Out2),
	find_items_to_sell(Pricing_Method, 'TLS', 6, Outstanding_Out2, _Outstanding_Out3, Cost_Of_Goods),
	%print_term(Cost_Of_Goods, []).
	Cost_Of_Goods = [outstanding('CZK', 'TLS', 5, value('AUD',25), date(2000, 1, 1)), outstanding('CZK', 'TLS', 1, value('AUD',50), date(2000, 1, 2))].
	
test(3) :-
	Pricing_Method = lifo,
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('AUD', 5), date(2000, 1, 1)), 
		[], Outstanding),
	add_bought_items(Pricing_Method, 
		outstanding('CZK', 'TLS', 5, value('USD', 5), date(2000, 1, 2)), 
		Outstanding, Outstanding2),
	find_items_to_sell(Pricing_Method, 'TLS', 6, Outstanding2, _Outstanding3, Cost_Of_Goods),
	%print_term(Cost_Of_Goods, []).
	Cost_Of_Goods = [outstanding('CZK', 'TLS', 5, value('AUD',25), date(2000, 1, 1)), outstanding('CZK', 'TLS', 1, value('USD',5), date(2000, 1, 2))].

:- end_tests(pricing).


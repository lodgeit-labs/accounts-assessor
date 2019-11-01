x :-
	Formulas = [
		stock_on_hand_at_end_of_year_count = stock_on_hand_at_beginning_of_year_count + natural_increase_count + purchases_count - killed_for_rations_count - losses_count - sales_count,
		natural_increase_value = natural_increase_count * natural_increase_value_per_head,
		opening_and_purchases_and_increase_count = stock_on_hand_at_beginning_of_year_count + purchases_count + natural_increase_count,
		opening_and_purchases_value = stock_on_hand_at_beginning_of_year_value + purchases_value,
		average_cost = (opening_and_purchases_value + natural_increase_value) /  opening_and_purchases_and_increase_count,
		stock_on_hand_at_end_of_year_value = average_cost * stock_on_hand_at_end_of_year_count,
		killed_for_rations_value = killed_for_rations_count * average_cost,
		closing_and_killed_and_sales_minus_losses_count = sales_count + killed_for_rations_count + stock_on_hand_at_end_of_year_count - losses_count,
		closing_and_killed_and_sales_value = sales_value + killed_for_rations_value + stock_on_hand_at_end_of_year_value,
		revenue = sales_value,
		livestock_cogs = opening_and_purchases_value - stock_on_hand_at_end_of_year_value - killed_for_rations_value,
		gross_profit_on_livestock_trading = revenue - livestock_cogs
	],
	print_as_ops(Formulas).

print_as_ops([H|T]) :-
%	write('op('),
	print_as_ops(H),
%	write('),'),
	nl,
	print_as_ops(T).
print_as_ops([]):-!.	

print_as_ops(X) :-
	functor(X, _, Arity),
	Arity > 0,
	write('['),
	X =.. L,
	maplist(print_as_ops, L),
	write('],').

print_as_ops(X) :-
	write('"'), write(X), write('",').	
	
:- x.

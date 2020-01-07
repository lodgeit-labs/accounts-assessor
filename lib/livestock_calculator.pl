compute_livestock_by_simple_calculation(
	Natural_increase_count_In,
	Natural_increase_value_per_head_In,
	Sales_count_In,
	Sales_value_In,
	Killed_for_rations_count_In,
	Stock_on_hand_at_beginning_of_year_count_In,
	Stock_on_hand_at_beginning_of_year_value_In,
	Stock_on_hand_at_end_of_year_count_In,
	Purchases_count_In,
	Purchases_value_In,
	Losses_count_In,
	Killed_for_rations_value_Out,
	Stock_on_hand_at_end_of_year_value_Out,
	Closing_and_killed_and_sales_minus_losses_count_Out,
	Closing_and_killed_and_sales_value_Out,
	Opening_and_purchases_and_increase_count_Out,
	Opening_and_purchases_value_Out,
	Natural_Increase_value_Out,
	Average_cost_Out,
	Revenue_Out,
	Livestock_COGS_Out,
	Gross_Profit_on_Livestock_Trading_Out,
	Explanation
	) :-
	compile_with_variable_names_preserved((
		Stock_on_hand_at_end_of_year_count = Stock_on_hand_at_beginning_of_year_count + Natural_increase_count + Purchases_count - Killed_for_rations_count - Losses_count - Sales_count,
		Natural_Increase_value = Natural_increase_count * Natural_increase_value_per_head,
		Opening_and_purchases_and_increase_count = Stock_on_hand_at_beginning_of_year_count + Purchases_count + Natural_increase_count,
		Opening_and_purchases_value = Stock_on_hand_at_beginning_of_year_value + Purchases_value,
		Average_cost_Formula = (Opening_and_purchases_value + Natural_Increase_value) /  Opening_and_purchases_and_increase_count,
		Stock_on_hand_at_end_of_year_value = Average_cost * Stock_on_hand_at_end_of_year_count,
		Killed_for_rations_value = Killed_for_rations_count * Average_cost,
		Closing_and_killed_and_sales_minus_losses_count = Sales_count + Killed_for_rations_count + Stock_on_hand_at_end_of_year_count - Losses_count,
		Closing_and_killed_and_sales_value = Sales_value + Killed_for_rations_value + Stock_on_hand_at_end_of_year_value,
		Revenue = Sales_value,
		Livestock_COGS = Opening_and_purchases_value - Stock_on_hand_at_end_of_year_value - Killed_for_rations_value,
		Gross_Profit_on_Livestock_Trading = Revenue - Livestock_COGS
	),	Names1),
	term_string(Gross_Profit_on_Livestock_Trading, Gross_Profit_on_Livestock_Trading_Formula_String, [Names1]),
	term_string(Average_cost_Formula, Average_cost_Formula_String, [Names1]),
	Natural_increase_count = Natural_increase_count_In,
	Natural_increase_value_per_head = Natural_increase_value_per_head_In,
	Sales_count = Sales_count_In,
	Sales_value = Sales_value_In,
	Killed_for_rations_count = Killed_for_rations_count_In,
	Stock_on_hand_at_beginning_of_year_count = Stock_on_hand_at_beginning_of_year_count_In,
	Stock_on_hand_at_beginning_of_year_value = Stock_on_hand_at_beginning_of_year_value_In,
	Purchases_count = Purchases_count_In,
	Purchases_value = Purchases_value_In,
	Losses_count = Losses_count_In,
	pretty_term_string(Average_cost_Formula, Average_cost_Formula_String2),
	Average_cost is Average_cost_Formula,
	pretty_term_string(Gross_Profit_on_Livestock_Trading, Gross_Profit_on_Livestock_Trading_Formula_String2),

	Killed_for_rations_value_Out
	is
	Killed_for_rations_value,
	Stock_on_hand_at_end_of_year_value_Out
	is
	Stock_on_hand_at_end_of_year_value,
	Closing_and_killed_and_sales_minus_losses_count_Out
	is
	Closing_and_killed_and_sales_minus_losses_count,
	Closing_and_killed_and_sales_value_Out
	is
	Closing_and_killed_and_sales_value,
	Opening_and_purchases_and_increase_count_Out
	is
	Opening_and_purchases_and_increase_count,
	Opening_and_purchases_value_Out is Opening_and_purchases_value,
	Natural_Increase_value_Out is Natural_Increase_value,
	Average_cost_Out is Average_cost,
	Revenue_Out is Revenue,
	Livestock_COGS_Out is Livestock_COGS,
	Gross_Profit_on_Livestock_Trading_Out is Gross_Profit_on_Livestock_Trading,
	Stock_on_hand_at_end_of_year_count_Out is Stock_on_hand_at_end_of_year_count,
	(
		(
			(Stock_on_hand_at_end_of_year_count_In = Stock_on_hand_at_end_of_year_count_Out,!)
		;
			Stock_on_hand_at_end_of_year_count_In =:= Stock_on_hand_at_end_of_year_count_Out
		)
	->
		true
	;
		throw_string(["closing count mismatch, should be:", Stock_on_hand_at_end_of_year_count_Out])
	),
	Explanation = [
		(['Gross_Profit_on_Livestock_Trading = ', Gross_Profit_on_Livestock_Trading_Formula_String]),
		(['Gross_Profit_on_Livestock_Trading = ', Gross_Profit_on_Livestock_Trading_Formula_String2]),
		(['Average_cost = ', Average_cost_Formula_String]),
		(['Average_cost = ', Average_cost_Formula_String2])
	].


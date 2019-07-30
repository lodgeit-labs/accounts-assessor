:- ['../../lib/hirepurchase'].
:- ['../../lib/days'].
:- ['../../lib/transactions'].
:- ['../../lib/pacioli'].

:- begin_tests(hirepurchase, [setup(init)]).

init :-
	write("Are we now testing the hire purchase subprogram?"),
	recorda(transactions,
		[transaction(735614, "invest in business", hp_account, coord(200.47, 0)),
		transaction(735614, "invest in business a", hp_account, coord(200.47, 0)),
		transaction(735614, "invest in business b", hp_account, coord(200.47, 0)),
		transaction(736511, "invest in business", bank, coord(100, 0)),
		transaction(736511, "invest in business", share_capital, coord(0, 100)),
		transaction(736512, "buy inventory", inventory, coord(50, 0)),
		transaction(736512, "buy inventory", accounts_payable, coord(0, 50)),
		transaction(736513, "sell inventory", accounts_receivable, coord(100, 0)),
		transaction(736513, "sell inventory", sales, coord(0, 100)),
		transaction(736513, "sell inventory", cost_of_goods_sold, coord(50, 0)),
		transaction(736513, "sell inventory", inventory, coord(0, 50)),
		transaction(736876, "pay creditor", accounts_payable, coord(50, 0)),
		transaction(736876, "pay creditor", bank, coord(0, 50)),
		transaction(737212, "buy stationary", stationary, coord(10, 0)),
		transaction(737212, "buy stationary", bank, coord(0, 10)),
		transaction(737241, "buy inventory", inventory, coord(125, 0)),
		transaction(737241, "buy inventory", accounts_payable, coord(0, 125)),
		transaction(737248, "sell inventory", accounts_receivable, coord(100, 0)),
		transaction(737248, "sell inventory", sales, coord(0, 100)),
		transaction(737248, "sell inventory", cost_of_goods_sold, coord(50, 0)),
		transaction(737248, "sell inventory", inventory, coord(0, 50)),
		transaction(737468, "payroll payrun", wages, coord(200, 0)),
		transaction(737469, "payroll payrun", super_expense, coord(19, 0)),
		transaction(737468, "payroll payrun", super_payable, coord(0, 19)),
		transaction(737468, "payroll payrun", paygw_tax, coord(0, 20)),
		transaction(737468, "payroll payrun", wages_payable, coord(0, 180)),
		transaction(737468, "pay wage liability", wages_payable, coord(180, 0)),
		transaction(737468, "pay wage liability", bank, coord(0, 180)),
		transaction(737516, "buy truck", motor_vehicles, coord(3000, 0)),
		transaction(737516, "buy truck", hirepurchase_truck, coord(0, 3000)),
		transaction(737516, "hire purchase truck repayment", hirepurchase_truck, coord(60, 0)),
		transaction(737516, "hire purchase truck repayment", bank, coord(0, 60)),
		transaction(737543, "pay 3rd qtr bas", paygw_tax, coord(20, 0)),
		transaction(737543, "pay 3rd qtr bas", bank, coord(0, 20)),
		transaction(737543, "pay super", super_payable, coord(19, 0)),
		transaction(737543, "pay super", bank, coord(0, 19)),
		transaction(737546, "hire purchase truck replacement", hirepurchase_truck, coord(41.16, 0)),
		transaction(737546, "hire purchase truck replacement", hirepurchase_interest, coord(18.84, 0)),
		transaction(737546, "hire purchase truck replacement", bank, coord(0, 60)),
		transaction(737578, "hire purchase truck replacement", hirepurchase_truck, coord(41.42, 0)),
		transaction(737579, "hire purchase truck replacement", hirepurchase_interest, coord(18.58, 0)),
		transaction(737577, "hire purchase truck replacement", bank, coord(0, 60)),
		transaction(737586, "collect accs rec", accounts_receivable, coord(0, 100)),
		transaction(737586, "collect accs rec", bank, coord(100, 0))]
	).

test(regular_schedule) :-

% Make a regular schedule of installments:
write("Is the output for the installment schedule correct?"),

findall(Installments,
	installments(date(2015, 1, 16), 100, date(0, 1, 0), 200.47, Installments),
	
	[[hp_installment(735614, 200.47), hp_installment(735645, 200.47), hp_installment(735673, 200.47), hp_installment(735704, 200.47),
		hp_installment(735734, 200.47), hp_installment(735765, 200.47), hp_installment(735795, 200.47), hp_installment(735826, 200.47),
		hp_installment(735857, 200.47), hp_installment(735887, 200.47), hp_installment(735918, 200.47), hp_installment(735948, 200.47),
		hp_installment(735979, 200.47), hp_installment(736010, 200.47), hp_installment(736039, 200.47), hp_installment(736070, 200.47),
		hp_installment(736100, 200.47), hp_installment(736131, 200.47), hp_installment(736161, 200.47), hp_installment(736192, 200.47),
		hp_installment(736223, 200.47), hp_installment(736253, 200.47), hp_installment(736284, 200.47), hp_installment(736314, 200.47),
		hp_installment(736345, 200.47), hp_installment(736376, 200.47), hp_installment(736404, 200.47), hp_installment(736435, 200.47),
		hp_installment(736465, 200.47), hp_installment(736496, 200.47), hp_installment(736526, 200.47), hp_installment(736557, 200.47),
		hp_installment(736588, 200.47), hp_installment(736618, 200.47), hp_installment(736649, 200.47), hp_installment(736679, 200.47),
		hp_installment(736710, 200.47), hp_installment(736741, 200.47), hp_installment(736769, 200.47), hp_installment(736800, 200.47),
		hp_installment(736830, 200.47), hp_installment(736861, 200.47), hp_installment(736891, 200.47), hp_installment(736922, 200.47),
		hp_installment(736953, 200.47), hp_installment(736983, 200.47), hp_installment(737014, 200.47), hp_installment(737044, 200.47),
		hp_installment(737075, 200.47), hp_installment(737106, 200.47), hp_installment(737134, 200.47), hp_installment(737165, 200.47),
		hp_installment(737195, 200.47), hp_installment(737226, 200.47), hp_installment(737256, 200.47), hp_installment(737287, 200.47),
		hp_installment(737318, 200.47), hp_installment(737348, 200.47), hp_installment(737379, 200.47), hp_installment(737409, 200.47),
		hp_installment(737440, 200.47), hp_installment(737471, 200.47), hp_installment(737500, 200.47), hp_installment(737531, 200.47),
		hp_installment(737561, 200.47), hp_installment(737592, 200.47), hp_installment(737622, 200.47), hp_installment(737653, 200.47),
		hp_installment(737684, 200.47), hp_installment(737714, 200.47), hp_installment(737745, 200.47), hp_installment(737775, 200.47),
		hp_installment(737806, 200.47), hp_installment(737837, 200.47), hp_installment(737865, 200.47), hp_installment(737896, 200.47),
		hp_installment(737926, 200.47), hp_installment(737957, 200.47), hp_installment(737987, 200.47), hp_installment(738018, 200.47),
		hp_installment(738049, 200.47), hp_installment(738079, 200.47), hp_installment(738110, 200.47), hp_installment(738140, 200.47),
		hp_installment(738171, 200.47), hp_installment(738202, 200.47), hp_installment(738230, 200.47), hp_installment(738261, 200.47),
		hp_installment(738291, 200.47), hp_installment(738322, 200.47), hp_installment(738352, 200.47), hp_installment(738383, 200.47),
		hp_installment(738414, 200.47), hp_installment(738444, 200.47), hp_installment(738475, 200.47), hp_installment(738505, 200.47),
		hp_installment(738536, 200.47), hp_installment(738567, 200.47), hp_installment(738595, 200.47), hp_installment(738626, 200.47)]]).






test(add_ballon) :-
% Add a ballon to a regular schedule of installments:
write("Is the output for the installment schedule with balloons inserted correct?"),

findall(Installments_With_Balloon,
	(installments(date(2015, 1, 16), 100, date(0, 1, 0), 200.47, Installments),
		absolute_day(date(2014, 12, 16), Balloon_Day),
		insert_balloon(hp_installment(Balloon_Day, 1000), Installments, Installments_With_Balloon)),
		
	[[hp_installment(735583, 1000), hp_installment(735614, 200.47), hp_installment(735645, 200.47), hp_installment(735673, 200.47),
/*?*/		hp_installment(735704, 200.47), hp_installment(735734, 200.47), hp_installment(735765, 200.47), hp_installment(735795, 200.47),
		hp_installment(735826, 200.47), hp_installment(735857, 200.47), hp_installment(735887, 200.47), hp_installment(735918, 200.47),
		hp_installment(735948, 200.47), hp_installment(735979, 200.47), hp_installment(736010, 200.47), hp_installment(736039, 200.47),
		hp_installment(736070, 200.47), hp_installment(736100, 200.47), hp_installment(736131, 200.47), hp_installment(736161, 200.47),
		hp_installment(736192, 200.47), hp_installment(736223, 200.47), hp_installment(736253, 200.47), hp_installment(736284, 200.47),
		hp_installment(736314, 200.47), hp_installment(736345, 200.47), hp_installment(736376, 200.47), hp_installment(736404, 200.47),
		hp_installment(736435, 200.47), hp_installment(736465, 200.47), hp_installment(736496, 200.47), hp_installment(736526, 200.47),
		hp_installment(736557, 200.47), hp_installment(736588, 200.47), hp_installment(736618, 200.47), hp_installment(736649, 200.47),
		hp_installment(736679, 200.47), hp_installment(736710, 200.47), hp_installment(736741, 200.47), hp_installment(736769, 200.47),
		hp_installment(736800, 200.47), hp_installment(736830, 200.47), hp_installment(736861, 200.47), hp_installment(736891, 200.47),
		hp_installment(736922, 200.47), hp_installment(736953, 200.47), hp_installment(736983, 200.47), hp_installment(737014, 200.47),
		hp_installment(737044, 200.47), hp_installment(737075, 200.47), hp_installment(737106, 200.47), hp_installment(737134, 200.47),
		hp_installment(737165, 200.47), hp_installment(737195, 200.47), hp_installment(737226, 200.47), hp_installment(737256, 200.47),
		hp_installment(737287, 200.47), hp_installment(737318, 200.47), hp_installment(737348, 200.47), hp_installment(737379, 200.47),
		hp_installment(737409, 200.47), hp_installment(737440, 200.47), hp_installment(737471, 200.47), hp_installment(737500, 200.47),
		hp_installment(737531, 200.47), hp_installment(737561, 200.47), hp_installment(737592, 200.47), hp_installment(737622, 200.47),
		hp_installment(737653, 200.47), hp_installment(737684, 200.47), hp_installment(737714, 200.47), hp_installment(737745, 200.47),
		hp_installment(737775, 200.47), hp_installment(737806, 200.47), hp_installment(737837, 200.47), hp_installment(737865, 200.47),
		hp_installment(737896, 200.47), hp_installment(737926, 200.47), hp_installment(737957, 200.47), hp_installment(737987, 200.47),
		hp_installment(738018, 200.47), hp_installment(738049, 200.47), hp_installment(738079, 200.47), hp_installment(738110, 200.47),
		hp_installment(738140, 200.47), hp_installment(738171, 200.47), hp_installment(738202, 200.47), hp_installment(738230, 200.47),
		hp_installment(738261, 200.47), hp_installment(738291, 200.47), hp_installment(738322, 200.47), hp_installment(738352, 200.47),
		hp_installment(738383, 200.47), hp_installment(738414, 200.47), hp_installment(738444, 200.47), hp_installment(738475, 200.47),
		hp_installment(738505, 200.47), hp_installment(738536, 200.47), hp_installment(738567, 200.47), hp_installment(738595, 200.47),
		hp_installment(738626, 200.47)]]).



% What is the total amount the customer will pay over the course of the hire purchase
% arrangement?
test(total_pay) :-
write("Is the output for the total payment in hire purchase arrangement correct?"),

findall(Total_Payment,
	(absolute_day(date(2014, 12, 16), Begin_Day),
		installments(date(2015, 1, 16), 36, date(0, 1, 0), 200.47, Installments),
		hp_arr_total_payment_from(hp_arrangement(0, 5953.2, Begin_Day, 13, Installments), Begin_Day, Total_Payment)),
		
	[7216.920000000002]).









% What is the total interest the customer will pay over the course of the hire purchase
% arrangement?
test(total_interest) :-
write("Is the output for the total interest payment in hire purchase arrangement correct?"),

findall(Total_Interest,
	(absolute_day(date(2014, 12, 16), Begin_Day),
		installments(date(2015, 1, 16), 36, date(0, 1, 0), 200.47, Installments),
		hp_arr_total_interest_from(hp_arrangement(0, 5953.2, Begin_Day, 13, Installments), Begin_Day, Total_Interest)),
		
	[1268.8307569608373]).







% Give me all the records of a hire purchase arrangement:
test(all_records) :-
write("Is the output for the records of a hire purchase arrangement correct?"),

findall(Record,
	(absolute_day(date(2014, 12, 16), Begin_Day),
		installments(date(2015, 1, 16), 36, date(0, 1, 0), 200.47, Installments),
		hp_arr_record(hp_arrangement(0, 5953.2, Begin_Day, 13, Installments), Record)),
		
	[hp_record(1, 5953.2, 13, 64.493, 200.47, 5817.223, 735583, 735614),
		hp_record(2, 5817.223, 13, 63.01991583333333, 200.47, 5679.772915833333, 735614, 735645),
		hp_record(3, 5679.772915833333, 13, 61.530873254861106, 200.47, 5540.833789088194, 735645, 735673),
		hp_record(4, 5540.833789088194, 13, 60.02569938178876, 200.47, 5400.389488469982, 735673, 735704),
		hp_record(5, 5400.389488469982, 13, 58.50421945842481, 200.47, 5258.423707928407, 735704, 735734),
		hp_record(6, 5258.423707928407, 13, 56.96625683589107, 200.47, 5114.919964764297, 735734, 735765),
		hp_record(7, 5114.919964764297, 13, 55.41163295161322, 200.47, 4969.86159771591, 735765, 735795),
		hp_record(8, 4969.86159771591, 13, 53.84016730858902, 200.47, 4823.231765024499, 735795, 735826),
		hp_record(9, 4823.231765024499, 13, 52.25167745443206, 200.47, 4675.01344247893, 735826, 735857),
		hp_record(10, 4675.01344247893, 13, 50.6459789601884, 200.47, 4525.189421439119, 735857, 735887),
		hp_record(11, 4525.189421439119, 13, 49.02288539892378, 200.47, 4373.742306838042, 735887, 735918),
		hp_record(12, 4373.742306838042, 13, 47.38220832407878, 200.47, 4220.65451516212, 735918, 735948),
		hp_record(13, 4220.65451516212, 13, 45.72375724758964, 200.47, 4065.90827240971, 735948, 735979),
		hp_record(14, 4065.90827240971, 13, 44.04733961777186, 200.47, 3909.485612027482, 735979, 736010),
		hp_record(15, 3909.485612027482, 13, 42.35276079696438, 200.47, 3751.368372824447, 736010, 736039),
		hp_record(16, 3751.368372824447, 13, 40.63982403893151, 200.47, 3591.5381968633787, 736039, 736070),
		hp_record(17, 3591.5381968633787, 13, 38.90833046601993, 200.47, 3429.976527329399, 736070, 736100),
		hp_record(18, 3429.976527329399, 13, 37.15807904606848, 200.47, 3266.6646063754674, 736100, 736131),
		hp_record(19, 3266.6646063754674, 13, 35.38886656906757, 200.47, 3101.583472944535, 736131, 736161),
		hp_record(20, 3101.583472944535, 13, 33.6004876235658, 200.47, 2934.713960568101, 736161, 736192),
		hp_record(21, 2934.713960568101, 13, 31.79273457282109, 200.47, 2766.0366951409223, 736192, 736223),
		hp_record(22, 2766.0366951409223, 13, 29.965397530693323, 200.47, 2595.532092671616, 736223, 736253),
		hp_record(23, 2595.532092671616, 13, 28.118264337275836, 200.47, 2423.180357008892, 736253, 736284),
		hp_record(24, 2423.180357008892, 13, 26.251120534262995, 200.47, 2248.961477543155, 736284, 736314),
		hp_record(25, 2248.961477543155, 13, 24.363749340050845, 200.47, 2072.855226883206, 736314, 736345),
		hp_record(26, 2072.855226883206, 13, 22.455931624568063, 200.47, 1894.841158507774, 736345, 736376),
		hp_record(27, 1894.841158507774, 13, 20.527445883834215, 200.47, 1714.8986043916082, 736376, 736404),
		hp_record(28, 1714.8986043916082, 13, 18.57806821424242, 200.47, 1533.0066726058506, 736404, 736435),
		hp_record(29, 1533.0066726058506, 13, 16.60757228656338, 200.47, 1349.144244892414, 736435, 736465),
		hp_record(30, 1349.144244892414, 13, 14.615729319667816, 200.47, 1163.2899742120817, 736465, 736496),
		hp_record(31, 1163.2899742120817, 13, 12.602308053964219, 200.47, 975.4222822660458, 736496, 736526),
		hp_record(32, 975.4222822660458, 13, 10.56707472454883, 200.47, 785.5193569905946, 736526, 736557),
		hp_record(33, 785.5193569905946, 13, 8.509793034064774, 200.47, 593.5591500246593, 736557, 736588),
		hp_record(34, 593.5591500246593, 13, 6.430224125267142, 200.47, 399.5193741499264, 736588, 736618),
		hp_record(35, 399.5193741499264, 13, 4.328126553290869, 200.47, 203.3775007032173, 736618, 736649),
		hp_record(36, 203.3775007032173, 13, 2.2032562576181873, 200.47, 5.110756960835488, 736649, 736679)]).


















% Present a hire purchase arrangement as it would appear in a financial statement
test(financial_statement) :-
	write("Is the output for the summary of a hire purchase arrangement correct?"),
	findall(
		Statement,
		(	
			absolute_day(date(2018, 6, 30), Arr_Beg_Day),
			Insts_Beg_Date = date(2018, 7, 31),
			absolute_day(Insts_Beg_Date, Insts_Beg_Day),
			installments(Insts_Beg_Date, 36, date(0, 1, 0), 636.06, Insts),
			hp_arr_report(hp_arrangement(0, 12703.32, Arr_Beg_Day, 5.53, Insts), Insts_Beg_Day,
				Cur_Liability, Cur_Unexpired_Interest, Non_Cur_Liability, Non_Cur_Unexpired_Interest),
			Statement = [Cur_Liability, Cur_Unexpired_Interest, Non_Cur_Liability, Non_Cur_Unexpired_Interest]
		),
		Results
	),
	writeln('got:'),
	writeln(Results),
	writeln('expected:'),
	Expected = [[coord(0, 7632.7199999999975), coord(524.114832611094, 0), coord(0, 5724.539999999999), coord(129.69950314096081, 0)]],
	writeln(Expected),
	Results = Expected,
	writeln(okies).




% Split the range between 10 and 20 into 100 equally spaced intervals and give me their
% boundaries:
test(split_range_equally) :-
write("Is the output for a range subdivision correct?"),

findall(X, range(10, 20, 0.1, X),

	[10, 10.1, 10.2, 10.299999999999999, 10.399999999999999, 10.499999999999998, 10.599999999999998, 10.699999999999998,
		10.799999999999997, 10.899999999999997, 10.999999999999996, 11.099999999999996, 11.199999999999996, 11.299999999999995,
		11.399999999999995, 11.499999999999995, 11.599999999999994, 11.699999999999994, 11.799999999999994, 11.899999999999993,
		11.999999999999993, 12.099999999999993, 12.199999999999992, 12.299999999999992, 12.399999999999991, 12.499999999999991,
		12.59999999999999, 12.69999999999999, 12.79999999999999, 12.89999999999999, 12.99999999999999, 13.099999999999989,
		13.199999999999989, 13.299999999999988, 13.399999999999988, 13.499999999999988, 13.599999999999987, 13.699999999999987,
		13.799999999999986, 13.899999999999986, 13.999999999999986, 14.099999999999985, 14.199999999999985, 14.299999999999985,
		14.399999999999984, 14.499999999999984, 14.599999999999984, 14.699999999999983, 14.799999999999983, 14.899999999999983,
		14.999999999999982, 15.099999999999982, 15.199999999999982, 15.299999999999981, 15.39999999999998, 15.49999999999998,
		15.59999999999998, 15.69999999999998, 15.79999999999998, 15.899999999999979, 15.999999999999979, 16.09999999999998,
		16.19999999999998, 16.299999999999983, 16.399999999999984, 16.499999999999986, 16.599999999999987, 16.69999999999999,
		16.79999999999999, 16.89999999999999, 16.999999999999993, 17.099999999999994, 17.199999999999996, 17.299999999999997,
		17.4, 17.5, 17.6, 17.700000000000003, 17.800000000000004, 17.900000000000006, 18.000000000000007, 18.10000000000001,
		18.20000000000001, 18.30000000000001, 18.400000000000013, 18.500000000000014, 18.600000000000016, 18.700000000000017,
		18.80000000000002, 18.90000000000002, 19.00000000000002, 19.100000000000023, 19.200000000000024, 19.300000000000026,
		19.400000000000027, 19.50000000000003, 19.60000000000003, 19.70000000000003, 19.800000000000033, 19.900000000000034]).













% Give me the interest rates in the range of 10% to 20% that will cause the hire purchase
% arrangement to conclude in exactly 36 months:
test(interest_rates) :-
write("Is the output for the interest rates that cause a hire purchase arrangement to have a certain duration correct?"),

findall(Interest_Rate,
	(range(10, 20, 0.1, Interest_Rate),
		absolute_day(date(2014, 12, 16), Begin_Day),
		installments(date(2015, 1, 16), 100, date(0, 1, 0), 200.47, Installments),
		hp_arr_record_count(hp_arrangement(0, 5953.2, Begin_Day, Interest_Rate, Installments), 36)),
		
	[11.399999999999995, 11.499999999999995, 11.599999999999994, 11.699999999999994, 11.799999999999994, 11.899999999999993,
		11.999999999999993, 12.099999999999993, 12.199999999999992, 12.299999999999992, 12.399999999999991, 12.499999999999991,
		12.59999999999999, 12.69999999999999, 12.79999999999999, 12.89999999999999]).




























% Note that several to different interest rates can result in hire purchase
% arrangements with the same duration. In this case, it is only the closing balance
% after the last installment that changes.

% The ledger has erroneous transactions: its second and third transactions are duplicates
% of the first, can we make some correctional transactions to undo the payments to the
% hire purchase account and put them into the hire purchase suspense account. Also
% none of the installments other than the first were paid, can we make some correctional
% transactions to debit the hire purchase account and credit the hire purchase suspense
% account?
test(closing_balance, [fixme(its_broken)]) :-
write("Are the outputed corrections to the general ledger correct?"),

findall(
	Correction_Transactions,
	(
		recorded(transactions, Transactions),
		absolute_day(date(2014, 12, 16), Begin_Day),
		installments(date(2015, 1, 16), 36, date(0, 1, 0), 200.47, Installments),
		hp_arr_corrections(hp_arrangement(0, 5953.2, Begin_Day, 13, Installments),
			hp_account, hp_suspense_account, Transactions, Correction_Transactions)
	),
	Results
),
writeln('actual results'),
print_term(Results, []),

Expected_Results = 
	[[% Undo the first duplicate transaction in the hire purchase account
		transaction(0, correction, hp_account, coord(0, 200.47)),
		% Put the amount in the hire purchase suspense account
		transaction(0, correction, hp_suspense_account, coord(200.47, 0)),
		% ...
		transaction(0, correction, hp_account, coord(0, 200.47)), transaction(0, correction, hp_suspense_account, coord(200.47, 0)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47)),
		transaction(0, correction, hp_account, coord(200.47, 0)), transaction(0, correction, hp_suspense_account, coord(0, 200.47))]],
writeln('expected results'),
print_term(Expected_Results, []),

Results = Expected_Results.

/*
< actual results
< [ [ transaction(0,correction,hp_account,coord(200.47,0)),
<     transaction(0,correction,hp_suspense_account,coord(0,200.47)),
---
> expected results
> [ [ transaction(0,correction,hp_account,coord(0,200.47)),
>     transaction(0,correction,hp_suspense_account,coord(200.47,0)),
>     transaction(0,correction,hp_account,coord(0,200.47)),
>     transaction(0,correction,hp_suspense_account,coord(200.47,0)),
*/

:- end_tests(hirepurchase).

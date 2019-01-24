% Add a ballon to a regular schedule of installments:
installments(date(2015, 1, 16), 100, date(0, 1, 0), 200.47, Installments),
absolute_day(date(2014, 12, 16), Balloon_Day),
insert_balloon(hp_installment(Balloon_Day, 1000), Installments, Installments_With_Balloon).
% Result:
% Installments = [hp_installment(5494, 200.47), hp_installment(5525, 200.47), hp_installment(5553, 200.47), ...|...],
% Balloon_Day = 5463,
% Installments_With_Balloon = [hp_installment(5463, 1000), hp_installment(5494, 200.47), hp_installment(5525, 200.47), ...|...]

% What is the total amount the customer will pay over the course of the hire purchase
% arrangement?
absolute_day(date(2014, 12, 16), Begin_Day),
installments(date(2015, 1, 16), 36, date(0, 1, 0), 200.47, Installments),
hp_arr_total_payment(hp_arrangement(0, 5953.2, Begin_Day, 13, 1, Installments), Total_Payment).
% Result: Total_Payment = 7216.920000000002.

% What is the total interest the customer will pay over the course of the hire purchase
% arrangement?
absolute_day(date(2014, 12, 16), Begin_Day),
installments(date(2015, 1, 16), 36, date(0, 1, 0), 200.47, Installments),
hp_arr_total_interest(hp_arrangement(0, 5953.2, Begin_Day, 13, 1, Installments), Total_Interest).
% Result: Total_Interest = 1269.925914056732.

% Give me all the records of a hire purchase arrangement:
absolute_day(date(2014, 12, 16), Begin_Day),
installments(date(2015, 1, 16), 36, date(0, 1, 0), 200.47, Installments),
hp_arr_record(hp_arrangement(0, 5953.2, Begin_Day, 13, 1, Installments), Record).
% Result:
% Record = hp_record(1, 5953.2, 13, 65.7298520547945, 200.47, 5818.459852054794) ;
% Record = hp_record(2, 5818.459852054794, 13, 64.24217316104335, 200.47, 5682.232025215837) ;
% ...
% Record = hp_record(36, 204.4909423440125, 13, 2.184971712716846, 200.47, 6.205914056729341) ;

% Split the range between 10 and 20 into 100 equally spaced intervals and give me their
% boundaries:
range(10, 20, 0.1, X).
% Result:
% X = 10 ;
% X = 10.1 ;
% X = 10.2 ;
% ...
% X = 19.900000000000034 ;

% Give me the interest rates in the range of 10% to 20% that will cause the hire purchase
% arrangement to conclude in exactly 36 months:
range(10, 20, 0.1, Interest_Rate),
absolute_day(date(2014, 12, 16), Begin_Day),
installments(date(2015, 1, 16), 100, date(0, 1, 0), 200.47, Installments),
hp_arr_record_count(hp_arrangement(0, 5953.2, Begin_Day, Interest_Rate, 1, Installments), 36).
% Result:
% Interest_Rate = 12.99999999999999 ;
% Interest_Rate = 13.099999999999989 ;
% ...
% Interest_Rate = 14.399999999999984 ;
% Note that several to different interest rates can result in hire purchase
% arrangements with the same duration. In this case, it is only the closing balance
% after the last installment that changes.


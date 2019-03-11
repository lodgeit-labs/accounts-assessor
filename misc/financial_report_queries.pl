% Bind the following fact to test_fact
recorda(test_fact, fact(
	[aspect('Report Entity', "http://regulator.gov/id#1234567890"),
		aspect('Period', date(2010, 12, 31)),
		aspect('Concept', 'Finished Goods'),
		aspect('Legal Entity', 'Consolidated Entity')],
	600000, usd, 1000)).

% What is the value of test_fact?
recorded(test_fact, Test_Fact), fact_value(Test_Fact, Value).
% Value = 600000.

% What is the unit of test_fact?
recorded(test_fact, Test_Fact), fact_unit(Test_Fact, Unit).
% Unit = usd.

% What is the rounding of test_fact?
recorded(test_fact, Test_Fact), fact_rounding(Test_Fact, Rounding).
% Rounding = 1000.

% What are the aspects of of test_fact?
recorded(test_fact, Test_Fact), fact_aspects(Test_Fact, Apects), member(Aspect, Apects),
	aspect_type(Aspect, Type), aspect_description(Aspect, Description).
% Type = 'Report Entity', Description = "http://regulator.gov/id#1234567890" ;
% Type = 'Period', Description = date(2010, 12, 31) ;
% Type = 'Concept', Description = 'Finished Goods' ;
% Type = 'Legal Entity', Description = 'Consolidated Entity'.

% Bind the following fact_set to test_fact

recorda(fact_set,
	[
		fact(
			[	aspect(report_entity, "http://regulator.gov/id#1234567890"),
				aspect(period, date(2010, 12, 31)),
				aspect(concept, gaap_finished_goods),
				aspect(legal_entity, gaap_consolidated_entity)],
			600000, usd, 1000, []),
		fact(
			[aspect(report_entity, "http://regulator.gov/id#1234567890"),
				aspect(period, date(2009, 12, 31)),
				aspect(concept, gaap_finished_goods),
				aspect(legal_entity, gaap_consolidated_entity)],
			600000, usd, 1000, []),
		fact(
			[aspect(report_entity, "http://regulator.gov/id#1234567890"),
				aspect(period, date(2010, 12, 31)),
				aspect(concept, gaap_work_in_progress),
				aspect(legal_entity, gaap_consolidated_entity)],
			300000, usd, 1000, []),
		fact(
			[aspect(report_entity, "http://regulator.gov/id#1234567890"),
				aspect(period, date(2009, 12, 31)),
				aspect(concept, gaap_work_in_progress),
				aspect(legal_entity, gaap_consolidated_entity)],
			300000, usd, 1000, []),
		fact(
			[aspect(report_entity, "http://regulator.gov/id#1234567890"),
				aspect(period, date(2010, 12, 31)),
				aspect(concept, gaap_raw_material),
				aspect(legal_entity, gaap_consolidated_entity)],
			100000, usd, 1000, []),
		fact(
			[aspect(report_entity, "http://regulator.gov/id#1234567890"),
				aspect(period, date(2009, 12, 31)),
				aspect(concept, gaap_raw_material),
				aspect(legal_entity, gaap_consolidated_entity)],
			100000, usd, 1000, []),
		fact(
			[aspect(report_entity, "http://regulator.gov/id#1234567890"),
				aspect(period, date(2010, 12, 31)),
				aspect(concept, gaap_inventory),
				aspect(legal_entity, gaap_consolidated_entity)],
			1000000, usd, 1000, []),
		fact(
			[aspect(report_entity, "http://regulator.gov/id#1234567890"),
				aspect(period, date(2009, 12, 31)),
				aspect(concept, gaap_inventory),
				aspect(legal_entity, gaap_consolidated_entity)],
			1000000, usd, 1000, [])
	]
).

% Bind the following information model to info_model

recorda(info_model,
	[info("Inventory", line_items, none, none, gaap_inventory, none),
	info("Finished Good", monetary, as_of, debit, gaap_finished_goods, gaap_inventory),
	info("Work in Progress", monetary, as_of, debit, gaap_work_in_progress, gaap_inventory),
	info("Raw Material", monetary, as_of, debit, gaap_raw_material, gaap_inventory)]).

% Make a table of the fact set fact_set with its top-level headings being aspects of type
% report_entity, second-level headings being aspects of type legal_entity, third level
% headings being aspects of type period, and fourth level headings being aspects of type
% concept.

recorded(fact_set, Fact_Set), table([report_entity, legal_entity, period, concept], Fact_Set, Table).

% Table =
%	[ (aspect(report_entity, "http://regulator.gov/id#1234567890"),
%	[ (aspect(legal_entity, gaap_consolidated_entity),
%	[ (aspect(period, date(2010, 12, 31)),
%			[ (aspect(concept, gaap_finished_goods), [fact([], 600000, usd, 1000, [])]),
%			(aspect(concept, gaap_work_in_progress), [fact([], 300000, usd, 1000, [])]),
%			(aspect(concept, gaap_raw_material), [fact([], 100000, usd, 1000, [])]),
%			(aspect(concept, gaap_inventory), [fact([], 1000000, usd, 1000, [])])]),
%	(aspect(period, date(2009, 12, 31)),
%			[ (aspect(concept, gaap_finished_goods), [fact([], 600000, usd, 1000, [])]),
%			(aspect(concept, gaap_work_in_progress), [fact([], 300000, usd, 1000, [])]),
%			(aspect(concept, gaap_raw_material), [fact([], 100000, usd, 1000, [])]),
%			(aspect(concept, gaap_inventory), [fact([], 1000000, usd, 1000, [])])])])])]

% Derive what the fact value for the given fact should be with respect to the fact set
% and information model. It does this by summing the fact values of the facts whose
% concept aspect are members of the concept aspect of this fact.

recorded(fact_set, Fact_Set), recorded(info_model, Info_Model),
	fact_total_value(Fact_Set, Info_Model,
		fact(
			[aspect(report_entity, "http://regulator.gov/id#1234567890"),
				aspect(period, date(2010, 12, 31)),
				aspect(concept, gaap_inventory),
				aspect(legal_entity, gaap_consolidated_entity)],
			1000000, usd, 1000, []), Total_Value).

% Total_Value = 1000000.

% Does the fact value of the given fact equal the value derived using the information
% model?

recorded(fact_set, Fact_Set), recorded(info_model, Info_Model),
	value_equals_total(Fact_Set, Info_Model,
		fact(
			[aspect(report_entity, "http://regulator.gov/id#1234567890"),
				aspect(period, date(2010, 12, 31)),
				aspect(concept, gaap_inventory),
				aspect(legal_entity, gaap_consolidated_entity)],
			1500000, usd, 1000, [])).

% false.
% (This is because the fact value of 1500000 is not equal to 1000000.)

% What is the value of test_fact?
recorded(fact_set, [Test_Fact | _]), fact_value(Test_Fact, Value).
% Value = 600000.

% What is the unit of test_fact?
recorded(fact_set, [Test_Fact | _]), fact_unit(Test_Fact, Unit).
% Unit = usd.

% What is the rounding of test_fact?
recorded(fact_set, [Test_Fact | _]), fact_rounding(Test_Fact, Rounding).
% Rounding = 1000.

% What are the aspects of of test_fact?
recorded(fact_set, [Test_Fact | _]), fact_aspects(Test_Fact, Apects), member(Aspect, Apects),
	aspect_type(Aspect, Type), aspect_description(Aspect, Description).
% Type = report_entity, Description = "http://regulator.gov/id#1234567890" ;
% Type = period, Description = date(2010, 12, 31) ;
% Type = concept, Description = gaap_finished_goods ;
% Type = legal_entity, Description = gaap_consolidated_entity.


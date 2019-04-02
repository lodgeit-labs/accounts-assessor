% The elements of the RollUp taxonomy

recorda(elements,
  [element('pattern_BuildingsNet', 'BuildingsNet'),
  element('pattern_ComputerEquipmentNet', 'ComputerEquipmentNet'),
  element('pattern_FurnitureAndFixturesNet', 'FurnitureAndFixturesNet'),
  element('pattern_Land', 'Land'),
  element('pattern_OtherPropertyPlantAndEquipmentNet', 'OtherPropertyPlantAndEquipmentNet'),
  element('pattern_PropertyPlantAndEquipmentByComponentLineItems', 'PropertyPlantAndEquipmentByComponentLineItems'),
  element('pattern_PropertyPlantAndEquipmentNet', 'PropertyPlantAndEquipmentNet'),
  element('pattern_PropertyPlantAndEquipmentNetRollUp', 'PropertyPlantAndEquipmentNetRollUp'),
  element('pattern_PropertyPlantEquipmentByComponentTable', 'PropertyPlantEquipmentByComponentTable'),
  element('pattern_SampleCompanyMember', 'SampleCompanyMember'),
  element('frm_ConsolidatedEntityMember', 'ConsolidatedEntityMember'),
  element('frm_LegalEntityAxis', 'LegalEntityAxis')]).

% The labels for the RollUp taxonomy

recorda(labels,
  [label('pattern_BuildingsNet_lbl', 'documentation', "Etiam ipsum orci, gravida nec, feugiat ut, malesuada quis, mauris. Etiam porttitor. Ut venenatis, velit a accumsan interdum, odio metus mollis mauris, non pharetra augue arcu eu felis."),
  label('pattern_BuildingsNet_lbl', 'label', "Buildings, Net"),
  label('pattern_ComputerEquipmentNet_lbl', 'documentation', "Suspendisse vestibulum augue eu justo. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas."),
  label('pattern_ComputerEquipmentNet_lbl', 'label', "Computer Equipment, Net"),
  label('pattern_FurnitureAndFixturesNet_lbl', 'documentation', "Praesent eleifend dignissim eros. Proin feugiat lobortis mi. Nunc congue. Fusce venenatis."),
  label('pattern_FurnitureAndFixturesNet_lbl', 'label', "Furniture and Fixtures, Net"),
  label('pattern_Land_lbl', 'documentation', "Sed eu nibh. Fusce vitae mi. Sed dapibus venenatis ipsum. Sed in purus. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos hymenaeos."),
  label('pattern_Land_lbl', 'periodEndLabel', "Land, Ending Balance"),
  label('pattern_Land_lbl', 'periodStartLabel', "Land, Beginning Balance"),
  label('pattern_Land_lbl', 'label', "Land"),
  label('pattern_OtherPropertyPlantAndEquipmentNet_lbl', 'documentation', "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Praesent id mauris. Sed dapibus dui quis lectus. Donec id sem."),
  label('pattern_OtherPropertyPlantAndEquipmentNet_lbl', 'label', "Other Property, Plant and Equipment, Net"),
  label('pattern_PropertyPlantAndEquipmentByComponentLineItems_lbl', 'documentation', "Proin elit sem, ornare non, ullamcorper vel, sollicitudin a, lacus. Mauris tincidunt cursus est."),
  label('pattern_PropertyPlantAndEquipmentByComponentLineItems_lbl', 'label', "Property, Plant and Equipment, by Component [Line Items]"),
  label('pattern_PropertyPlantAndEquipmentNetRollUp_lbl', 'documentation', "Praesent fringilla feugiat magna. Suspendisse et lorem eu risus convallis placerat."),
  label('pattern_PropertyPlantAndEquipmentNetRollUp_lbl', 'label', "Property, Plant and Equipment, Net [Roll Up]"),
  label('pattern_PropertyPlantAndEquipmentNet_lbl', 'documentation', "Duis fermentum. Nullam dui orci, scelerisque porttitor, volutpat a, porttitor a, enim. Sed lobortis."),
  label('pattern_PropertyPlantAndEquipmentNet_lbl', 'label', "Property, Plant and Equipment, Net"),
  label('pattern_PropertyPlantAndEquipmentNet_lbl', 'totalLabel', "Property, Plant and Equipment, Net, Total"),
  label('pattern_PropertyPlantEquipmentByComponentTable_lbl', 'documentation', "Nam rhoncus mi. Nunc eu dui non mauris interdum tincidunt. Sed magna felis, accumsan a, fermentum quis, varius sed, ipsum."),
  label('pattern_PropertyPlantEquipmentByComponentTable_lbl', 'label', "Property, Plant and Equipment, by Component [Table]"),
  label('pattern_SampleCompanyMember_lbl', 'label', "Sample Company [Member]")]).

% The links between the labels and elements of the RollUp taxonomy

recorda(label_arcs,
  [label_arc('concept-label', 'pattern_BuildingsNet', 'pattern_BuildingsNet_lbl'),
  label_arc('concept-label', 'pattern_ComputerEquipmentNet', 'pattern_ComputerEquipmentNet_lbl'),
  label_arc('concept-label', 'pattern_FurnitureAndFixturesNet', 'pattern_FurnitureAndFixturesNet_lbl'),
  label_arc('concept-label', 'pattern_Land', 'pattern_Land_lbl'),
  label_arc('concept-label', 'pattern_OtherPropertyPlantAndEquipmentNet', 'pattern_OtherPropertyPlantAndEquipmentNet_lbl'),
  label_arc('concept-label', 'pattern_PropertyPlantAndEquipmentByComponentLineItems', 'pattern_PropertyPlantAndEquipmentByComponentLineItems_lbl'),
  label_arc('concept-label', 'pattern_PropertyPlantAndEquipmentNetRollUp', 'pattern_PropertyPlantAndEquipmentNetRollUp_lbl'),
  label_arc('concept-label', 'pattern_PropertyPlantAndEquipmentNet', 'pattern_PropertyPlantAndEquipmentNet_lbl'),
  label_arc('concept-label', 'pattern_PropertyPlantEquipmentByComponentTable', 'pattern_PropertyPlantEquipmentByComponentTable_lbl'),
  label_arc('concept-label', 'pattern_SampleCompanyMember', 'pattern_SampleCompanyMember_lbl')]).

% The hierarchy of the elements of the RollUp taxonomy

recorda(presentation_arcs,
  [presentation_arc('parent-child', 'pattern_PropertyPlantEquipmentByComponentTable', 'frm_LegalEntityAxis'),
  presentation_arc('parent-child', 'frm_LegalEntityAxis', 'frm_ConsolidatedEntityMember'),
  presentation_arc('parent-child', 'pattern_PropertyPlantEquipmentByComponentTable', 'pattern_PropertyPlantAndEquipmentByComponentLineItems'),
  presentation_arc('parent-child', 'pattern_PropertyPlantAndEquipmentByComponentLineItems', 'pattern_PropertyPlantAndEquipmentNetRollUp'),
  presentation_arc('parent-child', 'pattern_PropertyPlantAndEquipmentNetRollUp', 'pattern_Land'),
  presentation_arc('parent-child', 'pattern_PropertyPlantAndEquipmentNetRollUp', 'pattern_BuildingsNet'),
  presentation_arc('parent-child', 'pattern_PropertyPlantAndEquipmentNetRollUp', 'pattern_FurnitureAndFixturesNet'),
  presentation_arc('parent-child', 'pattern_PropertyPlantAndEquipmentNetRollUp', 'pattern_ComputerEquipmentNet'),
  presentation_arc('parent-child', 'pattern_PropertyPlantAndEquipmentNetRollUp', 'pattern_OtherPropertyPlantAndEquipmentNet'),
  presentation_arc('parent-child', 'pattern_PropertyPlantAndEquipmentNetRollUp', 'pattern_PropertyPlantAndEquipmentNet')]).

% Attachments between variables and assertions using the given names

recorda(variable_arcs,
  [variable_arc('variable-set', 'ASSERTION', 'VARIABLE_Concept', 'VARIABLE_Concept'),
  variable_arc('variable-set', 'ASSERTION', 'VARIABLE_Total', 'PropertyPlantAndEquipmentNet'),
  variable_arc('variable-set', 'ASSERTION', 'VARIABLE_A', 'Land'),
  variable_arc('variable-set', 'ASSERTION', 'VARIABLE_B', 'BuildingsNet'),
  variable_arc('variable-set', 'ASSERTION', 'VARIABLE_C', 'FurnitureAndFixturesNet'),
  variable_arc('variable-set', 'ASSERTION', 'VARIABLE_D', 'ComputerEquipmentNet'),
  variable_arc('variable-set', 'ASSERTION', 'VARIABLE_E', 'OtherPropertyPlantAndEquipmentNet')]).

% Variable declarations

recorda(fact_variables,
  [fact_variable('VARIABLE_Concept'),
  fact_variable('VARIABLE_Total'),
  fact_variable('VARIABLE_A'),
  fact_variable('VARIABLE_B'),
  fact_variable('VARIABLE_C'),
  fact_variable('VARIABLE_D'),
  fact_variable('VARIABLE_E')]).

% Variable definitions

recorda(variable_filter_arcs,
  [variable_filter_arc('variable-filter', 'VARIABLE_Concept', 'FILTER_Concept'),
  variable_filter_arc('variable-filter', 'VARIABLE_Total', 'FILTER_Total'),
  variable_filter_arc('variable-filter', 'VARIABLE_A', 'FILTER_A'),
  variable_filter_arc('variable-filter', 'VARIABLE_B', 'FILTER_B'),
  variable_filter_arc('variable-filter', 'VARIABLE_C', 'FILTER_C'),
  variable_filter_arc('variable-filter', 'VARIABLE_D', 'FILTER_D'),
  variable_filter_arc('variable-filter', 'VARIABLE_E', 'FILTER_E')]).

% Filters on the facts of an instances

recorda(concept_names,
  [concept_name('FILTER_Concept', 'PropertyPlantAndEquipmentNet'),
  concept_name('FILTER_Total', 'PropertyPlantAndEquipmentNet'),
  concept_name('FILTER_A', 'Land'),
  concept_name('FILTER_B', 'BuildingsNet'),
  concept_name('FILTER_C', 'FurnitureAndFixturesNet'),
  concept_name('FILTER_D', 'ComputerEquipmentNet'),
  concept_name('FILTER_E', 'OtherPropertyPlantAndEquipmentNet')]).

% The assertion that a net value is the sum of its components

recorda(value_assertions,
  [value_assertion('RollUp_PropertyPlantAndEquipmentNet', 'PropertyPlantAndEquipmentNet' = ('Land' + 'BuildingsNet' + 'FurnitureAndFixturesNet' + 'ComputerEquipmentNet' + 'OtherPropertyPlantAndEquipmentNet'))]).

% The facts, as expressed within the above taxonomy

recorda(instances,
  [instance('Land', 'I-2010', 5347000),
  instance('Land', 'I-2009', 1147000),
  instance('BuildingsNet', 'I-2010', 244508000),
  instance('BuildingsNet', 'I-2009', 366375000),
  instance('FurnitureAndFixturesNet', 'I-2010', 34457000),
  instance('FurnitureAndFixturesNet', 'I-2009', 34457000),
  instance('ComputerEquipmentNet', 'I-2010', 4169000),
  instance('ComputerEquipmentNet', 'I-2009', 5313000),
  instance('OtherPropertyPlantAndEquipmentNet', 'I-2010', 6702000),
  instance('OtherPropertyPlantAndEquipmentNet', 'I-2009', 6149000),
  instance('PropertyPlantAndEquipmentNet', 'I-2010', 295183000),
  instance('PropertyPlantAndEquipmentNet', 'I-2009', 413441000)]).

% The possible contexts of the facts

recorda(contexts,
  [context('I-2010', [explicit_member('LegalEntityAxis', 'ConsolidatedEntityMember')], date(2010, 12, 31)),
  context('I-2009', [explicit_member('LegalEntityAxis', 'ConsolidatedEntityMember')], date(2009, 12, 31))]).

recorded(elements, Elements), recorded(labels, Labels), recorded(label_arcs, Label_Arcs),
recorded(presentation_arcs, Presentation_Arcs), recorded(instances, Instances),
recorded(contexts, Contexts),
display(Instances, Contexts, Elements, Presentation_Arcs, Label_Arcs, Labels, Display).


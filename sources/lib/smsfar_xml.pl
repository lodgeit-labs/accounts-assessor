/*
see doc/smsf/ato.smsfar.2020.xsd

the xsd also seems to correspond to:
 https://www.ato.gov.au/forms/self-managed-superannuation-fund-annual-return-2020/
 https://www.ato.gov.au/Forms/Self-managed-superannuation-fund-annual-return-instructions-2020/?page=6#Answering_questions_in_section_B
 etc, so ultimately, we could make use of the formulas in ato sbr. (doc/xbrl/SBR_AU)
*/

xml_outline_to_xml(
	nil(X),
	element([nil=true],[])
) :-
	!.

xml_outline_to_xml([], []) :-
	!.

xml_outline_to_xml(X, X) :-
	atom(X),
	!.

xml_outline_to_xml(In, element([], Args2)) :-
	dif(Args, []),
	In =.. [Element_name|Args],
	maplist(!xml_outline_to_xml, Args, Args2).

smsfar_xml(Xml) :-
	Outline =
	'SMSFARComplete2020'(
		'SMSFAR2020'(
			'FinancialYearEnding'($>'report end date FinancialYearEnding'),
			'SectionA-Fund'(
				'FundAddress'([]),
				nil('AmendmentIndicator'),
				nil('FirstReturn'),
				'AuditorType'([]),
				nil('StatusAustralianFund')),
			'SectionB-Income'(
				'A-NetCapitalGain'(
					$>!fs([report - pl/current, account_role - ('Trading_Accounts'/'Capital_Gain/(Loss)')]),
				'B-GrossRentAndOtherIncome'(
					$>!fs([report - pl/current, account_role - ('Rent_Received')]),
				'C-GrossInterest'(
					$>!fs([report - pl/current, account_role - ('Interest_Received_-_Control')]),
				%'J-UnfrankedDividendAmount'(?
				%'K-FrankedDividendAmount'(?
				'L-DividendFrankingCredit'(
					$>!fs([concept - smsf/income_tax/'Franking Credits on dividends']),
				'AssessableContributions'(
					'R-AssessableContributionsTotal'([]),
					'R1-AssessableEmployerContributions'(
						$>!fs([report - pl/current, account_role - ('Employer_Contribution')]),
					'R2-AssessablePersonalContributions'(
						$>!fs([report - pl/current, account_role - ('Contribution_Received']))
				),
				%'Other_Income'(
				%	rl('Other_Income')),
				'GrossIncome'(
					'W-GrossIncome'(
						$>!fs([report - pl/current, account_role - ('Income')])
						@surendar
					),
				'TotalAssessableIncome'(
					'V-TotalAssessableIncome'(
						@surendar
					)),
				),
			'SectionC-Deductions'(
				'SMSFAuditorFee'(
					'H1-DeductibleAmount'(),
					'H2-NonDeductibleAmount'()
				),
				'N-TotalDeductibleAmount'(),
				'Y-TotalNonDeductibleAmount'(),
				'TaxableIncomeOrLoss'(
					'O-TaxableIncomeOrLoss'(),
					'O-LossIndicator'()
				),
				'Z-TotalSMSFExpenses'()
			),
			'SectionD-IncomeTaxCalculation'(
				'A-TaxableIncome'(
					$>aspects([concept - smsf/income_tax/'Taxable income'])),
				'GrossTax'(
					'T1-TaxOnTaxableIncome'(),
					nil('J-TaxOnNonTFNQuotedConts'),
					'B-GrossTax'()
				),
				'T5-TaxPayable'(
					aspects([concept - smsf/income_tax/'Income_Tax_Payable/(Refund)'])),
				%'K-PAYGInstallmentsRaised'(
				'L-SupervisoryLevy'(
					aspects([concept - smsf/income_tax/'ATO_Supervisory_Levy'])),
				'S-AmountDueOrRefundable'(
					aspects([concept - smsf/income_tax/'to pay'])),
				$>('..='(['SectionF-Members'|($>'smsfar ActiveMember')]))
			),
			'SectionH-AssetsAndLiabilities'(
				'E-CashAndTermDeposits'(),
				'H-ListedShares'(
					$>!fs([report - bs/current, account_role - ('Assets'/'Units_in_Listed_Unit_Trusts_Australian')])
				),
				'I-UnlistedShares'(
					$>!fs([report - bs/current, account_role - ('Assets'/'Shares_in_Unlisted_Companies_Australian')])
				),
				'Liabilities'(
					'W-TotalMemberClosingBalances'(
						$>!fs([report - bs/current, account_role - smsf_equity])
					)
				)
			)
		),
		'CGTSchedule2020'(
			'Section1-CurrentYearCapitalGainsAndCapitalLosses'(
				nil('A-GainSharesInCompaniesListedOnAnAusEx'),
				nil('B-GainOtherShares'),
				'C-GainUnitsInUnitTrustsListedOnAnAusEx'(
					re-categorize our investments?
					just the gain part?
					realized or unrealized?),
				nil('D-GainOtherUnits'),
				nil('E-GainRealEstateSituatedInAustralia'),
				nil('F-GainOtherRealEstate'),
				nil('G-GainAmountOfCapitalGainsFromATrust'),
				nil('H-GainCollectables'),
				nil('I-GainOtherCGTAssetsAndAnyOtherCGTEvents'),
				nil('J-TotalCurrentYearCapitalGains'),
				nil('K-LossSharesInCompaniesListedOnAnAusEx'),
				nil('L-LossOtherShares'),
				nil('M-LossUnitsInUnitTrustsListedOnAnAusEx'),
				nil('N-LossOtherUnits'),
				nil('O-LossRealEstateSituatedInAustralia'),
				nil('P-LossOtherRealEstate'),
				nil('Q-LossCollectables'),
				nil('R-LossOtherCGTAssetsAndAnyOtherCGTEvents'),
					nil('S-CapitalGainPreviouslyDeferred')
				),
			'Section2-CapitalLosses'(
				'A-TotalCurrentYearCapitalLosses'(
					just the loss part?
				)
				nil('B-TotalCurrentYearCapitalLossesApplied'),
				nil('C-TotalPriorYearNetCapitalLossesApplied'),
				nil('D-TotalCapitalLossesTransferredInApplied'),
				nil('E-TotalCapitalLossesApplied')
			),
			'Section3-UnappliedNetCapitalLossesCarriedForward'(
				nil('A-NetCapitalLossesFromCollectables'),
				nil('B-OtherNetCapitalLosses')
			),
			'Section4-CGTDiscount'(
				nil('A-TotalCGTDiscountApplied')
			),
			'Section5-CGTConcessionsForSmallBusiness'(
				nil('A-SmallBusinessActiveAssetReduction'),
				nil('B-SmallBusinessRetirementExemption'),
				nil('C-SmallBusinessRollover'),
				nil('D-TotalSmallBusinessConcessionsApplied')),
			'Section6-NetCapitalGain'(
				'A-NetCapitalGain'(
					?
				)
			)
		)
	),
	xml_outline_to_xml(Outline, Xml).


'report end date FinancialYearEnding'(Y) :-
	result_property(l:end_date, date(Y,_,_)).


'smsfar_xml NetCapitalGain'(X) :-


'smsfar ActiveMember'(M) :-
	M =
	'ActiveMember'(
		'Title'($>Name),
		'OpeningAccountBalance'(
			aspects([
				report - final/bs/current,
				concept - smsf/member/gl/'Opening_Balance'])
		),
		'A-EmployerContributions'(
			PL or bs?
		),
		'B-PersonalContributions',
		'N-TotalContributions',
		'AllocatedEarningsOrLosses'(
			'O-AllocatedEarningsOrLosses',
			'O-LossIndicator'
		),
		'P-RolloversIn',?
		'Q-RolloversOut',

		'S1-AccumulationPhaseBalance',?
		'S2-RetirementPhaseNonCapped',
		'S3-RetirementPhaseCapped',
		'S-ClosingAccountBalance'(
			aspects([
				concept - smsf/member/derived/'total'])
	)

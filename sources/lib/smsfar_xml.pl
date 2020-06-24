x :-
E = 'SMSFARComplete2020'(
		'SMSFAR2020'(
			'FinancialYearEnding'($>'report end date FinancialYearEnding'),
			'SectionA-Fund'(
				'PostalAddressType'(),
				nil('AmendmentIndicator'),
				nil('FirstReturn'),
				'AuditorType'(),
				nil('StatusAustralianFund')),
			'SectionB-Income'(
				'A-NetCapitalGain'(
					rl('TradingAccounts'/'Capital GainLoss')),
				'B-GrossRentAndOtherIncome'(
					rl('Rent Received')),
				'C-GrossInterest'(
					rl('Interest Received - control')),
				%'J-UnfrankedDividendAmount'(?
				%'K-FrankedDividendAmount'(?
				'L-DividendFrankingCredit'(
					aspects([concept - smsf/income_tax/'Franking Credits on dividends'])),
				'AssessableContributions'(
					'R-AssessableContributionsTotal'(),
					'R1-AssessableEmployerContributions'(
						rl('Employer Contribution')),
					'R2-AssessablePersonalContributions'(
						rl('Contribution Received'))
				),
				%'OtherIncome'(
				%	rl('Other Income')),
				'GrossIncome'(
					'W-GrossIncome'(?)),
				'TotalAssessableIncome'(
					'V-TotalAssessableIncome'()),
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
					aspects([concept - smsf/income_tax/'Income Tax Payable/(Refund)'])),
				%'K-PAYGInstallmentsRaised'(
				'L-SupervisoryLevy'(
					aspects([concept - smsf/income_tax/'ATO Supervisory Levy'])),
				'S-AmountDueOrRefundable'(
					aspects([concept - smsf/income_tax/'to pay'])),
				$>('..='(['SectionF-Members'|($>'smsfar ActiveMember')]))
			),
			'SectionH-AssetsAndLiabilities'(
				'E-CashAndTermDeposits'(),
				'H-ListedShares',
				'I-UnlistedShares',
				'Liabilities'(
					'W-TotalMemberClosingBalances'
				)
			)
		),
		'CGTSchedule2020'(
			'Section1-CurrentYearCapitalGainsAndCapitalLosses'(
				nil('A-GainSharesInCompaniesListedOnAnAusEx'),
				nil('B-GainOtherShares'),
				nil('C-GainUnitsInUnitTrustsListedOnAnAusEx'),
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
				'A-TotalCurrentYearCapitalLosses',
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
				'A-NetCapitalGain'
			)
		)
	),
	...

	.


'smsfar_xml NetCapitalGain'(X) :-


'smsfar ActiveMember'(M) :-
	M =
	'ActiveMember'(
		'Title'($>Name),
		'OpeningAccountBalance'(),
		'A-EmployerContributions',
		'B-PersonalContributions',
		'N-TotalContributions',
		'AllocatedEarningsOrLosses'(
			'O-AllocatedEarningsOrLosses',
			'O-LossIndicator'
		),
		'P-RolloversIn',
		'Q-RolloversOut',

		'S1-AccumulationPhaseBalance',
		'S2-RetirementPhaseNonCapped',
		'S3-RetirementPhaseCapped',
		'S-ClosingAccountBalance'
	)



%					account_balance(reports/pl/current, 'Distribution Received'/_Unit/'Franking Credit')),

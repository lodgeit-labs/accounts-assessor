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
					'R-AssessableContributionsTotal'(
					'R1-AssessableEmployerContributions'(
						rl('Employer Contribution')),
					'R2-AssessablePersonalContributions'(
						rl('Contribution Received')),
					'OtherIncome'(
						rl('Other Income')),
					






					account_balance(reports/pl/current, 'Distribution Received'/_Unit/'Franking Credit')),





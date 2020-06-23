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






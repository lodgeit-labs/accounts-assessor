Here's how i'm making sense of it. First, the whole hierarchy:

```
NetAssets
	Assets
		Cash at Bank 
		Contribution Receivable 
		Distribution Receivable 
		Dividends Receivable 
		Dividend Reinvestment - Residual Account
		Formation Expenses
		Interest Receivable 
		Other Assets 
		Prepaid Expenses 
		Sundry Debtors
		Investments 
			Derivatives
			Fixed Interest Securities (Australian)
			Fixed Interest Securities (Overseas) 
			Fixtures and Fittings (at written down value)
			Government Securities (Australian)
			Government Securities (Overseas)
			Interests in Partnerships (Australian)
			Managed Investments (Australian)
			Managed Investments (Overseas)
			Motor Vehicles (at written down value)
			Other Assets
			Plant and Equipment (at written
			down value)
			Real Estate Properties (Australian)
			Real Estate Properties (Overseas)
			Shares in Listed Companies (Australian)
			Shares in Listed Companies
			(Overseas)
			Shares in Unlisted Companies (Australian)
			Shares in Unlisted Companies (Overseas)
			Units in Listed Unit Trusts (Australian)
			Units in Listed Unit Trusts (Overseas)
			Units in Unlisted Unit Trusts (Australian)
			Units in Unlisted Unit Trusts (Overseas)
	Liabilities 
		Amounts owing to other Persons
		GST Payable
		Income Tax Payable 
		Income Tax Payable 
		Imputed Credits 
		Foreign and Other Tax Credits 
		Tax Instalment paid 
		Tax File Number Credits 
		Australian Business Number Credits 
		PAYG Payable 
		Deferred Tax Liability 
		Data Clearing Account 
		SUSPENSE

Equity 
	< member 1/member 2/.. >
		Opening Balance - Preserved/Taxable
		Opening Balance - Preserved/Tax Free
		Opening Balance - Unrestricted Non Preserved/Taxable
		Opening Balance - Unrestricted Non Preserved/Tax Free
		Opening Balance - Restricted Non Preserved/Taxable
		Opening Balance - Restricted Non Preserved/Tax Free
		
		Employer Contributions - Concessional 
		Member/Personal Contributions - Concessional 
		Member/Personal Contributions - Non Concessional 
		Other Contributions
		Transfers In - Preserved/Taxable
		Transfers In - Preserved/Tax Free
		Transfers In - Unrestricted Non Preserved/Taxable
		Transfers In - Unrestricted Non Preserved/Tax Free
		Transfers In - Restricted Non Preserved/Taxable
		Transfers In - Restricted Non Preserved/Tax Free
		
		Share of Profit/(Loss) - Preserved/Tax Free
		Share of Profit/(Loss) - Preserved/Taxable
		Share of Profit/(Loss) - Unrestricted Non Preserved/Tax Free
		Share of Profit/(Loss) - Unrestricted Non Preserved/Taxable
		Share of Profit/(Loss) - Restricted Non Preserved/Tax Free
		Share of Profit/(Loss) - Restricted Non Preserved/Taxable

		Income Tax - Preserved/Taxable 
		Income Tax - Preserved/Tax Free
		Income Tax - Unrestricted Non Preserved/Taxable
		Income Tax - Unrestricted Non Preserved/Tax Free
		Income Tax - Restricted Non Preserved/Taxable
		Income Tax - Restricted Non Preserved/Tax Free

		Contribution Tax - Preserved/Taxable 
		Contribution Tax - Preserved/Tax Free
		Contribution Tax - Unrestricted Non Preserved/Taxable
		Contribution Tax - Unrestricted Non Preserved/Tax Free
		Contribution Tax - Restricted Non Preserved/Taxable
		Contribution Tax - Restricted Non Preserved/Tax Free

		Pensions Paid - Preserved/Taxable
		Pensions Paid - Preserved/Taxfree
		Pensions Paid - Unrestricted Non Preserved/Taxable
		Pensions Paid - Unrestricted Non Preserved/Tax Free
		Pensions Paid - Restricted Non Preserved/Taxable
		Pensions Paid - Restricted Non Preserved/Tax Free
		Benefits Paid - Preserved/Taxable
		Benefits Paid - Preserved/Taxfree
		Benefits Paid - Unrestricted Non Preserved/Taxable
		Benefits Paid - Unrestricted Non Preserved/Tax Free
		Benefits Paid - Restricted Non Preserved/Taxable
		Benefits Paid - Restricted Non Preserved/Tax Free
		Transfers Out - Preserved/Taxable
		Transfers Out - Preserved/Tax Free
		Transfers Out - Unrestricted Non Preserved/Taxable
		Transfers Out - Unrestricted Non Preserved/Tax Free
		Transfers Out - Restricted Non Preserved/Taxable
		Transfers Out - Restricted Non Preserved/Tax Free
		Life Insurance Premiums - Preserved/Taxable
		Life Insurance Premiums - Preserved/Tax Free
		Life Insurance Premiums - Unrestricted Non Preserved/Taxable
		Life Insurance Premiums - Unrestricted Non Preserved/Tax Free
		Life Insurance Premiums - Restricted Non Preserved/Taxable
		Life Insurance Premiums - Restricted Non Preserved/Tax Free

		Internal Transfers In - Preserved/Taxable
		Internal Transfers In - Preserved/Tax Free
		Internal Transfers In - Unrestricted Non Preserved/Taxable
		Internal Transfers In - Unrestricted Non Preserved/Tax Free
		Internal Transfers In - Restricted Non Preserved/Taxable
		Internal Transfers In - Restricted Non Preserved/Tax Free
		Internal Transfers Out - Preserved/Taxable
		Internal Transfers Out - Preserved/Tax Free
		Internal Transfers Out - Unrestricted Non Preserved/Taxable
		Internal Transfers Out - Unrestricted Non Preserved/Tax Free
		Internal Transfers Out - Restricted Non Preserved/Taxable
		Internal Transfers Out - Restricted Non Preserved/Tax Free

P&L
	Income
		Capital Gains/Losses _ taxable 
		Capital Gains/Losses _ Non taxable 
		Distribution received 
		Dividends Received
		Interest Received 
		Rent Received 
		Employer Contribution 
			< member 1/member 2/.. >
		Member Contribution Concessional 
			< member 1/member 2/.. >
		Member Contribution Non Concessional 
			< member 1/member 2/.. >
		Transfer In 
			< member 1/member 2/.. >

	Expenses
		Accountancy Fees
		Adminstration Costs
		ATO Supervisory Levy 
		Audit Fees
		Bank Charges
		Rental Expenses
		Investment Expenses 
		Fines
		Legal Fees
		Life Insurance Premium 
			< member 1/member 2/.. >
		Pension paid 
			< member 1/member 2/.. >
		Benefits Paid 
			< member 1/member 2/.. >
		Tranfer Out 
			< member 1/member 2/.. >
		Income Tax Expenses 

```

What i suppose the program should do, in phases:

1) post all of NetAssets. Post Opening Balances for each member.
2) process bank transactions and investment statements, affecting Assets and P&L. Some of the P&L accounts are subdivided by members, so that we don't have to hunt this information down later.
3) end of year: 
	1) generate the fund's P&L report
	2) post allocation transactions, clearing out P&L into members equity accounts (excluding Opening Balance accounts)
	3) generate member reports, etc.


Some musing: notice how the program would not be able to generate the fund's P&L report from the state of the ledger after allocation transactions are posted. In what we've been doing so far (risera etc), this is sidestepped by projecting (like with an unbalanced journal entry) the total ComprehensiveIncome into Equity-CurrentEarnings after all transactions are processed. 
What if a clean-slate computerized accounting would, instead of using dr-cr pairs, use triplets:
	1) Asset changes as usual
	2) Equity tracking ownership
	3) P&L tracking reasons of asset change

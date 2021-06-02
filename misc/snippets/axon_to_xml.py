

import xml.etree.ElementTree as ET
import axon


def axon_to_xml(axon_string):
   a = axon.loads(axon_string)
   e = ET.Element(a[0].__tag__) 
   pr(e, a[0])
   return e

def pr(e, x): 
   for i in x: 
      pr(ET.SubElement(e, i.__tag__), i) 



input = """
Accounts
        Assets
                CurrentAssets
                        CashAndCashEquivalents
                                WellsFargo
                                NationalAustraliaBank
        NoncurrentAssets
                FinancialInvestments

        Equity
                ShareCapital
        Liabilities
                NoncurrentLiabilities
                        NoncurrentLoans
                CurrentLiabilities
                        CurrentLoans
        Earnings
                Revenue
                        InvestmentIncome

                Expenses
                        BankCharges
                        ForexLoss
                CurrentEarningsLosses
                RetainedEarnings
"""

xml_string = ET.tostring(axon_to_xml(input))

# elementtree doesnt have prettyprint, fixme: use minidom for everything 

import xml.dom.minidom
dom = xml.dom.minidom.parseString(xml_string)
print(dom.toprettyxml())

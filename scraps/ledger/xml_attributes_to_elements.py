xml_string="""
<actionTaxonomy>
<action Id="Invest_In"  Description="Shares"            ExchangeAccount="FinancialInvestments" TradingAccount="InvestmentIncome" />
<action Id="Dispose_Off"        Description="Shares"            ExchangeAccount="FinancialInvestments" TradingAccount="InvestmentIncome" />
<action Id="Borrow"             Description="Shares"            ExchangeAccount="NoncurrentLoans"       TradingAccount="InvestmentIncome" />
<action Id="Introduce_Capital" Description="Unit_Investment"    ExchangeAccount="ShareCapital"  TradingAccount="InvestmentIncome" />
<action Id="Gain"               Description="Unit_Investment"   ExchangeAccount="ShareCapital"  TradingAccount="InvestmentIncome" />
<action Id="Loss"               Description="No Description"    ExchangeAccount="ShareCapital"  TradingAccount="InvestmentIncome" />
<action Id="PayBank"            Description="No Description"    ExchangeAccount="BankCharges"           TradingAccount="InvestmentIncome" />
</actionTaxonomy>"""

import xml.dom.minidom
dom = xml.dom.minidom.parseString(xml_string)
print(dom.toprettyxml())


from xml.dom.minidom import getDOMImplementation
impl = getDOMImplementation()
newdoc = impl.createDocument(None, "actionTaxonomy", None)
top_element = newdoc.documentElement



ch=dom.childNodes[0]
for b in ch.childNodes:
    if type(b) == xml.dom.minidom.Element:
        #import IPython; IPython.embed()
        
        a = newdoc.createElement("action")
        top_element.appendChild(a)
        
        for k,v in b.attributes.items():
            k = k[0].lower() + k[1:]
            f = newdoc.createElement(k)
            a.appendChild(f)
            text = newdoc.createTextNode(v)
            f.appendChild(text)
            
print(newdoc.toprettyxml())

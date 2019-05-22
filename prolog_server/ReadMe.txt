This directory contains a SWI Prolog server (prolog_server.pl) that 
accepts a ledger/loan-request.xml and generates a ledger/loan-response.xml. 
Note that this code relies on Murisi's Prolog code.

To use the server download and install SWI Prolog available at:

   http://www.swi-prolog.org/Download.html

To run the server double click on the file: prolog_server.pl.

Open a web browser at: http://localhost:8080/

Upload the XML file (loan-request.xml) and in our case the following XML loan-response.xml is generated:

<LoanSummary xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<IncomeYear>0</IncomeYear>
<OpeningBalance>55000</OpeningBalance>
<InterestRate>5.95</InterestRate>
<MinYearlyRepayment>9834.923730309254</MinYearlyRepayment>
<TotalRepayment>28000</TotalRepayment>
<RepaymentShortfall>0</RepaymentShortfall>
<TotalInterest>3230.7684931506847</TotalInterest>
<TotalPrincipal>24769.231506849315</TotalPrincipal>
<ClosingBalance>50230.76849315068</ClosingBalance>
</LoanSummary>


This directory has following sub-directories:
- loan: contains prolog code that process loan request.
- ledger: contains prolog code that process ledger request.
- taxonomy: contains all taxonomy files.
Both loan and ledger directories contain a sample request file.


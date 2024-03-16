[](mrkev2query: "
the “Accounts Assessor” below corresponds to:
products:robust kb:project_name ?x. 
?x rdf:value ?y.
")

# Accounts Assessor - introduction

[](mrkev2entity: "
the “This repository” below corresponds to:
codebases:labs_accounts_assessor
")

This repository hosts practical research into leveraging logic programming to solve accounting problems.
The core logic runs in SWI-Prolog, and is aided by several smaller python codebases.

We use it at http://www.nobleaccounting.com.au to automate reporting and auditing tasks.

Several services are available:

[](mrkev2extra: "
products:accounts_assessor kb:has_service kb:investment_calculator
")

[](mrkev2query: "
the “investment calculator” below corresponds to:
investment calculator kb:investment_calculator rdfs:label ?x.
")

* investment calculator
* hirepurchase agreement
* depreciation
* livestock (standalone)
* division 7A loan calculator


## investment calculator
The most complex endpoint is the investment calculator; it validates and processes financial data of a financial entity for a given period:
* bank statements
* general ledger transactions
* forex and investments
* Australian SMSF accounting
* livestock accounting

![screenshot](sources/static/docs/readme/ic-sheets.png?raw=true)

It automates some accounting procedures, like tax calculations, and generates balance sheets, trial balances, investment report and other types of reports.

![screenshot](sources/static/docs/readme/ic-result.png?raw=true)


## livestock calculator
![screenshot](sources/static/docs/readme/livestock-standalone-sheet.png?raw=true)
![screenshot](sources/static/docs/readme/livestock-standalone-result.png?raw=true)


## depreciation calculator
![screenshot](sources/static/docs/readme/depreciation-sheets.png?raw=true)
![screenshot](sources/static/docs/readme/depreciation-result.png?raw=true)


## hirepurchase calculator
![screenshot](sources/static/docs/readme/hp-sheet.png?raw=true)
(todo: UI)

Given a hire purchase arrangement, it can track the balance of a hire purchase account through time, the total payment and the total interest.

## Division 7A Loan calculator
![screenshot](sources/static/docs/readme/Div7A-sheet.png?raw=true)

![screenshot](sources/static/docs/readme/Div7A-result.png?raw=true)




## chatbot services
* determine tax residency by carrying out a dialog with the user
* determine small business entity status by carrying out a dialog with the user



# in detail

## running the server with docker

1) `git clone --recurse-submodules https://github.com/lodgeit-labs/accounts-assessor/`
2) `docker_scripts/up.sh`

## usage

#### with Excel and LSU plugin
[https://github.com/koo5/accounts-assessor-public-wiki/blob/master/excel_usage/README.md](https://github.com/koo5/accounts-assessor-public-wiki/blob/master/excel_usage/README.md)

#### with OneDrive explorer
navigate to https://robust1.ueueeu.eu/static/onedrive-explorer-js/ and log in. Log into OneDrive, the choose a file and click "run investment calculator".

#### through file upload form
1) Load http://localhost:8877/view/upload_form in your browser
2) upload one of the example input files

#### with curl
```
curl -F file1=@'tests2/endpoint_tests/loan/single_step/loan-0/request/request.xml' http://localhost:8877/upload
```

#### with test runner
see [tests2/runner/README.md](tests2/runner/README.md)

#### through a custom GPT
we have an experimental endpoint for [custom GPT](https://openai.com/blog/introducing-gpts), which you can register as an "action" - https://robust1.ueueeu.eu/ai3/openapi.json - see [/wiki/CustomGPT.md]


## input files
#### endpoint_tests
* `tests/endpoint_tests/**/request/*`
* todo make sure that this includes whatever we generate from rdf templates - Robust Input Example 8.7.2021



## how to generate an input file from template



## documentation
todo, this is all private at the moment:

most endpoints should have some resources in lodgeit_private/doc/. Introductions to individual concepts can be found in videos on dropbox.

videos:
https://www.dropbox.com/sh/prgubjzoo9zpkhp/AACd6YmoWxf9IUi5CriihKlLa?dl=0
https://www.dropbox.com/sh/o5ck3qm79zwgpc5/AABD9jUcWiNpWMb2fxsmeVfia?dl=0

wiki:
https://github.com/lodgeit-labs/accounts-assessor-wiki/


## architecture
there are 4 main components:

### services
various helper functions that prolog invokes over http/rpc

### workers
a remoulade worker that:
* wraps prolog and spawns prolog on request
* talks to the triplestore

### frontend
lets users upload request files and triggers workers.

### apache
serves static files and proxies requests to frontend


`

## directory structure

* source/lib - prolog source code
* tests
** plunit - contains queries that test the functionality of the main Prolog program
** endpoint_tests - contains test requests for the web endpoint as well as expected reponses
* misc - contains the stuff that does not yet clearly fit into a category
* server_root - this directory is served by the prolog server
** tmp - each request gets its own directory here
** taxonomy - contains all xbrl taxonomy files.
** schemas - xsd schemas



## version 2.0

A new version is planned, using a constrained logic programming language, aiming for these features:

Derives, validates, and corrects the financial information that it is given. The program uses redundancy to carry out its validations and corrections. By this it is meant that knowledge of parts of a company's financial data imposes certain constraints on the company's other financial data. If the program is given a company's ledger, then it knows what the balance sheet should look like. If the program is given a company's balance sheet, then it has a rough idea of what the ledger should look like.

* Given a hire purchase arrangement and ledger, it can guess what the erroneous transactions are
* Given a hire purchase arrangement and ledger, it can generate correction transactions to fix the erroneous transactions
...


## todo: comparisons to other projects
* https://github.com/johannesgerer/buchhaltung
* gnu cash
...

## Contributors ✨

<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-5-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://github.com/sto0pkid"><img src="https://avatars2.githubusercontent.com/u/9160425?v=4" width="100px;" alt=""/><br /><sub><b>stoopkid</b></sub></a><br /><a href="#infra-sto0pkid" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="https://github.com/lodgeit-labs/accounts-assessor/commits?author=sto0pkid" title="Tests">⚠️</a> <a href="https://github.com/lodgeit-labs/accounts-assessor/commits?author=sto0pkid" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/Schwitter"><img src="https://avatars3.githubusercontent.com/u/8089563?v=4" width="100px;" alt=""/><br /><sub><b>Schwitter</b></sub></a><br /><a href="#infra-Schwitter" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="https://github.com/lodgeit-labs/accounts-assessor/commits?author=Schwitter" title="Tests">⚠️</a> <a href="https://github.com/lodgeit-labs/accounts-assessor/commits?author=Schwitter" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/salamt2"><img src="https://avatars0.githubusercontent.com/u/2647629?v=4" width="100px;" alt=""/><br /><sub><b>salamt2</b></sub></a><br /><a href="#infra-salamt2" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="https://github.com/lodgeit-labs/accounts-assessor/commits?author=salamt2" title="Tests">⚠️</a> <a href="https://github.com/lodgeit-labs/accounts-assessor/commits?author=salamt2" title="Code">💻</a></td>
    <td align="center"><a href="http://github.com/murisi"><img src="https://avatars0.githubusercontent.com/u/6886764?v=4" width="100px;" alt=""/><br /><sub><b>Murisi Tarusenga</b></sub></a><br /><a href="#infra-murisi" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="https://github.com/lodgeit-labs/accounts-assessor/commits?author=murisi" title="Tests">⚠️</a> <a href="https://github.com/lodgeit-labs/accounts-assessor/commits?author=murisi" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/koo5"><img src="https://avatars1.githubusercontent.com/u/114276?v=4" width="100px;" alt=""/><br /><sub><b>koo5</b></sub></a><br /><a href="#infra-koo5" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="https://github.com/lodgeit-labs/accounts-assessor/commits?author=koo5" title="Tests">⚠️</a> <a href="https://github.com/lodgeit-labs/accounts-assessor/commits?author=koo5" title="Code">💻</a></td>
  </tr>
</table>

<!-- markdownlint-enable -->
<!-- prettier-ignore-end -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!


[](mrkev2extra: "
products:robust kb:has_codebase codebases:labs_accounts_assessor.
products:robust kb:has_codebase codebases:LodgeITSmart.
")






[](mrkev2query: "
the “Accounts Assessor” below corresponds to:
products:accounts_assessor kb:project_name ?x.
?x rdf:value ?y.
")

# Accounts Assessor - introduction

[](mrkev2entity: "
the “This repository” below corresponds to:
codebases:labs_accounts_assessor
")

This repository hosts practical research into leveraging logic programming to solve accounting problems.
The core logic runs in SWI-Prolog, and is aided by a python webserver.
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

We use it at http://www.nobleaccounting.com.au, along with a proprietary (but free) frontend in the form of a Microsoft Excel plugin, to automate accounting tasks.



## investment calculator
The most complex endpoint is the investment calculator; it validates and processes financial data of a financial entity for a given period:
* bank statements
* raw general ledger input
* change in investment unit values
* (SMSF member accounting - fixme)
* (livestock accounting information - fixme)

![screenshot](sources/static/docs/readme/ic-sheets.png?raw=true)

It automates some of the usual accounting procedures, like tax calculations, and it generates balance sheets, trial balances, investment report and other types of reports.

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

1) clone the repo,
2) `git submodule update --init --recursive`
3) `cd docker_scripts`
3) `./first_run.sh`
4) `./develop.sh`  

## usage

#### with Excel and LSU plugin
[https://github.com/koo5/accounts-assessor-public-wiki/blob/master/excel_usage/README.md]()

#### without Excel
1) Load http://localhost:88/ in your browser
2) upload one of the request files found in tests/endpoint_tests/ (todo: needs updating)
3) you should get back a json with links to generated report files




## documentation
todo, this is all private at the moment:

most endpoints should have some resources in lodgeit_private/doc/. Introductions to individual concepts can be found in videos on dropbox.

videos:
https://www.dropbox.com/sh/prgubjzoo9zpkhp/AACd6YmoWxf9IUi5CriihKlLa?dl=0
https://www.dropbox.com/sh/o5ck3qm79zwgpc5/AABD9jUcWiNpWMb2fxsmeVfia?dl=0

wiki:
https://github.com/lodgeit-labs/accounts-assessor-wiki/


## architecture
there are 4 components:

### internal_services
various helper functions that prolog invokes over http/rpc

### internal_workers
a celery worker that:
* wraps prolog and spawns prolog on request
* talks to the triplestore

### frontend_server
lets users upload request files and triggers internal_workers. Django provides a development http server which serves static/tmp files, but for production, this has to be augmented with:

### apache
serves static files and proxies requests to frontend_server


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
products:robust has_codebase codebases:labs_accounts_assessor.
products:robust kb:has_codebase codebases:LodgeITSmart.
")





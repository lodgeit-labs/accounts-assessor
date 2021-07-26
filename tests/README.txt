testcases have been unmaintained for some time, mainly because reviewing differences from saved testcases was fairly time-consuming, and because newer reports contain bits that vary with each run (triplestore urls). Some better way to manage this would be useful..

run from prolog_server directory, so the http server can serve files:
```
reset;echo -e "\e[3J";   swipl -s ../tests/run_tests.pl   -g "halt"
```


#### Run the tests against a running server:
(tests need updating..)

`cd server_root; reset;echo -e "\e[3J";   swipl -s ../lib/dev_runner.pl   --problem_lines_whitelist=../misc/problem_lines_whitelist  --script ../lib/endpoint_tests.pl  -g "set_flag(overwrite_response_files, false), set_flag(add_missing_response_files, false), set_prolog_flag(grouped_assertions,true), run_tests"`

#### Run one testcase:
`cd server_root; reset;echo -e "\e[3J";   swipl -s ../lib/dev_runner.pl   --problem_lines_whitelist=../misc/problem_lines_whitelist  --script ../lib/endpoint_tests.pl  -g "set_flag(overwrite_response_files, false), set_flag(add_missing_response_files, false), set_prolog_flag(grouped_assertions,false), set_prolog_flag(testcase,(ledger,'endpoint_tests/ledger/ledger-2')), run_tests(endpoints:testcase)"`

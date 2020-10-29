testcases have been unmaintained for some time, mainly because reviewing differences from saved testcases was fairly time-consuming, and because newer reports contain bits that vary with each run (triplestore urls). Some better way to manage this would be useful..

run from prolog_server directory, so the http server can serve files:
```
reset;echo -e "\e[3J";   swipl -s ../tests/run_tests.pl   -g "halt"
```
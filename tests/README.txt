run from prolog_server directory, so the http server can serve files.
```
reset;echo -e "\e[3J";   swipl -s ../tests/run_tests.pl   -g "halt"
```
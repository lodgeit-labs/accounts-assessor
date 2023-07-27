rm /tmp/robust_testsuite_runlog; rm -rf /tmp/robust_tests/xxx; reset;echo -e "\e[3J"; PYTHONPATH=(pwd) luigi --module runner.tests2  AsyncComputationStart --test='{"debug": false, "dir": "bad/loan-0", "path": "/tmp/robust_tests/xxx/2023-07-27_10_02_40.037002/bad/loan-0/nodebug", "robust_server_url": "http://localhost:8877", "suite": "../endpoint_tests/loan"}'


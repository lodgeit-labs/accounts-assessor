rm log; reset;echo -e "\e[3J"; PYTHONPATH=(pwd) luigi --local-scheduler --module runner.tests2 EndpointTestsSummary --suite ../endpoint_tests/loan/


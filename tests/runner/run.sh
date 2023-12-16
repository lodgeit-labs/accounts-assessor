
reset;echo -e "\e[3J"; PYTHONPATH=(pwd) luigi --module runner.tests2 --Permutations-robust-server-url http://jj.internal:8877 --Permutations-suite ../endpoint_tests/ledger/  --workers=30 Summary

```
./init_venv.sh
pip install -r requirements.txt
```

```
. venv/bin/activate.fish
rm -rf /tmp/luigid; ./luigi_scheduler_server.sh
```

```
rm log; reset;echo -e "\e[3J"; PYTHONPATH=(pwd) luigi --module runner.tests2 EndpointTestsSummary --Permutations-suite ../endpoint_tests/loan --workers=20

Informed scheduler that task   EndpointTestsSummary__tmp_robust_test_40b464af1a   has status   PENDING
Informed scheduler that task   Permutations__http___localhost__tmp_robust_test_53b242c6fe   has status   PENDING
Done scheduling tasks
Running Worker with 1 processes

```

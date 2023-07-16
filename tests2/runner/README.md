```
./init_venv.sh
pip install -r requirements.txt
```

```
. venv/bin/activate.fish
rm -rf /tmp/luigid; ./luigi_scheduler_server.sh
```

```
rm log; reset;echo -e "\e[3J"; PYTHONPATH=(pwd) luigi --module runner.tests2 EndpointTestsSummary --Permutations-suite ../endpoint_tests/loan --workers=2
```

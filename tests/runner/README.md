#### initial setup
```
./init_venv.sh
pip install -r requirements.txt
```

#### start scheduler server:
```
. venv/bin/activate.fish
rm -rf /tmp/luigid; ./luigi_scheduler_server.sh
```

#### start worker with a task
```
. venv/bin/activate.fish
rm log; reset;echo -e "\e[3J"; PYTHONPATH=(pwd) luigi --module runner.tests2 EndpointTestsSummary --Permutations-suite ../endpoint_tests/loan --workers=2
```

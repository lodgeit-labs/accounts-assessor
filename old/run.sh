#!/usr/bin/env bash

. venv/bin/activate
bash -c "cd internal_services; ./run.sh 0.0.0.0:17778 --noreload"&
bash -c "cd frontend_server; ./run.sh  0.0.0.0:7778  --noreload"&




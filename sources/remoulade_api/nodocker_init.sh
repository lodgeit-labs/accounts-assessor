#!/usr/bin/env fish

rm -rf venv
virtualenv -p /usr/bin/python3.10 venv
. venv/bin/activate.fish
pip install -e ../common/libs/remoulade[rabbitmq,redis,postgres]
pip install -r requirements.txt
pip install pip-tools

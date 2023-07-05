#!/usr/bin/env bash

function _; or status --is-interactive; or exit 1; end

virtualenv -p /usr/bin/python3 venv ;_
. ./venv/bin/activate ;_

python3 -m pip install --no-cache-dir -r requirements.txt ;_
python3 -m pip install --no-cache-dir -e ../common/libs/remoulade/[rabbitmq,redis,postgres] ;_

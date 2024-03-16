#!/usr/bin/env fish
function _; or status --is-interactive; or exit 1; end



virtualenv -p /usr/bin/python3.10 venv ;_
. ./venv/bin/activate.fish ;_

python3 -m pip install --no-cache-dir -r requirements-dev.txt ;_
#python3 -m pip install --no-cache-dir -e ../common/libs/remoulade/[rabbitmq,redis,postgres] ;_


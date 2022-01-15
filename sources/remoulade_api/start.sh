#!/usr/bin/env bash
set -xv
/app/sources/wait-for-it/wait-for-it.sh $RABBITMQ_URL -t 300
cd /app/sources/common/libs/remoulade/remoulade/api/
flask run -h "0.0.0.0" --no-debugger #--no-reload


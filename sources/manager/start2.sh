#!/usr/bin/env bash
set -xv

export PYTHONPATH=../common/libs/remoulade/
remoulade-gevent --prefetch-multiplier 1 --threads 1 --queues $1 manager


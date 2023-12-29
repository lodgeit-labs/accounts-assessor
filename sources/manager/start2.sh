#!/usr/bin/env bash
set -xv

export PYTHONPATH=../common/libs/remoulade/
remoulade-gevent --prefetch-multiplier 1 --threads 1024 --queues $argv manager


#!/usr/bin/env fish
set -x

remoulade --prefetch-multiplier 1 --queues $argv[1] --threads 1 worker

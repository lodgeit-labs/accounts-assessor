#!/usr/bin/env bash
set -x

remoulade --prefetch-multiplier 1 --queues $1 --threads 1 main

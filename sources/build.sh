#!/usr/bin/env fish

set -x WHAT internal_workers; and cp ../../secrets*.json .; and git status > git_info.txt; and git log >> git_info.txt; and docker build -t "koo5/$WHAT" -f "$WHAT/Dockerfile" . ; and \
set -x WHAT internal_services; and cp ../../secrets*.json .; and git status > git_info.txt; and git log >> git_info.txt; and docker build -t "koo5/$WHAT" -f "$WHAT/Dockerfile" . ; and \
set -x WHAT frontend_server; and cp ../../secrets*.json .; and git status > git_info.txt; and git log >> git_info.txt; and docker build -t "koo5/$WHAT" -f "$WHAT/Dockerfile" . ; and echo "ok"


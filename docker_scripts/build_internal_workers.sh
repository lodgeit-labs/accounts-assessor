#!/usr/bin/env fish

set -x WHAT internal_workers;   and cp ../../secrets*.json .; and git status > git_info.txt; and git log >> git_info.txt; and docker build --label  "koo5/$WHAT:latest"  -t "koo5/$WHAT" -f "$WHAT/Dockerfile" . 

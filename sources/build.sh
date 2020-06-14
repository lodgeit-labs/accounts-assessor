#!/usr/bin/env fish

set -x WHAT internal_workers;  cp ../../secrets*.json .;  git status > git_info.txt; git log >> git_info.txt; docker build -t "koo5/$WHAT" -f "$WHAT/Dockerfile" .
set -x WHAT internal_services;  cp ../../secrets*.json .;  git status > git_info.txt; git log >> git_info.txt; docker build -t "koo5/$WHAT" -f "$WHAT/Dockerfile" .
set -x WHAT frontend_server;  cp ../../secrets*.json .;  git status > git_info.txt; git log >> git_info.txt; docker build -t "koo5/$WHAT" -f "$WHAT/Dockerfile" .

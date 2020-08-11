#!/usr/bin/env fish

git status > static/docs/git_info.txt; and git log >> static/docs/git_info.txt;
and cp ../../secrets*.json .; 
and docker build --label  "koo5/$WHAT:latest"  -t "koo5/$WHAT" -f "$WHAT/Dockerfile" .


#!/usr/bin/env fish

git status > static/docs/git_info.txt; and git log >> static/docs/git_info.txt ;

and cp ../../secrets*.json .; and docker build --label  "koo5/internal-workers:latest"  -t "koo5/internal-workers" -f "internal_workers/Dockerfile" .

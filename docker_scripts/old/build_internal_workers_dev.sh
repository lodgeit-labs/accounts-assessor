#!/usr/bin/env fish

git status > static/docs/git_info.txt; and git log >> static/docs/git_info.txt ;

and docker build --label  "koo5/internal-workers-dev"  -t "koo5/internal-workers-dev:latest" -f "internal_workers/Dockerfile" .


#!/usr/bin/env fish

set DIR (dirname (readlink -m (status --current-filename)))
cd "$DIR"/../sources/static

git status -vv > git_info.txt
git log --graph --decorate  --abbrev-commit >> git_info.txt


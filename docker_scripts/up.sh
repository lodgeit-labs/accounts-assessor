#!/usr/bin/env fish
function e; or status --is-interactive; or exit 1; end # this serves as a replacement for the bash "set -e" flag
set DIR (dirname (readlink -m (status --current-filename))); cd "$DIR"
#function _old_fish_prompt; end; # https://github.com/python/cpython/issues/93858 ?


./first_run.sh

set VENV_PATH ./venv
. $VENV_PATH/bin/activate.fish ;e

LOGURU_COLORIZE=false PYTHONUNBUFFERED=true ./develop.sh --parallel_build true --container_startup_sequencing False --develop False --stay_running False $argv

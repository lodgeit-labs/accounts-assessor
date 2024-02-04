#!/usr/bin/env fish
function e; or status --is-interactive; or exit 1; end

set DIR (dirname (readlink -m (status --current-filename))); cd "$DIR"

set VENV_PATH ./venv
. $VENV_PATH/bin/activate.fish ;_

if test -e ./../generated_stack_files/last.yml;
	docker-compose  -f ../generated_stack_files/last.yml -p robust --compatibility down;
else;
	echo "./../generated_stack_files/last.yml not found, nothing to do.";
end

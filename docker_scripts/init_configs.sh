#!/usr/bin/env fish
function e; or status --is-interactive; or exit 1; end # this serves as a replacement for the bash "set -e" flag

set DIR (dirname (readlink -m (status --current-filename))); cd "$DIR"

# if we're running under CI, the working directory is cleared every time, so we need to do this every time. This is achieved by calling this script from the workflow yaml file.

cd ..
cp -r secrets_example secrets ;e
cp -r sources/config_example/production sources/config ;e




#!/usr/bin/env fish

set DIR (dirname (readlink -m (status --current-filename)))
cd "$DIR"

cd ..
cp -r secrets_example secrets
cp -r sources/config_example sources/config

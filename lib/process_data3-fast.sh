#!/usr/bin/env bash

VIEWER=$1
FILEPATH=$2

if [ -f "$FILEPATH" ]
then
	swipl -s ../lib/dev_runner.pl --debug=false ../lib/load2.pl "prolog_server:process_data_cmdline('$FILEPATH')"
else
	echo "$FILEPATH not found"
fi

#!/usr/bin/env bash

VIEWER=$1
FILEPATH=$2

if [ -f "$FILEPATH" ]
then
	echo swipl -s ../lib/dev_runner.pl --viewer="$VIEWER"  ../lib/debug1.pl "prolog_server:process_data_cmdline('$FILEPATH')"
	swipl -s ../lib/dev_runner.pl --viewer="$VIEWER"  ../lib/debug1.pl "prolog_server:process_data_cmdline('$FILEPATH')"
else
	echo "$FILEPATH not found"
fi

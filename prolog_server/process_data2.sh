#!/usr/bin/env bash

VIEWER=$1
FILEPATH=$2

if [ -f "$FILEPATH" ]
then
	swipl -s dev_runner.pl -- "$VIEWER"  process_data.pl "debug,process_data_cmdline(_, '$FILEPATH')"
else
	echo "$FILEPATH not found"
fi

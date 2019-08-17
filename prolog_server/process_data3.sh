#!/usr/bin/env bash

VIEWER=$1
FILEPATH=$2

if [ -f "$FILEPATH" ]
then
	swipl -s dev_runner.pl -- "$VIEWER"  debug1.pl "prolog_server:process_data2(_, '$FILEPATH')"
else
	echo "$FILEPATH not found"
fi

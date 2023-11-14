#!/usr/bin/env fish

PYTHONPATH=(pwd) luigi --module runner.tests2 AssistantStartup --assistant --no-lock  --workers=30 $argv

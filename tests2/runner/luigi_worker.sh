#!/usr/bin/env fish

PYTHONPATH=(pwd) luigi --module runner.tests2 AssistantStartup --assistant --no-lock  --workers=150 --worker-force-multiprocessing true $argv

#!/usr/bin/env fish

PYTHONPATH=(pwd) luigi --module runner.tests2 AssistantStartup --assistant

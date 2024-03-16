#!/usr/bin/env fish

rm -rf /tmp/luigid;
mkdir -p /tmp/luigid/
luigid --pidfile /tmp/luigid/pid --state-path /tmp/luigid/state $argv


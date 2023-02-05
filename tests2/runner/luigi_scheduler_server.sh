#!/usr/bin/env fish

mkdir -p /tmp/luigid/log/

luigid --pidfile /tmp/luigid/pid --logdir /tmp/luigid/log --state-path /tmp/luigid/state

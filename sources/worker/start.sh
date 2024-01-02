#!/usr/bin/env bash

set -x

if [ ! -z $WATCHMEDO ]; then
  watchmedo auto-restart --debounce-interval 1 --interval $WATCHMEDO_INTERVAL -d .  -d ../common  --patterns="*.py;*.egg" --recursive  --  start2.sh
else
  start2.sh
fi

echo ".process end ======================================================================= end process ."


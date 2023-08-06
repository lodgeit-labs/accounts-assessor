#!/usr/bin/env fish

./down.sh; time begin ./develop.sh --public_url "http://jj.internal:8877" --develop True --container_startup_sequencing False --offline True --stay_running False; ./health_check.sh ; end

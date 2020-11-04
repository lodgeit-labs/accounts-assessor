set -x WHAT frontend_server; and docker run -it  --mount source=tmp,target=/app/server_root/tmp  --entrypoint bash "koo5/$WHAT"

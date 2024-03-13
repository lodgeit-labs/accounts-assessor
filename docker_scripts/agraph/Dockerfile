# https://hub.docker.com/r/franzinc/agraph/tags?page=1&ordering=last_updated

FROM franzinc/agraph:v8.0.0




#start interval is the time between health checks during the start period. This option requires Docker Engine version 25.0 or later.
USER root
RUN mkdir /healthcheck
RUN chown agraph:agraph /healthcheck
USER agraph
ENV HC="agraph-control --config /agraph/etc/agraph.cfg status"
HEALTHCHECK --interval=2s --timeout=600s CMD { test -f /healthcheck/ok && echo -n "sleep.." && sleep 555 && echo -n "hc..>> " && /bin/sh -c '/bin/sh -c "$HC"' && echo -n " <<..hc passed." ; } || { echo -n "hc..>> " && echo -n "$HC" && echo -n " <<... " && /bin/sh -c '/bin/sh -c "$HC"' && echo -n " << first hc passed." && touch /healthcheck/ok && echo " flag stored." ; } 


#todo:
# docker exec -it (docker ps -aqf "name=robust_agraph_1") agtool user --server localhost:10077 add anonymous
# http://robust2.ueueeu.eu:10077/classic-webview#/repositories/pub/users - grant read on pub to anonymous



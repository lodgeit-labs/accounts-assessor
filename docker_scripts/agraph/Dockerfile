# https://hub.docker.com/r/franzinc/agraph/tags?page=1&ordering=last_updated

FROM franzinc/agraph:v7.2.0

# nope, can only do this after agraph generates it: 
#RUN sudo -c echo -e "CorsAllowOrigin www.irisa.fr\nCorsAllowCredentials yes\n" >> /agraph/etc/agraph.cfg





#start interval is the time between health checks during the start period. This option requires Docker Engine version 25.0 or later.
USER root
RUN mkdir /healthcheck
RUN chown agraph:agraph /healthcheck
USER agraph
ENV HC="agraph-control --config /agraph/etc/agraph.cfg status"
HEALTHCHECK --interval=2s --timeout=60s CMD { test -f /healthcheck/ok && echo -n "sleep.." && sleep 55 && echo -n "hc..>> " && /bin/sh -c '/bin/sh -c "$HC"' && echo -n " <<..hc passed." ; } || { echo -n "hc..>> " && echo -n "$HC" && echo -n " <<... " && /bin/sh -c '/bin/sh -c "$HC"' && echo -n " << first hc passed." && touch /healthcheck/ok && echo " flag stored." ; } 

FROM httpd:2


VOLUME /usr/local/apache2/htdocs/tmp/
VOLUME /usr/local/apache2/htdocs/static/
COPY conf/* /usr/local/apache2/conf/
ENV proxy-initial-not-pooled true

 
RUN apt-get update -y && \
    apt-get install -y curl dos2unix && \
    apt-get autoremove --purge -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 8877






ENV HC="curl -L -S --fail http://127.0.0.1:8877/health" 






#start interval is the time between health checks during the start period. This option requires Docker Engine version 25.0 or later.
RUN mkdir /healthcheck
HEALTHCHECK --interval=2s --timeout=60s CMD { test -f /healthcheck/ok && echo -n "sleep.." && sleep 55 && echo -n "hc..>> " && /bin/sh -c '/bin/sh -c "$HC"' && echo -n " <<..hc passed." ; } || { echo -n "hc..>> " && echo -n "$HC" && echo -n " <<... " && /bin/sh -c '/bin/sh -c "$HC"' && echo -n " << first hc passed." && touch /healthcheck/ok && echo " flag stored." ; } 



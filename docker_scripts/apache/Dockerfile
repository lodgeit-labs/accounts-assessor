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

ARG APACHE_HEALTHCHECK_INTERVAL=60s

EXPOSE 8877
HEALTHCHECK --interval={APACHE_HEALTHCHECK_INTERVAL} --timeout=50s --start-period=5s --retries=3 CMD curl -L -S --fail http://127.0.0.1:8877/

# todo make a non-hollow(with static files copy) Dockerfile

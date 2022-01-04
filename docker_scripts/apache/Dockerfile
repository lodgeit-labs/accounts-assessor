FROM httpd:2


VOLUME /usr/local/apache2/htdocs/tmp/
VOLUME /usr/local/apache2/htdocs/static/
COPY conf/* /usr/local/apache2/conf/
ENV proxy-initial-not-pooled true



# todo make a non-hollow(with static files copy) Dockerfile

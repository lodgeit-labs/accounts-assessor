# todo make a non-hollow(with static files copy) Dockerfile

FROM httpd:2.4.46-alpine

VOLUME /usr/local/apache2/htdocs/tmp/
VOLUME /usr/local/apache2/htdocs/static/



COPY apache/conf/* /usr/local/apache2/conf/



#VOLUME /usr/local/apache2/conf/
#RUN rm /usr/local/apache2/conf/httpd.conf
#VOLUME /usr/local/apache2/conf/httpd.conf
#VOLUME /usr/local/apache2/conf/htpasswd


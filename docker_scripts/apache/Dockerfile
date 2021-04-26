FROM httpd:2.4.46-alpine

COPY apache/conf/* /usr/local/apache2/conf/
#COPY apache/crypto/* /usr/local/apache2/conf/

# todo make a non-hollow(with static files copy) Dockerfile

#VOLUME /usr/local/apache2/conf/

#RUN rm /usr/local/apache2/conf/httpd.conf

#VOLUME /usr/local/apache2/conf/httpd.conf
#VOLUME /usr/local/apache2/conf/htpasswd

VOLUME /usr/local/apache2/htdocs/tmp/
VOLUME /usr/local/apache2/htdocs/static/


# todo use https://github.com/BirgerK/docker-apache-letsencrypt/blob/master/Dockerfile - maybe better not

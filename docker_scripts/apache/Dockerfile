# todo make a non-hollow(with static files copy) Dockerfile

FROM httpd:2



VOLUME /usr/local/apache2/htdocs/tmp/
VOLUME /usr/local/apache2/htdocs/static/



COPY conf/* /usr/local/apache2/conf/
#COPY conf /etc/apache2/conf.d/



ENV proxy-initial-not-pooled true



#RUN echo ServerName $ServerName >> /usr/local/apache2/conf/local.conf
#VOLUME /usr/local/apache2/conf/
#RUN rm /usr/local/apache2/conf/httpd.conf
#VOLUME /usr/local/apache2/conf/httpd.conf
#VOLUME /usr/local/apache2/conf/htpasswd



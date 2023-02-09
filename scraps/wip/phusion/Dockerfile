FROM phusion/passenger-customizable:1.0.15


ENV HOME /root

CMD ["/sbin/my_init"]

RUN /pd_build/python.sh

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN rm -f /etc/service/nginx/down




#non-hollow:
#COPY --chown=app:app /local/path/of/your/app /home/app/webapp

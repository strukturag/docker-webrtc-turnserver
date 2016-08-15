# docker build -t docker-webrtc-turnserver .
# docker run --rm --name my-turnserver-dev -i -v `pwd`/data:/srv -t docker-webrtc-turnserver

FROM phusion/baseimage:0.9.19
MAINTAINER Simon Eisenmann <simon@struktur.de>

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Install coturn.
RUN apt-get update && apt-get -y install \
	coturn
RUN mkdir /etc/service/coturn
ADD coturn.sh /etc/service/coturn/run
ADD coturn.logrotate /etc/logrotate.d/coturn

# Fix logrotate.
RUN sed -i 's/su root syslog/su root adm/g' /etc/logrotate.conf

# Get rid of sshd.
RUN rm -rf /etc/service/sshd && rm -f /etc/my_init.d/00_regen_ssh_host_keys.sh

VOLUME = /srv

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

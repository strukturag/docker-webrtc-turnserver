# Coturn TURN server in Docker
#
# This Dockerfile creates a container which runs a Coturn TURN server suitable
# for use with Spreed WebRTC.
#
# Install Docker and then run `docker build -t docker-webrtc-turnserver .` to
# build the image.
#
# Due to the nature of TURN, the container needs to use the hosts network. To
# configure the details, create the config file `data/config`. See the example
# in `data/config.example` for some ideas.
# ```
#
# Afterwards run the container like this:
#
#   ```
#   docker run --rm --net=host --name my-spreed-turnserver -i -v `pwd`/data:/srv -t spreed-turnserver
#   ```
#
# This runs the container with the settings as defined in the config file which is # made available to the container using the volume (-v) option. This volume is also
# used as storage for persistent data created by the TURN server.

FROM phusion/baseimage:0.9.19
MAINTAINER Simon Eisenmann <simon@struktur.de>

# Set locale.
RUN locale-gen --no-purge en_US.UTF-8
ENV LC_ALL en_US.UTF-8

ENV DEBIAN_FRONTEND noninteractive

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

# Allow volume.
VOLUME /srv

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

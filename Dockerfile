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
#   docker run --rm --net=host --name my-spreed-turnserver -i -v `pwd`/data:/srv -t monogramm/docker-coturn
#   ```
#
# This runs the container with the settings as defined in the config file which is
# made available to the container using the volume (-v) option. This volume is also
# used as storage for persistent data created by the TURN server.

# https://hub.docker.com/_/alpine
FROM alpine:edge

LABEL maintainer="mathieu.brunot at monogramm dot io"

# Environment variables for setup
ENV COTURN_VERSION=4.5.1.1 \
	LISTENING_PORT="3478" \
	TLS_LISTENING_PORT="5349" \
	ALT_LISTENING_PORT="3479" \
	ALT_TLS_LISTENING_PORT="5350" \
	REALM="localdomain" \
	MIN_PORT="49152" \
	MAX_PORT="65535" \
	# 5 Mbit/second per TURN session
	MAX_BPS="640000" \
	# 50 Mbit/second
	BPS_CAPACITY="6400000" \
	CIPHER_LIST="ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AES:RSA+3DES:!ADH:!AECDH:!MD5" \
	USER_QUOTA=100 \
	TOTAL_QUOTA=300 \
	USER_DB="/srv/turnserver/db/turndb.sqlite" \
	LOG_FILE="/srv/turnserver/logs/turn.log" \
	PID_FILE="/srv/turnserver/turn.pid"


# Add coturn
COPY docker-entrypoint.sh /entrypoint.sh

# Build and install Coturn
RUN set -ex; \
	chmod 755 /entrypoint.sh; \
	echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' \
	# TODO: remove after mongo-c-driver moves to main/community from testing
			>> /etc/apk/repositories \
	&& apk update \
	&& apk upgrade \
	&& apk add --no-cache \
			ca-certificates \
			curl \
	&& update-ca-certificates \
		\
	# Install Coturn dependencies
	&& apk add --no-cache \
			libevent \
			libcrypto1.1 libssl1.1 \
			libpq mariadb-connector-c sqlite-libs \
			hiredis mongo-c-driver \
		\
	# Install tools for building
	&& apk add --no-cache --virtual .tool-deps \
			coreutils autoconf g++ libtool make \
		\
	# Install Coturn build dependencies
	&& apk add --no-cache --virtual .build-deps \
			linux-headers \
			libevent-dev \
			openssl-dev \
			postgresql-dev mariadb-connector-c-dev sqlite-dev \
			hiredis-dev mongo-c-driver-dev \
		\
	# Download and prepare Coturn sources
	&& curl -fL -o /tmp/coturn.tar.gz \
			https://github.com/coturn/coturn/archive/$COTURN_VERSION.tar.gz \
	&& tar -xzf /tmp/coturn.tar.gz -C /tmp/ \
	&& cd /tmp/coturn-* \
		\
	# Build Coturn from sources
	&& ./configure --prefix=/usr \
			--turndbdir=/var/lib/coturn \
			--disable-rpath \
			--sysconfdir=/etc/coturn \
			# No documentation included to keep image size smaller
			--mandir=/tmp/coturn/man \
			--docsdir=/tmp/coturn/docs \
			--examplesdir=/tmp/coturn/examples \
	&& make \
		\
	# Install and configure Coturn
	&& make install \
	# Preserve license file
	&& mkdir -p /usr/share/licenses/coturn/ \
	&& cp /tmp/coturn/docs/LICENSE /usr/share/licenses/coturn/ \
	# Remove default config file
	&& rm -f /etc/coturn/turnserver.conf.default \
		\
	# Cleanup unnecessary stuff
	&& apk del .tool-deps .build-deps \
	&& rm -rf /var/cache/apk/* \
			/tmp/*

# Allow volume.
VOLUME /srv

WORKDIR /
ENTRYPOINT ["sh","/entrypoint.sh"]

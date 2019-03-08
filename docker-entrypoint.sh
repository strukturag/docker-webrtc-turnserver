#!/bin/bash
set -e

ARGS=()

mkdir -p /srv/turnserver
chown root.root /srv/turnserver
chmod 755 /srv/turnserver

if [ -e "/srv/config" ]; then
	. /srv/config
fi

if [ -z "$LISTENING_PORT" ]; then
    LISTENING_PORT="3478"
fi

if [ -z "$TLS_LISTENING_PORT" ]; then
	TLS_LISTENING_PORT="5349"
fi

if [ -z "$ALT_LISTENING_PORT" ]; then
	ALT_LISTENING_PORT="3479"
fi

if [ -z "$ALT_TLS_LISTENING_PORT" ]; then
	ALT_TLS_LISTENING_PORT="5350"
fi

for ip in $LISTEN_IPS; do
	ARGS+=" -L $ip"
done

for ip in $EXTERNAL_IPS; do
	ARGS+=" -X $ip"
done

ARGS+=" --listening-port=$LISTENING_PORT"
ARGS+=" --tls-listening-port=$TLS_LISTENING_PORT"
ARGS+=" --alt-listening-port=$ALT_LISTENING_PORT"
ARGS+=" --alt-tls-listening-port=$ALT_TLS_LISTENING_PORT"

if [ -n "$TLS_CERT" ]; then
	ARGS+=" --cert=$TLS_CERT"
fi

if [ -n "$TLS_KEY" ]; then
	ARGS+=" --pkey=$TLS_KEY"
fi

if [ -n "$DH_FILE" ]; then
	ARGS+=" --dh-file=$DH_FILE"
fi

if [ -n "$RELAY_IP" ]; then
	ARGS+=" --relay-ip=$RELAY_IP"
fi

if [ -n "$STATIC_AUTH_SECRET" ]; then
	ARGS+=" --lt-cred-mech --use-auth-secret --static-auth-secret=$STATIC_AUTH_SECRET"
fi

if [ -n "$RELAY_THREADS" ]; then
	ARGS+=" --relay-threads=$RELAY_THREADS"
fi

if [ -n "$NO_AUTH" ]; then
	ARGS+=" --no-auth"
fi

if [ "$VERBOSE" = "1" ]; then
	ARGS+=" --verbose"
fi

if [ "$DEBUG" = "1" ]; then
	ARGS+=" --Verbose"
fi

if [ -n "$REDIS_STATSDB" ]; then
	# Use like REDIS_STATSDB=mydb password=secret, and link with redis container, named redis.
	ARGS+=" --redis-statsdb=host=$REDIS_PORT_6379_TCP_ADDR dbname=$REDIS_STATSDB port=$REDIS_PORT_6379_TCP_PORT connect_timeout=30"
fi

if [ -z "$CIPHER_LIST" ]; then
	CIPHER_LIST="ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AES:RSA+3DES:!ADH:!AECDH:!MD5"
fi

if [ -z "$REALM" ]; then
	REALM="localdomain"
fi

if [ -z "$MIN_PORT"]; then
	MIN_PORT="49152"
fi

if [ -z "$MAX_PORT" ]; then
	MAX_PORT="65535"
fi

if [ -z "$MAX_BPS" ]; then
	MAX_BPS="640000" # 5 Mbit/second per TURN session
fi

if [ -z "$BPS_CAPACITY" ]; then
	BPS_CAPACITY="6400000" # 50 Mbit/second
fi

if [ -z "$USER_QUOTA" ]; then
	USER_QUOTA=100
fi

if [ -z "$TOTAL_QUOTA" ]; then
	TOTAL_QUOTA=300
fi

if [ -z "$USER_DB" ]; then
	USER_DB="/srv/turnserver/turndb"
fi

if [ -z "$LOG_FILE" ]; then
	LOG_FILE="syslog"
fi


sleep 2
exec /usr/bin/turnserver \
	-n \
	${ARGS[@]} \
	--no-cli \
	--log-file=$LOG_FILE \
	--no-stdout-log \
	--simple-log \
	--fingerprint \
	--dh2066 \
	--realm=$REALM \
	--stale-nonce \
	--check-origin-consistency \
	--no-loopback-peers \
	--no-multicast-peers \
	--min-port=$MIN_PORT \
	--max-port=$MAX_PORT \
	--max-bps=$MAX_BPS \
	--bps-capacity=$BPS_CAPACITY \
	--cipher-list=$CIPHER_LIST \
	--userdb=$USER_DB \
	--user-quota=$USER_QUOTA \
	--total-quota=$TOTAL_QUOTA

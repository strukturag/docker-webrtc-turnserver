#!/bin/sh
set -e

ARGS=""

echo "Initiliazing Coturn server directories..."

mkdir -p /srv/turnserver/db/
mkdir -p /srv/turnserver/logs/
chown root.root /srv/turnserver
chmod 755 /srv/turnserver

echo "Initiliazing Coturn server properties..."

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
	ARGS="$ARGS -L $ip"
done

for ip in $EXTERNAL_IPS; do
	ARGS="$ARGS -X $ip"
done

ARGS="$ARGS --listening-port=$LISTENING_PORT"
ARGS="$ARGS --tls-listening-port=$TLS_LISTENING_PORT"
ARGS="$ARGS --alt-listening-port=$ALT_LISTENING_PORT"
ARGS="$ARGS --alt-tls-listening-port=$ALT_TLS_LISTENING_PORT"

if [ -n "$TLS_CERT" ]; then
	echo "    - setting certificate file: $TLS_CERT"
	ARGS="$ARGS --cert=$TLS_CERT"
fi

if [ -n "$TLS_KEY" ]; then
	echo "    - setting private key file: $TLS_KEY"
	ARGS="$ARGS --pkey=$TLS_KEY"
fi

if [ -n "$WEB_ADMIN" ]; then
	echo "    - enabling web admin..."
	ARGS="$ARGS --web-admin"
fi

if [ -n "$WEB_ADMIN_IP" ]; then
	echo "    - setting web admin local system IP address: $WEB_ADMIN_IP"
	ARGS="$ARGS --web-admin-ip=$WEB_ADMIN_IP"
fi

if [ -n "$WEB_ADMIN_PORT" ]; then
	echo "    - setting web admin server port: $WEB_ADMIN_PORT"
	ARGS="$ARGS --web-admin-port=$WEB_ADMIN_PORT"
fi

if [ -n "$DH_FILE" ]; then
	echo "    - setting DH TLS key: $DH_FILE"
	ARGS="$ARGS --dh-file=$DH_FILE"
fi

if [ -n "$RELAY_IP" ]; then
	echo "    - setting relay IP: $RELAY_IP"
	ARGS="$ARGS --relay-ip=$RELAY_IP"
fi

if [ -n "$LONG_TERM_CREDENTIALS" ]; then
	echo "    - enabling long term credentials..."
	ARGS="$ARGS --lt-cred-mech"
fi

if [ -n "$STATIC_AUTH_SECRET" ]; then
	echo "    - setting auth secret..."
	ARGS="$ARGS --use-auth-secret --static-auth-secret=$STATIC_AUTH_SECRET"
fi

if [ -n "$SECURE_STUN" ]; then
	echo "    - enabling authentication of the STUN Binding request..."
	ARGS="$ARGS --secure-stun"
fi

if [ -n "$CLI_PASSWORD" ]; then
	echo "    - setting CLI password..."
	ARGS="$ARGS --cli-password=$(turnadmin -P -p $CLI_PASSWORD)"
fi

if [ -n "$RELAY_THREADS" ]; then
	echo "    - setting relay threads number: $RELAY_THREADS"
	ARGS="$ARGS --relay-threads=$RELAY_THREADS"
fi

if [ -n "$NO_AUTH" ]; then
	echo "    - disabling credential mechanism..."
	ARGS="$ARGS --no-auth"
fi

if [ -n "$PROD" ]; then
	echo "    - enabling production mode (hide the software version)..."
	ARGS="$ARGS --prod"
fi

if [ -n "$NO_STDOUT_LOG" ]; then
	echo "    - disabling stdout log messages..."
	ARGS="$ARGS --no-stdout-log"
fi

if [ -n "$SYSLOG" ]; then
	echo "    - enabling output all log information into the system log (syslog)..."
	ARGS="$ARGS --syslog"
fi

if [ -n "$SIMPLE_LOG" ]; then
	echo "    - enabling simple log file (no rolling out log file, simple file name)..."
	ARGS="$ARGS --simple-log"
fi

if [ "$VERBOSE" = "1" ]; then
	echo "    - enabling 'Moderate' verbose mode..."
	ARGS="$ARGS --verbose"
fi

if [ "$DEBUG" = "1" ]; then
	echo "    - enabling extra verbose mode (for debug purposes only)..."
	ARGS="$ARGS --Verbose"
fi

if [ -n "$REDIS_STATSDB" ]; then
	# Use like REDIS_STATSDB=mydb password=secret, and link with redis container, named redis.
	ARGS="$ARGS --redis-statsdb=host=$REDIS_PORT_6379_TCP_ADDR dbname=$REDIS_STATSDB port=$REDIS_PORT_6379_TCP_PORT connect_timeout=30"
fi

if [ -z "$CIPHER_LIST" ]; then
	CIPHER_LIST="ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AES:RSA+3DES:!ADH:!AECDH:!MD5"
fi

if [ -z "$REALM" ]; then
	REALM="localdomain"
fi

if [ -z "$MIN_PORT" ]; then
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
	USER_DB="/srv/turnserver/db/turndb.sqlite"
fi

if [ -z "$LOG_FILE" ]; then
	LOG_FILE="/srv/turnserver/logs/turn.log"
fi

sleep 2

echo "Starting Coturn server..."
exec turnserver \
	-n \
	$ARGS \
	--no-cli \
	--log-file=$LOG_FILE \
	--fingerprint \
	--dh2066 \
	--realm=$REALM \
	--stale-nonce \
	--check-origin-consistency \
	--no-multicast-peers \
	--min-port=$MIN_PORT \
	--max-port=$MAX_PORT \
	--max-bps=$MAX_BPS \
	--bps-capacity=$BPS_CAPACITY \
	--cipher-list=$CIPHER_LIST \
	--userdb=$USER_DB \
	--user-quota=$USER_QUOTA \
	--total-quota=$TOTAL_QUOTA

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

if [ -n "$LISTEN_IPS" ]; then
	echo "    - setting listener IP address of relay server: $LISTEN_IPS"
	for ip in $LISTEN_IPS; do
		ARGS="$ARGS -L $ip"
	done
fi

if [ -n "$EXTERNAL_IPS" ]; then
	echo "    - setting TURN Server public/private address mapping: $EXTERNAL_IPS"
	for ip in $EXTERNAL_IPS; do
		ARGS="$ARGS -X $ip"
	done
fi

if [ -n "$TLS_CERT" ]; then
	echo "    - setting certificate file: $TLS_CERT"
	ARGS="$ARGS --cert=$TLS_CERT"
fi

if [ -n "$TLS_KEY" ]; then
	echo "    - setting private key file: $TLS_KEY"
	ARGS="$ARGS --pkey=$TLS_KEY"
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
	echo "    - enabling long term credentials (needed for WebRTC usage)..."
	ARGS="$ARGS --lt-cred-mech"
fi

if [ -n "$STATIC_AUTH_SECRET" ]; then
	echo "    - setting auth secret (needed for TURN Server REST API)..."
	ARGS="$ARGS --use-auth-secret --static-auth-secret=$STATIC_AUTH_SECRET"
fi

if [ -n "$SECURE_STUN" ]; then
	echo "    - enabling authentication of the STUN Binding request..."
	ARGS="$ARGS --secure-stun"
fi

if [ -n "$NO_CLI" ]; then
	echo "    - disabling CLI..."
	ARGS="$ARGS --no-cli"
fi

if [ -n "$CLI_IP" ]; then
	echo "    - setting local system IP address to be used for CLI server endpoint: $CLI_IP"
	ARGS="$ARGS --cli-ip=$CLI_IP"
fi

if [ -n "$CLI_PORT" ]; then
	echo "    - setting CLI server port: $CLI_PORT"
	ARGS="$ARGS --cli-port=$CLI_PORT"
fi

if [ -n "$CLI_PASSWORD" ]; then
	echo "    - setting CLI password..."
	ARGS="$ARGS --cli-password=$(turnadmin -P -p $CLI_PASSWORD | sed -e 's|\\$|\\\\$|g')"
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

if [ -n "$WEB_ADMIN_PASSWORD" ]; then

	if [ -z "$WEB_ADMIN_USERNAME" ]; then
		WEB_ADMIN_USERNAME=root
	fi

	if ! echo "$(turnadmin -L -b $USER_DB)" | grep -q "^$WEB_ADMIN_USERNAME$"; then
		echo "    - setting Web Admin user '$WEB_ADMIN_USERNAME'..."
		turnadmin -A -b $USER_DB -u $WEB_ADMIN_USERNAME -p "$(turnadmin -P -p $WEB_ADMIN_PASSWORD | sed -e 's|\\$|\\\\$|g')"
	else
		echo "    - Web Admin user '$WEB_ADMIN_USERNAME' already set"
	fi
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
	echo "    - enabling REDIS statistics database..."
	# Use like REDIS_STATSDB=mydb password=secret, and link with redis container, named redis.
	ARGS="$ARGS --redis-statsdb=host=$REDIS_PORT_6379_TCP_ADDR dbname=$REDIS_STATSDB port=$REDIS_PORT_6379_TCP_PORT connect_timeout=30"
fi

sleep 2

echo "Starting Coturn server..."
exec turnserver \
	-n \
	$ARGS \
	--fingerprint \
	--dh2066 \
	--stale-nonce \
	--check-origin-consistency \
	--no-multicast-peers \
	--listening-port=$LISTENING_PORT \
	--tls-listening-port=$TLS_LISTENING_PORT \
	--alt-listening-port=$ALT_LISTENING_PORT \
	--alt-tls-listening-port=$ALT_TLS_LISTENING_PORT \
	--realm=$REALM \
	--min-port=$MIN_PORT \
	--max-port=$MAX_PORT \
	--max-bps=$MAX_BPS \
	--bps-capacity=$BPS_CAPACITY \
	--cipher-list=$CIPHER_LIST \
	--userdb=$USER_DB \
	--user-quota=$USER_QUOTA \
	--total-quota=$TOTAL_QUOTA \
	--log-file=$LOG_FILE \
	--pidfile=$PID_FILE

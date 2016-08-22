# Docker image for Coturn suitable for WebRTC

This Docker repository provides the [Coturn](https://github.com/coturn/coturn) TURN server with a configuration suitable to use with [Spreed WebRTC](https://github.com/strukturag/spreed-webrtc).

## Build Docker image

Install Docker and then run `docker build -t docker-webrtc-turnserver .` to build the image.

## TURN server configuration for WebRTC

To get the best out of TURN it is required to have two different routable IP addresses, you can run it with one but will loose [RFC-5780](https://tools.ietf.org/html/rfc5780) support.

Also the TURN server supports TLS encryption for TURN and STUN requests. This is optional and not required. Not encrypting TURN and STUN does leak end-point information to the wire but the WebRTC connection going through TURN is still end-to-end encrypted, no matter if TURN/STUN is encrypted or not. If you choose to use TURN with TLS make sure to provide a certificate including the full chain and configure the TURN hostnames to match what is in the certificate as normal certificate validation is done. Also note that TURN with TLS is currently [not supported by Firefox](https://bugzilla.mozilla.org/show_bug.cgi?id=1056934) - so make sure to include turns: and turn: endpoints in the configuration. The TURN server supports all enabled protocols on all ports.

Furthermore, to get best firewall traversal it is recommended to let the TURN server listen on port 443 and solely use that port in client configurations.

Due to the nature of TURN, the container needs to use the hosts network. To  configure the details, create the config file `data/config` like this minimal example:

```
LISTENING_PORT=443
ALT_LISTENING_PORT=3478
LISTEN_IPS="##FIRST_IP## ##SECOND_IP##"
RELAY_IP=##FIRST_IP##
STATIC_AUTH_SECRET=##SECRET##
REALM=myturnserver
VERBOSE=1
```

Of course replace the ##placeholders## with the appropriate values. Also as we are using host networking, make sure the IPs you use here are actually configured and up.

There are many more configuration settings. See `data/config.example` for a full production ready example. For the whole list see the `coturn.sh` script.


## Run TURN server Docker image

```
docker run --rm --net=host --name my-webrtc-turnserver -i -v `pwd`/data:/srv -t docker-webrtc-turnserver
```

This runs the container with the settings as defined in the `config` file which is  made available to the container using the volume (-v) option. This volume is also used as storage for persistent data created by the TURN server.


## Spreed WebRTC integration

When the TURN server is running, make sure you have set `STATIC_AUTH_SECRET` in the `config` file. That is the value you need to use as `turnSecret` in the Spreed WebRTC `server.conf`. Last do not forget to also set `turnURIs` to point to your TURN servers end points and provided protocols.

```
turnSecret = ##SECRET##
turnURIs = turn:##FIRST_IP##:443?transport=udp turn:##FIRST_IP##:443?transport=tcp
```

Or, if you have configured TLS for TURN:

```
turnSecret = ##SECRET##
turnURIs = turns:##FQDN##:443?transport=udp turns:##FQDN##:443?transport=tcp turn:##FQDN##:443?transport=udp turn:##FQDN##:443?transport=tcp
```

Of course you can always use the full qualified domain name (##FQDN##) if you have it (DNS configuration) but it is only mandatory for TURN/STUN with TLS.

And last, you can disable the `stunURIs` setting, as the TURN server will also provide STUN automatically.

Do not forget to restart Spreed WebRTC and to reload the Web client to receive new TURN credentials.


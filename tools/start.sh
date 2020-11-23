#!/bin/bash -ue

port=${PORT:-1194}

[ -c /dev/net/tun ] || ( mkdir -p /dev/net && mknod /dev/net/tun c 10 200 )

# Options relevant to external environment are configured here
openvpn \
    --config /etc/openvpn/openvpn.conf \
    --mode server \
    --port $port \
    --proto udp4 \
    --user nobody \
    --group nogroup \
    --verb 3 \
    --status /var/lib/openvpn/status 1 \
    --status-version 3

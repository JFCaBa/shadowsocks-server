#!/bin/bash

set -e

# Configuration
CONFIG_FILE="/etc/shadowsocks/config.json"

# Check if password is provided as environment variable
if [ ! -z "$SHADOWSOCKS_PASSWORD" ]; then
    # Generate config from template using printf to properly escape special characters for sed
    ESCAPED_PASSWORD=$(printf '%s\n' "$SHADOWSOCKS_PASSWORD" | sed -e 's/[]\/$*.^|()+{}[]/\\&/g')
    sed "s@__PASSWORD__@$ESCAPED_PASSWORD@g" /etc/shadowsocks/config.json.template > $CONFIG_FILE
else
    # Copy the template as is (assuming password is already hardcoded)
    cp /etc/shadowsocks/config.json.template $CONFIG_FILE
fi

# Use provided values or defaults
if [ ! -z "$SHADOWSOCKS_SERVER_PORT" ]; then
    sed -i "s|\"server_port\": [0-9]*|\"server_port\": $SHADOWSOCKS_SERVER_PORT|g" $CONFIG_FILE
fi

if [ ! -z "$SHADOWSOCKS_METHOD" ]; then
    sed -i "s|\"method\": \"[^\"]*\"|\"method\": \"$SHADOWSOCKS_METHOD\"|g" $CONFIG_FILE
fi

if [ ! -z "$SHADOWSOCKS_PATH" ]; then
    sed -i "s|path=[^;]*|path=$SHADOWSOCKS_PATH|g" $CONFIG_FILE
fi

if [ ! -z "$SHADOWSOCKS_HOST" ]; then
    sed -i "s|host=[^;]*|host=$SHADOWSOCKS_HOST|g" $CONFIG_FILE
fi

echo "Starting Shadowsocks server with configuration:"
cat $CONFIG_FILE

# Start the Shadowsocks server in the foreground
exec ss-server -c $CONFIG_FILE
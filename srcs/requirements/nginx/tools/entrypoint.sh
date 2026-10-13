#!/bin/sh
set -e

SSL_DIR=/etc/nginx/ssl

if [ -z "$DOMAIN_NAME" ]; then
    echo "DOMAIN_NAME is not set" >&2
    exit 1
fi

if [ ! -f "$SSL_DIR/inception.crt" ]; then
    mkdir -p "$SSL_DIR"
    openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
        -keyout "$SSL_DIR/inception.key" -out "$SSL_DIR/inception.crt" \
        -subj "/C=BR/ST=SP/L=Sao Paulo/O=42/CN=$DOMAIN_NAME" \
        -addext "subjectAltName=DNS:$DOMAIN_NAME,DNS:www.$DOMAIN_NAME" 2> /dev/null
    chmod 600 "$SSL_DIR/inception.key"
fi

sed "s/__DOMAIN_NAME__/$DOMAIN_NAME/g" /etc/nginx/inception.conf.template \
    > /etc/nginx/http.d/default.conf

exec "$@"

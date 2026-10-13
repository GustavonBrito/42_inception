FROM alpine:3.23

ARG ADMINER_VERSION=5.4.1

RUN apk add --no-cache php84 php84-session php84-mysqli php84-pdo_mysql curl && \
    mkdir -p /var/www && \
    curl -fsSL -o /var/www/index.php \
        https://github.com/vrana/adminer/releases/download/v${ADMINER_VERSION}/adminer-${ADMINER_VERSION}.php

USER nobody

EXPOSE 8080

CMD ["php84", "-S", "0.0.0.0:8080", "-t", "/var/www"]
